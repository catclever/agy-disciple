#!/bin/bash
# ==============================================================================
# jules_watchdog.sh - Google Jules Autonomous Cloud Watchdog
# Part of the agy-disciple multi-agent plugin suite.
#
# Dispatches coding/ops tasks to Google Jules, monitors session status,
# captures PR deliverables, and supports autonomous PR auto-merge.
# ==============================================================================

# Default configurations
BRANCH="main"
AUTO_MERGE=false
POLL_INTERVAL=30
TASK_ID=""
REPO=""
PROMPT=""
API_KEY=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -t|--task) TASK_ID="$2"; shift ;;
        -r|--repo) REPO="$2"; shift ;;
        -b|--branch) BRANCH="$2"; shift ;;
        -p|--prompt) PROMPT="$2"; shift ;;
        -k|--api-key) API_KEY="$2"; shift ;;
        --auto-merge) AUTO_MERGE=true ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [[ -z "$TASK_ID" || -z "$REPO" || -z "$PROMPT" ]]; then
    echo "Usage: $0 -t <Task_ID> -r <owner/repo> -p <Prompt> [-b <branch>] [-k <API_KEY>] [--auto-merge]"
    echo "Example: $0 -t auth_001 -r owner/repo -p 'Fix JWT expiration bug' --auto-merge"
    exit 1
fi

SIGNAL_FILE="/tmp/${TASK_ID}.signal"
LOG_FILE="/tmp/jules_${TASK_ID}.log"

# Clean up any leftover signal file
rm -f "$SIGNAL_FILE"

# Resolve API Key from argument, env, or user config
if [[ -z "$API_KEY" ]]; then
    API_KEY="$JULES_API_KEY"
fi
if [[ -z "$API_KEY" && -f "$HOME/.config/jules/env" ]]; then
    source "$HOME/.config/jules/env"
    API_KEY="$JULES_API_KEY"
fi

echo "=== Jules Watchdog Initialized ===" | tee "$LOG_FILE"
echo "Task ID         : $TASK_ID" | tee -a "$LOG_FILE"
echo "Target Repo     : $REPO" | tee -a "$LOG_FILE"
echo "Starting Branch : $BRANCH" | tee -a "$LOG_FILE"
echo "Auto Merge      : $AUTO_MERGE" | tee -a "$LOG_FILE"

# ------------------------------------------------------------------------------
# 1. Dispatching to Jules (API or CLI)
# ------------------------------------------------------------------------------
SESSION_ID=""

if [[ -n "$API_KEY" ]]; then
    echo "Authenticating via Jules REST API..." | tee -a "$LOG_FILE"
    
    PAYLOAD=$(jq -n \
      --arg prompt "$PROMPT" \
      --arg repo "sources/github/$REPO" \
      --arg branch "$BRANCH" \
      --arg title "Task $TASK_ID" \
      '{
        prompt: $prompt,
        sourceContext: {
          source: $repo,
          githubRepoContext: {
            startingBranch: $branch
          }
        },
        automationMode: "AUTO_CREATE_PR",
        title: $title
      }')

    RESP=$(curl -s -X POST "https://jules.googleapis.com/v1alpha/sessions" \
      -H "X-Goog-Api-Key: $API_KEY" \
      -H "Content-Type: application/json" \
      -d "$PAYLOAD")

    echo "API Response: $RESP" >> "$LOG_FILE"
    SESSION_ID=$(echo "$RESP" | jq -r '.name // empty')

    if [[ -z "$SESSION_ID" ]]; then
        ERR_MSG=$(echo "$RESP" | jq -r '.error.message // "Failed to create Jules session"')
        echo "FAILED: $ERR_MSG" | tee -a "$LOG_FILE"
        echo "FAILED: $ERR_MSG" > "$SIGNAL_FILE"
        exit 1
    fi
else
    # Fallback to CLI
    echo "JULES_API_KEY not found. Attempting CLI fallback (jules remote new)..." | tee -a "$LOG_FILE"
    CLI_OUTPUT=$(jules remote new --repo "$REPO" --session "$PROMPT" 2>&1)
    echo "$CLI_OUTPUT" >> "$LOG_FILE"

    if [[ "$CLI_OUTPUT" == *"did you forget to login"* || "$CLI_OUTPUT" == *"without a valid client"* ]]; then
        echo "FAILED: Neither JULES_API_KEY is configured nor jules CLI is logged in." | tee -a "$LOG_FILE"
        echo "FAILED: MISSING_AUTH - Please set JULES_API_KEY or run jules login" > "$SIGNAL_FILE"
        exit 1
    fi

    SESSION_ID=$(echo "$CLI_OUTPUT" | grep -oE "sessions/[a-zA-Z0-9_-]+" | head -n 1)
    if [[ -z "$SESSION_ID" ]]; then
        SESSION_ID=$(echo "$CLI_OUTPUT" | grep -oE "[0-9]{5,}" | head -n 1)
    fi
fi

echo "Jules Session Created: $SESSION_ID" | tee -a "$LOG_FILE"
echo "IN_PROGRESS: $SESSION_ID" > "$SIGNAL_FILE"

# ------------------------------------------------------------------------------
# 2. Polling for Completion
# ------------------------------------------------------------------------------
echo "Monitoring Jules Session for completion..." | tee -a "$LOG_FILE"

while true; do
    sleep "$POLL_INTERVAL"

    if [[ -n "$API_KEY" ]]; then
        STATUS_RESP=$(curl -s "https://jules.googleapis.com/v1alpha/${SESSION_ID}" -H "X-Goog-Api-Key: $API_KEY")
        STATE=$(echo "$STATUS_RESP" | jq -r '.state // empty')
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Current State: $STATE" >> "$LOG_FILE"

        if [[ "$STATE" == "SUCCEEDED" || "$STATE" == "COMPLETED" ]]; then
            PR_URL=$(echo "$STATUS_RESP" | jq -r '.. | .url? // empty' | grep -E "github.com/[^/]+/[^/]+/pull/[0-9]+" | head -n 1)
            if [[ -z "$PR_URL" ]]; then
                PR_URL=$(echo "$STATUS_RESP" | jq -r '.outputs.pullRequestUrl // .pullRequest.url // empty')
            fi

            echo "Jules task finished successfully. PR URL: $PR_URL" | tee -a "$LOG_FILE"

            # Check if Auto Merge is requested
            if [[ "$AUTO_MERGE" == "true" && -n "$PR_URL" ]]; then
                echo "Auto-merge enabled. Attempting gh pr merge..." | tee -a "$LOG_FILE"
                MERGE_OUT=$(gh pr merge "$PR_URL" --squash --auto 2>&1 || gh pr merge "$PR_URL" --squash 2>&1)
                echo "Merge output: $MERGE_OUT" >> "$LOG_FILE"
                echo "DONE: PR Merged: $PR_URL" > "$SIGNAL_FILE"
            else
                echo "DONE: PR Created: $PR_URL" > "$SIGNAL_FILE"
            fi
            break

        elif [[ "$STATE" == "FAILED" || "$STATE" == "CANCELLED" ]]; then
            ERR_MSG=$(echo "$STATUS_RESP" | jq -r '.error.message // "Jules session failed"')
            echo "Jules task failed: $ERR_MSG" | tee -a "$LOG_FILE"
            echo "FAILED: $ERR_MSG" > "$SIGNAL_FILE"
            break
        fi
    else
        # CLI Polling fallback
        CLI_LIST=$(jules remote list --session 2>&1)
        if echo "$CLI_LIST" | grep -q "$SESSION_ID.*COMPLETED"; then
            echo "DONE: Jules session $SESSION_ID completed via CLI" | tee -a "$LOG_FILE"
            echo "DONE: Session $SESSION_ID Completed" > "$SIGNAL_FILE"
            break
        elif echo "$CLI_LIST" | grep -q "$SESSION_ID.*FAILED"; then
            echo "FAILED: Jules session $SESSION_ID failed via CLI" | tee -a "$LOG_FILE"
            echo "FAILED: Session $SESSION_ID Failed" > "$SIGNAL_FILE"
            break
        fi
    fi
done

echo "Watchdog Finished with status: $(cat "$SIGNAL_FILE")" | tee -a "$LOG_FILE"

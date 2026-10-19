#!/bin/bash
# ==============================================================================
# jules_watchdog.sh - Google Jules Autonomous Cloud Watchdog
# Part of the agy-disciple multi-agent plugin suite.
#
# Dispatches coding/ops tasks to Google Jules, monitors session status,
# captures PR deliverables, and supports autonomous PR auto-merge.
# Includes pre-flight Git auto-commit & push synchronization check.
# Supports Dual Modes:
#   - Standard Mode (Default): Preserves human plan approval & feedback.
#   - Autonomous Mode (--autonomous): Activates Defenses 1, 2, 3 for zero-stalls.
# ==============================================================================

# Default values
BRANCH="main"
AUTO_MERGE=false
AUTONOMOUS=false
MAX_AUTO_REPLIES=3
AUTO_REPLY_COUNT=0
POLL_INTERVAL=30
TASK_ID=""
REPO=""
PROMPT=""
API_KEY=""
PROJECT_DIR=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -t|--task) TASK_ID="$2"; shift ;;
        -r|--repo) REPO="$2"; shift ;;
        -b|--branch) BRANCH="$2"; shift ;;
        -p|--prompt) PROMPT="$2"; shift ;;
        -d|--dir) PROJECT_DIR="$2"; shift ;;
        -k|--api-key) API_KEY="$2"; shift ;;
        --auto-merge) AUTO_MERGE=true ;;
        --autonomous|--auto-approve) AUTONOMOUS=true ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [[ -z "$TASK_ID" || -z "$REPO" || -z "$PROMPT" ]]; then
    echo "Usage: $0 -t <Task_ID> -r <owner/repo> -p <Prompt> [-d <Project_Dir>] [-b <branch>] [-k <API_KEY>] [--autonomous] [--auto-merge]"
    exit 1
fi

SIGNAL_FILE="/tmp/${TASK_ID}.signal"
LOG_FILE="/tmp/jules_${TASK_ID}.log"

# Clean up any leftover signal file
rm -f "$SIGNAL_FILE"

# Resolve API Key
if [[ -z "$API_KEY" ]]; then
    API_KEY="$JULES_API_KEY"
fi

# Fallback: Check ~/.config/jules/env or shell profiles if not in current environment
if [[ -z "$API_KEY" ]]; then
    if [[ -f "$HOME/.config/jules/env" ]]; then
        source "$HOME/.config/jules/env"
        API_KEY="$JULES_API_KEY"
    fi
fi

echo "=== Jules Watchdog Initialized ===" | tee "$LOG_FILE"
echo "Task ID         : $TASK_ID" | tee -a "$LOG_FILE"
echo "Target Repo     : $REPO" | tee -a "$LOG_FILE"
echo "Starting Branch : $BRANCH" | tee -a "$LOG_FILE"
echo "Project Dir     : ${PROJECT_DIR:-'(Not specified, checking PWD)'}" | tee -a "$LOG_FILE"
echo "Autonomous Mode : $AUTONOMOUS (Defenses 1, 2, 3)" | tee -a "$LOG_FILE"
echo "Auto Merge      : $AUTO_MERGE" | tee -a "$LOG_FILE"

# ------------------------------------------------------------------------------
# 0. Git Pre-Flight Synchronization
# Ensures local Git state matches remote origin before Jules dispatches.
# If not synced, commit and push. If any step fails, abort immediately.
# ------------------------------------------------------------------------------
TARGET_GIT_DIR=""
if [[ -n "$PROJECT_DIR" ]]; then
    if [[ ! -d "$PROJECT_DIR" ]]; then
        echo "FAILED: Specified project directory does not exist: $PROJECT_DIR" | tee -a "$LOG_FILE"
        echo "FAILED: GIT_DIR_NOT_FOUND" > "$SIGNAL_FILE"
        exit 1
    fi
    TARGET_GIT_DIR="$PROJECT_DIR"
elif git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    TARGET_GIT_DIR="$PWD"
fi

if [[ -n "$TARGET_GIT_DIR" ]]; then
    echo "Checking Git synchronization in: $TARGET_GIT_DIR" | tee -a "$LOG_FILE"
    cd "$TARGET_GIT_DIR" || {
        echo "FAILED: Cannot enter directory $TARGET_GIT_DIR" | tee -a "$LOG_FILE"
        echo "FAILED: GIT_CD_FAILED" > "$SIGNAL_FILE"
        exit 1
    }

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "FAILED: $TARGET_GIT_DIR is not a Git repository" | tee -a "$LOG_FILE"
        echo "FAILED: NOT_A_GIT_REPO" > "$SIGNAL_FILE"
        exit 1
    fi

    # 1. Commit uncommitted changes if any
    if [[ -n $(git status --porcelain) ]]; then
        echo "Uncommitted changes detected. Committing..." | tee -a "$LOG_FILE"
        git add -A 2>&1 | tee -a "$LOG_FILE"
        if ! git commit -m "chore(auto): pre-jules sync checkpoint for task ${TASK_ID}" 2>&1 | tee -a "$LOG_FILE"; then
            echo "FAILED: Failed to commit local changes" | tee -a "$LOG_FILE"
            echo "FAILED: GIT_COMMIT_FAILED" > "$SIGNAL_FILE"
            exit 1
        fi
    else
        echo "Working tree clean." | tee -a "$LOG_FILE"
    fi

    # 2. Fetch remote branch
    echo "Fetching remote origin/${BRANCH}..." | tee -a "$LOG_FILE"
    if ! git fetch origin "$BRANCH" 2>&1 | tee -a "$LOG_FILE"; then
        echo "FAILED: Failed to fetch origin/${BRANCH}" | tee -a "$LOG_FILE"
        echo "FAILED: GIT_FETCH_FAILED" > "$SIGNAL_FILE"
        exit 1
    fi

    # 3. Check divergence between local and remote
    LOCAL_REV=$(git rev-parse HEAD 2>/dev/null)
    REMOTE_REV=$(git rev-parse "origin/${BRANCH}" 2>/dev/null)

    if [[ "$LOCAL_REV" != "$REMOTE_REV" ]]; then
        echo "Local ($LOCAL_REV) and remote ($REMOTE_REV) differ. Synchronizing..." | tee -a "$LOG_FILE"

        BEHIND=$(git rev-list --count HEAD.."origin/${BRANCH}" 2>/dev/null || echo 0)
        AHEAD=$(git rev-list --count "origin/${BRANCH}"..HEAD 2>/dev/null || echo 0)

        if [[ "$BEHIND" -gt 0 ]]; then
            echo "Local is $BEHIND commit(s) behind remote. Attempting rebase..." | tee -a "$LOG_FILE"
            if ! git pull --rebase origin "$BRANCH" 2>&1 | tee -a "$LOG_FILE"; then
                echo "FAILED: Conflict or error during git pull --rebase" | tee -a "$LOG_FILE"
                git rebase --abort 2>/dev/null || true
                echo "FAILED: GIT_PULL_REBASE_FAILED" > "$SIGNAL_FILE"
                exit 1
            fi
        fi

        echo "Pushing local changes to origin/${BRANCH}..." | tee -a "$LOG_FILE"
        if ! git push origin "$BRANCH" 2>&1 | tee -a "$LOG_FILE"; then
            echo "FAILED: Failed to push to origin/${BRANCH}" | tee -a "$LOG_FILE"
            echo "FAILED: GIT_PUSH_FAILED" > "$SIGNAL_FILE"
            exit 1
        fi

        # Verify sync state again
        git fetch origin "$BRANCH" >/dev/null 2>&1
        LOCAL_REV=$(git rev-parse HEAD 2>/dev/null)
        REMOTE_REV=$(git rev-parse "origin/${BRANCH}" 2>/dev/null)

        if [[ "$LOCAL_REV" != "$REMOTE_REV" ]]; then
            echo "FAILED: Git local and remote are still not synchronized after push/pull" | tee -a "$LOG_FILE"
            echo "FAILED: GIT_SYNC_VERIFY_FAILED" > "$SIGNAL_FILE"
            exit 1
        fi
    fi

    echo "Git pre-flight sync successful: HEAD is aligned with origin/${BRANCH} ($LOCAL_REV)." | tee -a "$LOG_FILE"
else
    echo "No Git workspace specified or detected. Skipping local Git pre-flight sync." | tee -a "$LOG_FILE"
fi

# ------------------------------------------------------------------------------
# 1. Dispatching to Jules (API or CLI)
# Defense 1: If Autonomous Mode is on, requirePlanApproval=false suppresses manual stop.
# ------------------------------------------------------------------------------
SESSION_ID=""

if [[ "$AUTONOMOUS" == "true" ]]; then
    REQUIRE_PLAN_APPROVAL=false
else
    REQUIRE_PLAN_APPROVAL=true
fi

if [[ -n "$API_KEY" ]]; then
    echo "Using Jules REST API (API Key authenticated)..." | tee -a "$LOG_FILE"
    echo "requirePlanApproval set to: $REQUIRE_PLAN_APPROVAL" | tee -a "$LOG_FILE"
    
    PAYLOAD=$(jq -n \
      --arg prompt "$PROMPT" \
      --arg repo "sources/github/$REPO" \
      --arg branch "$BRANCH" \
      --arg title "Task $TASK_ID" \
      --argjson requirePlan "$REQUIRE_PLAN_APPROVAL" \
      '{
        prompt: $prompt,
        sourceContext: {
          source: $repo,
          githubRepoContext: {
            startingBranch: $branch
          }
        },
        requirePlanApproval: $requirePlan,
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

    # Attempt to extract session ID from CLI output
    SESSION_ID=$(echo "$CLI_OUTPUT" | grep -oE "sessions/[a-zA-Z0-9_-]+" | head -n 1)
    if [[ -z "$SESSION_ID" ]]; then
        SESSION_ID=$(echo "$CLI_OUTPUT" | grep -oE "[0-9]{5,}" | head -n 1)
    fi
fi

echo "Jules Session Created: $SESSION_ID" | tee -a "$LOG_FILE"
echo "IN_PROGRESS: $SESSION_ID" > "$SIGNAL_FILE"

# ------------------------------------------------------------------------------
# 2. Polling for Completion & Handling Confirmations (Defenses 2 & 3)
# ------------------------------------------------------------------------------
echo "Monitoring Jules Session for completion..." | tee -a "$LOG_FILE"

while true; do
    sleep "$POLL_INTERVAL"

    if [[ -n "$API_KEY" ]]; then
        STATUS_RESP=$(curl -s "https://jules.googleapis.com/v1alpha/${SESSION_ID}" -H "X-Goog-Api-Key: $API_KEY")
        STATE=$(echo "$STATUS_RESP" | jq -r '.state // empty')
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Current State: $STATE" >> "$LOG_FILE"

        # Reset auto-reply counter when session transitions away from AWAITING_USER_FEEDBACK
        if [[ "$STATE" != "AWAITING_USER_FEEDBACK" && "$AUTO_REPLY_COUNT" -gt 0 ]]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] State transitioned to $STATE. Resetting auto-feedback counter to 0." >> "$LOG_FILE"
            AUTO_REPLY_COUNT=0
        fi

        # Defense 2: Auto-approve plan if Jules enters AWAITING_PLAN_APPROVAL
        if [[ "$STATE" == "AWAITING_PLAN_APPROVAL" ]]; then
            if [[ "$AUTONOMOUS" == "true" ]]; then
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] [Defense 2] Auto-approving plan for session $SESSION_ID..." | tee -a "$LOG_FILE"
                APPROVE_RESP=$(curl -s -X POST "https://jules.googleapis.com/v1alpha/${SESSION_ID}:approvePlan" \
                  -H "X-Goog-Api-Key: $API_KEY" \
                  -H "Content-Type: application/json")
                echo "ApprovePlan Response: $APPROVE_RESP" >> "$LOG_FILE"
            else
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Session is awaiting manual plan approval at https://jules.google.com" >> "$LOG_FILE"
            fi

        # Defense 3: Auto-respond if Jules asks clarifying questions (AWAITING_USER_FEEDBACK)
        elif [[ "$STATE" == "AWAITING_USER_FEEDBACK" ]]; then
            if [[ "$AUTONOMOUS" == "true" ]]; then
                if [[ "$AUTO_REPLY_COUNT" -lt "$MAX_AUTO_REPLIES" ]]; then
                    AUTO_REPLY_COUNT=$((AUTO_REPLY_COUNT + 1))
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [Defense 3] Auto-responding to clarification ($AUTO_REPLY_COUNT/$MAX_AUTO_REPLIES)..." | tee -a "$LOG_FILE"
                    MSG_RESP=$(curl -s -X POST "https://jules.googleapis.com/v1alpha/${SESSION_ID}:sendMessage" \
                      -H "X-Goog-Api-Key: $API_KEY" \
                      -H "Content-Type: application/json" \
                      -d '{"prompt": "Please proceed with your recommended best practice solution."}')
                    echo "SendMessage Response: $MSG_RESP" >> "$LOG_FILE"
                else
                    # Do NOT break the loop! Stop sending messages in this branch, keep polling and allow manual/agent progress.
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [Defense 3] Max auto-replies ($MAX_AUTO_REPLIES) reached for current inquiry. Suppressing further auto-messages; continuing to monitor..." >> "$LOG_FILE"
                fi
            else
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Session is awaiting manual user feedback at https://jules.google.com" >> "$LOG_FILE"
            fi

        elif [[ "$STATE" == "SUCCEEDED" || "$STATE" == "COMPLETED" ]]; then
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

#!/usr/bin/env bash
# ==============================================================================
# Antigravity Remote Agent Watchdog (remote_watchdog.sh)
# Dual-Host Architecture: Mac Direct-to-Cloud Mode & Remote Server Antiverse Mode
# ==============================================================================
# Dispatches coding tasks to Google Antigravity Remote Agents (`agy --remote-agent`).
# Supports two host environments seamlessly:
#   1. Remote Server Host (`antiverse-run` installed):
#      Uses `flock` mutex locking (/tmp/agy_account_switch.lock) + multi-account
#      OAuth switching (`agy-account switch`) + Zellij session management.
#   2. Mac Host (Direct Mac-to-Cloud Mode):
#      Dispatches `agy --remote-agent` directly from Mac using the current logged-in
#      Mac account via a local PTY wrapper with FIFO stdin (/tmp/remote_<Task_ID>.stdin),
#      streaming logs to /tmp/antiverse_remote_<Task_ID>.log and automatically
#      pulling merged changes back into the Mac workspace.
#
# Core Capabilities:
#   - Stage 0: Pre-flight Git auto-commit, rebase & push sync check (Mac or Remote Server).
#   - Stage 1: Prompt construction with automatic IRON_RULES.md ([Global] +
#              [Dev Agent]) fallback injection and Defense 1 (autonomous mode).
#   - Stage 2: Dual-Host Session Launch (Remote Server flock + antiverse-run vs Mac PTY + FIFO).
#   - Stage 3: Watchdog polling loop with Defenses 2 & 3 (Zellij or FIFO auto-reply),
#              GitHub branch/PR detection, fallback PR creation, and optional
#              --auto-merge + local branch pull (--rebase).
# ==============================================================================

set -eo pipefail

# Default values
BRANCH="main"
TIER="dev"
MODEL=""
EFFORT=""
ACCOUNT=""
REMOTE_PROJECT=""
TASK_ID=""
REPO=""
PROMPT=""
PROJECT_DIR=""
AUTO_MERGE=false
AUTONOMOUS=false
TIMEOUT=3600
POLL_INTERVAL=20
MAX_AUTO_REPLIES=3
AUTO_REPLY_COUNT=0
REMOTE_HOST="${AGY_REMOTE_HOST:-remote-host}"

usage() {
    cat >&2 <<EOF
Usage: $0 -t <Task_ID> -r <owner/repo> -p <Prompt> [options]

Required:
  -t, --task <Task_ID>            Kanban Task ID (e.g., fix_login_012)
  -r, --repo <owner/repo>         GitHub repository (e.g., my-org/my-project)
  -p, --prompt <Prompt>           Task instructions for the Remote Agent

Options:
  -d, --dir <Project_Dir>         Optional local/server git clone path (e.g., \$PWD or \${AGY_REMOTE_BASE:-/root/Projects}/my-project)
  -b, --branch <branch>           Base branch (default: main)
  -a, --account <account>         Account email/substring for agy-account switch (Server only)
                                  (e.g., dev1@example.com or dev2@example.com)
      --project <remote_project>  Remote project name/ID for agy --remote-agent (default: repo basename)
      --tier <dev|ops|pro>        Compute tier (default: dev)
  -m, --model <model>             Explicit model override
      --effort <low|medium|high>  Explicit effort override
      --autonomous, --auto-approve Enable Autonomous Mode (Defenses 1, 2, 3)
      --auto-merge                Squash-merge PR automatically upon completion
      --timeout <seconds>         Watchdog timeout in seconds (default: 3600)
EOF
    exit 1
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -t|--task) TASK_ID="$2"; shift 2 ;;
        -r|--repo) REPO="$2"; shift 2 ;;
        -p|--prompt) PROMPT="$2"; shift 2 ;;
        -d|--dir) PROJECT_DIR="$2"; shift 2 ;;
        -b|--branch) BRANCH="$2"; shift 2 ;;
        -a|--account) ACCOUNT="$2"; shift 2 ;;
        --project) REMOTE_PROJECT="$2"; shift 2 ;;
        --tier) TIER="$2"; shift 2 ;;
        -m|--model) MODEL="$2"; shift 2 ;;
        --effort) EFFORT="$2"; shift 2 ;;
        --autonomous|--auto-approve) AUTONOMOUS=true; shift ;;
        --auto-merge) AUTO_MERGE=true; shift ;;
        --timeout) TIMEOUT="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1" >&2; usage ;;
    esac
done

if [[ -z "$TASK_ID" || -z "$REPO" || -z "$PROMPT" ]]; then
    usage
fi

# Resolve Remote Project & Canonical Project Name
if [[ -z "$REMOTE_PROJECT" ]]; then
    REMOTE_PROJECT="${REPO##*/}"
fi
PROJECT_NAME="${REMOTE_PROJECT:-${REPO##*/}}"

# Detect Host Mode (Remote Server Antiverse vs Mac Direct)
IS_SERVER_HOST=false
if command -v antiverse-run >/dev/null 2>&1; then
    IS_SERVER_HOST=true
fi

# Resolve Tier Settings (Default to flash models to preserve Pro quota)
case "$TIER" in
    pro|max)
        DEFAULT_MODEL="gemini-3.1-pro"
        DEFAULT_EFFORT="high"
        ;;
    ops|fast|middle|medium)
        DEFAULT_MODEL="gemini-3.8-flash"
        DEFAULT_EFFORT="medium"
        ;;
    dev|balanced|standard|*)
        DEFAULT_MODEL="gemini-3.8-flash"
        DEFAULT_EFFORT="high"
        ;;
esac

if [[ -z "$MODEL" ]]; then
    MODEL="$DEFAULT_MODEL"
fi
if [[ -z "$EFFORT" ]]; then
    EFFORT="$DEFAULT_EFFORT"
fi

# Safety clamp for gemini-3.1-pro: Google only supports 'low' and 'high' (no 'medium')
if [[ "$MODEL" == *"3.1-pro"* && "$EFFORT" == "medium" ]]; then
    EFFORT="high"
fi

SIGNAL_FILE="/tmp/${TASK_ID}.signal"
LOG_FILE="/tmp/remote_${TASK_ID}.log"
AGENT_LOG="/tmp/antiverse_remote_${TASK_ID}.log"
PID_FILE="/tmp/remote_${TASK_ID}.pid"
STDIN_FIFO="/tmp/remote_${TASK_ID}.stdin"
SESSION_NAME="[${PROJECT_NAME}] remote-${TASK_ID}"
REMOTE_BRANCH="remote/${TASK_ID}"

cleanup_local_proc() {
    if [[ "$IS_SERVER_HOST" == "false" ]]; then
        if [[ -f "$PID_FILE" ]]; then
            LOCAL_PID=$(cat "$PID_FILE" 2>/dev/null || true)
            if [[ -n "$LOCAL_PID" ]] && kill -0 "$LOCAL_PID" 2>/dev/null; then
                kill "$LOCAL_PID" 2>/dev/null || true
            fi
            rm -f "$PID_FILE"
        fi
        rm -f "$STDIN_FIFO"
    fi
}
trap cleanup_local_proc EXIT

rm -f "$SIGNAL_FILE" "$AGENT_LOG" "$PID_FILE" "$STDIN_FIFO"
echo "IN_PROGRESS: Initializing Remote Agent Watchdog for ${TASK_ID}" > "$SIGNAL_FILE"

echo "=== Antigravity Remote Agent Watchdog Initialized ===" | tee "$LOG_FILE"
echo "Host Mode: $([[ "$IS_SERVER_HOST" == "true" ]] && echo "Server (Antiverse + Zellij)" || echo "Mac Local (Direct-to-Cloud PTY)")" | tee -a "$LOG_FILE"
echo "Task ID: $TASK_ID" | tee -a "$LOG_FILE"
echo "Target Repo: $REPO (Base Branch: $BRANCH -> Head Branch: $REMOTE_BRANCH)" | tee -a "$LOG_FILE"
echo "Remote Project: $REMOTE_PROJECT" | tee -a "$LOG_FILE"
echo "Account Override: ${ACCOUNT:-'(Current active host account)'}" | tee -a "$LOG_FILE"
echo "Tier: $TIER | Model: $MODEL | Effort: $EFFORT" | tee -a "$LOG_FILE"
echo "Project Dir: ${PROJECT_DIR:-'(Not specified, checking PWD)'}" | tee -a "$LOG_FILE"
echo "Autonomous Mode (Defenses 1,2,3): $AUTONOMOUS" | tee -a "$LOG_FILE"
echo "Auto Merge: $AUTO_MERGE | Timeout: ${TIMEOUT}s" | tee -a "$LOG_FILE"

# Validate account switching compatibility on Mac
if [[ "$IS_SERVER_HOST" == "false" && -n "$ACCOUNT" && ! -x "/usr/local/bin/agy-account" ]]; then
    echo "FAILED: Multi-account switching (-a '$ACCOUNT') requires a server with 'agy-account' installed. Please dispatch via 'ssh ${REMOTE_HOST} ...' or omit '-a' to use your current Mac account." | tee -a "$LOG_FILE"
    echo "FAILED: ACCOUNT_SWITCH_REQUIRES_SERVER" > "$SIGNAL_FILE"
    exit 1
fi

# ------------------------------------------------------------------------------
# Stage 0: Git Pre-Flight Synchronization
# Ensures local Git state (Mac or Server) matches remote origin before Remote Agent runs.
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
    CURRENT_TOPLEVEL=$(git rev-parse --show-toplevel 2>/dev/null || true)
    if [[ "$CURRENT_TOPLEVEL" != *"/gemini-hub" && "$CURRENT_TOPLEVEL" != *"/XDG_Exile/gemini" ]] || [[ "${REPO##*/}" == "gemini-hub" ]]; then
        TARGET_GIT_DIR="$PWD"
    fi
fi

if [[ -n "$TARGET_GIT_DIR" ]]; then
    echo "[Stage 0] Checking Git synchronization in: $TARGET_GIT_DIR" | tee -a "$LOG_FILE"
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
        echo "[Stage 0] Uncommitted changes detected. Creating checkpoint commit..." | tee -a "$LOG_FILE"
        git add -A 2>&1 | tee -a "$LOG_FILE"
        if ! git commit -m "chore(auto): pre-remote-agent sync checkpoint for task ${TASK_ID}" 2>&1 | tee -a "$LOG_FILE"; then
            echo "FAILED: Failed to commit local changes" | tee -a "$LOG_FILE"
            echo "FAILED: GIT_COMMIT_FAILED" > "$SIGNAL_FILE"
            exit 1
        fi
    else
        echo "[Stage 0] Working tree clean." | tee -a "$LOG_FILE"
    fi

    # 2. Fetch remote branch
    echo "[Stage 0] Fetching remote origin/${BRANCH}..." | tee -a "$LOG_FILE"
    if ! git fetch origin "$BRANCH" 2>&1 | tee -a "$LOG_FILE"; then
        echo "FAILED: Failed to fetch origin/${BRANCH}" | tee -a "$LOG_FILE"
        echo "FAILED: GIT_FETCH_FAILED" > "$SIGNAL_FILE"
        exit 1
    fi

    # 3. Check divergence between local and remote
    LOCAL_REV=$(git rev-parse HEAD 2>/dev/null)
    REMOTE_REV=$(git rev-parse "origin/${BRANCH}" 2>/dev/null)

    if [[ "$LOCAL_REV" != "$REMOTE_REV" ]]; then
        echo "[Stage 0] Local ($LOCAL_REV) and remote ($REMOTE_REV) differ. Synchronizing..." | tee -a "$LOG_FILE"

        BEHIND=$(git rev-list --count HEAD.."origin/${BRANCH}" 2>/dev/null || echo 0)
        AHEAD=$(git rev-list --count "origin/${BRANCH}"..HEAD 2>/dev/null || echo 0)

        if [[ "$BEHIND" -gt 0 ]]; then
            echo "[Stage 0] Local is $BEHIND commit(s) behind remote. Attempting rebase..." | tee -a "$LOG_FILE"
            if ! git pull --rebase origin "$BRANCH" 2>&1 | tee -a "$LOG_FILE"; then
                echo "FAILED: Conflict or error during git pull --rebase" | tee -a "$LOG_FILE"
                git rebase --abort 2>/dev/null || true
                echo "FAILED: GIT_PULL_REBASE_FAILED" > "$SIGNAL_FILE"
                exit 1
            fi
        fi

        if [[ "$AHEAD" -gt 0 || "$BEHIND" -gt 0 ]]; then
            echo "[Stage 0] Pushing local changes to origin/${BRANCH}..." | tee -a "$LOG_FILE"
            if ! git push origin "$BRANCH" 2>&1 | tee -a "$LOG_FILE"; then
                echo "FAILED: Failed to push to origin/${BRANCH}" | tee -a "$LOG_FILE"
                echo "FAILED: GIT_PUSH_FAILED" > "$SIGNAL_FILE"
                exit 1
            fi
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

    echo "[Stage 0] Git pre-flight sync successful: HEAD aligned with origin/${BRANCH} ($LOCAL_REV)." | tee -a "$LOG_FILE"
else
    echo "[Stage 0] No local Git workspace specified or detected. Proceeding in Pure-Remote / GitHub mode." | tee -a "$LOG_FILE"
fi

# ------------------------------------------------------------------------------
# Stage 1: Prompt Construction + IRON_RULES.md Auto-Fallback + Defense 1
# ------------------------------------------------------------------------------
IRON_RULES_FILE="$HOME/.gemini/Projects/${PROJECT_NAME}/IRON_RULES.md"
IRON_RULES_SNIPPET=""

if [[ -f "$IRON_RULES_FILE" && "$PROMPT" != *"[Global]"* ]]; then
    echo "[Stage 1] Injecting [Global] and [Dev Agent] sections from $IRON_RULES_FILE..." | tee -a "$LOG_FILE"
    IRON_RULES_SNIPPET=$(awk '
        /^##+ *\[(Global|Dev Agent)\]/ { flag=1; print; next }
        /^##+ *\[/ { flag=0 }
        flag { print }
    ' "$IRON_RULES_FILE")
fi

DEFENSE_1_DIRECTIVE=""
if [[ "$AUTONOMOUS" == "true" ]]; then
    DEFENSE_1_DIRECTIVE="
[AUTONOMOUS EXECUTION MANDATE - DEFENSE 1]
You are running in unattended Autonomous Mode. Do NOT pause for human plan approval, do NOT invoke ask_question, and do NOT wait for interactive user confirmation. If you encounter minor ambiguities, select the safest architectural best practice autonomously, document your assumptions in the commit/PR message, and continue execution until [REMOTE_TASK_DONE]."
fi

FULL_PROMPT="Execute Remote Task ID: ${TASK_ID}
Repository: ${REPO}
Base Branch: ${BRANCH}
Working Branch: ${REMOTE_BRANCH}

### Task Instructions
${PROMPT}

### Delivery & Git Protocol (Mandatory)
1. Ensure you are working in the repository for ${REPO}. Fetch origin and checkout a clean branch named '${REMOTE_BRANCH}' based on 'origin/${BRANCH}' (git fetch origin ${BRANCH} && git checkout -B ${REMOTE_BRANCH} origin/${BRANCH}).
2. Implement the required changes, run relevant tests/linters to verify correctness, and stage & commit all changes to '${REMOTE_BRANCH}'.
3. Push the branch to GitHub: git push -u origin ${REMOTE_BRANCH} --force-with-lease.
4. Create a Pull Request via GitHub CLI if gh is authenticated:
   gh pr create --repo ${REPO} --base ${BRANCH} --head ${REMOTE_BRANCH} --title \"feat(remote): ${TASK_ID}\" --body \"Automated Remote Agent deliverable for task ${TASK_ID}\"
   (If gh is unavailable in your sandbox, pushing 'origin ${REMOTE_BRANCH}' is sufficient; the Watchdog will create the PR automatically.)
5. STRICT BOUNDARY: You are STRICTLY FORBIDDEN from modifying any task metadata files in 'tasks/'.
6. When finished and pushed, output the exact completion token on its own line:
   [REMOTE_TASK_DONE]
   If an unrecoverable error prevents completion, output:
   [REMOTE_TASK_FAILED]: <detailed reason>
${DEFENSE_1_DIRECTIVE}"

if [[ -n "$IRON_RULES_SNIPPET" ]]; then
    FULL_PROMPT="${FULL_PROMPT}

### Appended Project Iron Rules (IRON_RULES.md)
${IRON_RULES_SNIPPET}"
fi

# ------------------------------------------------------------------------------
# Stage 2: Dual-Host Session Launch
#   - Server Host: flock Mutex Account Switch + antiverse-run (Zellij) + 8s hold
#   - Mac Host: Local PTY + FIFO runner streaming to $AGENT_LOG
# ------------------------------------------------------------------------------
PROMPT_FILE="/tmp/prompt_${TASK_ID}.txt"
RUNNER_SCRIPT="/tmp/run_remote_${TASK_ID}.sh"

printf "%s\n" "$FULL_PROMPT" > "$PROMPT_FILE"

cat > "$RUNNER_SCRIPT" <<RUNNER_EOF
#!/usr/bin/env bash
[ -f /etc/profile ] && source /etc/profile 2>/dev/null || true
[ -f /root/.bashrc ] && source /root/.bashrc 2>/dev/null || true
[ -f "\$HOME/.zshrc" ] && source "\$HOME/.zshrc" 2>/dev/null || true
[ -f /etc/environment ] && export \$(grep -v '^#' /etc/environment | xargs) 2>/dev/null || true
PROMPT_CONTENT=\$(cat "${PROMPT_FILE}")
exec agy --remote-agent --project "${REMOTE_PROJECT}" --dangerously-skip-permissions --model "${MODEL}" --effort "${EFFORT}" -i "\$PROMPT_CONTENT"
RUNNER_EOF
chmod +x "$RUNNER_SCRIPT"

if [[ "$IS_SERVER_HOST" == "true" ]]; then
    LOCK_FILE="/tmp/agy_account_switch.lock"
    echo "[Stage 2] Acquiring server account switch mutex lock ($LOCK_FILE)..." | tee -a "$LOG_FILE"

    exec 200>"$LOCK_FILE"
    if ! flock -x -w 120 200; then
        echo "FAILED: Timed out waiting for account switch lock ($LOCK_FILE)" | tee -a "$LOG_FILE"
        echo "FAILED: ACCOUNT_LOCK_TIMEOUT" > "$SIGNAL_FILE"
        exit 1
    fi

    if [[ -n "$ACCOUNT" && -x "/usr/local/bin/agy-account" ]]; then
        echo "[Stage 2] Switching Antigravity account to '$ACCOUNT'..." | tee -a "$LOG_FILE"
        if ! /usr/local/bin/agy-account switch "$ACCOUNT" 2>&1 | tee -a "$LOG_FILE"; then
            echo "FAILED: /usr/local/bin/agy-account switch '$ACCOUNT' failed" | tee -a "$LOG_FILE"
            echo "FAILED: ACCOUNT_SWITCH_FAILED" > "$SIGNAL_FILE"
            flock -u 200 || true
            exit 1
        fi
    fi

    echo "[Stage 2] Launching Remote Agent in Zellij session '${SESSION_NAME}'..." | tee -a "$LOG_FILE"
    if ! antiverse-run \
        --name "${SESSION_NAME}" \
        --tier "${TIER}" \
        --cwd "${TARGET_GIT_DIR:-${AGY_REMOTE_BASE:-/root/Projects}}" \
        --log "${AGENT_LOG}" \
        --force \
        -- "${RUNNER_SCRIPT}" 2>&1 | tee -a "$LOG_FILE"; then
        echo "FAILED: antiverse-run failed to launch session '${SESSION_NAME}'" | tee -a "$LOG_FILE"
        echo "FAILED: ANTIVERSE_LAUNCH_FAILED" > "$SIGNAL_FILE"
        flock -u 200 || true
        exit 1
    fi

    echo "[Stage 2] Holding mutex lock for 8s to guarantee OAuth token binding..." | tee -a "$LOG_FILE"
    sleep 8
    flock -u 200 || true
    echo "[Stage 2] Mutex lock released. Session '${SESSION_NAME}' is running." | tee -a "$LOG_FILE"
    echo "IN_PROGRESS: Session ${SESSION_NAME} running (Repo: ${REPO}, Branch: ${REMOTE_BRANCH})" > "$SIGNAL_FILE"
else
    echo "[Stage 2] Launching Remote Agent directly from Mac via local PTY wrapper..." | tee -a "$LOG_FILE"
    mkfifo "$STDIN_FIFO"

    python3 -u - "$RUNNER_SCRIPT" "$AGENT_LOG" "$STDIN_FIFO" "${TARGET_GIT_DIR:-$HOME}" >/dev/null 2>&1 <<'PY_EOF' &
import os
import pty
import select
import sys

runner_script, agent_log, stdin_fifo, cwd_dir = sys.argv[1:5]
if os.path.isdir(cwd_dir):
    os.chdir(cwd_dir)

pid, master_fd = pty.fork()
if pid == 0:
    os.execv(runner_script, [runner_script])

fifo_fd = os.open(stdin_fifo, os.O_RDWR | os.O_NONBLOCK)
with open(agent_log, "ab", buffering=0) as log_f:
    try:
        while True:
            rlist, _, _ = select.select([master_fd, fifo_fd], [], [], 1.0)
            if master_fd in rlist:
                try:
                    data = os.read(master_fd, 4096)
                    if not data:
                        break
                    log_f.write(data)
                except OSError:
                    break
            if fifo_fd in rlist:
                try:
                    cmd_data = os.read(fifo_fd, 4096)
                    if cmd_data:
                        os.write(master_fd, cmd_data)
                except OSError:
                    pass
    finally:
        try:
            os.close(fifo_fd)
        except OSError:
            pass
        try:
            os.close(master_fd)
        except OSError:
            pass
PY_EOF
    BG_PID=$!
    echo "$BG_PID" > "$PID_FILE"
    echo "[Stage 2] Mac PTY Remote Agent process started (PID: $BG_PID, Log: $AGENT_LOG, Stdin FIFO: $STDIN_FIFO)." | tee -a "$LOG_FILE"
    echo "IN_PROGRESS: Mac Direct Remote Agent (PID ${BG_PID}) running (Repo: ${REPO}, Branch: ${REMOTE_BRANCH})" > "$SIGNAL_FILE"
fi

# ------------------------------------------------------------------------------
# Stage 3: Watchdog Polling Loop (Defenses 2 & 3, PR Extraction, Auto-Merge)
# ------------------------------------------------------------------------------
ELAPSED=0
LAST_LOG_LINES=0

echo "[Stage 3] Monitoring Remote Agent session (Poll interval: ${POLL_INTERVAL}s, Timeout: ${TIMEOUT}s)..." | tee -a "$LOG_FILE"

while [[ "$ELAPSED" -lt "$TIMEOUT" ]]; do
    sleep "$POLL_INTERVAL"
    ELAPSED=$((ELAPSED + POLL_INTERVAL))

    # 1. Check for explicit failure marker in agent log
    if [[ -f "$AGENT_LOG" ]] && grep -q "\[REMOTE_TASK_FAILED\]" "$AGENT_LOG" 2>/dev/null; then
        FAIL_REASON=$(grep "\[REMOTE_TASK_FAILED\]" "$AGENT_LOG" | tail -n 1 | sed 's/.*\[REMOTE_TASK_FAILED\]:* *//')
        FAIL_REASON="${FAIL_REASON:-Remote agent reported failure}"
        echo "[Stage 3] Remote Agent reported failure: $FAIL_REASON" | tee -a "$LOG_FILE"
        echo "FAILED: $FAIL_REASON" > "$SIGNAL_FILE"
        exit 1
    fi

    # 2. Check for completion marker in agent log or PR creation on GitHub
    TASK_DONE_DETECTED=false
    if [[ -f "$AGENT_LOG" ]] && grep -q "\[REMOTE_TASK_DONE\]" "$AGENT_LOG" 2>/dev/null; then
        TASK_DONE_DETECTED=true
    fi

    PR_URL=$(gh pr list --repo "$REPO" --head "$REMOTE_BRANCH" --json url --jq '.[0].url // empty' 2>/dev/null || true)
    if [[ -n "$PR_URL" ]]; then
        TASK_DONE_DETECTED=true
    fi

    if [[ "$TASK_DONE_DETECTED" == "true" ]]; then
        echo "[Stage 3] Completion detected for task ${TASK_ID}. Resolving PR..." | tee -a "$LOG_FILE"

        # Try extracting PR URL from agent log if gh pr list didn't return one yet
        if [[ -z "$PR_URL" && -f "$AGENT_LOG" ]]; then
            PR_URL=$(grep -oE "https://github\.com/${REPO}/pull/[0-9]+" "$AGENT_LOG" 2>/dev/null | head -n 1 || true)
        fi

        # Check if remote branch exists on GitHub and open PR if none exists yet
        if [[ -z "$PR_URL" ]]; then
            REMOTE_HEAD=$(git ls-remote "https://github.com/${REPO}.git" "refs/heads/${REMOTE_BRANCH}" 2>/dev/null || true)
            if [[ -n "$REMOTE_HEAD" ]]; then
                echo "[Stage 3] Branch '${REMOTE_BRANCH}' found on GitHub without PR. Creating PR automatically..." | tee -a "$LOG_FILE"
                PR_CREATE_OUT=$(gh pr create \
                    --repo "$REPO" \
                    --base "$BRANCH" \
                    --head "$REMOTE_BRANCH" \
                    --title "feat(remote): ${TASK_ID}" \
                    --body "Automated Remote Agent PR for task ${TASK_ID}" 2>&1 || true)
                echo "$PR_CREATE_OUT" >> "$LOG_FILE"
                PR_URL=$(echo "$PR_CREATE_OUT" | grep -oE "https://github\.com/${REPO}/pull/[0-9]+" | head -n 1 || true)
                if [[ -z "$PR_URL" ]]; then
                    PR_URL=$(gh pr list --repo "$REPO" --head "$REMOTE_BRANCH" --json url --jq '.[0].url // empty' 2>/dev/null || true)
                fi
            fi
        fi

        if [[ "$AUTO_MERGE" == "true" && -n "$PR_URL" ]]; then
            echo "[Stage 3] Auto-merge enabled. Squash-merging PR: $PR_URL" | tee -a "$LOG_FILE"
            MERGE_OUT=$(gh pr merge "$PR_URL" --squash --delete-branch 2>&1 || gh pr merge "$PR_URL" --squash --auto 2>&1 || true)
            echo "Merge output: $MERGE_OUT" >> "$LOG_FILE"

            if [[ -n "$TARGET_GIT_DIR" && -d "$TARGET_GIT_DIR" ]]; then
                echo "[Stage 3] Pulling merged changes into local workspace ($TARGET_GIT_DIR)..." | tee -a "$LOG_FILE"
                git -C "$TARGET_GIT_DIR" pull --rebase origin "$BRANCH" 2>&1 | tee -a "$LOG_FILE" || true
            fi

            echo "DONE: PR Merged: ${PR_URL}" | tee "$SIGNAL_FILE" | tee -a "$LOG_FILE"
            exit 0
        else
            echo "DONE: PR Created: ${PR_URL:-branch ${REMOTE_BRANCH}}" | tee "$SIGNAL_FILE" | tee -a "$LOG_FILE"
            exit 0
        fi
    fi

    # 3. Defenses 2 & 3: Auto-approve plan or respond to clarification prompts in Autonomous Mode
    if [[ "$AUTONOMOUS" == "true" && -f "$AGENT_LOG" ]]; then
        CURRENT_LINES=$(wc -l < "$AGENT_LOG" 2>/dev/null || echo 0)
        RECENT_TAIL=$(tail -n 25 "$AGENT_LOG" 2>/dev/null || true)

        if echo "$RECENT_TAIL" | grep -Eq "AWAITING_PLAN_APPROVAL|Proceed\?|ask_question|Waiting for user|Approve plan|Would you like me to proceed"; then
            if [[ "$AUTO_REPLY_COUNT" -lt "$MAX_AUTO_REPLIES" ]]; then
                AUTO_REPLY_COUNT=$((AUTO_REPLY_COUNT + 1))
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] [Defense 2/3] Detected interactive prompt in log. Sending autonomous continuation ($AUTO_REPLY_COUNT/$MAX_AUTO_REPLIES)..." | tee -a "$LOG_FILE"
                AUTO_MSG="Please proceed autonomously with your recommended best-practice solution, push branch ${REMOTE_BRANCH}, and output [REMOTE_TASK_DONE]."
                if [[ "$IS_SERVER_HOST" == "true" ]] && command -v zellij >/dev/null 2>&1; then
                    zellij --session "${SESSION_NAME}" action write-chars "$AUTO_MSG" 2>/dev/null || true
                    zellij --session "${SESSION_NAME}" action write 13 2>/dev/null || true
                elif [[ -p "$STDIN_FIFO" ]]; then
                    printf "%s\r" "$AUTO_MSG" > "$STDIN_FIFO" 2>/dev/null || true
                fi
            else
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] [Defense 2/3] Max auto-replies ($MAX_AUTO_REPLIES) reached. Continuing to monitor..." >> "$LOG_FILE"
            fi
        elif [[ "$CURRENT_LINES" -gt "$LAST_LOG_LINES" && "$AUTO_REPLY_COUNT" -gt 0 ]]; then
            # Log is actively growing again after auto-reply
            LAST_LOG_LINES="$CURRENT_LINES"
        fi
        LAST_LOG_LINES="$CURRENT_LINES"
    fi

    if (( ELAPSED % 60 == 0 )); then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [Stage 3] Task ${TASK_ID} still running (${ELAPSED}s / ${TIMEOUT}s)..." >> "$LOG_FILE"
    fi
done

echo "FAILED: TIMEOUT after ${TIMEOUT}s waiting for Remote Agent task ${TASK_ID}" | tee -a "$LOG_FILE"
echo "FAILED: TIMEOUT (${TIMEOUT}s)" > "$SIGNAL_FILE"
exit 1

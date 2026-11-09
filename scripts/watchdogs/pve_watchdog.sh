#!/usr/bin/env bash
# ==============================================================================
# pve_watchdog.sh: Local Client Dispatcher & Watchdog for Remote Antigravity Tasks
# ==============================================================================
# Architecture:
#   1. Runs LOCALLY on Mac/Client. Never executes as a remote-internal tab process.
#   2. Injects pure Antigravity (agy -i) directly into remote server's Antiverse session.
#   3. The remote Zellij tab is 100% Antigravity TUI — zero watchdog wrapper noise.
#   4. The watchdog loop stays on local client, polling task completion signals via SSH.
# ==============================================================================

set -eo pipefail

AGENT_TYPE="dev"
MODEL=""
EFFORT=""
TIER=""
TASK_ID=""
PROJECT_DIR=""
PROMPT=""
REMOTE_HOST="${AGY_REMOTE_HOST:-remote-host}"
WARM_HOURS=2

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -t|--task) TASK_ID="$2"; shift 2 ;;
        -a|--agent) AGENT_TYPE="$2"; shift 2 ;;
        -d|--dir) PROJECT_DIR="$2"; shift 2 ;;
        -p|--prompt) PROMPT="$2"; shift 2 ;;
        -m|--model) MODEL="$2"; shift 2 ;;
        -h|--host) REMOTE_HOST="$2"; shift 2 ;;
        --effort) EFFORT="$2"; shift 2 ;;
        --tier) TIER="$2"; shift 2 ;;
        --warm-hours) WARM_HOURS="$2"; shift 2 ;;
        *) echo "Unknown parameter passed: $1" >&2; exit 1 ;;
    esac
done

if [[ -z "$TASK_ID" || -z "$PROJECT_DIR" || -z "$PROMPT" ]]; then
    echo "Usage: $0 -t <Task_ID> -a <dev|ops> -d <Project_Dir> -p <Prompt> [-h <Remote_Host>] [--tier <dev|ops|pro>] [-m <model>] [--effort <low|medium|high>]" >&2
    exit 1
fi

PROJECT_NAME=$(basename "$PROJECT_DIR")

# Determine default tier if not explicitly specified
if [[ -z "$TIER" ]]; then
    if [[ "$AGENT_TYPE" == "ops" ]]; then
        TIER="ops"
    else
        TIER="dev"
    fi
fi

# Resolve Tier Settings (Default to flash models to avoid consuming interactive Pro quota)
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
        DEFAULT_MODEL="gemini-3.8-flash-high"
        DEFAULT_EFFORT="high"
        ;;
esac

# Allow explicit model override via -m
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

# Resolve Remote Working Directory and Session Name on remote server
REMOTE_BASE="${AGY_REMOTE_BASE:-/root/Projects}"
if [[ "$PROJECT_DIR" == /* && "$PROJECT_DIR" != "$PWD"* ]]; then
    REMOTE_DIR="$PROJECT_DIR"
else
    REMOTE_DIR="${REMOTE_BASE}/${PROJECT_NAME}"
fi
SESSION_NAME="[${PROJECT_NAME}] ${AGENT_TYPE}-${TASK_ID}"

echo "======================================================================"
echo "🐕 [Local Watchdog] Preparing Remote Task: $TASK_ID"
echo "🎯 Host: $REMOTE_HOST | Agent: $AGENT_TYPE | Tier: $TIER | Model: $MODEL ($EFFORT effort)"
echo "📂 Remote Target: $REMOTE_DIR"
echo "🌌 Dedicated Session: $SESSION_NAME"
echo "======================================================================"

# Base prompt with safety overrides
SAFE_PROMPT="Execute Task ID: ${TASK_ID}. ${PROMPT}. You are STRICTLY FORBIDDEN from updating task metadata files in tasks/. When finished, write DONE to /tmp/${TASK_ID}.signal."

# 1. Clean previous signal and inject prompt cleanly onto remote disk
ssh "$REMOTE_HOST" "rm -f /tmp/${TASK_ID}.signal /tmp/prompt_${TASK_ID}.txt 2>/dev/null || true"
echo "$SAFE_PROMPT" | ssh "$REMOTE_HOST" "cat > /tmp/prompt_${TASK_ID}.txt"

# 2. Build agent invocation flag
AGENT_FLAG=""
if [[ "$AGENT_TYPE" == "dev" ]]; then
    AGENT_FLAG="--agent dev"
elif [[ "$AGENT_TYPE" == "ops" ]]; then
    AGENT_FLAG="--agent ops"
fi

# 3. Create runner script on remote host to safely load prompt with explicit model and effort flags
ssh "$REMOTE_HOST" "bash -s" << EOF
cat << 'RUNNER_EOF' > /tmp/run_${TASK_ID}.sh
#!/usr/bin/env bash
[ -f /etc/profile ] && source /etc/profile 2>/dev/null || true
[ -f /root/.bashrc ] && source /root/.bashrc 2>/dev/null || true
[ -f "\$HOME/.zshrc" ] && source "\$HOME/.zshrc" 2>/dev/null || true
[ -f /etc/environment ] && export \$(grep -v '^\#' /etc/environment | xargs) 2>/dev/null || true
cd "${REMOTE_DIR}" || exit 1
PROMPT=\$(cat /tmp/prompt_${TASK_ID}.txt)
exec agy --remote-control --dangerously-skip-permissions ${AGENT_FLAG} --model "${MODEL}" --effort "${EFFORT}" -i "\$PROMPT"
RUNNER_EOF
chmod +x /tmp/run_${TASK_ID}.sh
EOF

echo "[Local Watchdog] Spawning Antigravity in dedicated Zellij session '${SESSION_NAME}' (Warm Period: ${WARM_HOURS}h)..."

ssh "$REMOTE_HOST" "if command -v antiverse-run >/dev/null 2>&1; then \
  antiverse-run \
    --name '${SESSION_NAME}' \
    --tier '${TIER}' \
    --warm-hours '${WARM_HOURS}' \
    --cwd '${REMOTE_DIR}' \
    --force \
    -- /tmp/run_${TASK_ID}.sh; \
else \
  zellij --session Antiverse action new-tab --name '${SESSION_NAME}' 2>/dev/null || true; \
  nohup /tmp/run_${TASK_ID}.sh > /tmp/agy_${AGENT_TYPE}_${TASK_ID}.log 2>&1 & \
fi"

echo "======================================================================"
echo "📺 [Monitor] To view session: ssh $REMOTE_HOST -t 'antiverse a ${TASK_ID}' (or zellij attach)"
echo "💡 [Tip] Press [Alt + s] inside any Zellij window to switch tasks instantly."
echo "☕ [Warm Period] Session stays active for ${WARM_HOURS} hours post-completion."
echo "======================================================================"
echo "[Local Watchdog] Antigravity process launched on remote server. Now watching for completion..."

# 4. Polling loop runs exclusively on local client
POLL_COUNT=0
while true; do
    sleep 15
    POLL_COUNT=$((POLL_COUNT + 1))
    
    STATUS=$(ssh -o ConnectTimeout=10 "$REMOTE_HOST" "cat /tmp/${TASK_ID}.signal 2>/dev/null" || true)
    
    if [[ "$STATUS" == *"DONE"* ]]; then
        echo ""
        echo "======================================================================"
        echo "🎉 [Local Watchdog] Remote Task $TASK_ID Finished: DONE"
        echo "☕ Session '${SESSION_NAME}' is active in ${WARM_HOURS}-hour warm period."
        echo "👉 Attach anytime: ssh $REMOTE_HOST -t 'antiverse a ${TASK_ID}'"
        echo "======================================================================"
        exit 0
    elif [[ "$STATUS" == *"FAILED"* ]]; then
        echo ""
        echo "======================================================================"
        echo "❌ [Local Watchdog] Remote Task $TASK_ID Failed: $STATUS"
        echo "======================================================================"
        exit 1
    fi

    # Output periodic heartbeat every minute
    if (( POLL_COUNT % 4 == 0 )); then
        echo "[Local Watchdog] Task $TASK_ID is running on remote server ($((POLL_COUNT * 15))s elapsed)..."
    fi
done

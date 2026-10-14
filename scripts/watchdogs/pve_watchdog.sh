#!/bin/bash
# ==============================================================================
# agy_pve_watchdog.sh - Antigravity Remote Server Watchdog
# Part of the agy-disciple multi-agent plugin suite.
#
# Dispatches dev or ops subagent tasks to a remote Linux/PVE server via SSH,
# monitors autonomous execution in the background, and listens for the completion signal.
# ==============================================================================

# Default configurations
AGENT_TYPE="dev"
MODEL="gemini-3.8-flash-high"
REMOTE_HOST="${AGY_REMOTE_HOST:-Antigravity}"
POLL_INTERVAL=30

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -t|--task) TASK_ID="$2"; shift ;;
        -a|--agent) AGENT_TYPE="$2"; shift ;;
        -d|--dir) PROJECT_DIR="$2"; shift ;;
        -p|--prompt) PROMPT="$2"; shift ;;
        -m|--model) MODEL="$2"; shift ;;
        -h|--host) REMOTE_HOST="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [[ -z "$TASK_ID" || -z "$PROJECT_DIR" || -z "$PROMPT" ]]; then
    echo "Usage: $0 -t <Task_ID> -a <dev|ops> -d <Project_Dir> -p <Prompt> [-m <Model>] [-h <Remote_Host>]"
    echo "Example: $0 -t auth_001 -a dev -d /root/Projects/my-app -p 'Implement JWT validation' -h my-pve"
    exit 1
fi

PROJECT_NAME=$(basename "$PROJECT_DIR")

# Base prompt with safety overrides
SAFE_PROMPT="Execute Task ID: ${TASK_ID}. ${PROMPT}. You are STRICTLY FORBIDDEN from updating task metadata files. When finished, write DONE to /tmp/${TASK_ID}.signal."
PROMPT_B64=$(echo -n "$SAFE_PROMPT" | base64)

echo "=== Antigravity Remote Watchdog Initialized ==="
echo "Remote Host      : $REMOTE_HOST"
echo "Sub-Agent Type   : $AGENT_TYPE"
echo "Task ID          : $TASK_ID"
echo "Target Directory : $PROJECT_DIR"

if [ "$AGENT_TYPE" == "dev" ]; then
    ssh "$REMOTE_HOST" << SSH_EOF
cat << 'REMOTE_SCRIPT' > /tmp/run_${TASK_ID}.sh
#!/bin/bash
DECODED_PROMPT=\$(echo "$PROMPT_B64" | base64 --decode)
AGENT_FLAG=""
if agy agents 2>/dev/null | grep -q "dev"; then
    AGENT_FLAG="--agent dev"
fi
for i in {1..5}; do
    agy --remote-control --dangerously-skip-permissions \$AGENT_FLAG --model "${MODEL}" --effort high --prompt "\$DECODED_PROMPT"
    if [ \$? -eq 0 ]; then break; fi
    sleep 10
done
if [ \$? -ne 0 ]; then echo "FAILED_STARTUP" > /tmp/${TASK_ID}.signal; fi
REMOTE_SCRIPT

cd "$PROJECT_DIR"
nohup bash /tmp/run_${TASK_ID}.sh > /tmp/agy_dev_${TASK_ID}.log 2>&1 &
SSH_EOF

elif [ "$AGENT_TYPE" == "ops" ]; then
    if [ "$MODEL" == "gemini-3.1-pro" ]; then
        MODEL="gemini-3.8-flash"
    fi
    ssh "$REMOTE_HOST" << SSH_EOF
cat << 'REMOTE_SCRIPT' > /tmp/run_${TASK_ID}.sh
#!/bin/bash
DECODED_PROMPT=\$(echo "$PROMPT_B64" | base64 --decode)
AGENT_FLAG=""
if agy agents 2>/dev/null | grep -q "ops"; then
    AGENT_FLAG="--agent ops"
fi
cd "${PROJECT_DIR}"
for i in {1..3}; do 
    agy --remote-control --dangerously-skip-permissions \$AGENT_FLAG --model "${MODEL}" --effort high --prompt "\$DECODED_PROMPT" 2>&1 | tee /tmp/agy_ops_${TASK_ID}.log
    if [ \$? -eq 0 ]; then break; fi
    sleep 10
done
if [ \$? -ne 0 ]; then echo "FAILED_STARTUP" > /tmp/${TASK_ID}.signal; fi
echo "Ops Task Ended"
REMOTE_SCRIPT

chmod +x /tmp/run_${TASK_ID}.sh
zellij --session Antiverse action new-tab --name '[${PROJECT_NAME}] ops-${TASK_ID}'
zellij --session Antiverse action go-to-tab-name '[${PROJECT_NAME}] ops-${TASK_ID}'
zellij --session Antiverse action write-chars "/tmp/run_${TASK_ID}.sh"
zellij --session Antiverse action send-keys 'Enter'
SSH_EOF

else
    echo "Unknown agent type: $AGENT_TYPE"
    exit 1
fi

echo "Remote agent successfully dispatched. Monitoring completion signal on /tmp/${TASK_ID}.signal..."

while true; do
    STATUS=$(ssh "$REMOTE_HOST" "cat /tmp/${TASK_ID}.signal 2>/dev/null")
    if [[ "$STATUS" == *"DONE"* || "$STATUS" == *"FAILED"* ]]; then
        echo "Remote Task Finished with status: $STATUS"
        break
    fi
    sleep "$POLL_INTERVAL"
done

#!/usr/bin/env bash
# ==============================================================================
# Strictly On-Demand Remote Test Environment Manager (pve_test_sync.sh)
# ==============================================================================
# Manages on-demand Git synchronization and Zellij dev server lifecycle on
# remote server (`${AGY_REMOTE_BASE:-/root/Projects}/<project>`) for Local,
# Server-Native, and Pure-Remote projects.
#
# Key Principles:
#   - STRICTLY ON-DEMAND: Normal commits/pushes to `main` NEVER auto-restart or
#     auto-launch the dev server.
#   - Actions:
#       * sync    : `git fetch && git pull --rebase` only (preserves hot-reload)
#       * start   : `sync` + start `[<project>] env` if not already running
#       * restart : `sync` + force-restart `[<project>] env`
#       * stop    : terminate `[<project>] env` Zellij session
#       * status  : show HEAD commit, session status, and last 30 log lines
#       * watch   : lightweight 15s tag watcher (`refs/tags/pve-env-*`) so Cloud
#                   Remote Agent conversations can trigger remote actions on demand
#                   with zero open ports and read back results via GitHub commit
#                   comments (`--post-github-status`).
# ==============================================================================

set -eo pipefail

PROJECT_NAME=""
ACTION="sync"
PROJECT_DIR=""
BRANCH="main"
DEV_SERVER_CMD=""
REPO=""
POST_GITHUB_STATUS=false
WATCH_INTERVAL=15

usage() {
    cat >&2 <<EOF
Usage: $0 -p <project_name> [options]

Required:
  -p, --project <name>        Canonical project name (e.g., my_project)

Options:
  -a, --action <action>       Action: sync | start | restart | stop | status | watch (default: sync)
  -d, --dir <path>            Remote project clone path (default: \${AGY_REMOTE_BASE:-/root/Projects}/<project_name>)
  -b, --branch <branch>       Git branch to sync (default: main)
  -c, --cmd <command>         Dev server start command override (default: reads PVE-Dev-Server-Cmd from IRON_RULES.md)
  -r, --repo <owner/repo>     GitHub repo slug (default: \${AGY_GITHUB_ORG:-my-org}/<project_name>)
      --post-github-status    Post execution summary + 30-line log to GitHub HEAD commit comments
  -h, --help                  Show this help message
EOF
    exit 1
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -p|--project) PROJECT_NAME="$2"; shift 2 ;;
        -a|--action) ACTION="$2"; shift 2 ;;
        -d|--dir) PROJECT_DIR="$2"; shift 2 ;;
        -b|--branch) BRANCH="$2"; shift 2 ;;
        -c|--cmd) DEV_SERVER_CMD="$2"; shift 2 ;;
        -r|--repo) REPO="$2"; shift 2 ;;
        --post-github-status) POST_GITHUB_STATUS=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1" >&2; usage ;;
    esac
done

if [[ -z "$PROJECT_NAME" ]]; then
    usage
fi

REMOTE_BASE="${AGY_REMOTE_BASE:-/root/Projects}"
if [[ -z "$PROJECT_DIR" ]]; then
    PROJECT_DIR="${REMOTE_BASE}/${PROJECT_NAME}"
fi

if [[ -z "$REPO" ]]; then
    REPO="${AGY_GITHUB_ORG:-my-org}/${PROJECT_NAME}"
fi

SESSION_NAME="[${PROJECT_NAME}] env"
IRON_RULES_FILE="$HOME/.gemini/Projects/${PROJECT_NAME}/IRON_RULES.md"

resolve_dev_cmd() {
    if [[ -n "$DEV_SERVER_CMD" ]]; then
        return 0
    fi
    if [[ -f "$IRON_RULES_FILE" ]]; then
        DEV_SERVER_CMD=$(grep -E "(PVE-Dev-Server-Cmd|Dev-Server-Cmd):" "$IRON_RULES_FILE" | head -n 1 | sed -E 's/.*(PVE-Dev-Server-Cmd|Dev-Server-Cmd):[[:space:]]*//; s/^`//; s/`$//' || true)
    fi
    if [[ -z "$DEV_SERVER_CMD" ]]; then
        echo "ERROR: No dev server command provided via -c/--cmd and no 'PVE-Dev-Server-Cmd:' found in $IRON_RULES_FILE" >&2
        return 1
    fi
}

is_session_running() {
    local sessions
    sessions=$(zellij list-sessions -n 2>/dev/null || true)
    if echo "$sessions" | grep -Fq "${SESSION_NAME}"; then
        if ! echo "$sessions" | grep -F "${SESSION_NAME}" | grep -Fq "EXITED"; then
            return 0
        fi
    fi
    return 1
}

get_latest_env_log() {
    local log_file=""
    log_file=$(ls -1t /tmp/antiverse_*"${PROJECT_NAME}"*env*.log 2>/dev/null | head -n 1 || true)
    if [[ -z "$log_file" ]]; then
        log_file="/tmp/antiverse_${PROJECT_NAME}_env.log"
    fi
    echo "$log_file"
}

do_sync() {
    if [[ ! -d "$PROJECT_DIR" ]]; then
        echo "ERROR: Project directory does not exist on remote server: $PROJECT_DIR" >&2
        return 1
    fi
    echo "[Test-Sync] Syncing '$PROJECT_DIR' with origin/${BRANCH}..."
    git -C "$PROJECT_DIR" fetch origin "$BRANCH" 2>&1
    git -C "$PROJECT_DIR" pull --rebase origin "$BRANCH" 2>&1
    local head_info
    head_info=$(git -C "$PROJECT_DIR" log -1 --oneline 2>/dev/null || true)
    echo "[Test-Sync] Sync complete. HEAD is now: $head_info"
}

do_status() {
    local head_info="(Directory $PROJECT_DIR not found)"
    if [[ -d "$PROJECT_DIR" ]]; then
        head_info=$(git -C "$PROJECT_DIR" log -1 --oneline 2>/dev/null || echo "Unknown")
    fi
    local running_state="STOPPED"
    if is_session_running; then
        running_state="RUNNING (${SESSION_NAME})"
    fi
    local log_file
    log_file=$(get_latest_env_log)

    echo "=== Test Environment Status: ${PROJECT_NAME} ==="
    echo "Directory : ${PROJECT_DIR}"
    echo "Branch    : ${BRANCH}"
    echo "HEAD      : ${head_info}"
    echo "Service   : ${running_state}"
    echo "Log File  : ${log_file}"
    echo "--- Last 30 Lines of Server Log ---"
    if [[ -f "$log_file" ]]; then
        tail -n 30 "$log_file" 2>/dev/null || true
    else
        echo "(No log file found)"
    fi
}

do_start() {
    do_sync
    if is_session_running; then
        echo "[Test-Sync] Session '${SESSION_NAME}' is already running. Skipping restart (hot-reload preserved)."
    else
        resolve_dev_cmd
        local log_file="/tmp/antiverse_${PROJECT_NAME}_env.log"
        echo "[Test-Sync] Starting Zellij session '${SESSION_NAME}' with command: $DEV_SERVER_CMD"
        if command -v antiverse-run >/dev/null 2>&1; then
            antiverse-run --name "${SESSION_NAME}" --cwd "$PROJECT_DIR" --log "$log_file" --force -- bash -lc "$DEV_SERVER_CMD"
        else
            zellij --session "${SESSION_NAME}" action new-tab --name "env" 2>/dev/null || true
            nohup bash -lc "$DEV_SERVER_CMD" > "$log_file" 2>&1 &
        fi
        sleep 3
    fi
    do_status
}

do_restart() {
    do_sync
    resolve_dev_cmd
    local log_file="/tmp/antiverse_${PROJECT_NAME}_env.log"
    echo "[Test-Sync] Force-restarting Zellij session '${SESSION_NAME}' with command: $DEV_SERVER_CMD"
    if command -v antiverse-run >/dev/null 2>&1; then
        antiverse-run --name "${SESSION_NAME}" --cwd "$PROJECT_DIR" --log "$log_file" --force -- bash -lc "$DEV_SERVER_CMD"
    else
        zellij kill-session "${SESSION_NAME}" 2>/dev/null || true
        nohup bash -lc "$DEV_SERVER_CMD" > "$log_file" 2>&1 &
    fi
    sleep 3
    do_status
}

do_stop() {
    echo "[Test-Sync] Stopping Zellij session '${SESSION_NAME}'..."
    zellij kill-session "${SESSION_NAME}" 2>/dev/null || true
    zellij delete-session --force "${SESSION_NAME}" 2>/dev/null || true
    echo "[Test-Sync] Session '${SESSION_NAME}' stopped."
    do_status
}

post_github_commit_comment() {
    local action_name="$1"
    local output_text="$2"
    if [[ ! -d "$PROJECT_DIR" ]]; then
        return 0
    fi
    local head_sha
    head_sha=$(git -C "$PROJECT_DIR" rev-parse HEAD 2>/dev/null || true)
    if [[ -z "$head_sha" ]]; then
        return 0
    fi
    local comment_body
    comment_body=$(cat <<EOF
### [Remote Test Environment] On-Demand Action: \`${action_name}\`
- **Timestamp**: $(date '+%Y-%m-%d %H:%M:%S %Z')
- **Project**: \`${PROJECT_NAME}\` (\`${PROJECT_DIR}\`)
- **Commit**: \`${head_sha}\`

\`\`\`text
${output_text}
\`\`\`
EOF
)
    gh api "repos/${REPO}/commits/${head_sha}/comments" -f body="$comment_body" >/dev/null 2>&1 || true
}

execute_single_action() {
    local act="$1"
    local out=""
    case "$act" in
        sync)
            out=$(do_sync 2>&1)
            ;;
        start)
            out=$(do_start 2>&1)
            ;;
        restart)
            out=$(do_restart 2>&1)
            ;;
        stop)
            out=$(do_stop 2>&1)
            ;;
        status)
            out=$(do_status 2>&1)
            ;;
        *)
            echo "ERROR: Unsupported action '$act'" >&2
            exit 1
            ;;
    esac
    echo "$out"
    if [[ "$POST_GITHUB_STATUS" == "true" ]]; then
        post_github_commit_comment "$act" "$out"
    fi
}

do_watch() {
    echo "=== [Test-Sync Watcher] Strictly On-Demand Tag Listener Started ==="
    echo "Project : ${PROJECT_NAME} (${PROJECT_DIR})"
    echo "Repo    : ${REPO}"
    echo "Polling : refs/tags/pve-env-<sync|start|restart|stop|status> every ${WATCH_INTERVAL}s"
    echo "Note    : Normal pushes to '${BRANCH}' are ignored. Only explicit pve-env-* tags trigger execution."

    while true; do
        sleep "$WATCH_INTERVAL"
        if [[ ! -d "$PROJECT_DIR" ]]; then
            continue
        fi

        REMOTE_TAGS=$(git -C "$PROJECT_DIR" ls-remote --tags origin "refs/tags/pve-env-*" 2>/dev/null | awk '{print $2}' | sed 's#refs/tags/##' | grep -v '\^{}' || true)
        if [[ -z "$REMOTE_TAGS" ]]; then
            continue
        fi

        for tag in $REMOTE_TAGS; do
            req_action="${tag#pve-env-}"
            case "$req_action" in
                sync|start|restart|stop|status)
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Detected on-demand trigger tag '${tag}'. Consuming tag and executing '${req_action}'..."
                    git -C "$PROJECT_DIR" push origin ":refs/tags/${tag}" >/dev/null 2>&1 || true
                    git -C "$PROJECT_DIR" tag -d "${tag}" >/dev/null 2>&1 || true
                    POST_GITHUB_STATUS=true
                    execute_single_action "$req_action" || true
                    ;;
                *)
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Ignoring unrecognized tag '${tag}'."
                    ;;
            esac
        done
    done
}

if [[ "$ACTION" == "watch" ]]; then
    do_watch
else
    execute_single_action "$ACTION"
fi

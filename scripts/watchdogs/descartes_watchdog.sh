#!/bin/bash

# ==============================================================================
# Descartes / EnginEdge Watchdog
# Dispatches a coding task to the headless `enginedge run` agent (cloud brain:
# Descartes/Dalembert hub; local tools confined to the CWD jail), inside an
# isolated git worktree + branch `descartes/<Task_ID>`.
#
# Autonomous coding dispatcher for projects. No GitHub dependency: this
# script NEVER pushes, pulls or fetches.
#
# Contract shared with pve_watchdog.sh:
#   - args:    -t <Task_ID> -d <Project_Dir> -p <Prompt>
#   - signal:  /tmp/<Task_ID>.signal   (first line starts with
#              IN_PROGRESS / DONE / FAILED)
#   - log:     /tmp/descartes_<Task_ID>.log
#
# Failure codes: BAD_ARGS ENGINEDGE_NOT_FOUND NOT_A_GIT_REPO BRANCH_EXISTS
#   WORKTREE_FAILED ENGINEDGE_EXIT_<n> TIMEOUT VERIFY_FAILED COMMIT_FAILED
#   MERGE_CONFLICT UNEXPECTED_EXIT
#
# Compatible with bash 3.2+ (macOS) and Linux bash.
# ==============================================================================

# ---------------------------- defaults / globals ------------------------------
TASK_ID=""
PROJECT_DIR=""
PROMPT=""
BASE_BRANCH=""
AUTO_MERGE=false
PROFILE=""
MAX_TURNS=""
HUB_URL=""
VERIFY_CMD=""
TIMEOUT_SECS=3600
KEEP_WORKTREE=false

SIGNAL_FILE=""
LOG_FILE=""
MAIN_DIR=""            # top-level of the user's main working tree
WT_ROOT="/tmp/descartes_worktrees"
WT_PATH=""             # the worktree for this task (only path we may rm -rf)
BRANCH=""              # descartes/<Task_ID>
BASE_SHA=""
FINAL_WRITTEN=false
TIMEOUT_MARKER=""

usage() {
    cat <<'EOF'
Usage: descartes_watchdog.sh -t <Task_ID> -d <Project_Dir> -p <Prompt>
         [-b <base_branch>] [--auto-merge] [--profile <llm_profile>]
         [--max-turns <turns>] [--hub-url <url>] [--verify "<cmd>"]
         [--timeout <seconds>] [--keep-worktree]
Env: ENGINEDGE_BIN overrides the enginedge binary path.
EOF
}

# ------------------------------ helpers ---------------------------------------
log() {
    if [ -n "$LOG_FILE" ]; then
        printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE"
    else
        printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
    fi
}

# Atomically replace the signal file content (single line).
write_signal() {
    [ -n "$SIGNAL_FILE" ] || return 0
    local tmp="${SIGNAL_FILE}.tmp.$$"
    printf '%s\n' "$1" > "$tmp" 2>/dev/null && mv -f "$tmp" "$SIGNAL_FILE" 2>/dev/null
}

# fail <CODE> [detail...]  -> writes FAILED signal, exits 1
fail() {
    local code="$1"; shift
    local msg="FAILED: ${code}"
    if [ "$#" -gt 0 ]; then msg="${msg} $*"; fi
    log "$msg"
    write_signal "$msg"
    FINAL_WRITTEN=true
    exit 1
}

# done_ok <detail...> -> writes DONE signal, exits 0
done_ok() {
    local msg="DONE: $*"
    log "$msg"
    write_signal "$msg"
    FINAL_WRITTEN=true
    exit 0
}

on_exit() {
    local rc=$?
    [ -n "$TIMEOUT_MARKER" ] && rm -f "$TIMEOUT_MARKER" 2>/dev/null
    if [ "$FINAL_WRITTEN" != "true" ]; then
        write_signal "FAILED: UNEXPECTED_EXIT (exit code ${rc})"
        [ -n "$LOG_FILE" ] && printf '[%s] FAILED: UNEXPECTED_EXIT (exit code %s)\n' \
            "$(date '+%Y-%m-%d %H:%M:%S')" "$rc" >> "$LOG_FILE"
    fi
}

# Remove ONLY this task's worktree. Never removes anything else.
remove_worktree() {
    [ -n "$WT_PATH" ] || return 0
    cd "$MAIN_DIR" 2>/dev/null || cd / 
    if [ -d "$WT_PATH" ]; then
        if ! git -C "$MAIN_DIR" worktree remove --force "$WT_PATH" >> "$LOG_FILE" 2>&1; then
            case "$WT_PATH" in
                "$WT_ROOT"/*/*)
                    log "git worktree remove failed; removing ${WT_PATH} manually"
                    rm -rf "$WT_PATH"
                    ;;
                *)
                    log "WARNING: refusing to rm -rf unexpected path: ${WT_PATH}"
                    ;;
            esac
        fi
    fi
    git -C "$MAIN_DIR" worktree prune >> "$LOG_FILE" 2>&1
}

# Pick timeout implementation (empty => bash fallback)
TIMEOUT_BIN=""
if command -v timeout >/dev/null 2>&1; then
    TIMEOUT_BIN="timeout"
elif command -v gtimeout >/dev/null 2>&1; then
    TIMEOUT_BIN="gtimeout"
fi

# run_with_timeout <secs> <cmd...>  -> exit 124 on timeout (like coreutils).
run_with_timeout() {
    local secs="$1"; shift
    if [ -n "$TIMEOUT_BIN" ]; then
        "$TIMEOUT_BIN" -k 15 "$secs" "$@"
        return $?
    fi
    # Pure-bash fallback (job control gives the child its own process group).
    local pid wd rc
    rm -f "$TIMEOUT_MARKER"
    set -m
    "$@" &
    pid=$!
    (
        sleep "$secs"
        : > "$TIMEOUT_MARKER"
        kill -TERM -- "-${pid}" 2>/dev/null
        sleep 10
        kill -KILL -- "-${pid}" 2>/dev/null
    ) >/dev/null 2>&1 &
    wd=$!
    wait "$pid" 2>/dev/null
    rc=$?
    kill -TERM -- "-${wd}" 2>/dev/null
    kill -TERM "$wd" 2>/dev/null
    wait "$wd" 2>/dev/null
    if [ -e "$TIMEOUT_MARKER" ]; then
        rm -f "$TIMEOUT_MARKER"
        return 124
    fi
    return "$rc"
}

# ------------------------------ arg parsing -----------------------------------
need_val() { # need_val <opt> <remaining-arg-count>
    if [ "$2" -lt 2 ]; then
        echo "Missing value for option: $1" >&2
        usage >&2
        exit 1
    fi
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        -t|--task)        need_val "$1" "$#"; TASK_ID="$2"; shift ;;
        -d|--dir)         need_val "$1" "$#"; PROJECT_DIR="$2"; shift ;;
        -p|--prompt)      need_val "$1" "$#"; PROMPT="$2"; shift ;;
        -b|--branch)      need_val "$1" "$#"; BASE_BRANCH="$2"; shift ;;
        --profile)        need_val "$1" "$#"; PROFILE="$2"; shift ;;
        --max-turns)      need_val "$1" "$#"; MAX_TURNS="$2"; shift ;;
        --hub-url)        need_val "$1" "$#"; HUB_URL="$2"; shift ;;
        --verify)         need_val "$1" "$#"; VERIFY_CMD="$2"; shift ;;
        --timeout)        need_val "$1" "$#"; TIMEOUT_SECS="$2"; shift ;;
        --auto-merge)     AUTO_MERGE=true ;;
        --keep-worktree)  KEEP_WORKTREE=true ;;
        -h|--help)        usage; exit 0 ;;
        *) echo "Unknown parameter passed: $1" >&2; usage >&2; exit 1 ;;
    esac
    shift
done

# Task ID must be path/ref-safe BEFORE it is used to build any path.
case "$TASK_ID" in
    ""|-*|.*|*..*|*/*|*[!A-Za-z0-9._-]*)
        echo "FAILED: BAD_ARGS invalid or missing Task_ID (allowed: [A-Za-z0-9._-], must not start with '-' or '.')" >&2
        usage >&2
        exit 1
        ;;
esac

SIGNAL_FILE="/tmp/${TASK_ID}.signal"
LOG_FILE="/tmp/descartes_${TASK_ID}.log"
TIMEOUT_MARKER="/tmp/descartes_${TASK_ID}.timeout.$$"
BRANCH="descartes/${TASK_ID}"

# Reset signal + log, then install traps: from here on the signal file can
# never be left stuck at IN_PROGRESS.
rm -f "$SIGNAL_FILE"
: > "$LOG_FILE"
write_signal "IN_PROGRESS: ${TASK_ID} (initializing)"
trap on_exit EXIT
trap 'exit 143' TERM
trap 'exit 130' INT HUP

log "=== Descartes Watchdog Initialized ==="
log "Task ID: ${TASK_ID}"

if [ -z "$PROJECT_DIR" ] || [ -z "$PROMPT" ]; then
    fail BAD_ARGS "missing -d <Project_Dir> or -p <Prompt>"
fi
case "$TIMEOUT_SECS" in
    ""|*[!0-9]*|0) fail BAD_ARGS "--timeout must be a positive integer (seconds)" ;;
esac
if [ -n "$MAX_TURNS" ]; then
    case "$MAX_TURNS" in
        ""|*[!0-9]*|0) fail BAD_ARGS "--max-turns must be a positive integer" ;;
    esac
fi
if [ ! -d "$PROJECT_DIR" ]; then
    fail BAD_ARGS "project directory does not exist: ${PROJECT_DIR}"
fi

# Optional credentials (HUB_AUTH_TOKEN / DESCARTES_WS_URL ...), exported.
if [ -f "$HOME/.config/descartes/env" ]; then
    set -a
    # shellcheck disable=SC1091
    . "$HOME/.config/descartes/env"
    set +a
fi
if [ -n "$HUB_URL" ]; then
    export DESCARTES_WS_URL="$HUB_URL"
fi

# ----------------------------- pre-flight checks ------------------------------
ENGINEDGE=""
if [ -n "${ENGINEDGE_BIN:-}" ]; then
    if [ -x "$ENGINEDGE_BIN" ] && [ -f "$ENGINEDGE_BIN" ]; then
        ENGINEDGE="$ENGINEDGE_BIN"
    fi
elif command -v enginedge >/dev/null 2>&1; then
    ENGINEDGE="$(command -v enginedge)"
elif [ -x "$HOME/.cargo/bin/enginedge" ]; then
    ENGINEDGE="$HOME/.cargo/bin/enginedge"
fi
if [ -z "$ENGINEDGE" ]; then
    fail ENGINEDGE_NOT_FOUND "set ENGINEDGE_BIN, or install enginedge into PATH or ~/.cargo/bin"
fi

if ! MAIN_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)" || [ -z "$MAIN_DIR" ]; then
    fail NOT_A_GIT_REPO "$PROJECT_DIR"
fi
MAIN_DIR="$(cd "$MAIN_DIR" && pwd -P)"
PROJECT_NAME="$(basename "$MAIN_DIR")"

if [ -z "$BASE_BRANCH" ]; then
    BASE_BRANCH="$(git -C "$MAIN_DIR" symbolic-ref --short -q HEAD 2>/dev/null)"
    if [ -z "$BASE_BRANCH" ]; then
        fail BAD_ARGS "project is on a detached HEAD; pass -b <base_branch>"
    fi
fi
if ! BASE_SHA="$(git -C "$MAIN_DIR" rev-parse --verify --quiet "${BASE_BRANCH}^{commit}" 2>/dev/null)" || [ -z "$BASE_SHA" ]; then
    fail BAD_ARGS "base branch/ref not found: ${BASE_BRANCH}"
fi
if git -C "$MAIN_DIR" show-ref --verify --quiet "refs/heads/${BRANCH}"; then
    fail BRANCH_EXISTS "$BRANCH"
fi

WT_PATH="${WT_ROOT}/${PROJECT_NAME}/${TASK_ID}"
if [ -e "$WT_PATH" ]; then
    fail WORKTREE_FAILED "worktree path already exists: ${WT_PATH}"
fi

log "Project Dir:   ${MAIN_DIR}"
log "Base Branch:   ${BASE_BRANCH} (${BASE_SHA})"
log "Work Branch:   ${BRANCH}"
log "Worktree:      ${WT_PATH}"
log "enginedge:     ${ENGINEDGE}"
[ -n "$MAX_TURNS" ] && log "Max Turns:     ${MAX_TURNS}"
log "Timeout:       ${TIMEOUT_SECS}s (impl: ${TIMEOUT_BIN:-bash-fallback})"
log "Auto Merge:    ${AUTO_MERGE}"
[ -n "$VERIFY_CMD" ] && log "Verify:        ${VERIFY_CMD}"

if [ -n "$(git -C "$MAIN_DIR" status --porcelain 2>/dev/null)" ]; then
    log "WARNING: project main working tree has uncommitted changes. The worktree only contains COMMITTED content; uncommitted changes are invisible to the agent."
fi

# ------------------------------ create worktree -------------------------------
mkdir -p "${WT_ROOT}/${PROJECT_NAME}" || fail WORKTREE_FAILED "cannot create ${WT_ROOT}/${PROJECT_NAME}"
if ! git -C "$MAIN_DIR" worktree add -b "$BRANCH" "$WT_PATH" "$BASE_SHA" >> "$LOG_FILE" 2>&1; then
    fail WORKTREE_FAILED "git worktree add failed (see ${LOG_FILE})"
fi
cd "$WT_PATH" || fail WORKTREE_FAILED "cannot cd into ${WT_PATH}"

write_signal "IN_PROGRESS: ${TASK_ID} ${BRANCH}"

# ------------------------------ run enginedge ---------------------------------
export ENGINEDGE_META_DIR="$HOME/.gemini/Projects/${PROJECT_NAME}"

ENGINE_CMD=("$ENGINEDGE" run "--task=$PROMPT")
if [ -n "$PROFILE" ]; then
    ENGINE_CMD=("${ENGINE_CMD[@]}" "--profile=$PROFILE")
fi
if [ -n "$MAX_TURNS" ]; then
    ENGINE_CMD=("${ENGINE_CMD[@]}" "--max-turns=$MAX_TURNS")
fi

log "Launching enginedge in ${WT_PATH} ..."
run_with_timeout "$TIMEOUT_SECS" "${ENGINE_CMD[@]}" </dev/null 2>&1 | tee -a "$LOG_FILE"
ENGINE_RC=${PIPESTATUS[0]}

if [ "$ENGINE_RC" -eq 124 ]; then
    fail TIMEOUT "after ${TIMEOUT_SECS}s; worktree kept at ${WT_PATH}, branch ${BRANCH}"
elif [ "$ENGINE_RC" -ne 0 ]; then
    fail "ENGINEDGE_EXIT_${ENGINE_RC}" "worktree kept at ${WT_PATH}, branch ${BRANCH}"
fi
log "enginedge finished successfully."

# ------------------------------ independent verify ----------------------------
if [ -n "$VERIFY_CMD" ]; then
    log "Running verification in worktree: ${VERIFY_CMD}"
    run_with_timeout "$TIMEOUT_SECS" bash -c "$VERIFY_CMD" </dev/null 2>&1 | tee -a "$LOG_FILE"
    VERIFY_RC=${PIPESTATUS[0]}
    if [ "$VERIFY_RC" -ne 0 ]; then
        fail VERIFY_FAILED "(exit ${VERIFY_RC}); worktree kept at ${WT_PATH}, branch ${BRANCH}"
    fi
    log "Verification passed."
fi

# ------------------------------ detect changes --------------------------------
if [ -z "$(git -C "$WT_PATH" status --porcelain 2>/dev/null)" ]; then
    log "Agent produced no file changes."
    if [ "$KEEP_WORKTREE" != "true" ]; then
        remove_worktree
        git -C "$MAIN_DIR" branch -D "$BRANCH" >> "$LOG_FILE" 2>&1
    fi
    done_ok "NO_CHANGES ${TASK_ID}"
fi

# ------------------------------ commit ----------------------------------------
GIT_ID_ARGS=()
if [ -z "$(git -C "$WT_PATH" config user.email 2>/dev/null)" ]; then
    GIT_ID_ARGS=(-c "user.name=Descartes Watchdog" -c "user.email=descartes@localhost")
fi
if ! git -C "$WT_PATH" add -A >> "$LOG_FILE" 2>&1; then
    fail COMMIT_FAILED "git add failed; worktree kept at ${WT_PATH}"
fi
if ! git -C "$WT_PATH" ${GIT_ID_ARGS[@]+"${GIT_ID_ARGS[@]}"} commit -m "feat(descartes): ${TASK_ID}" >> "$LOG_FILE" 2>&1; then
    fail COMMIT_FAILED "git commit failed; worktree kept at ${WT_PATH}, branch ${BRANCH}"
fi

COMMIT_COUNT="$(git -C "$MAIN_DIR" rev-list --count "${BASE_SHA}..${BRANCH}" 2>/dev/null)"
DIFFSTAT="$(git -C "$MAIN_DIR" diff --shortstat "$BASE_SHA" "$BRANCH" 2>/dev/null | sed -e 's/^ *//')"
[ -n "$DIFFSTAT" ] || DIFFSTAT="no diffstat"
SUMMARY="${COMMIT_COUNT} commit(s), ${DIFFSTAT}"
log "Committed on ${BRANCH}: ${SUMMARY}"

if [ "$KEEP_WORKTREE" != "true" ]; then
    remove_worktree
fi

# ------------------------------ deliver ---------------------------------------
if [ "$AUTO_MERGE" != "true" ]; then
    done_ok "BRANCH_READY ${BRANCH} (${SUMMARY})"
fi

# --- guarded auto-merge (squash) ---
SKIP_REASON=""
CUR_BRANCH="$(git -C "$MAIN_DIR" symbolic-ref --short -q HEAD 2>/dev/null)"
if [ "$CUR_BRANCH" != "$BASE_BRANCH" ]; then
    SKIP_REASON="main working tree is on '${CUR_BRANCH:-detached HEAD}', not base branch '${BASE_BRANCH}'"
elif [ -n "$(git -C "$MAIN_DIR" status --porcelain 2>/dev/null)" ]; then
    SKIP_REASON="main working tree is not clean"
fi
if [ -n "$SKIP_REASON" ]; then
    done_ok "BRANCH_READY ${BRANCH} (${SUMMARY}) (auto-merge skipped: ${SKIP_REASON})"
fi

# Undo ONLY the failed squash attempt
rollback_squash() {
    git -C "$MAIN_DIR" merge --abort >> "$LOG_FILE" 2>&1
    git -C "$MAIN_DIR" reset --merge >> "$LOG_FILE" 2>&1
}

log "Auto-merging ${BRANCH} into ${BASE_BRANCH} (squash) ..."
if ! git -C "$MAIN_DIR" merge --squash "$BRANCH" >> "$LOG_FILE" 2>&1; then
    rollback_squash
    fail MERGE_CONFLICT "${BRANCH} (merge rolled back; branch kept)"
fi

if git -C "$MAIN_DIR" diff --cached --quiet; then
    rollback_squash
    done_ok "BRANCH_READY ${BRANCH} (${SUMMARY}) (auto-merge skipped: squash produced no changes, already in ${BASE_BRANCH}?)"
fi

if ! git -C "$MAIN_DIR" ${GIT_ID_ARGS[@]+"${GIT_ID_ARGS[@]}"} commit -m "feat(descartes): ${TASK_ID}" >> "$LOG_FILE" 2>&1; then
    rollback_squash
    fail COMMIT_FAILED "squash commit failed on ${BASE_BRANCH}; merge rolled back; branch ${BRANCH} kept"
fi

MERGED_SHA="$(git -C "$MAIN_DIR" rev-parse --short HEAD 2>/dev/null)"
if [ "$KEEP_WORKTREE" = "true" ]; then
    log "--keep-worktree set: leaving branch ${BRANCH} and worktree in place."
else
    git -C "$MAIN_DIR" branch -D "$BRANCH" >> "$LOG_FILE" 2>&1
fi
done_ok "MERGED ${TASK_ID} ${MERGED_SHA}"

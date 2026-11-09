---
name: night-shift
description: Standard Operating Procedures for transferring the agent to an autonomous remote server environment when the user goes off work.
---
# Night Shift & Autonomous Handoff Protocol

When the user indicates they are leaving work or explicitly triggers the "Night Shift" (e.g., "转到后台", "我下班了"), you MUST execute this protocol to transition the current conversation into a fully autonomous, unattended run.

## Routing: Choose the Execution Engine

Select the overnight execution path based on the nature of the remaining tasks:
- **Path A (Well-Scoped Unattended Task Queue — No GitHub Required)**: Use the **Descartes Autonomous Pipeline (`descartes_watchdog.sh --auto-merge`)** for serial, single-module coding tasks with deterministic test verification in isolated git worktrees.
- **Path B (Heavy / Multi-File GitHub Task Queue — Cloud Sandbox + PR Auto-Merge)**: Use the **Google Remote Agent Autonomous Pipeline (`remote_watchdog.sh --autonomous --auto-merge -a <account>`)** for heavier multi-file features or refactors on GitHub-backed projects (`<owner>/<project>`), leveraging server multi-account rotation.
- **Path C (Interactive / Complex Master Controller Handoff)**: Use the **Antiverse Zellij Protocol (`antiverse-run`)** for open-ended, multi-agent, or server-local service orchestration sessions.

---

## Path A: Descartes Autonomous Pipeline (`descartes_watchdog.sh --auto-merge`)

> [!TIP]
> **Complete Sleep / Lid-Close Immunity**: `descartes_watchdog.sh` runs directly on the remote server in isolated git worktrees (`descartes/<Task_ID>`) without requiring local client connectivity or GitHub round-trips.

### Step 1: Pre-Handoff Checkpoint & Sync (Remote Server)
Ensure all work is synced and committed on the server (`<remote_dir>/<project>`) so each worktree starts from a clean, up-to-date base branch:
```bash
ssh <REMOTE_HOST> "cd <remote_dir>/<project> && git status --short && git add . && git commit -m 'chore(auto): Pre-handoff Night Shift checkpoint' || true"
```

### Step 2: Queue Remaining Tasks to Descartes with `--verify` and `--auto-merge`
Compile pending well-scoped tasks from `tasks/` into an automated serial pipeline on the server.
> [!IMPORTANT]
> **Serial Execution & Mandatory Verification**: Because the Descartes Hub is shared, tasks MUST run serially at night (never in parallel) and include both `--verify "<test cmd>"` and `--auto-merge` (automatic squash merge into the base branch once verification passes).

Launch the unattended runner in background on the server:
```bash
ssh <REMOTE_HOST> 'bash -s' << 'EOF'
cat > /tmp/descartes_night_runner.sh << 'RUNNER'
declare -A PROMPTS=(
  ["<task_a>"]="<Prompt A>"
  ["<task_b>"]="<Prompt B>"
)
for task in <task_a> <task_b>; do
  bash scripts/watchdogs/descartes_watchdog.sh \
    -t "$task" \
    -d "<remote_dir>/<project>" \
    -p "${PROMPTS[$task]}" \
    --verify "<test cmd>" \
    --auto-merge
  if [ "$(grep -c DONE /tmp/${task}.signal)" -eq 0 ]; then
    echo "Task $task failed, stopping pipeline."
    break
  fi
done
RUNNER
nohup bash /tmp/descartes_night_runner.sh > /tmp/descartes_night_shift.log 2>&1 &
EOF
```

### Step 3: Inform User & Rollback Safety
Inform the user that Night Shift is handed off to the Descartes autonomous pipeline with automated squash merging.
- **Next Morning**: User reviews `git log` on server (or via Mutagen sync locally) to inspect all merged commits.
- **Rollback Guarantee**: Each task is merged as a single squash commit (`feat(descartes): <Task_ID>`). Any suboptimal task can be cleanly reverted via `git revert <commit_hash>`, and any failed task leaves its `descartes/<Task_ID>` branch intact for review.

---

## Path B: Google Remote Agent Autonomous Pipeline (`remote_watchdog.sh --autonomous --auto-merge -a <account>`)

> [!TIP]
> **Cloud-Scale Execution with Multi-Account Quota Isolation**: `remote_watchdog.sh` launches Google Antigravity Remote Agents (`agy --remote-agent`), automatically injects `IRON_RULES.md`, guards account switching with a `flock` mutex, enforces Defenses 1–3 against stalls, and squash-merges PRs on GitHub.

### Step 1: Distill Context & Select Account
1. Query `kb_search` for the target project and synthesize architectural constraints into each task prompt.
2. Choose the Google account (`-a dev1@example.com` or `-a dev2@example.com`), or alternate accounts across tasks in the queue.

### Step 2: Launch Overnight Remote Agent Pipeline
```bash
ssh <REMOTE_HOST> 'bash -s' << 'EOF'
cat > /tmp/remote_night_runner.sh << 'RUNNER'
declare -A PROMPTS=(
  ["<task_a>"]="<Distilled Prompt A>"
  ["<task_b>"]="<Distilled Prompt B>"
)
declare -A ACCOUNTS=(
  ["<task_a>"]="dev1@example.com"
  ["<task_b>"]="dev2@example.com"
)
for task in <task_a> <task_b>; do
  bash scripts/watchdogs/remote_watchdog.sh \
    -t "$task" \
    -r "<owner>/<project>" \
    -d "<remote_dir>/<project>" \
    -b "main" \
    -a "${ACCOUNTS[$task]}" \
    --tier "dev" \
    --autonomous \
    --auto-merge \
    -p "${PROMPTS[$task]}"
  if [ "$(grep -c DONE /tmp/${task}.signal)" -eq 0 ]; then
    echo "Remote Task $task failed, stopping pipeline."
    break
  fi
done
RUNNER
nohup bash /tmp/remote_night_runner.sh > /tmp/remote_night_shift.log 2>&1 &
EOF
```

---

## Path C: Antiverse Zellij Protocol (`antiverse-run`)

All overnight tasks, master controllers, and dispatched subagents can also be launched as **dedicated, isolated Zellij sessions** via `antiverse-run` (e.g., `[<project_name>] night`, `[<project_name>] dev-<task_id>`).

1. Write prompt to command file:
   ```text
   /goal Complete remaining tasks autonomously overnight.
   ```
2. Launch master session:
   ```bash
   ssh <REMOTE_HOST> "antiverse-run --name '[<project_name>] night' --tier dev --cwd '<remote_dir>/<project>' --force -- agy -i /tmp/night_shift.txt"
   ```

## Infinite Loop Prevention
- If a task fails 3 consecutive times, mark it as `status: failed_needs_human` in Kanban, terminate the subagent, and advance to the next task in the queue.

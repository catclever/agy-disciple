---
name: night-shift
description: Standard Operating Procedures for transferring the agent to an autonomous remote server environment when the user goes off work.
---
# Night Shift & Autonomous Handoff Protocol (Server Mode)

When the user indicates they are leaving work or explicitly triggers the "Night Shift" (e.g., "转到服务器", "进入夜班"), execute this protocol to transition the current workspace into a fully autonomous, unattended run on the remote compute server.

## Routing: Choose the Execution Engine

> [!IMPORTANT]
> **Default Path**: Remote Server Multiplexer Session with native `agy` CLI agent (**Path A**). Works for all repositories without requiring GitHub cloud integration or Ultra subscriptions.
> **Opt-in Path**: Google Cloud Jules autonomous pipeline (**Path B**), used ONLY when the user explicitly requests Jules (e.g., "夜间用 jules 跑", "run night shift with jules") AND the project is pushed to GitHub.

---

## Path A: Remote Multiplexer Session (Default: Server-Native `agy`)

### Phase 1: Context Gathering & Clean Up
1. Stop local watchdogs or background monitors.
2. Note down running task IDs on remote server.
3. Pre-handoff Git Checkpoint on remote server.

### Phase 2: Handoff Execution
Spawn a new master tab inside the persistent multiplexer session (e.g., Zellij `Antiverse` or tmux):
```bash
ssh <REMOTE_HOST> "zellij --session <SESSION_NAME> action new-tab --name '[<project_name>]' && zellij --session <SESSION_NAME> action write-chars 'cd <remote_dir> && agy --remote-control --dangerously-skip-permissions -i \"\$(cat commands/night_shift.txt)\"; echo \"Agent exited with code \$?\"' && zellij --session <SESSION_NAME> action send-keys 'Enter'"
```

### Phase 3: Autonomous SOPs on Server
1. **Git Checkpoint Rule**: Commit before merging (`git add . && git commit -m "chore(auto): Night Shift checkpoint"`).
2. **Infinite Loop Prevention**: If a task fails 3 consecutive times, mark it as `status: failed_needs_human`, kill the dev agent, and proceed to next task.

---

## Path B: Headless Autonomous Cloud Pipeline (Opt-in: Explicit Jules Request)

### Step 1: Pre-Handoff Checkpoint & Push
Ensure all local work is committed and pushed to remote:
```bash
git status
git add . && git commit -m "chore(auto): Pre-handoff Night Shift checkpoint"
git push origin main
```

### Step 2: Queue Remaining Tasks to Autonomous Runner
Compile pending tasks from `tasks/` into an automated sequential pipeline on the remote server:

> [!IMPORTANT]
> **Mandatory Autonomous Flags**: In Night Shift mode, tasks MUST be invoked with `--autonomous` (arming Defenses 1, 2, 3 to prevent plan/clarification stalls), `-d "<project_dir>"` (pre-flight Git sync), and `--auto-merge` (automatic squash merge once CI passes).

```bash
ssh <REMOTE_HOST> "nohup bash -c '
  for task in <TASK_LIST>; do
    bash scripts/watchdogs/jules_watchdog.sh \
      -t \"\$task\" \
      -r \"<owner/repo>\" \
      -p \"<Prompt>\" \
      -d \"<project_dir>\" \
      --autonomous \
      --auto-merge
    if [ \$(cat /tmp/\${task}.signal | grep -c \"DONE\") -eq 0 ]; then
      echo \"Task \$task failed, stopping pipeline.\"
      break
    fi
  done
' > /tmp/night_shift.log 2>&1 &"
```

### Step 3: Inform User & Rollback Safety
Inform the user that Night Shift is handed off to Jules.
- The user can inspect completed tasks next morning via `git pull`.
- Each task PR or squash commit is cleanly revertible.

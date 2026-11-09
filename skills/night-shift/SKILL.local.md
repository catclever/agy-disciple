---
name: night-shift
description: Standard Operating Procedures for transitioning the agent to an autonomous, unattended run on the local machine or cloud when the user goes off work.
---
# Night Shift Protocol (Local-First Mode)

When the user indicates they are leaving work or explicitly triggers "Night Shift" (e.g., "我下班了", "进入夜间自主模式"), execute this protocol to transition the current workspace into an unattended, autonomous run.

## Routing: Choose Local or Cloud Engine

- **Option 1 (Local Autonomous Queue)**: Use native `dev` subagents with `/goal` for rapid local iteration when the local machine stays awake.
- **Option 2 (Direct Mac-to-Cloud Remote Agent Pipeline)**: Use `remote_watchdog.sh` for heavy multi-file GitHub-backed tasks, creating PRs and auto-merging them into `main`.

---

## Option 1: Local Autonomous Queue (`/goal`)

### Step 1: Pre-Handoff Git Checkpoint
Ensure all working progress is cleanly committed:
```bash
git status
git add -A && git commit -m "chore(auto): Pre-handoff Night Shift checkpoint" || true
```

### Step 2: Compile Pending Tasks
1. Scan `tasks/` (via `kanban-task-manager` MCP `list_tasks`) for all tasks with `status: backlog` or `status: active`.
2. Order them by priority (`high` $\rightarrow$ `medium` $\rightarrow$ `low`).
3. Prepare clear execution criteria and constraints for each task.

### Step 3: Trigger Autonomous Execution (/goal)
Recommend or launch autonomous mode:
- Use the `/goal` command:
  ```text
  /goal Complete all remaining backlog tasks in tasks/.
  For each task:
  1. Break down and invoke the dev agent.
  2. Verify within sandbox.
  3. Merge using merger agent.
  4. Commit code: git commit -m "feat(<task_id>): complete task".
  5. Update task status to 'completed' via MCP.
  ```

---

## Option 2: Direct Mac-to-Cloud Remote Agent Pipeline (`remote_watchdog.sh`)

If tasks are heavy or GitHub PR review is desired:
```bash
cat > /tmp/night_remote_runner.sh << 'EOF'
declare -A PROMPTS=(
  ["<task_a>"]="<Prompt A>"
  ["<task_b>"]="<Prompt B>"
)
for task in <task_a> <task_b>; do
  bash scripts/watchdogs/remote_watchdog.sh \
    -t "$task" \
    -r "<owner>/<project>" \
    -d "$PWD" \
    -b "main" \
    --tier "dev" \
    --autonomous \
    --auto-merge \
    -p "${PROMPTS[$task]}"
  if [ "$(grep -c DONE /tmp/${task}.signal 2>/dev/null || echo 0)" -eq 0 ]; then
    echo "Task $task failed, stopping pipeline."
    break
  fi
done
EOF
nohup bash /tmp/night_remote_runner.sh > /tmp/night_remote.log 2>&1 &
```

---

## Safety & Infinite Loop Prevention
- If a task fails verification 3 consecutive times, mark it as `status: failed_needs_human` with an explanation.
- Terminate the dev agent for that task and advance to the next task in the queue.
- Never block the entire night shift on a single stubborn bug.

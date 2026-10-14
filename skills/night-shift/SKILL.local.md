---
name: night-shift
description: Standard Operating Procedures for transitioning the agent to an autonomous, unattended run on the local machine when the user goes off work.
---
# Night Shift Protocol (Local-First Mode)

When the user indicates they are leaving work or explicitly triggers "Night Shift" (e.g., "我下班了", "进入夜间自主模式"), execute this protocol to transition the current workspace into an unattended, autonomous run.

## Step 1: Pre-Handoff Git Checkpoint
Ensure all working progress is cleanly committed:
```bash
git status
git add . && git commit -m "chore(auto): Pre-handoff Night Shift checkpoint"
```

## Step 2: Compile Pending Tasks
1. Scan `tasks/` for all tasks with `status: backlog` or `status: active`.
2. Order them by priority (`high` -> `medium` -> `low`).
3. Prepare clear execution criteria and constraints for each task.

## Step 3: Trigger Autonomous Execution (/goal)
Recommend or launch autonomous mode:
- Use the `/goal` command:
  ```text
  /goal Complete all remaining backlog tasks in tasks/.
  For each task:
  1. Break down and invoke the dev agent.
  2. Verify within sandbox.
  3. Merge using merger agent.
  4. Commit code: git commit -m "feat(<task_id>): complete task".
  5. Update task status to 'completed'.
  ```

## Step 4: Safety & Infinite Loop Prevention
- If a task fails verification 3 consecutive times, mark it as `status: failed_needs_human` with an explanation.
- Terminate the dev agent for that task and advance to the next task in the queue.
- Never block the entire night shift on a single stubborn bug.

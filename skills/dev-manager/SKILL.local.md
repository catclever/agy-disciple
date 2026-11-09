---
name: dev-manager
description: "SOP for delegating development tasks to local sub-agents or direct Mac-to-Cloud Remote Agents."
---
# Dev Manager SOP (Local-First Mode)

This skill defines how the Lead Architect (Main Agent) orchestrates coding tasks on the local machine. It provides a dual-engine architecture for the development sub-agent.

## Available Dev Sub-Agents

The Lead Architect can select the appropriate Dev engine depending on task complexity and execution scope:

### Engine Option A: Native `dev` Agent (`agents/dev.yaml`) [DEFAULT]
- **Execution Target**: Local Antigravity IDE conversation tree via `invoke_subagent`.
- **Model**: Local Antigravity model (Gemini 3.8 Flash or Gemini 3.1 Pro).
- **Best For**: Rapid iterations, short bug fixes, interactive user review.
- **Workflow**: Generates draft files (`api_task_001.py`), runs sandboxed unit tests, and hands off to `merger`.
- **Completion Condition**: The `dev` agent is ONLY considered completed AFTER the user has manually tested and explicitly accepted the code changes. Until then, it stays suspended (idle), waiting for you to relay user feedback for further fixes.

### Engine Option B: Direct Mac-to-Cloud Remote Agent (`remote_watchdog.sh`) [OPT-IN]
- **Execution Target**: Google Cloud Remote Agent launched directly from Mac without needing external servers:
  ```bash
  nohup bash scripts/watchdogs/remote_watchdog.sh \
    -t "<Task_ID>" \
    -r "<owner/repo>" \
    -d "$PWD" \
    -b "main" \
    --tier "dev" \
    --autonomous \
    --auto-merge \
    -p "<Distilled Prompt + Acceptance Criteria>" \
    > /dev/null 2>&1 &
  ```
- **Strategic Value**: Dispatches heavy or multi-file coding tasks to the Google Cloud Sandbox (`agy --remote-agent`). Defenses 1–3 prevent stalls, and upon completion the PR is merged and automatically pulled back into the local workspace (`git pull --rebase`).
- **Trigger Condition**: Select Engine B ONLY when the user explicitly requests offloading to cloud remote agent and the repository is hosted on GitHub.

---

## The `merger` Agent (Located in `agents/merger.yaml`)
- **Role**: Replaces original source files with development drafts after creating `.bak` backups (used when Engine A is active).
- **Completion Condition**: Completed the moment backup and file rename operations finish. It requires no user verification.

---

## Delegation Lifecycle & Opportunistic Silent GC

0. **Prerequisite & Pre-Dispatch GC [节点 A · 派发前检查]**:
   - You MUST NOT invoke a `dev` agent unless you have already executed the `task-breakdown` skill and created the task in Kanban via MCP.
   - **Silent GC Before Dispatch**: Prior to calling `invoke_subagent`, silently inspect the session tree (`manage_subagents`) and background tasks (`manage_task`). Silently kill any previously closed/completed sub-agents and purge finished zombie tasks to keep the context clean.
1. **Assign**: Main Agent reads the task and invokes the `dev` agent, passing the `Task ID` and required file coordinates.
2. **Suspend & Review**: The `dev` agent finishes drafting and suspends itself (goes idle). The Main Agent reviews the results.
3. **Merge (Draft)**: The Main Agent invokes the `merger` agent to apply the drafts. Once merged, the `merger` agent is immediately killed.
4. **User Verification & Post-Acceptance Silent GC [节点 B · 验收闭环时]**: The Main Agent asks the user to manually verify the changes.
   - *If rework is needed*: Wake up the suspended `dev` agent by sending it a message with the feedback. Repeat from step 2.
   - *If verified*: The task is complete. Mark the Kanban task status as `completed` via MCP, and **immediately and silently kill** the `dev` agent. If multiple agents ran or local scratch files piled up, optionally trigger `python3 scripts/clean_subagents.py --session <current_conversation_id> --min-age-hours 24 --quiet` silently.

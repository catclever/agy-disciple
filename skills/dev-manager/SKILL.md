---
name: dev-manager
description: "SOP for delegating development tasks to local sub-agents or local Jules cloud workers."
---
# Dev Manager SOP (Local-First Mode)

This skill defines how the Lead Architect (Main Agent) orchestrates coding tasks on the local machine. It provides a dual-engine architecture for the development sub-agent.

## Available Dev Sub-Agents

The Lead Architect can select the appropriate Dev engine depending on task complexity and token budget:

### Engine Option A: Native `dev` Agent (`agents/dev.yaml`)
- **Execution Target**: Local Antigravity IDE conversation tree via `invoke_subagent`.
- **Model**: Local Antigravity model (Gemini 3.8 Flash or Argon).
- **Best For**: Rapid iterations, short bug fixes, interactive user review.
- **Workflow**: Generates draft files (`api_task_001.py`), runs sandboxed unit tests, and hands off to `merger`.

### Engine Option B: Local `jules-dev` Agent (`agents/jules-dev.yaml`)
- **Execution Target**: Google Cloud Jules cloud VM launched via local watchdog:
  ```bash
  bash scripts/watchdogs/jules_watchdog.sh -t '<Task_ID>' -r '<owner/repo>' -p '<Prompt>' [--auto-merge]
  ```
- **Model & Quota**: **Gemini 3.1 Pro** running on dedicated Jules cloud quota.
- **Strategic Value (Quota Arbitrage)**:
  - Antigravity currently only offers expensive models (like Argon) and lightweight models (Gemini 3.8 Flash).
  - Offloading heavy implementation tasks to Jules leverages **Gemini 3.1 Pro**'s superior reasoning without burning expensive Antigravity tokens!
- **Deliverable**: Creates a GitHub Pull Request and optionally auto-merges it via `gh pr merge --squash`.

---

## The `merger` Agent (Located in `agents/merger.yaml`)
- **Role**: Replaces original source files with development drafts after creating `.bak` backups (used when Engine A is active).
- **Completion Condition**: Completed the moment backup and file rename operations finish.

---

## Delegation Lifecycle

0. **Prerequisite**: Register the task card in `tasks/` (via `kanban-task-manager` MCP or Markdown).
1. **Engine Selection**:
   - For light tasks or quick scripts -> Select **Engine A (Native `dev`)**.
   - For complex features, multi-file refactors, or saving Antigravity tokens -> Select **Engine B (Local `jules-dev`)**.
2. **Execute & Verify**:
   - If Engine A: Wait for draft files, invoke `merger`, ask user to verify.
   - If Engine B: Wait for `/tmp/<Task_ID>.signal`, review PR URL on GitHub, pull changes via `git pull`.
3. **Completion**: Close the task card and report final status to the user.

---
name: dev-manager
description: "SOP for delegating tasks to sub-agents across local, remote server, and cloud execution environments."
---
# Dev Manager SOP (Dual-Topology / Server Mode)

This skill defines how the Lead Architect (Main Agent) orchestrates development tasks, routing between local sub-agents and remote server execution depending on the project's target environment and execution certainty.

## Topology Routing & Dev Engines

By default, development tasks should be handled cleanly according to the project's environment topology:

### Engine 1: Remote Server Native Agent (`pve_watchdog.sh` / `agy`) [DEFAULT for Remote Projects]
- **Execution Target**: Dedicated remote server running `agy` inside a background session or watchdog (`antiverse-run`).
- **Why Default**: Reliable, zero-external-dependency execution for any repository (GitHub, GitLab, or private local projects).
- **Execution**: Dispatch via `pve_watchdog.sh` over SSH.

### Engine 2: Google Cloud Remote Agent (`remote_watchdog.sh`) [OPT-IN: Cloud GitHub Workloads]
- **Execution Target**: Google Cloud Remote Agent dispatched from local Mac (Option B1) or routed through remote server (Option B2 with `flock` + `agy-account switch`):
  ```bash
  ssh <REMOTE_HOST> "bash scripts/watchdogs/remote_watchdog.sh -t '<Task_ID>' -r '<owner/repo>' -d '<remote_dir>/<project>' -b 'main' -a 'account@example.com' --tier 'dev' --autonomous --auto-merge -p '<Prompt>'"
  ```
- **Trigger Condition**: Use when offloading heavy multi-file coding or PR generation on GitHub-backed repositories to Google Cloud infrastructure.

### Engine 3: Descartes + EnginEdge Watchdog (`descartes_watchdog.sh`) [OPT-IN: Worktree-Isolated Coding]
- **Execution Target**: Remote server isolated git worktree with EnginEdge agent:
  ```bash
  ssh <REMOTE_HOST> "bash scripts/watchdogs/descartes_watchdog.sh -t '<Task_ID>' -d '<remote_dir>/<project>' -p '<Prompt>' --verify '<test cmd>'"
  ```
- **Trigger Condition**: Use for well-scoped single-module tasks (≤50 turns) where no GitHub PR or human plan-approval is required.

### Engine 4: Local Native `dev` Agent (`agents/dev.yaml`)
- **Execution Target**: Local Antigravity IDE conversation tree via `invoke_subagent`.
- **Best For**: Rapid exploratory fixes and interactive code edits reviewed directly by the user on the local client.

---

## Delegation Lifecycle & Opportunistic Silent GC

0. **Prerequisite & Pre-Dispatch GC [节点 A · 派发前检查]**:
   - You MUST NOT invoke a `dev` agent unless you have registered the task in Kanban via MCP.
   - **Silent GC Before Dispatch**: Prior to invoking a new sub-agent, silently check the session tree (`manage_subagents`) and background tasks (`manage_task`). Silently kill any previously closed/completed sub-agents and purge finished zombie tasks.
1. **Assign**: Lead Architect formats requirements, injects `IRON_RULES.md` (`[Global]` + `[Dev Agent]`), and dispatches to the chosen engine.
2. **Monitor**: For remote engines, watchdog polls `/tmp/<Task_ID>.signal`. For local subagents, the agent goes idle after producing draft files.
3. **User Verification & Post-Acceptance Silent GC [节点 B · 验收闭环时]**:
   - The Lead Architect verifies the changes with the user.
   - Once accepted and marked `completed` in Kanban via MCP, **immediately and silently kill** the corresponding sub-agent.
   - Optionally trigger `python3 scripts/clean_subagents.py --session <current_conversation_id> --min-age-hours 24 --quiet` to reclaim disk space.

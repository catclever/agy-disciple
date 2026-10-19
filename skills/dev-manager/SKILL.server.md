---
name: dev-manager
description: "SOP for delegating tasks to sub-agents across local, remote server (PVE), and server-side Jules environments."
---
# Dev Manager SOP (Dual-Topology / Server Mode)

This skill defines how the Lead Architect (Main Agent) orchestrates development tasks, routing between local sub-agents and remote server execution depending on the project's target environment.

## Topology Routing & Dev Engines

By default, all development tasks MUST be delegated to the **Remote Server Native Agent (Engine 1)** or **Local Native dev (Engine 3)** without requiring external cloud setups. Use Jules ONLY when the user explicitly requests it.

### Engine 1: Remote Server Native Agent (`pve_watchdog.sh` / `agy`) [DEFAULT]
- **Execution Target**: Dedicated remote server running `agy` inside a background session or watchdog.
- **Why Default**: Reliable, zero-configuration out-of-the-box execution for any repository (GitHub, GitLab, or private local projects).

### Engine 2: Server-Side Jules Cloud Watchdog [OPT-IN: Explicit Request Only]
- **Execution Target**: Dispatched to the remote server via SSH, which runs Jules watchdog in the background:
  ```bash
  ssh <REMOTE_HOST> "bash scripts/watchdogs/jules_watchdog.sh -t '<Task_ID>' -r '<owner/repo>' -p '<Prompt>' [-d '<project_dir>'] [--autonomous] [--auto-merge]"
  ```
- **Trigger Condition**: Use ONLY when the user explicitly asks for Jules (e.g. "用 jules 跑", "派发给 jules dev", "run with jules") AND the project is pushed to GitHub with Jules credentials configured.
- **Model & Quota**: **Gemini 3.1 Pro** running on dedicated Google Cloud Jules quota.
- **Why Use**: Drains Ultra cloud allowance to save Antigravity tokens, with 3.1 Pro deep reasoning and cloud auto-merge.

### Engine 3: Local Native `dev` Agent (`agents/dev.yaml`)
- **Execution Target**: Local Antigravity IDE conversation tree via `invoke_subagent`.
- **Best For**: Quick, interactive code edits reviewed directly by the user on the local client.

---

## Delegation Lifecycle (Server Jules Workflow)
0. **Prerequisite**: Task card logged in `tasks/`.
1. **Assign**: Lead Architect formats the requirements and invokes `jules_watchdog.sh` on the remote server.
2. **Monitor**: Watchdog polls `/tmp/<Task_ID>.signal` until PR is created or merged.
3. **Sync Deliverables**: Once merged, run `git pull` on the local workspace.

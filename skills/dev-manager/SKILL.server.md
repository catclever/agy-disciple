---
name: dev-manager
description: "SOP for delegating tasks to sub-agents across local, remote server (PVE), and server-side Jules environments."
---
# Dev Manager SOP (Dual-Topology / Server Mode)

This skill defines how the Lead Architect (Main Agent) orchestrates development tasks, routing between local sub-agents and remote server execution depending on the project's target environment.

## Topology Routing & Dev Engines

Before delegating any development task, select the execution engine:

### Engine 1: Server-Side Jules Cloud Watchdog (Google Cloud Jules via PVE)
- **Execution Target**: Dispatched to the remote server via SSH, which runs Jules watchdog in the background:
  ```bash
  ssh <REMOTE_HOST> "bash scripts/watchdogs/jules_watchdog.sh -t '<Task_ID>' -r '<owner/repo>' -p '<Prompt>' [--auto-merge]"
  ```
- **Model & Quota**: **Gemini 3.1 Pro** running on dedicated Google Cloud Jules quota.
- **Why Use**: Saves expensive Antigravity tokens, leverages 3.1 Pro's deep reasoning, and executes in the cloud completely immune to local client shutdowns.

### Engine 2: Remote PVE Native Agent (`pve_watchdog.sh`)
- **Execution Target**: Dedicated Linux/PVE server running `agy --remote-control` inside a persistent Zellij tab.
- **Best For**: Non-GitHub private projects, heavy local builds, or custom server environments.

### Engine 3: Local Native `dev` Agent (`agents/dev.yaml`)
- **Execution Target**: Local Antigravity IDE conversation tree via `invoke_subagent`.
- **Best For**: Quick, interactive code edits reviewed directly by the user.

---

## Delegation Lifecycle (Server Jules Workflow)
0. **Prerequisite**: Task card logged in `tasks/`.
1. **Assign**: Lead Architect formats the requirements and invokes `jules_watchdog.sh` on the remote server.
2. **Monitor**: Watchdog polls `/tmp/<Task_ID>.signal` until PR is created or merged.
3. **Sync Deliverables**: Once merged, run `git pull` on the local workspace.

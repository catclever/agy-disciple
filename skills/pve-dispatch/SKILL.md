---
name: pve-dispatch
description: "SOP for delegating tasks to REMOTE agents on a remote PVE or Linux server. Use this when the project is configured for remote compute."
---
# Remote Server Dispatch SOP

This skill defines how the Lead Architect (Main Agent) should orchestrate sub-agents (like `dev` or `ops`) for projects running on a remote compute server (e.g., PVE / Linux server) while the Main Agent is running on the local client.

## When to Use This Skill
Use this skill whenever delegating tasks to remote compute resources.

## Dispatch Routing Strategy

> [!IMPORTANT]
> **Default Route: Direct Remote Agent Dispatch (Native `agy`)**:
> By default, all remote tasks MUST be dispatched to the remote server's native agent environment (**Mode A**). This requires zero external cloud accounts and works seamlessly for all codebases (GitHub, GitLab, or local private repos).
>
> **Opt-in Route: Google Cloud Jules Dispatch (Explicit Request Only)**:
> Use **Mode B (Cloud / Jules Dispatch)** ONLY when the user explicitly requests it (e.g., "用 jules 跑", "派发给 jules", "run with jules") AND the project has a GitHub remote repository (`git remote get-url origin` containing `github.com`).

### Mode A: Direct Remote Agent Dispatch (Default: Native `agy`)
Use this default mode to run tasks directly on the remote server using the resident `agy` CLI agent:

1. **Prerequisite**: Task card logged in `tasks/`.
2. **Assign via Remote Watchdog / CLI**:
   Run the remote server watchdog script in the background:
   ```bash
   bash scripts/watchdogs/pve_watchdog.sh -t '<Task_ID>' -a '<dev|ops>' -d '<project_dir>' -p '<Prompt>' -h '<REMOTE_HOST>'
   ```
3. **Wait for Native Wakeup**:
   Wait for completion notification or signal file (`/tmp/<Task_ID>.signal`).
4. **User Verification & Remote Merge**:
   Ask user to verify, then merge drafts.

---

### Mode B: Cloud / Jules Dispatch (Opt-in: Explicit User Request)
Use this mode ONLY when the user explicitly asks to run on Jules and the repository is hosted on GitHub:

1. **Pre-Flight Git Sync**: Ensure local changes are committed and pushed:
   ```bash
   git status
   git add . && git commit -m "chore: save before remote dispatch" && git push
   ```
2. **Dispatch via Jules Watchdog**:
   Run the Jules watchdog script on the remote host in the background:
   ```bash
   ssh <REMOTE_HOST> "bash scripts/watchdogs/jules_watchdog.sh -t '<Task_ID>' -r '<owner/repo>' -p '<Prompt>' -b '<branch>'"
   ```
3. **Wait for Completion Signal**:
   Wait for `/tmp/<Task_ID>.signal` to indicate completion.
4. **Merge Deliverables**:
   Once merged on GitHub, run `git pull` locally.

---

## Remote Server Environment Tips
- Ensure the remote user environment has package version managers properly sourced (e.g., `mise`, `asdf`, `nvm`).
- Ensure all operational commands run inside their respective virtual environments.

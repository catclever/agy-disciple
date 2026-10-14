---
name: pve-dispatch
description: "SOP for delegating tasks to REMOTE agents on a remote PVE or Linux server. Use this when the project is configured for remote compute."
---
# Remote Server Dispatch SOP

This skill defines how the Lead Architect (Main Agent) should orchestrate sub-agents (like `dev` or `ops`) for projects running on a remote compute server (e.g., PVE / Linux server) while the Main Agent is running on the local client.

## When to Use This Skill
Use this skill whenever delegating tasks to remote compute resources.

## Dispatch Routing Strategy

Before dispatching, check if the current project has a GitHub remote repository (`git remote get-url origin` containing `github.com`):

### Mode A: Cloud / Jules Dispatch (Priority 1: GitHub Projects)
1. **Pre-Flight Git Sync**: Ensure local changes are committed and pushed:
   ```bash
   git status
   git add . && git commit -m "chore: save before remote dispatch" && git push
   ```
2. **Dispatch via Watchdog**:
   Run the watchdog script on the remote host in the background:
   ```bash
   ssh <REMOTE_HOST> "bash scripts/watchdog.sh -t '<Task_ID>' -r '<owner/repo>' -p '<Prompt>' -b '<branch>'"
   ```
3. **Wait for Completion Signal**:
   Wait for `/tmp/<Task_ID>.signal` to indicate completion.
4. **Merge Deliverables**:
   Once merged on remote/GitHub, run `git pull` locally.

---

### Mode B: Direct Remote Agent Dispatch (Priority 2: Private / Non-GitHub Projects)
Use this mode when working on a remote server without GitHub auto-merge pipelines:

1. **Prerequisite**: Task card logged in `tasks/`.
2. **Assign via Remote Watchdog / CLI**:
   Run the remote agent in the background on the remote server:
   ```bash
   ssh <REMOTE_HOST> "cd <remote_project_dir> && agy -t '<Task_ID>' -p '<Prompt>'"
   ```
3. **Wait for Native Wakeup**:
   Wait for completion notification or signal file.
4. **User Verification & Remote Merge**:
   Ask user to verify, then merge drafts.

---

## Remote Server Environment Tips
- Ensure the remote user environment has package version managers properly sourced (e.g., `mise`, `asdf`, `nvm`).
- Ensure all operational commands run inside their respective virtual environments.

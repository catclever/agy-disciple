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

1. **Pre-Flight Git Sync (Local)**: Ensure local changes are committed and pushed:
   ```bash
   git status
   git add . && git commit -m "chore: save before remote dispatch" && git push
   ```
2. **Dispatch via Jules Watchdog**:
   Run the Jules watchdog script on the remote host in the background using SSH Stdin stream (`bash -s` with Heredoc). This avoids nested Shell escaping conflicts and eliminates temporary disk files:
   ```bash
   ssh <REMOTE_HOST> 'bash -s' << 'EOF'
   bash scripts/watchdogs/jules_watchdog.sh \
     -t "<Task_ID>" \
     -r "<owner/repo>" \
     -b "<branch>" \
     -p "<Prompt>" \
     -d "<project_dir>" \
     [--autonomous]  # Optional: Default OFF. Append only if zero-intervention is requested.
   EOF
   ```
   *Mode Selection Rules*:
   - **Standard Mode (Default for Daytime)**: Omits `--autonomous`. Preserves human-in-the-loop plan reviews (`requirePlanApproval: true`). If Jules enters `AWAITING_PLAN_APPROVAL` or `AWAITING_USER_FEEDBACK`, it waits for user interaction on jules.google.com.
   - **Autonomous Mode (`--autonomous`)**: Activates three lines of defense for unattended runs:
     1. *Defense 1*: Pre-suppresses plan stops (`requirePlanApproval: false`).
     2. *Defense 2*: Auto-approves plan via `:approvePlan` if `AWAITING_PLAN_APPROVAL` occurs.
     3. *Defense 3*: Auto-replies with best-practice directive via `:sendMessage` if `AWAITING_USER_FEEDBACK` occurs (max 3 retries).
   *Note: If `-d` is specified, the watchdog will automatically commit and push dirty files on the server before dispatching, aborting if synchronization fails.*
   *For Night Shift / Autonomous runs, append both `--autonomous` and `--auto-merge`.*
3. **Wait for Completion Signal**:
   Wait for `/tmp/<Task_ID>.signal` to indicate completion (`DONE: PR Created: <PR_URL>`).
4. **Merge Deliverables**:
   Once merged on GitHub, run `git pull` locally.

---

## Remote Server Environment Tips
- **Node.js & Language Version Management**: The remote compute server recommended setup uses `mise` for global and project-level environment version management.
- Ensure all operational commands run inside their respective virtual environments (e.g. `uv` or `venv` for Python).

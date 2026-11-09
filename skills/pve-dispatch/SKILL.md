---
name: pve-dispatch
description: "SOP for delegating tasks to REMOTE agents (server compute engines or Google Cloud Remote Agents). Use this for Server-Native projects, or when dispatching any GitHub-backed project to Cloud Remote Agents (Mode B)."
---
# Remote & Server Dispatch SOP

This skill defines how the Lead Architect (Main Agent) should orchestrate remote execution engines (`descartes_watchdog.sh`, `remote_watchdog.sh`, and `pve_watchdog.sh`) across local client, remote servers, and Google Cloud Remote Agents.

## When to use this skill
Use this skill whenever:
1. Delegating tasks to remote compute resources (`Project-Environment: PVE-Native` or Server-Native), OR
2. Delegating heavy/autonomous coding tasks on **any GitHub-backed project** (`Local`, `PVE-Native`, or `Pure-Remote`) to Google Cloud Remote Agents (`Mode B`).

## Dispatch Routing Strategy

Before dispatching, evaluate the scope, GitHub backing, account requirements, and interactivity of the task across three execution modes:

| Mode | Watchdog Script | Engine | Best For |
| :--- | :--- | :--- | :--- |
| **Mode A** | `descartes_watchdog.sh` | Descartes + EnginEdge | Well-scoped, single-module tasks (≤50 turns) on remote server, worktree-isolated, **no GitHub needed** |
| **Mode B** | `remote_watchdog.sh` | Google Cloud Remote Agent (`agy --remote-agent`) | Heavy/multi-file tasks on **GitHub-backed** projects (supports **Option B1 Direct Mac-to-Cloud** & **Option B2 Server Multi-Account/Lid-Close**) |
| **Mode C** | `pve_watchdog.sh` | Server Local `agy` (Zellij TUI) | Interactive/open-ended Server-Native tasks requiring local toolchains, databases, or services |

---

### Mode A: Descartes Unattended Watchdog (Well-Scoped, Single-Module Tasks)
> [!TIP]
> **Headless & Worktree-Isolated**: For well-scoped, single-module coding tasks that do not require interactive plan approval or arbitrary shell commands, delegate to the `descartes-dispatch` skill (`descartes_watchdog.sh`).

1. **When to Choose Mode A**:
   - The task targets a single module or concern and can be completed within ~30–50 ReAct turns.
   - An independent verification command (`--verify "<test cmd>"`) on the whitelist (`cargo`, `pytest`, `npm`, `go test`, etc.) can validate the outcome.
   - All relevant code is committed on the remote repository (`<remote_dir>/<project>`).
2. **Execution**:
   - Read and follow `skills/descartes-dispatch/SKILL.md` to dispatch `descartes_watchdog.sh` over SSH in an isolated git worktree (`descartes/<Task_ID>`).

---

### Mode B: Google Remote Agent Watchdog (`remote_watchdog.sh` — Heavy / Multi-File GitHub Tasks)
Use this mode for heavy coding or multi-file refactoring tasks on GitHub-backed projects. `remote_watchdog.sh` is a **Dual-Host** script that can run either directly on local client (Option B1) or on remote server with `flock`-guarded multi-account switching (Option B2).

1. **Mandatory Pre-Dispatch Context Distillation Checklist**:
   - [ ] Log the task in Kanban via `kanban-task-manager` MCP (`create_task` / `update_task_status`).
   - [ ] Query project knowledge via `kb_search(project="<project>", query="...")` and distill key architectural rules directly into `<Prompt>`.
   - [ ] `remote_watchdog.sh` automatically appends `[Global]` and `[Dev Agent]` from `~/.gemini/Projects/<project>/IRON_RULES.md` if not already present in `<Prompt>`.

2. **Choose Between Option B1 (Local Direct) and Option B2 (Server Routed)**:

   #### Option B1: Direct Mac-to-Cloud Dispatch (No Server Hop — Default when using current account)
   ```bash
   nohup bash scripts/watchdogs/remote_watchdog.sh \
     -t "<Task_ID>" \
     -r "<owner>/<project>" \
     -d "$PWD" \
     -b "main" \
     --tier "dev" \
     --autonomous \
     --auto-merge \
     -p "<Distilled Prompt + Acceptance Criteria>" \
     > /dev/null 2>&1 &
   ```
   - Spawns `agy --remote-agent` locally via a background PTY + FIFO (`/tmp/remote_<Task_ID>.stdin`) for autonomous Defenses 2 & 3, squash-merges the PR upon completion, and automatically runs `git -C "$PWD" pull --rebase origin main`.

   #### Option B2: Server-Routed Multi-Account / Lid-Close Dispatch (`ssh <REMOTE_HOST>`)
   Use this option when switching Google accounts (`-a account@example.com`), dispatching parallel multi-account queues, or running overnight with the local lid closed:
   ```bash
   ssh <REMOTE_HOST> 'bash -s' << 'EOF'
   nohup bash scripts/watchdogs/remote_watchdog.sh \
     -t "<Task_ID>" \
     -r "<owner>/<project>" \
     -d "<remote_dir>/<project>" \
     -b "main" \
     -a "dev@example.com" \
     --tier "dev" \
     --autonomous \
     --auto-merge \
     -p "<Distilled Prompt + Acceptance Criteria>" \
     > /dev/null 2>&1 &
   EOF
   ```

---

### Mode C: Server `agy` Dispatch (Interactive, Local-Service, or Open-Ended Tasks)
Use this mode for exploratory debugging, tasks requiring server-local hardware/services/containers, or interactive sessions.

1. **Prerequisite**: Tasks must be physically logged via `kanban-task-manager` MCP.
2. **Assign via Local Watchdog Script**:
   Execute the local watchdog script on your local machine:
   ```bash
   bash scripts/watchdogs/pve_watchdog.sh \
     -t "<Task_ID>" \
     -a "<dev|ops>" \
     -d "<remote_dir>/<project>" \
     -p "<Prompt>" \
     [--tier "<dev|ops|pro>"]
   ```
   - The remote task runs in its own dedicated Zellij session (`[<project>] <agent>-<task_id>`).
   - Monitor via `ssh <REMOTE_HOST> -t 'antiverse attach <Task_ID>'` or `zellij a '<session>'`.
3. **Wait for Native System Wakeup**:
   Wait for `/tmp/<Task_ID>.signal` completion.
4. **User Verification & Remote Merge**:
   Verify with user, then merge and update Kanban via MCP.

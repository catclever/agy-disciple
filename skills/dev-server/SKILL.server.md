---
name: dev-server
description: "SOP for strictly on-demand management of project dev servers, preview environments, and remote test environments across local, remote server, and Cloud Remote Project conversations."
---
# Dev Server & Remote Test Environment Protocol (Strictly On-Demand)

This skill defines the standard operating procedure for syncing, starting, restarting, inspecting, or stopping dev servers and remote test environments across three conversation contexts (**Local Client**, **Remote Server**, and **Cloud Remote Project**).

> [!IMPORTANT]
> **Strict On-Demand Principle**: Never automatically start or restart a dev server after every routine coding task or Git commit! Only sync or manage the test environment when the user explicitly requests it (e.g., *"同步到测试环境"*, *"启动测试服务"*, *"重启预览服务"*, *"关闭测试环境"*), or during an explicit `night-shift` handoff.

---

## 1. On Local Machine (Local Dev Server)
- **Rule**: **Manual / On-Demand Start Only**. Do NOT automatically start a local dev server during normal coding tasks.
- **Action**: Wait for the user to explicitly request starting the local server. Otherwise, assume the user runs it in their own terminal.

---

## 2. From Local or Server Conversation $\rightarrow$ Controlling the Remote Test Environment (`pve_test_sync.sh`)

When a project has a test clone on a remote server (`<remote_dir>/<project_name>`) and the user asks to sync code or control the preview service, use `pve_test_sync.sh` (via `ssh <REMOTE_HOST>` from local client, or directly if already on the remote server):

### Supported On-Demand Actions (`-a <action>`)

| Action | Command Example (from Local Client) | Behavior & Best Use Case |
| :--- | :--- | :--- |
| **`sync`** *(Default & Recommended)* | `ssh <REMOTE_HOST> "bash <scripts_dir>/pve_test_sync.sh -p <project_name> -a sync"` | Runs `git fetch && git pull --rebase` in `<remote_dir>/<project_name>` **without restarting the process**. Preferred whenever the dev server (e.g. Vite, Next.js, Uvicorn `--reload`) is already running and supports hot-reload! |
| **`start`** | `ssh <REMOTE_HOST> "bash <scripts_dir>/pve_test_sync.sh -p <project_name> -a start"` | Runs `sync`, then starts Zellij session `[<project_name>] env` **only if not already running**, and outputs the 30-line server log tail. |
| **`restart`** | `ssh <REMOTE_HOST> "bash <scripts_dir>/pve_test_sync.sh -p <project_name> -a restart"` | Runs `sync`, then unconditionally restarts `[<project_name>] env` (use when `.env`, dependencies, or backend configs changed). |
| **`stop`** | `ssh <REMOTE_HOST> "bash <scripts_dir>/pve_test_sync.sh -p <project_name> -a stop"` | Cleanly kills and deletes the `[<project_name>] env` Zellij session to free server memory/ports. |
| **`status`** | `ssh <REMOTE_HOST> "bash <scripts_dir>/pve_test_sync.sh -p <project_name> -a status"` | Prints current remote `HEAD` commit, whether `[<project_name>] env` is running, and the last 30 lines of server logs. |

- **CRITICAL Network Binding (`0.0.0.0`)**: Any dev server command on remote server (configured via `PVE-Dev-Server-Cmd:` in `~/.gemini/Projects/<project_name>/IRON_RULES.md` or passed via `-c "<cmd>"`) **MUST** bind to `0.0.0.0` (e.g. `--host 0.0.0.0`, `--bind 0.0.0.0`) so the user can access the preview from their local browser.

---

## 3. From a Cloud Remote Project Conversation $\rightarrow$ Controlling the Remote Test Environment On-Demand (Zero Public Port)

Because Google Cloud Remote Project sandboxes (`/workspace/<project_name>`) run in cloud containers and cannot SSH directly into private network servers:

1. **Lightweight On-Demand Tag Watcher on Remote Server**:
   - On the remote server, a lightweight watcher (`pve_test_sync.sh -p <project_name> -a watch`) polls `refs/tags/pve-env-*` every 15 seconds.
   - **Normal `git push origin main` commits are completely ignored** by the watcher — the server never wastes resources or interrupts running services during routine coding commits.
2. **How the Cloud Agent Triggers the Remote Server On-Demand**:
   - **ONLY** when the user explicitly commands inside the Cloud Remote conversation (e.g., *"把代码同步到测试环境"*, *"启动测试服务"*, *"重启测试服务"*, *"查看测试环境日志"*, *"停止测试服务"*):
   - **Step 1**: Ensure current changes are committed and pushed to `origin main`.
   - **Step 2**: Push the corresponding on-demand trigger tag (`pve-env-sync`, `pve-env-start`, `pve-env-restart`, `pve-env-stop`, or `pve-env-status`):
     ```bash
     ACTION="sync" # or: start | restart | stop | status
     git tag -f "pve-env-${ACTION}"
     git push -f origin "refs/tags/pve-env-${ACTION}"
     ```
   - **Step 3**: Wait ~15–20 seconds for the remote server to consume/delete the tag, execute the action, and post the status + 30-line server log to the current HEAD commit on GitHub. Then read it back directly in the Cloud sandbox:
     ```bash
     sleep 18
     gh api "repos/<owner>/<project_name>/commits/$(git rev-parse HEAD)/comments" \
       --jq '.[-1].body // "No status comment posted yet."'
     ```

---

## 4. Starting the Remote On-Demand Watcher (One-Time Setup on Server)

For any project where the user wants to control the remote test environment from inside a Cloud Remote Project conversation, launch the lightweight tag watcher in a dedicated Zellij session on the server:

```bash
ssh <REMOTE_HOST> "antiverse-run --name '[<project_name>] pve-sync-watch' --cwd <remote_dir>/<project_name> --force -- bash <scripts_dir>/pve_test_sync.sh -p <project_name> -a watch"
```

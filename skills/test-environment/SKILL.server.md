---
name: test-environment
description: SOP for managing and launching the project test environment across local and remote server environments.
---
# Test Environment Management Protocol (Server Mode)

This skill dictates the standard operating procedure for launching dev servers, test environments, or background services across local and remote server architectures.

## Environment-Specific Rules

### 1. On Local Machine
- **Manual Start Only**: Do NOT automatically start dev servers during normal development workflows unless explicitly asked.

### 2. On Remote Compute Server (PVE / Cloud VM)
- **Automatic Start via Multiplexer**: When handing off tasks to a remote server or operating autonomously, the test environment can be started inside a terminal multiplexer (e.g. `zellij` or `tmux`).
- **CRITICAL Network Binding**: When starting dev servers (Vite, Next.js, FastAPI, Django, etc.) on a remote server, pass flags to bind to `0.0.0.0` (e.g., `--host 0.0.0.0`, `--bind 0.0.0.0`) so the preview is accessible from the local client browser.
- **Execution Command (Example via SSH & Zellij)**:
  ```bash
  ssh <REMOTE_HOST> "zellij --session <SESSION_NAME> action new-tab -n '[<project_name>] env' && zellij --session <SESSION_NAME> action write-chars 'cd <remote_project_dir> && <start_command>' && zellij --session <SESSION_NAME> action send-keys 'Enter'"
  ```

## Coordination with Night Shift
When executing autonomous handoffs, verify that the remote test environment is running so that autonomous sub-agents can perform live integration tests if needed.

---

## Service Monitoring & Lifecycle Management
- **List Sessions**: Check running services via `ssh <REMOTE_HOST> "zellij list-sessions"` (or `tmux ls`).
- **Inspect Console / Logs**: Attach to the service session or inspect stdout/stderr logs.
- **Stop Service**: Terminate the dedicated multiplexer tab or session once verification or autonomous workflows finish.

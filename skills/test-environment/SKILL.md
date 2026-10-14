---
name: test-environment
description: SOP for managing and launching the project test environment in local development.
---
# Test Environment Management Protocol (Local-First Mode)

This skill dictates the standard operating procedure for launching dev servers, test environments, or background services in a local standalone workflow.

## Local Environment Rules

### 1. Manual Start by Default
- **Rule**: **Manual Start Only**. Do NOT automatically start long-running test environments or dev servers during normal code editing workflows unless explicitly requested.
- **Action**: Wait for the user to explicitly ask you to start it (e.g., "打开测试环境", "启动 dev server", "run tests"). Otherwise, assume the user prefers to run it in their own terminal or via IDE tasks.

### 2. When Explicitly Requested to Run Dev Servers
- Use `run_command` with appropriate background flags (`IsDaemon: true` or non-blocking).
- Clearly report the localhost URL (e.g., `http://localhost:3000` or `http://localhost:8000`) and how to terminate the process.
- Respect project virtual environments (e.g., `uv run`, `pnpm dev`, `bundle exec`).

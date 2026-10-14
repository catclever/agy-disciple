# Kanban Task Manager MCP Server

A lightweight, schema-enforcing Kanban task management MCP server for Antigravity.

## Features
- **Strict Status Validation**: `backlog` | `active` | `in_review` | `completed`
- **Session Tracking**: Supports linking task cards directly to Antigravity conversation sessions (`conversation://<uuid>`).
- **Flexible Storage Modes**:
  - **In-Repository (Default)**: Automatically manages task markdown files in `<workspace>/tasks/*.md`.
  - **Centralized Mode**: Set `PROJECTS_ROOT` environment variable (e.g. `~/.gemini/Projects`) to store tasks centralized across projects.

## Installation in Antigravity

### Option 1: Via Antigravity UI
1. In Antigravity, click **Additional Options (...)** -> **MCP Servers**.
2. Add a new Stdio server:
   - **Name**: `kanban-task-manager`
   - **Command**: `uv`
   - **Args**: `run`, `/path/to/agy-disciple/mcp/kanban-task-manager/server.py`

### Option 2: Via `~/.gemini/config/mcp_config.json`
Add the server definition:
```json
{
  "mcpServers": {
    "kanban-task-manager": {
      "command": "uv",
      "args": [
        "run",
        "/absolute/path/to/agy-disciple/mcp/kanban-task-manager/server.py"
      ]
    }
  }
}
```

## Tools Provided
- `create_task(project, task_id, title, status, priority, tags, session)`
- `list_tasks(project)`
- `update_task_status(project, task_id, status)`

# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "mcp",
#     "pyyaml"
# ]
# ///

import os
import sys
import glob
import re
from pathlib import Path
from typing import Literal
import yaml
from mcp.server.mcpserver import MCPServer

StatusEnum = Literal['backlog', 'active', 'in_review', 'completed']
PriorityEnum = Literal['low', 'medium', 'high']
VALID_STATUSES = {'backlog', 'active', 'in_review', 'completed'}

STATUS_MAPPING = {
    "todo": "backlog", "to-do": "backlog", "to_do": "backlog", "pending": "backlog",
    "open": "backlog", "planned": "backlog", "draft": "backlog", "queued": "backlog",
    "new": "backlog", "blocked": "backlog",
    "in_progress": "active", "in-progress": "active", "in progress": "active",
    "progress": "active", "doing": "active", "running": "active", "wip": "active",
    "started": "active", "ongoing": "active",
    "review": "in_review", "reviewing": "in_review", "in-review": "in_review",
    "in review": "in_review", "testing": "in_review", "qa": "in_review",
    "verify": "in_review", "verifying": "in_review",
    "done": "completed", "finished": "completed", "complete": "completed",
    "closed": "completed", "resolved": "completed", "merged": "completed",
    "success": "completed", "passed": "completed"
}

def normalize_status_value(raw: any) -> str:
    if raw is None:
        return "backlog"
    norm = str(raw).strip().lower().replace(" ", "_").replace("-", "_")
    if norm in VALID_STATUSES:
        return norm
    return STATUS_MAPPING.get(norm, "backlog")

mcp = MCPServer("KanbanTaskManager")

def resolve_project_tasks_dir(project: str) -> tuple[str, str]:
    """
    Resolves the tasks/ directory for a given project identifier or directory path.
    Supports both:
    1. Centralized mode (if PROJECTS_ROOT is set in environment, e.g. ~/.gemini/Projects)
    2. In-repository mode (defaults to <project_path>/tasks/)
    """
    if not project or not str(project).strip():
        raise ValueError("Project identifier or workspace path cannot be empty.")

    p_str = str(project).strip()
    projects_root = os.getenv("PROJECTS_ROOT")

    if projects_root and os.path.exists(os.path.expanduser(projects_root)):
        root_path = Path(os.path.expanduser(projects_root))
        canonical_name = Path(p_str).name
        tasks_dir = root_path / canonical_name / "tasks"
    else:
        # In-Repo mode
        target_path = Path(p_str).resolve()
        if not target_path.exists() and not target_path.is_absolute():
            # If relative name given, resolve relative to cwd
            target_path = Path.cwd() / p_str
        canonical_name = target_path.name
        tasks_dir = target_path / "tasks" if (target_path / "tasks").exists() or target_path.is_dir() else target_path

    tasks_dir.mkdir(parents=True, exist_ok=True)
    return canonical_name, str(tasks_dir)

def parse_frontmatter(content: str):
    match = re.match(r"^---\s*\n(.*?)\n---\s*\n(.*)", content, re.DOTALL)
    if match:
        try:
            return yaml.safe_load(match.group(1)) or {}, match.group(2)
        except Exception:
            return {}, content
    return {}, content

def format_frontmatter(metadata: dict, body: str) -> str:
    fm = yaml.dump(metadata, sort_keys=False, allow_unicode=True)
    return f"---\n{fm}---\n{body}"

@mcp.tool()
def list_tasks(project: str) -> str:
    """List all tasks and their exact statuses for a specific project or workspace path."""
    try:
        canonical_name, tasks_dir = resolve_project_tasks_dir(project)
    except ValueError as e:
        return f"Error: {e}"

    results = []
    for file_path in sorted(glob.glob(os.path.join(tasks_dir, "*.md"))):
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
            meta, _ = parse_frontmatter(content)
            task_id = meta.get("id", os.path.basename(file_path).replace(".md", ""))
            status = meta.get("status", "unknown")
            title = meta.get("title", "Untitled")
            results.append(f"[{task_id}] {title} (Status: {status})")
        except Exception:
            continue

    return "\n".join(results) if results else f"No tasks found for project '{canonical_name}'."

@mcp.tool()
def update_task_status(project: str, task_id: str, status: StatusEnum) -> str:
    """Update the status of a specific task with strict enumeration checking."""
    try:
        canonical_name, tasks_dir = resolve_project_tasks_dir(project)
    except ValueError as e:
        return f"Error: {e}"

    file_path = os.path.join(tasks_dir, f"{task_id}.md")
    if not os.path.exists(file_path):
        return f"Error: Task '{task_id}' not found in project '{canonical_name}' ({tasks_dir})."

    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    meta, body = parse_frontmatter(content)
    meta["status"] = status

    new_content = format_frontmatter(meta, body)
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(new_content)

    return f"Successfully updated [{canonical_name}] {task_id} status to '{status}'."

@mcp.tool()
def create_task(
    project: str,
    task_id: str,
    title: str,
    status: StatusEnum = 'backlog',
    priority: PriorityEnum = 'medium',
    tags: list[str] = None,
    session: str = None
) -> str:
    """Create a new task in the Kanban board with strictly enforced schema."""
    try:
        canonical_name, tasks_dir = resolve_project_tasks_dir(project)
    except ValueError as e:
        return f"Error: {e}"

    file_path = os.path.join(tasks_dir, f"{task_id}.md")
    if os.path.exists(file_path):
        return f"Error: Task '{task_id}' already exists in project '{canonical_name}'."

    meta = {
        "id": task_id,
        "title": title,
        "status": status,
        "priority": priority,
        "tags": tags or [],
        "session": session
    }

    new_content = format_frontmatter(meta, "")
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(new_content)

    return f"Successfully created task [{canonical_name}] {task_id}."

if __name__ == "__main__":
    mcp.run()

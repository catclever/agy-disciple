---
name: project-manager
description: >-
  Strict guidelines and workflows for in-repository project metadata, git status, and tasks.
  Use this skill whenever initializing a project, managing design brainstorms, or tracking tasks.
---

# Project Manager Skill (In-Repository Mode)

This skill enforces structured rules for managing project metadata, knowledge, and tasks directly within the project's repository.

## 1. In-Repository Structure
All project governance files are colocated inside the project repository root:

```text
<project_root>/
├── tasks/                # Data-driven Kanban (Task markdown files)
├── kb/                   # Single Source of Truth (Active schemas, architectures, gotchas)
│   ├── knowledge.md      # Active knowledge index
│   └── graveyard/        # Negative Knowledge (Anti-patterns, failed post-mortems)
│       └── grave.md      # Graveyard index
├── docs/                 # External specs, third-party references
├── design/               # Architecture brainstorms, tentative proposals
└── commands/             # Custom command shortcuts
```

---

## 2. Workflows & Lifecycles

### Knowledge Management (`kb/`)
- **Single Source of Truth**: Active schemas, gotchas, and architectural invariants belong in `kb/`.
- **The Graveyard (`kb/graveyard/`)**: Failed solutions, rejected designs, and bug post-mortems belong in `kb/graveyard/`.
- **MCP Enforcement**: Use the `knowledge-manager` MCP tools (`kb_search`, `kb_read`, `kb_record`, `kb_audit`) with `project: "$PWD"`.
- **Design Audit**: Before presenting architecture proposals, invoke `kb_audit(project="$PWD", proposal=...)` to detect conflicts.

### Task Management (`tasks/`)
- **MCP Enforcement**: Manage tasks exclusively via `kanban-task-manager` MCP tools (`list_tasks`, `create_task`, `update_task_status`, `update_task_content`).
- **Semantic Slug & Auto-Numbering**: Provide pure descriptive semantic slugs (e.g. `refactor_logger`); automatic sequential numbers (`_001`..`_NNN`) are assigned by the server.
- **Atomic Task Logging (Type 1 Tasks)**: Execute quick fixes and invoke `create_task` (`status: completed`) in the same turn.
- **Definition of Done (DoD Gatekeeper)**: Before outputting the final response, self-audit to verify Kanban board synchronization for any code or config change.

---
name: project-manager
description: >-
  Strict guidelines and workflows for centralized project metadata, git status, and tasks.
  Use this skill whenever initializing a project, managing design brainstorms, or tracking tasks.
---

# Project Manager Skill (Centralized Mode)

This skill enforces strict rules for managing project metadata, knowledge, and tasks in a centralized location outside the codebase repository to keep the working tree 100% clean.

## 1. Centralized Management Directory
All project metadata MUST be stored in `~/.gemini/Projects/<project_name>/`.
Do NOT store `.agent/`, `task.md`, or metadata inside the project's individual working directories.

### Directory Structure
```text
~/.gemini/Projects/<project_name>/
├── IRON_RULES.md         # Absolute project ironclad rules (injected into all Sub-Agents)
├── git_status.md         # Git status for all working directories
├── docs/                 # External information, reference documents, and third-party specs
├── kb/                   # Single Source of Truth (Active schemas, architectures, gotchas)
│   ├── knowledge.md      # Primary active knowledge index map
│   └── graveyard/        # Negative Knowledge (Anti-patterns, failed solutions, post-mortems)
│       └── grave.md      # Graveyard index map
├── tasks/                # Data-driven Kanban (All tasks in one flat folder)
├── design/               # Brainstorms, tentative conclusions, deprecated ideas (Date-stamped)
└── commands/             # Manually injected prompts and quick-actions (User-managed)
```

## 2. Workflows & Lifecycles

### Dynamic Path Resolution (`meta_resolver.py`)
To locate the centralized metadata directory for the current working directory, run the bundled resolver:
```bash
META_DIR=$(python3 scripts/meta_resolver.py "$PWD")
```
Always use this `$META_DIR` path for all task, knowledge, and config file operations.

### Git Status Management (`git_status.md`)
- Whenever a new working directory is introduced, check for a `.git` repository (or parent).
- Record the status and decisions for each working directory in `git_status.md`.

### Ironclad Rules (`IRON_RULES.md`)
- Divided into specific headings:
  - `## [Global]`: Project-wide context.
  - `## [Main Agent]`: Orchestration rules.
  - `## [Dev Agent]`: Strict coding and directory constraints.
  - `## [Ops Agent]`: Execution commands.
- **Injection Mandate**: NEVER inject the entire file into a sub-agent. Slice the document and inject ONLY the `[Global]` section plus the specific section that matches the target agent.

### Knowledge Base (`kb/`) & The Graveyard (`kb/graveyard/`)
- Store active schemas, architectures, and gotchas in `kb/`.
- Store post-mortems, failed approaches, and anti-patterns in `kb/graveyard/`.
- Perform pre-presentation double audit against `kb/knowledge.md` and `kb/graveyard/grave.md`.

### Task Management (`tasks/`)
- **Adaptive Task Engine**:
  1. **MCP Preferred**: If `kanban-task-manager` MCP tools (`list_tasks`, `create_task`, `update_task_status`) are available, use them with `project: "$PWD"` or canonical project name.
  2. **Native Markdown Fallback**: If the MCP server is not active, manage task files directly in `$META_DIR/tasks/<task_id>.md`.
- **Atomic Task Logging (Quick Fixes - Type 1)**:
  - Small fixes and minor optimizations MUST generate a task record (`status: completed`).
  - Perform atomic batching: execute the code change and register the task card within the same turn.
- **Definition of Done (DoD Gatekeeper)**: Before outputting the final response, verify: *Did any tool modify project code or config? If yes, is the task card registered?*

---
name: project-manager
description: >-
  Strict guidelines and workflows for managing project directories, git status, and tasks.
  Use this skill whenever initializing a project, managing design brainstorms, or moving tasks.
---

# Project Manager Skill (Centralized Mode)

This skill enforces strict rules for managing project metadata, knowledge, and tasks in a centralized location outside the codebase repository to keep the working tree 100% clean.

## 1. Centralized Management Directory
All project metadata MUST be stored in `~/.gemini/Projects/<project_name>/` (or `/workspace/gemini-hub/Projects/<project_name>/` inside a Cloud Remote Agent sandbox).
Do NOT store `.agent/`, `task.md`, or metadata inside the project's individual working directories.

### Directory Structure
```text
~/.gemini/Projects/<project_name>/
├── IRON_RULES.md         # Absolute project ironclad rules (injected into all Sub-Agents)
├── git_status.md         # Git status for all working directories
├── docs/                 # External information, reference documents, and third-party specs
├── kb/                   # Single Source of Truth (Active schemas, architectures, gotchas)
│   └── graveyard/        # Negative Knowledge (Anti-patterns, failed solutions, and post-mortems)
├── tasks/                # Data-driven Kanban (All tasks in one flat folder)
├── design/               # Brainstorms, tentative conclusions, deprecated ideas (Date-stamped)
└── commands/             # Manually injected prompts and quick-actions (User-managed)
```

### Project Environment Topologies
Every registered project operates under one of three explicit environment topologies declared in `IRON_RULES.md` (`Project-Environment`):

| Topology | Source Code Location | Execution & Dispatch Skills | Metadata Location |
| :--- | :--- | :--- | :--- |
| **`Local`** | Local directory (optional remote test clone at `<remote_dir>/<project_name>`) | `dev-manager`, `ops-manager`, or `remote_watchdog.sh` (Direct Mac-to-Cloud Option B1 / Remote Option B2); test sync via `dev-server` (`pve_test_sync.sh`) | `~/.gemini/Projects/<project_name>/` |
| **`PVE-Native`** | `<remote_dir>/<project_name>` on remote server (mirrored via Mutagen) | `pve-dispatch` (Mode A `descartes_watchdog.sh`, Mode B `remote_watchdog.sh`, Mode C `pve_watchdog.sh`) | `~/.gemini/Projects/<project_name>/` |
| **`Pure-Remote`** | GitHub-authoritative (`<owner>/<project_name>`), mounted at `/workspace/<project_name>` in Cloud Sandbox (zero local clones; optional test clone at `<remote_dir>/<project_name>`) | Cloud Remote Project UI or `remote_watchdog.sh`; on-demand test env via `dev-server` (`pve_test_sync.sh` / `pve-env-*` tags); initialize via **`pure-remote-init`**, migrate via **`local-to-remote-migration`** | `/workspace/gemini-hub/Projects/<project_name>/` |

- **Initializing a New Pure-Remote Project**: Follow `skills/pure-remote-init/SKILL.md`.
- **Migrating an Existing Local Repo to Pure-Remote**: Follow `skills/local-to-remote-migration/SKILL.md`.

---

## 2. Workflows & Lifecycles

### Dynamic Path Resolution (`meta_resolver.py`)
To locate the centralized metadata directory for the current working directory, run the bundled resolver:
```bash
META_DIR=$(python3 scripts/meta_resolver.py "$PWD" --mode centralized)
```
Always use this `$META_DIR` path for all task, knowledge, and config file operations.

### Git Status Management (`git_status.md`)
- Whenever a new working directory is introduced, check for a `.git` repository (or parent).
- Record the final decision and topology for each working directory in `git_status.md`.

### Ironclad Rules (`IRON_RULES.md`)
- Divided into specific headings:
  - `## [Global]`: Project-wide context (topology, repo, environment, test commands).
  - `## [Main Agent]`: Orchestration rules.
  - `## [Dev Agent]`: Strict coding and directory constraints.
  - `## [Ops Agent]`: Execution commands.
- **Injection Mandate**: You must NEVER inject the entire file into a sub-agent. Slice the document and inject ONLY the `[Global]` section plus the specific section that matches the target agent.

### Knowledge Base (`kb/`) & FastMCP Integration
- Store active schemas, architectures, and gotchas in `kb/`.
- Store post-mortems, failed approaches, and anti-patterns in `kb/graveyard/`.
- **MCP Enforcement**: Use the `knowledge-manager` MCP tools (`kb_search`, `kb_read`, `kb_record`, `kb_audit`), passing `project` as canonical project name, `<owner>/<project>`, or `$PWD`.
- **Pre-Presentation Design Audit**: Before presenting ANY technical proposal to the user, call `kb_audit(project=..., proposal=...)` to prevent repeating recorded failures.

### Task Management (`tasks/`) & FastMCP Integration
- **MCP Enforcement**: Use the `kanban-task-manager` MCP tools (`list_tasks`, `create_task`, `update_task_status`, `update_task_content`).
- **Semantic Slug Only**: Provide descriptive snake_case slugs (e.g., `user_auth_flow`) without manual sequence numbers; numbering (`_001`..`_NNN`) is handled automatically by the server.
- **Rich Task Body**: Provide a meaningful `description` when creating tasks.
- **Atomic Task Logging (Type 1 Tasks)**: For quick fixes and optimizations, execute the change and create the task (`status: completed`) in the same turn.
- **Definition of Done (DoD Gatekeeper)**: Verify Kanban task synchronization before outputting the final response.

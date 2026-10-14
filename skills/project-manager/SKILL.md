---
name: project-manager
description: >-
  Strict guidelines and workflows for managing in-repository metadata, git status, and tasks.
  Use this skill whenever initializing a project, managing design brainstorms, or tracking tasks.
---

# Project Manager Skill (In-Repository Mode)

This skill enforces strict rules for managing project metadata, knowledge, and tasks directly within the project's repository.

## 1. Project Directory Structure
All project metadata is stored directly in the repository root for seamless version control and team collaboration:

```text
<project_root>/
├── IRON_RULES.md         # Absolute project ironclad rules (injected into all Sub-Agents)
├── docs/                 # External documentation, reference specs, API guides
├── kb/                   # Single Source of Truth (Active schemas, architectures, gotchas)
│   ├── knowledge.md      # Primary knowledge index map
│   └── graveyard/        # Negative Knowledge (Anti-patterns, failed solutions, post-mortems)
│       └── grave.md      # Graveyard index map
├── tasks/                # Data-driven Kanban task cards (Flat markdown files)
├── design/               # Brainstorms and tentative conclusions (Date-stamped)
└── commands/             # User quick actions and manual execution prompts
```

## 2. Workflows & Lifecycles

### Git Status Management
- Whenever a working directory is introduced, verify `.git` repository status.
- If no Git repository is found, confirm with the user before initializing.

### Ironclad Rules (`IRON_RULES.md`)
- Contains non-negotiable architectural rules for the project.
- Divide into clear sections to prevent context pollution:
  - `## [Global]`: Project-wide context (e.g., dual-repo setup, language versions).
  - `## [Main Agent]`: Orchestration guidelines.
  - `## [Dev Agent]`: Strict coding and directory constraints.
  - `## [Ops Agent]`: Execution commands and permissions.
- **Injection Mandate**: NEVER inject the entire file into a sub-agent. Slice the document and inject ONLY `## [Global]` plus the specific section for the target sub-agent.

### Knowledge Base (`kb/`)
- Store ONLY **finalized, active** technical details here (active DB schemas, API specs, environment setup).
- Use `kb/knowledge.md` as the primary index.
- **The Graveyard (`kb/graveyard/`)**:
  - Store post-mortems, failed approaches, and anti-patterns here.
  - Maintain `kb/graveyard/grave.md` containing a one-sentence summary of each anti-pattern.
- **Consumption & Verification Workflow**:
  - **Pre-Presentation Audit**: Verify proposals against `kb/knowledge.md` and `kb/graveyard/grave.md`. Redesign internally if any conflict is detected.
  - **Sub-Agent Task Synthesis**: Digest knowledge into customized requirements; provide explicit file paths for sub-agent reading.

### Task Management (`tasks/`)
- **Adaptive Task Engine**:
  1. **MCP Preferred**: If `kanban-task-manager` MCP tools (`list_tasks`, `create_task`, `update_task_status`) are available, use them.
  2. **Native Markdown Fallback**: If the MCP server is not active, manage task markdown files directly in `tasks/<task_id>.md`.
- **Task Schema**:
  ```yaml
  ---
  id: auth_001
  title: Implement JWT authentication middleware
  status: backlog   # backlog | active | in_review | completed
  priority: medium  # low | medium | high
  tags: [auth, backend]
  session: conversation://<conversation-id>
  ---
  ```
- **Task ID**: Snake_case identifier (e.g., `auth_001`).
- **Atomic Task Logging (Quick Fixes - Type 1)**:
  - Small fixes and minor optimizations MUST generate a task record (`status: completed`).
  - Perform atomic batching: execute the code change and register the task card within the same turn.
- **Definition of Done (DoD Gatekeeper)**: Before final user response, verify: *Did any tool modify project code or config? If yes, is the task card updated/created?*

### External Documentation (`docs/`) & Design (`design/`)
- `docs/`: Reference specs, third-party manuals.
- `design/`: Date-stamped brainstorms (`YYYY-MM-DD_idea.md`) and tentative conclusions.

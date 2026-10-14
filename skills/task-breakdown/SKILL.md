---
name: task-breakdown
description: Standard Operating Procedures for decomposing user requests, performing double knowledge audits, and confirming logic before coding.
---
# Task Breakdown SOP

Before invoking any development sub-agents, the Lead Architect (Main Agent) MUST follow these rules to ensure the development process is consistent with existing project designs, knowledge base, and user intent.

### 1. Plan Formulation & Two-Track Confirmation
Upon receiving a user request, your primary responsibility is to investigate the codebase and formulate a concrete execution plan.

**Pre-Presentation Double Knowledge Audit (方案呈现前的双重知识审查)**:
Before presenting ANY design, architectural proposal, or plan to the user, you MUST perform a thorough cross-verification against project knowledge:
1. **Active Knowledge Audit**: Search and read `kb/knowledge.md` and relevant technical specs in `kb/`. Verify that your plan strictly conforms to existing architecture, database schemas, and conventions. **If any contradiction, violation, or flaw is found, you MUST redesign and fix the proposal internally before presenting it to the user.**
2. **Graveyard Radar Scan (Anti-Patterns)**: Read `kb/graveyard/grave.md` (or grep `kb/graveyard/`) to verify that your approach does not match a historically failed solution. If it does, you must pivot your plan and explicitly state to the user: "I checked the graveyard and avoided approach X."

Once the plan is verified and formulated, follow the two-track delegation rule:
- **Major Features & Architecture Changes**: You MUST present the plan to the user and WAIT for their explicit confirmation before proceeding to execution.
- **Bug Fixes & Minor Tweaks**: You should present the plan to the user to keep them informed, but you may IMMEDIATELY invoke the `dev` agent to begin fixing it concurrently without waiting for their approval.

### 2. Task Decomposition & Parallel Orchestration
A high-level user request is often too large for a single sub-agent to handle effectively. You MUST decompose the request into **Granular Requirements**.

**What constitutes a Granular Requirement?**
- **Scope**: It must be a single, isolated component, a specific feature, or an independent bug fix (e.g., "Implement JWT validation middleware", NOT "Build the entire Auth system").
- **Independence**: It should touch a specific set of files without causing massive merge conflicts with other requirements.

**Knowledge Synthesis for Sub-Agents (任务知识定制与指路)**:
Before creating tickets and dispatching to sub-agents:
- **Synthesize, Do NOT Dump**: Search `kb/knowledge.md` for relevant conventions, schemas, and gotchas. Digest and synthesize these technical points into concrete, actionable requirements and acceptance criteria for the sub-agent. NEVER blindly paste raw documents into the prompt.
- **Explicit Reading Guidance**: Explicitly inform the sub-agent of the specific `kb/` document paths (e.g., `kb/auth_schema.md`) so it can consult the original source if deeper context is needed.

**Task Engine & Delegation (1 Requirement = 1 Sub-Agent)**:
- **Task Logging (Adaptive Engine)**:
  - **MCP Available**: If the `kanban-task-manager` MCP server is active, invoke `create_task` with `project`, `task_id`, `title`, and `status: backlog`.
  - **Fallback (No MCP)**: If the MCP tool is not available, create `<tasks_dir>/<task_id>.md` with frontmatter:
    ```yaml
    ---
    id: <task_id>
    title: <title>
    status: backlog
    priority: medium
    tags: []
    ---
    ```
- **Parallel Execution**: If you decompose a request into multiple *independent* granular requirements (e.g., "Build the UI button" and "Create the Database Table"), you can and should dispatch them to **multiple Dev Sub-Agents concurrently**, assigning each its specific Task ID.
- **Sequential Execution (Dependencies)**: If Requirement B depends on Requirement A, you MUST NOT spawn them in parallel. You must spawn a Dev Agent for Task A, wait for it to finish and be merged, and only then spawn a Dev Agent for Task B.

### 3. Validation Planning
- For every decomposed granular requirement, you must define a clear, explicit verification plan.
- When analyzing possible causes of a problem, ONLY provide a description of the current status and root cause. DO NOT offer unsolicited advice or suggestions for fixes or changes. Wait for the user's explicit confirmation before proposing any actions.

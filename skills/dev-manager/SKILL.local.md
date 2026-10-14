---
name: dev-manager
description: "SOP for delegating tasks to LOCAL sub-agents. Use this for standard standalone local development."
---
# Dev Manager SOP (Local-First Mode)

This skill defines how the Lead Architect (Main Agent) should orchestrate local sub-agents (`dev` and `merger`) for coding tasks. 

## Host Boundary & Invocation Standard
> [!CRITICAL]
> **Native Subagent Only**: When delegating tasks on the local machine (inside the Antigravity client), you MUST exclusively use the native `invoke_subagent` tool to spawn subagents directly in the IDE conversation tree.

## Available Sub-Agents (Located in `agents/`)

### 1. The `dev` Agent
- **Role**: Writes code, fixes bugs, and performs sandboxed verification.
- **Completion Condition**: The `dev` agent is ONLY considered completed AFTER the user has manually tested and explicitly accepted the code changes. Until then, it stays suspended (idle), waiting for you to relay user feedback for further fixes.
- **Invocation Rules**:
  - Pass the `Task ID` in the invocation prompt.
  - Read `IRON_RULES.md`. Extract ONLY the `[Global]` and `[Dev Agent]` sections and append them to the `dev` agent's prompt to prevent context pollution.
  - **Knowledge Synthesis & Reading Guidance**: Search `kb/knowledge.md` for relevant conventions, schemas, or gotchas. Synthesize them into customized, concrete task requirements (NEVER blindly paste raw markdown documents into the prompt). Explicitly provide the specific paths to the relevant `kb/` documents that the `dev` agent can read for deep context.
  - Inform the `dev` agent of the files it needs to read. Remind it of the suffix rule (`_task_name`) for draft files.
  - **Boundary Restriction**: Explicitly instruct the `dev` agent that it is STRICTLY FORBIDDEN from modifying any task cards or project metadata in `tasks/`. All task state updates must be handled by you (the Main Agent).

### 2. The `merger` Agent
- **Role**: Replaces original source files with the development drafts.
- **Completion Condition**: The `merger` agent is considered completed the moment it successfully finishes backing up and renaming the files. It requires no user verification.
- **Invocation Rules**:
  - Invoke ONLY after the `dev` agent has successfully reported its draft files.
  - Pass the exact mapping of draft files to original files (e.g., "Replace `api.py` with `api_task_001.py`").
  - Instruct the `merger` agent to backup the original files (e.g., `api.bak.py`) before overwriting.

## Delegation Lifecycle

0. **Prerequisite**: You MUST NOT invoke a `dev` agent unless you have already registered the `Task ID` in `tasks/` (via `kanban-task-manager` MCP or local task card).
1. **Assign**: Main Agent reads the task and invokes the `dev` agent, passing the `Task ID`.
2. **Suspend & Review**: The `dev` agent finishes drafting, runs sandboxed verification, and suspends itself (goes idle). The Main Agent reviews the results.
3. **Merge (Draft)**: The Main Agent invokes the `merger` agent to apply the drafts. Once merged, the `merger` agent is immediately killed.
4. **User Verification**: The Main Agent asks the user to manually verify the changes. 
   - *If rework is needed*: Wake up the suspended `dev` agent by sending it a message with the feedback. Repeat from step 2.
   - *If verified*: The task is complete. Kill the `dev` agent.

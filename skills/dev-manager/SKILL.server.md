---
name: dev-manager
description: "SOP for delegating tasks to sub-agents across local and remote server environments."
---
# Dev Manager SOP (Dual-Topology / Server Mode)

This skill defines how the Lead Architect (Main Agent) orchestrates development tasks, routing between local sub-agents and remote server execution depending on the project's target environment.

## Topology Routing
Before delegating any development task:
1. **Check Project Environment**:
   - Inspect `IRON_RULES.md` for `Environment: PVE-Native` or remote compute tags.
2. **Execution Routing**:
   - **Local Tasks**: Use native `invoke_subagent` directly within the IDE tree (see Local Delegation below).
   - **Remote Server Tasks**: Delegate to the remote compute environment using the `pve-dispatch` skill.

---

## Local Delegation (Available Sub-Agents in `agents/`)

### 1. The `dev` Agent
- **Role**: Writes code, fixes bugs, and performs sandboxed verification.
- **Completion Condition**: Completed ONLY after user manual testing and explicit acceptance.
- **Invocation Rules**:
  - Pass the `Task ID` in the invocation prompt.
  - Read `IRON_RULES.md` (`## [Global]` and `## [Dev Agent]`).
  - Synthesize relevant items from `kb/knowledge.md` into concrete requirements.
  - Remind the agent of the suffix rule (`_task_name`) for draft files.
  - Restrict the agent from touching task cards in `tasks/`.

### 2. The `merger` Agent
- **Role**: Replaces original source files with development drafts after backing them up (`.bak`).
- **Completion Condition**: Completed as soon as backup and rename operations finish.

## Delegation Lifecycle
0. **Prerequisite**: Task card registered in `tasks/`.
1. **Assign**: Invoke `dev` subagent with `Task ID`.
2. **Review Drafts**: Once `dev` finishes drafting, Main Agent reviews changes.
3. **Merge**: Invoke `merger` subagent to apply drafts. Kill `merger` once verified.
4. **User Verification**: Ask user to verify. If fixes needed, message the idle `dev` agent. If approved, kill `dev` agent.

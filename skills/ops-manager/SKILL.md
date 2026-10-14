---
name: ops-manager
description: SOP for delegating high-cost, real-world, or non-idempotent script executions to the ops sub-agent.
---
# Ops Manager SOP

This skill defines how the Lead Architect (Main Agent) should orchestrate the `ops` sub-agent for executing operational scripts.

## The `ops` Agent (Located in `agents/`)

**When to Invoke**: 
Invoke the `ops` agent ONLY when you need to execute high-cost, non-idempotent, or real-world operational scripts. This explicitly includes:
- AI data generation and heavy batch processing.
- Cross-workspace file syncing and code migrations (e.g., `cp` files between repositories).
- Git deployment operations (e.g., `git add`, `git commit`, `git push`).
- Native project packaging and builds (e.g., Swift `xcodebuild`, iOS deployments, Docker builds).
Do NOT invoke `ops` for local unit tests (that is the `dev` agent's job).

**Invocation Rules**:
1. Inform the `ops` agent of the exact path to the project's `command_log.md` (e.g., `<kb_dir>/command_log.md`).
2. Read `IRON_RULES.md`. Extract ONLY the `[Global]` and `[Ops Agent]` sections and append them to the `ops` agent's prompt to ensure it has the correct sync and deployment ironclad rules.
3. Clearly state the semantic goal of the script execution (e.g., "Sync files from A to B and push to remote").
4. Warn the `ops` agent that if it cannot find the exact parameters in the log, it must suspend and report back to you rather than guessing.
5. **Boundary Restriction**: Explicitly instruct the `ops` agent that it is STRICTLY FORBIDDEN from modifying any task metadata in `tasks/`. All task state updates must be handled by you (the Main Agent).

**Delegation Lifecycle**:
1. **Assign**: Main Agent delegates the execution task to the `ops` agent.
2. **Suspend for Parameter Check**: If `ops` cannot find historical parameters, it will suspend and ask you. You MUST then ask the user for confirmation. Once the user replies, send the parameters back to the `ops` agent to wake it up.
3. **Execute & Log**: The `ops` agent runs the script and writes the successful command to `command_log.md`.
4. **Kill**: Once `ops` reports successful execution and logging, the Main Agent uses `manage_subagents` to `kill` it.

---
name: descartes-dispatch
description: "SOP for handing heavy, well-scoped coding tasks on remote server projects to the Descartes + EnginEdge watchdog (descartes_watchdog.sh), async/unattended. Do NOT use for vague/exploratory work, cross-repo or large refactors, tasks needing human plan approval, or local-only projects."
---
# Descartes Dispatch SOP

How the Lead Architect (Main Agent) delegates a task to `descartes_watchdog.sh` on a remote server. The watchdog creates an isolated git worktree, runs the EnginEdge agent (`enginedge run`), optionally verifies, commits to branch `descartes/<Task_ID>`, and signals the result. **No GitHub needed** (no push/pull).

## Engine Selection

| Engine | Where / Model | Best for | Limits |
| :--- | :--- | :--- | :--- |
| **Descartes** (this skill / `pve-dispatch` Mode A) | Remote server only; cloud ReAct agent, ≤50 turns | Small/medium single-module tasks, async or night queue, non-GitHub projects | Lighter model, no plan approval, whitelisted tools, shared Hub |
| **Remote Agent** (`pve-dispatch` Mode B / `remote_watchdog.sh`) | Mac or Remote server launcher $\rightarrow$ Cloud Sandbox (`agy --remote-agent`, `gemini-3.8-flash` / `3.1-pro`) | Heavy/multi-file tasks on GitHub-backed projects, multi-account rotation, PR auto-merge | Requires GitHub repo & Remote Project resource mounting |
| **Server agy** (`pve-dispatch` Mode C / `pve_watchdog.sh`) | Server Zellij, Antigravity TUI | Interactive/large/exploratory work needing server-local services or hardware | Heavier, needs Mutagen |
| **Local dev subagent** (`dev-manager`) | Local machine, full toolset | Exploration, multi-file refactors, anything needing a local shell | Occupies local session |

**Rule of thumb**: well-scoped + unattended (no GitHub required) $\rightarrow$ Descartes; heavy multi-file unattended on GitHub-backed repo $\rightarrow$ Remote Agent (`remote_watchdog.sh`); interactive server-local service work $\rightarrow$ Server agy (`pve_watchdog.sh`); local-first work $\rightarrow$ `dev-manager`.

> [!NOTE]
> Descartes currently runs on a remote Linux/Server environment with `enginedge` installed.

## Prerequisites Checklist (Remote Server)
- [ ] **`enginedge` installed** at `~/.cargo/bin/enginedge` (or on PATH, override: `ENGINEDGE_BIN`). **MUST be verified before first use**: `ssh <REMOTE_HOST> 'command -v enginedge'` (empty output $\rightarrow$ STOP and ask user to install; do not dispatch).
- [ ] `~/.config/descartes/env` exists with `HUB_AUTH_TOKEN` and `DESCARTES_WS_URL` (sourced automatically). Never print its contents.
- [ ] Project at `<remote_dir>/<project>` and is a git repo with the base branch committed.
- [ ] Mutagen sync active (`mutagen sync list`) so local edits reach remote server.
- [ ] **Fresh-checkout caveat**: the worktree has no untracked/ignored artifacts (`node_modules`, `target/`, `.venv`, bundler cache). Make `--verify` self-contained (e.g. `uv run pytest`, `cargo test`, `bundle exec rspec`), expect the first run to rebuild dependencies, and raise `--timeout` for heavy builds.
- [ ] **Commit first**: the worktree contains committed content only; uncommitted changes are invisible to the agent (watchdog only logs a warning). Commit on the server side or let Mutagen sync, then confirm with `ssh <REMOTE_HOST> 'cd <project_dir> && git status --short'`.

## Dispatch
Tasks must first be logged in Kanban via MCP (Task_ID = Kanban task slug). Run in the background over SSH stdin (`bash -s` heredoc avoids nested quoting):
```bash
ssh <REMOTE_HOST> 'bash -s' << 'EOF'
nohup bash scripts/watchdogs/descartes_watchdog.sh \
  -t "<Task_ID>" \
  -d "<remote_dir>/<project>" \
  -p "<Prompt>" \
  --verify "<test cmd>" \
  > /dev/null 2>&1 &
EOF
```
| Flag | Meaning |
| :--- | :--- |
| `-t` / `-d` / `-p` | Required: Task_ID, project dir, prompt |
| `-b <branch>` | Base branch (default: project dir's current branch) |
| `--verify "<cmd>"` | Independent check run in the worktree; **always pass it** (don't trust the agent's "done") |
| `--auto-merge` | Squash-merge into base automatically (night mode only; default stops at the branch) |
| `--profile <p>` / `--hub-url <u>` | LLM profile / Hub URL override |
| `--max-turns <N>` | Maximum reasoning turns on Hub (default 50 in EnginEdge; can raise to 60-100 for heavy tasks) |
| `--timeout <s>` | Default 3600 |
| `--keep-worktree` | Keep worktree directory for debugging |

Then **wait for `/tmp/<Task_ID>.signal`** (poll: `ssh <REMOTE_HOST> 'cat /tmp/<Task_ID>.signal'`).

## Signal Contract & Logs
- Signal file `/tmp/<Task_ID>.signal` starts with `IN_PROGRESS` / `DONE` / `FAILED` (loops use `grep -c DONE`).
- `DONE: BRANCH_READY descartes/<Task_ID> (<commits>, <diffstat>)` — default; also `(auto-merge skipped: <reason>)`.
- `DONE: MERGED <task> <sha>` — `--auto-merge` succeeded. `DONE: NO_CHANGES` — agent changed nothing (branch/worktree cleaned).
- Log: `ssh <REMOTE_HOST> 'tail -n 80 /tmp/descartes_<Task_ID>.log'` (live: `tail -f`).

## Failure Codes
| Code | Meaning $\rightarrow$ Action |
| :--- | :--- |
| `BAD_ARGS` | Missing/invalid flags $\rightarrow$ fix the command, re-dispatch |
| `ENGINEDGE_NOT_FOUND` | Binary missing $\rightarrow$ verify prerequisites, ask user to install; do not retry |
| `NOT_A_GIT_REPO` | `-d` is not a git repo $\rightarrow$ check path / `git init` + commit with user's confirmation |
| `BRANCH_EXISTS` | `descartes/<Task_ID>` already there $\rightarrow$ review it, or delete it (`git branch -D`) / use a new Task_ID |
| `WORKTREE_FAILED` | `git worktree add` failed $\rightarrow$ check base branch, `git worktree prune`, disk space |
| `ENGINEDGE_EXIT_<n>` | Agent/Hub error (worktree kept) $\rightarrow$ read log; fix prompt or Hub/token; retry max 2 |
| `TIMEOUT` | Exceeded `--timeout` $\rightarrow$ task too big: split it, then retry |
| `VERIFY_FAILED` | Tests failed (worktree + branch kept) $\rightarrow$ inspect diff/log, re-prompt narrower or take over via dev subagent |
| `COMMIT_FAILED` | Commit in worktree failed $\rightarrow$ inspect worktree (git identity, hooks) |
| `MERGE_CONFLICT` | `--auto-merge` rolled back, branch kept $\rightarrow$ resolve manually during acceptance |
| `UNEXPECTED_EXIT` | Trap fired $\rightarrow$ read log tail; check server disk/process state; then retry |

Same task failing 3 times $\rightarrow$ stop retrying, mark `failed_needs_human` and escalate (reroute to Remote Agent / Server agy via `pve-dispatch` or local dev via `dev-manager`).

## Acceptance Flow (Main Agent; run git on server inside `<project_dir>`)
1. Read the log: `ssh <REMOTE_HOST> 'tail -n 100 /tmp/descartes_<Task_ID>.log'`.
2. Review: `ssh <REMOTE_HOST> 'cd <project_dir> && git diff <base>...descartes/<Task_ID>'` (check scope creep and absence of secrets).
3. Run project tests (on server or after sync locally).
4. Merge: `git merge --squash descartes/<Task_ID> && git commit -m "feat: <Task_ID>"` (or note the `--auto-merge` outcome `DONE: MERGED`).
5. Cleanup: `git worktree prune && git branch -D descartes/<Task_ID>` (skip branch deletion if rejected but needed for reference).
6. **Update Kanban via MCP** (`update_task_status`). Only the Main Agent does this; the executing agent never touches task files.

## Night Shift Example (serial, stop on first non-DONE)
Mirrors `night-shift` Path A using Descartes with `--auto-merge`. The Hub is shared, so **never run in parallel at night**.
```bash
ssh <REMOTE_HOST> 'bash -s' << 'EOF'
cat > /tmp/descartes_night_runner.sh << 'RUNNER'
declare -A PROMPTS=( ["<task_a>"]="<Prompt A>" ["<task_b>"]="<Prompt B>" )
for task in <task_a> <task_b>; do
  bash scripts/watchdogs/descartes_watchdog.sh \
    -t "$task" -d "<remote_dir>/<project>" -p "${PROMPTS[$task]}" \
    --verify "<test cmd>" --auto-merge
  if [ "$(grep -c DONE /tmp/${task}.signal)" -eq 0 ]; then
    echo "Task $task failed, stopping pipeline."
    break
  fi
done
RUNNER
nohup bash /tmp/descartes_night_runner.sh > /tmp/descartes_night_shift.log 2>&1 &
EOF
```
Morning: User syncs and reviews `git log`; each task is one squash commit, revertable with `git revert <sha>`. Failed/skipped tasks leave a `descartes/<Task_ID>` branch for review.

## Capability Limits
- Agent tools: `list_files`, `read_file`, `grep_search`, `write_file`, `append_file`, `get_outline`, `read_symbol`, `replace_symbol`, `run_verification`. Cloud intelligence: `github_repo_survey`, `github_code_search`, `doc_fetcher`, `spec_inspector`, `knowledge_store`. No arbitrary shell.
- Large files / test suites: for files >3KB, avoid single massive `write_file` calls (which risk token output truncation). Write initial skeleton then chunk with `append_file` or `replace_symbol`.
- `run_verification` whitelist: `cargo`, `npm|pnpm|yarn|bun`, `pytest`, `python -m`, `bundle exec`, `go test|vet`, `make test|check`; forbids `& | ; > < \ ` $` and newlines.
- Blocked files (unreadable/unwritable): `.env*`, `*.pem`, `*.key`, `id_rsa*`, `.ssh`, `.aws`.
- Shared Hub instance: throttle parallel dispatches; serialize at night.

## Task Sizing Checklist
- [ ] One module / one concern; completable in $\lesssim$30 tool turns.
- [ ] Relevant files listed explicitly (paths, key symbols).
- [ ] Acceptance command given (also passed as `--verify`) and is on the whitelist.
- [ ] Out-of-scope stated ("do not touch X").
- [ ] Single repo; no big-bang refactor; no secrets/config files needed.
- [ ] Anything failing the above $\rightarrow$ split it, or use Remote Agent (`pve-dispatch`) or local dev (`dev-manager`).

---
name: local-to-remote-migration
description: "5-stage SOP for migrating an existing local repository on Mac into a Pure-Remote Project (Mode B), preserving metadata/theme colors, terminating Mutagen sync, optionally retaining an on-demand test environment, and safely deleting the local source directory."
---
# Local-to-Remote Project Migration SOP (`Local` $\rightarrow$ `Pure-Remote`)

This skill defines the strict, zero-data-loss 5-stage procedure for converting an existing local repository into a **Pure-Remote Project (Mode B)** and safely reclaiming local disk space (while optionally retaining `<remote_dir>/<project_name>` on a remote server as a strictly on-demand test environment).

> [!CAUTION]
> **Zero Data Loss Gate**: Never execute Stage 5 (`rm -rf <local_project_dir>`) unless Stage 1 (Git Cleanliness & Remote Push Audit) and Stage 3 (Metadata Sync to centralized repo) have both succeeded with zero errors.

---

## Stage 1: Git Cleanliness & Remote Push Audit (Blocking Gate)

Before touching any metadata or deleting files, verify that 100% of the local source repository is pushed to GitHub (`<owner>/<project_name>`):

1. **Verify Git Remote `origin`**:
   ```bash
   cd "<local_project_dir>"
   git remote -v
   ```
   - If no GitHub remote exists, STOP and ask the user whether to create `<owner>/<project_name>` via `gh repo create "<owner>/<project_name>" --private --source=. --push`.
2. **Verify Working Tree Cleanliness**:
   ```bash
   git status --porcelain
   ```
   - Must be completely empty. If untracked or modified files exist, inspect them with the user, commit them, or explicitly confirm they are disposable build artifacts.
3. **Verify Zero Stashes & Zero Unpushed Commits**:
   ```bash
   git stash list
   git fetch origin
   git status -sb
   git log --branches --not --remotes --oneline
   ```
   - Both `git stash list` and `git log --branches --not --remotes --oneline` MUST produce empty output. If any local branch has unpushed commits, push them (`git push origin --all && git push origin --tags`) before proceeding.

---

## Stage 2: Centralize Metadata & Harvest Theme Color

Ensure all project knowledge, tasks, and IDE identity settings are preserved in `~/.gemini/Projects/<project_name>/`:

1. **Resolve Centralized Metadata Directory**:
   ```bash
   META_DIR=$(python3 scripts/meta_resolver.py "<local_project_dir>" --mode centralized)
   echo "Resolved META_DIR: $META_DIR"
   ```
2. **Migrate Any Legacy `.agent/` Metadata**:
   - If `<local_project_dir>/.agent/` exists, migrate any `.agent/kb/` or `.agent/docs/` files into `$META_DIR/kb/` and `$META_DIR/docs/`, then remove `<local_project_dir>/.agent/`.
3. **Harvest & Preserve Theme Color (`.vscode/settings.json` & `IRON_RULES.md`)**:
   - **A. Central Metadata Archive**:
     If `<local_project_dir>/.vscode/settings.json` exists, copy it into `$META_DIR/.vscode/settings.json`:
     ```bash
     mkdir -p "$META_DIR/.vscode"
     cp "<local_project_dir>/.vscode/settings.json" "$META_DIR/.vscode/settings.json"
     ```
   - **B. Explicit `Theme-Color` Rule in `IRON_RULES.md`**:
     Extract the primary hex code (from `peacock.color` or `workbench.colorCustomizations["titleBar.activeBackground"]`) and record `- **Theme-Color**: #<HEX>` under `## [Global]` inside `$META_DIR/IRON_RULES.md`.
   - **C. In-Repo Preservation (For Cloud Sandbox IDE)**:
     Ensure `<local_project_dir>/.vscode/settings.json` remains committed and pushed inside `<owner>/<project_name>` (verified in Stage 1) so the Cloud Remote Project workspace (`/workspace/<project_name>`) retains its native window theme color when opened in Antigravity IDE.
4. **Update `IRON_RULES.md` & `git_status.md` to `Pure-Remote`**:
   - Update `$META_DIR/IRON_RULES.md` under `## [Global]` to set:
     - `Project-Environment: Pure-Remote`
     - `GitHub-Repo: <owner>/<project_name>`
     - `Theme-Color: #<HEX>`
     - `Local-Workspace: None (Migrated to Cloud-Only /workspace/<project_name>)`
     - `PVE-Test-Dir: <remote_dir>/<project_name>` *(if keeping test clone, or `None`)*
     - `PVE-Dev-Server-Cmd: <command binding 0.0.0.0>` *(if applicable)*
   - Update `$META_DIR/git_status.md` to record the migration date, the GitHub repository URL, `Local-Workspace: Deleted (Pure-Remote)`, and the optional `PVE-Test-Dir`.

---

## Stage 3: Sync Metadata to Centralized Repository

Commit and push the updated project metadata directory inside `~/.gemini` so the Google Cloud Remote Agent sandbox can immediately read all historical `kb/` cards, `tasks/`, and `IRON_RULES.md`:

```bash
cd ~/.gemini
git add "Projects/<project_name>"
git commit -m "chore(projects): migrate <project_name> metadata to Pure-Remote"
git push origin HEAD
```

---

## Stage 4: Terminate Mutagen Sync & Configure Optional Remote Test Environment

1. **Terminate Mutagen Sync (If Any)**:
   Check whether an active or paused Mutagen sync session exists for `<project_name>` and terminate it cleanly:
   ```bash
   mutagen sync list
   # If a session matching <project_name> exists:
   mutagen sync terminate "<session_name>"
   ```
2. **Optional Remote On-Demand Test Clone (`<remote_dir>/<project_name>`)**:
   - Terminating Mutagen and deleting the local folder does **NOT** require deleting `<remote_dir>/<project_name>` on the remote server if the user wants to keep the remote server as an on-demand test environment!
   - If preserving `<remote_dir>/<project_name>` for on-demand preview testing (managed via `dev-server` / `pve_test_sync.sh`), ensure `<remote_dir>/<project_name>` has its `origin` set to `https://github.com/<owner>/<project_name>.git` (or SSH equivalent) and optionally start the lightweight on-demand tag watcher:
     ```bash
     ssh <REMOTE_HOST> "antiverse-run --name '[<project_name>] pve-sync-watch' --cwd '<remote_dir>/<project_name>' --force -- bash <scripts_dir>/pve_test_sync.sh -p '<project_name>' -a watch"
     ```

---

## Stage 5: Delete Local Source Directory & Clean Local Project Pointer

1. **Remove the Local Source Code Directory**:
   ```bash
   rm -rf "<local_project_dir>"
   ```
2. **Clean Stale Local `file://` Entry in `~/.gemini/config/projects/*.json`**:
   - Inspect `~/.gemini/config/projects/*.json` for any file whose `projectResources` points to the deleted `file://<local_project_dir>` path.
   - Ensure `~/.gemini/Projects/<project_name>/.project_id` retains the project ID, and update the stale pointer so `meta_resolver.py` resolves `<project_name>` directly via `Projects/<project_name>/`.
3. **Final Handover Reminder to User**:
   - Remind the user to open the Remote Project in Antigravity IDE and attach **both** repositories under Project Resources:
     - `<owner>/<project_name>`
     - `<metadata_repo>` (e.g. `gemini-hub`)

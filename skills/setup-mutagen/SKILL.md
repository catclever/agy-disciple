---
name: setup-mutagen
description: "Automatically inspects the local project ecosystem (Go, Node, Python, Rust, Wails desktop, etc.), generates optimal ignore rules including nested build/packaging artifacts, and initializes a bidirectional Mutagen sync session to a remote server."
---

# Setup Mutagen SOP

This skill defines the standard procedure for establishing and configuring bidirectional code synchronization between a local workspace and a remote compute server using **Mutagen**.

It automatically detects project technologies (Go, Node/TypeScript, Python, Rust, Ruby, JVM, C/C++, Swift, and **Wails desktop applications**), generates a declarative `mutagen.yml` configuration file with tailored ignore rules, and starts synchronization via **`mutagen project start`**.

---

## When to Use This Skill
Activate this skill whenever:
- The user requests to sync a local project to a remote server.
- Initializing a project configured with a remote execution topology.
- Setting up the prerequisite file sync link required by remote dispatch or autonomous night shifts.

---

## Environment & Server Defaults
- **Remote SSH Alias**: Configured in `~/.ssh/config` (or set via `AGY_REMOTE_HOST`).
- **Remote Target Base**: Configured target directory (or set via `AGY_REMOTE_BASE`).
- **Sync Mode**: `two-way-resolved`.
- **Symlink Mode**: `posix-raw`.
- **VCS Ignore**: Always enable `vcs: true` (automatically ignores `.git/`, `.gitignore` entries).

---

## Standard Workflow: Helper Script

Run the bundled inspector:

```bash
# 1. Preview detected rules without making changes (Dry Run)
python3 skills/setup-mutagen/scripts/setup_mutagen.py --dry-run

# 2. Write mutagen.yml and execute `mutagen project start`
python3 skills/setup-mutagen/scripts/setup_mutagen.py --start --remote-host=<YOUR_SSH_ALIAS>

# 3. Write configuration file only (without starting)
python3 skills/setup-mutagen/scripts/setup_mutagen.py --write-config
```

---

## Project Lifecycle Management
- **Check Status**: `mutagen project list` (or `mutagen sync list`)
- **Pause Sync**: `mutagen project pause`
- **Resume Sync**: `mutagen project resume`
- **Flush Sync**: `mutagen project flush`
- **Terminate Sync**: `mutagen project terminate`

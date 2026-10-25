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

## Language & Framework Detection Matrix

The skill inspects project root and nested frontend directories to apply the corresponding ignore rules:

| Ecosystem | Manifest Indicators | Key Ignore Patterns |
| :--- | :--- | :--- |
| **Universal / OS** | All projects | `.DS_Store`, `.idea/`, `.vscode/`, `.gemini/`, `.agent/`, `.codex/`, `*.log`, `tmp/`, `temp/` |
| **Wails Desktop** | `wails.json` | `build/bin/`, `build/windows/*.syso`, `frontend/dist/`, `frontend/node_modules/`, `wails-*.log` *(Note: `build/` root is preserved for assets)* |
| **Nested Frontend** | `frontend/`, `web/`, `client/`, `ui/` | `<dir>/node_modules/`, `<dir>/dist/`, `<dir>/build/`, `<dir>/.next/`, `<dir>/.turbo/` |
| **Go** | `go.mod`, `go.sum`, `*.go` | `bin/`, `vendor/`, `*.test`, `*.out`, `*.exe`, `*.so`, `*.dylib` |
| **Node / Web** | `package.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lockb` | `node_modules/`, `dist/`, `build/`, `.next/`, `.nuxt/`, `.output/`, `.turbo/`, `coverage/` |
| **Python** | `pyproject.toml`, `requirements.txt`, `setup.py`, `Pipfile`, `uv.lock` | `.venv/`, `venv/`, `env/`, `__pycache__/`, `*.pyc`, `.pytest_cache/`, `.mypy_cache/`, `*.egg-info/`, `dist/` |
| **Rust** | `Cargo.toml`, `Cargo.lock` | `target/` |
| **Ruby** | `Gemfile`, `Gemfile.lock` | `.bundle/`, `vendor/bundle/` |
| **Java / JVM** | `pom.xml`, `build.gradle`, `gradlew` | `target/`, `build/`, `.gradle/`, `*.class` |
| **C / C++** | `CMakeLists.txt`, `Makefile`, `meson.build` | `build/`, `cmake-build-*/`, `*.o`, `*.a`, `*.so`, `*.dylib` |
| **Swift** | `Package.swift` | `.build/`, `.swiftpm/`, `DerivedData/` |

---

## Critical Handling: Packaging Artifacts & Embedded Dist

### 1. Wails Desktop Applications (`wails.json`)
Wails combines a Go backend with an embedded web frontend using `//go:embed all:frontend/dist`.
- **`frontend/dist/` MUST be ignored**:
  Building on the remote server automatically invokes frontend build steps, generating static assets remotely. Syncing hundreds of hashed assets back and forth causes disk churn and dirty Git states.
- **`build/bin/` MUST be ignored**:
  Contains platform-dependent native binaries (e.g. Linux ELF on server vs macOS `.app` locally).
- **Never blanket-ignore `build/` in Wails**:
  Wails stores native packaging templates in `build/darwin` (Info.plist, icons) and `build/windows` (manifests). Blanket-ignoring `build/` breaks compilation. Only `build/bin/` and build outputs should be ignored.

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

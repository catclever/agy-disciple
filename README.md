# agy-disciple 🚀

[English](README.md) | [简体中文](README_zh.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Antigravity](https://img.shields.io/badge/Antigravity-Plugin-purple.svg)](https://antigravity.google)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com)

> **A Production-Grade Multi-Agent Development Team Plugin for Google Antigravity (AGY)**  
> Transform single-threaded agent interactions into a disciplined, hierarchical engineering squad: Lead Architect, Dev, Merger, and Ops.

---

## 📖 Overview

Standard AI coding assistants operate as monolithic single agents. When faced with non-trivial refactors or complex features, monolithic agents often suffer from:
1. **Context Pollution**: Diagnostic outputs, compiler errors, and failed attempts overwhelm the conversation context.
2. **Accidental File Overwrites**: Agents directly edit production source files, risking broken working trees and hallucinated deletions.
3. **Repeated Anti-Patterns**: Without negative knowledge tracking, agents repeatedly attempt solutions that already failed in prior sessions.

`agy-disciple` (**Antigravity Disciple**) introduces a **hierarchical multi-agent engineering workflow**. It divides development responsibilities across specialized agents governed by strict isolation boundaries, draft suffix protocols, and double knowledge audits.

---

## 🏛️ Core Architecture

```
                       ┌────────────────────────────────┐
                       │     Lead Architect (Main)      │
                       │  • Task Breakdown & Confirmation│
                       │  • Double KB Audit & Graveyard │
                       │  • Kanban Board & DoD Gate     │
                       └───────────────┬────────────────┘
                                       │
         ┌─────────────────────────────┼─────────────────────────────┐
         ▼                             ▼                             ▼
┌─────────────────┐           ┌─────────────────┐           ┌─────────────────┐
│    dev Agent    │           │  merger Agent   │           │    ops Agent    │
│ • Sandboxed Dev │           │ • Atomic Backup │           │ • Non-Idempotent│
│ • Draft Suffix  │──drafts──►│ • Safe Renaming │           │ • Command Dict  │
│ • Self-Testing  │           │ • Zero Logic    │           │ • Host Scripts  │
└─────────────────┘           └─────────────────┘           └─────────────────┘
```

### 1. The Squad
* **Lead Architect (Main Agent)**: High-level system design, requirement decomposition, knowledge synthesis, user alignment, and Definition-of-Done (DoD) verification.
* **`dev` Sub-Agent ([agents/dev.yaml](agents/dev.yaml))**: Sandboxed implementation and unit testing. Strictly forbidden from modifying original source files directly.
* **`merger` Sub-Agent ([agents/merger.yaml](agents/merger.yaml))**: Replaces production files with verified drafts after creating atomic `.bak` backups. Contains zero business logic.
* **`ops` Sub-Agent ([agents/ops.yaml](agents/ops.yaml))**: Safely executes real-world, high-cost operational scripts (deployments, data migrations, packaging) with command dictionary verification.

---

## ⚡ Key Engineering Principles

### 1. Draft Suffix Isolation (Suffix Rule)
Instead of modifying `api.py` directly, `dev` generates draft files with task suffixes before the extension (e.g. `api_task_auth_001.py`):
* **Full IDE Tooling**: Preserves native syntax highlighting, linting, and type checking in the IDE.
* **Zero Disruption**: The original codebase remains completely functional and uncorrupted until tests pass.
* **Atomic Rollback**: If a proposal is rejected, discard the draft with zero collateral damage.

### 2. Double Knowledge Base Audit & The Graveyard
* **Active Knowledge (`kb/knowledge.md`)**: Houses finalized technical truths (DB schemas, API contracts, environment setups).
* **Anti-Pattern Graveyard (`kb/graveyard/grave.md`)**: Systematically tracks **negative knowledge** (failed approaches, dead ends, root cause post-mortems).
* **Radar Scan**: Before presenting any plan to the user, the Lead Architect performs an automatic double audit against active knowledge and scans the Graveyard to ensure historically failed solutions are never suggested again.

### 3. Adaptive Kanban Engine
Task tracking automatically detects environment capabilities:
* **MCP Mode**: When the bundled `kanban-task-manager` MCP server is active, enjoys strict schema enforcement and clickable session deep-links (`conversation://<uuid>`).
* **Native Fallback (Zero Config)**: Gracefully falls back to managing standard YAML frontmatter Markdown cards in `tasks/*.md` without requiring external MCP services.

---

## 🚦 Quick Start: Two Operating Modes & Setup

Before starting, run the built-in diagnostic doctor to verify your environment:
```bash
python configure.py --doctor
```

### Mode 1: Standalone / Local-First Mode (Default)
**Best for**: Individual developers and teams working directly inside the Antigravity IDE.

#### 1. Prerequisites
- **Git** (`git`)
- **Python** (>= 3.8)
- *No extra CLI binaries or remote servers required!*

#### 2. Installation
Clone into your Antigravity global plugin directory:
```bash
cd ~/.gemini/config/plugins/
git clone https://github.com/<your-username>/agy-disciple.git
```
*(Or clone into `<project_root>/.agents/plugins/agy-disciple` for project-level usage).*

#### 3. Start Developing
1. Open your project in the Antigravity IDE.
2. Ensure the standalone preset is active:
   ```bash
   python configure.py --preset=standalone
   ```
3. Issue requests directly in the chat:
   - *"Help me break down the authentication feature"* (triggers `task-breakdown` and spawns `dev`).
   - *"Save our database decision"* (triggers `extract-knowledge`).
   - *"I am heading off work"* (triggers local unattended `/goal` night shift).

---

### Mode 2: Remote Server & Jules Autonomous Mode
**Best for**: Power users with a dedicated Linux/PVE server or teams leveraging Google Cloud Jules for unattended overnight pull requests.

#### 1. Prerequisites & Tool Setup
* **Remote Host (PVE / Cloud VM)**:
  - **Antigravity CLI (`agy`)**: Install and authenticate on the remote server (see [Antigravity CLI Reference](https://antigravity.google/docs/cli)).
  - **SSH Access**: Configure your SSH alias in `~/.ssh/config` (e.g. `Host my-pve`).
  - **Zellij**: Install terminal multiplexer on the server (`cargo install zellij` or distro package).
* **Google Cloud Jules (For GitHub Autonomous Pipeline)**:
  - Set your API key in environment: `export JULES_API_KEY="AIzaSy..."` (or install and authenticate the `jules` CLI).
  - **GitHub CLI (`gh`)**: Required if `--auto-merge` is enabled.
* **Mutagen Sync (Optional)**:
  - Install locally via `brew install mutagen-io/mutagen/mutagen` for real-time two-way code synchronization.

#### 2. Enable Server Preset
Run in the plugin root:
```bash
python configure.py --preset=server-centralized
```

#### 3. Launching Watchdogs
The plugin provides two production-grade watchdog scripts in `scripts/watchdogs/`:

##### Watchdog A: Remote PVE Server Watchdog (`pve_watchdog.sh`)
Dispatches tasks to the remote server via SSH, runs `agy` in a persistent Zellij tab or background daemon, and monitors completion:
```bash
bash scripts/watchdogs/pve_watchdog.sh \
  -t auth_001 \
  -a dev \
  -d /root/Projects/my-app \
  -p "Implement JWT authentication" \
  -h my-pve
```

##### Watchdog B: Google Jules Cloud Watchdog (`jules_watchdog.sh`)
Dispatches tasks directly to Google Cloud Jules, monitors PR generation, and optionally auto-merges the PR via squash commit:
```bash
bash scripts/watchdogs/jules_watchdog.sh \
  -t auth_001 \
  -r "owner/repo" \
  -b "main" \
  -p "Fix security vulnerability in auth router" \
  --auto-merge
```

---

## 🧭 File Placement Guide (MCP & Scripts)

In the Antigravity ecosystem, understanding where configurations and scripts live ensures clean modularity:

### 1. Where do MCP Servers go?
* **Bundled Location**: The included task manager MCP lives inside [mcp/kanban-task-manager/server.py](mcp/kanban-task-manager/server.py).
* **System Registration**: To make an MCP server globally accessible across all Antigravity projects, register it in `~/.gemini/config/mcp_config.json`:
  ```json
  {
    "mcpServers": {
      "kanban-task-manager": {
        "command": "uv",
        "args": [
          "run",
          "/absolute/path/to/agy-disciple/mcp/kanban-task-manager/server.py"
        ]
      }
    }
  }
  ```
* **UI Alternative**: You can also add it visually via Antigravity IDE: **Additional Options (...) > MCP Servers > Add Server**.

### 2. Where do Custom Scripts go?
* **Repository Scripts**: All project scripts and automation helpers are kept in `scripts/`:
  - `scripts/watchdogs/`: Remote server and Jules dispatchers.
  - `scripts/meta_resolver.py`: Centralized metadata path locator.
  - `skills/setup-mutagen/scripts/`: Mutagen YAML generator.
* **Global Access (Optional)**: If you wish to invoke the watchdogs from any terminal directory without specifying relative paths, symlink them to your global config directory:
  ```bash
  mkdir -p ~/.gemini/config/scripts
  ln -sf $(pwd)/scripts/watchdogs/pve_watchdog.sh ~/.gemini/config/scripts/
  ln -sf $(pwd)/scripts/watchdogs/jules_watchdog.sh ~/.gemini/config/scripts/
  ```

---

## 📁 Repository Structure

```text
agy-disciple/
├── plugin.json                 # Antigravity plugin manifest
├── README.md                   # English documentation
├── README_zh.md                # 简体中文文档
├── LICENSE                     # MIT License
├── configure.py                # Preset switcher & environment doctor (--doctor)
│
├── agents/                     # Specialized Sub-Agent definitions
│   ├── dev.yaml                # Dev Agent (draft suffix & sandboxed tests)
│   ├── merger.yaml             # Merger Agent (safe backup & file swap)
│   └── ops.yaml                # Ops Agent (script safety & command logging)
│
├── skills/                     # Modular skills library
│   ├── task-breakdown/         # Task decomposition & two-track confirmation
│   ├── dev-manager/            # Development lifecycle orchestration (local / server)
│   ├── project-manager/        # Project metadata & task boards (in-repo / centralized)
│   ├── extract-knowledge/      # Knowledge extraction & Graveyard radar
│   ├── ops-manager/            # Operational script execution
│   ├── test-environment/      # Test servers and preview management
│   ├── night-shift/            # Autonomous unattended task handoff
│   ├── pve-dispatch/           # Remote SSH task dispatch
│   └── setup-mutagen/          # Smart language detection & Mutagen sync
│
├── mcp/                        # Bundled MCP server
│   └── kanban-task-manager/
│       ├── server.py           # Standalone FastMCP task board
│       ├── mcp_config.example.json
│       └── README.md           # Setup instructions
│
└── scripts/
    ├── watchdogs/              # Production watchdog dispatchers
    │   ├── pve_watchdog.sh     # Remote SSH / agy CLI watchdog
    │   └── jules_watchdog.sh   # Google Cloud Jules autonomous watchdog
    └── meta_resolver.py        # Centralized metadata path resolver
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

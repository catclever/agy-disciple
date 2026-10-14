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

## 🎛️ Dual-Mode Topology (Local vs. Server)

`agy-disciple` seamlessly accommodates solo local developers and power users with remote servers:

| Feature | Standalone / In-Repo (Default) | Server-Centralized / PVE |
| :--- | :--- | :--- |
| **Target Audience** | Individual developers, team Git repositories | Power users with PVE/Linux build servers |
| **Metadata Location** | Inside project repo (`./kb`, `./tasks`, `./docs`) | Centralized in `~/.gemini/Projects/<name>` |
| **Compute Topology** | Native local IDE sub-agents | Local Lead Architect + Remote SSH/Zellij agents |
| **Night Shift** | Local autonomous `/goal` execution loop | Remote unattended multiplexer pipeline |

### Instant Mode Switching

Switch presets in one command via `configure.py`:

```bash
# Check current active configuration
python configure.py --status

# Apply default standalone / in-repo preset
python configure.py --preset=standalone

# Apply server-centralized / PVE preset
python configure.py --preset=server-centralized

# Granular adjustments
python configure.py --meta=in-repo       # in-repo | centralized
python configure.py --topology=local     # local | server
```

---

## 🚀 Quick Start

### Installation

#### Method 1: Global Plugin (Recommended)
Clone into your Antigravity global plugin directory:
```bash
cd ~/.gemini/config/plugins/
git clone https://github.com/<your-username>/agy-disciple.git
```
Reload or restart Antigravity. The plugin will be automatically discovered.

#### Method 2: Project-Specific Plugin
Clone into the project's `.agents/plugins/` directory:
```bash
mkdir -p .agents/plugins
cd .agents/plugins
git clone https://github.com/<your-username>/agy-disciple.git
```

---

## 📦 Optional: Kanban Task Manager MCP

`agy-disciple` includes a self-contained, lightweight Kanban task manager MCP server built with FastMCP.

### Setup in Antigravity
1. Open Antigravity **Additional Options (...)** > **MCP Servers**.
2. Add a new Stdio server:
   - **Name**: `kanban-task-manager`
   - **Command**: `uv`
   - **Args**: `run`, `/absolute/path/to/agy-disciple/mcp/kanban-task-manager/server.py`

Or declare it in `~/.gemini/config/mcp_config.json`:
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

See [mcp/kanban-task-manager/README.md](mcp/kanban-task-manager/README.md) for details.

---

## 📁 Repository Structure

```text
agy-disciple/
├── plugin.json                 # Antigravity plugin manifest
├── README.md                   # English documentation
├── README_zh.md                # 简体中文文档
├── LICENSE                     # MIT License
├── configure.py                # Preset and mode switcher
│
├── agents/                     # Specialized Sub-Agent definitions
│   ├── dev.yaml                # Dev Agent (draft suffix & sandboxed tests)
│   ├── merger.yaml             # Merger Agent (safe backup & file swap)
│   └── ops.yaml                # Ops Agent (script safety & command logging)
│
├── skills/                     # Modular skills library
│   ├── task-breakdown/         # Task decomposition & two-track confirmation
│   ├── dev-manager/            # Development lifecycle orchestration
│   ├── project-manager/        # Project metadata & task boards
│   ├── extract-knowledge/      # Knowledge extraction & Graveyard radar
│   ├── ops-manager/            # Operational script execution
│   ├── test-environment/      # Test servers and preview management
│   ├── night-shift/            # Autonomous unattended task handoff
│   ├── pve-dispatch/           # Remote SSH task dispatch
│   └── setup-mutagen/          # Smart language detection & Mutagen sync
│
├── mcp/                        # Bundled MCP server
│   └── kanban-task-manager/    # Standalone task management MCP server
│
└── scripts/
    └── meta_resolver.py        # Centralized metadata path resolver
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

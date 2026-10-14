# agy-disciple 🚀

[English](README.md) | [简体中文](README_zh.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Antigravity](https://img.shields.io/badge/Antigravity-Plugin-purple.svg)](https://antigravity.google)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com)

> **A Production-Grade Multi-Agent Development Team Plugin for Google Antigravity (AGY)**  
> Transform single-threaded agent interactions into a disciplined, hierarchical engineering squad: Lead Architect, Dev, Merger, and Ops.

---

## 1. 📖 Overview

Standard AI coding assistants operate as monolithic single agents. When faced with complex features or large refactors, developers frequently face critical bottlenecks:
* **Google's Monetization Trap & The Model Void**: In a transparent push for commercial monetization, Google removed the sweet-spot **Gemini 3.1 Pro** from the Antigravity client. Developers are left stranded between **Gemini 4 Argon (a notorious "Quota Assassin" whose deep-thinking tokens devour monthly tier limits in minutes)** and **Gemini 3.8 Flash (lightweight and cheap, but still no match for 3.1 Pro on complex multi-file reasoning and refactoring)**. Local quotas drain at alarming speeds;
* **The Untapped Ultra / Jules Treasure**: Many developers subscribe to Google Ultra or possess Google Cloud quotas with abundant, rich **Google Cloud Jules allowances**, but Antigravity provides no native way to exploit this quota during everyday IDE development—leaving premium compute sitting idle;
* **Context Window Pollution**: Raw compile logs, test stack traces, and trial-and-error attempts flood the main conversation context;
* **Source Code Corruption**: Agents directly mutate production source files, risking broken working trees and hallucinated deletions;
* **Repeated Anti-Patterns**: Without negative knowledge tracking, agents repeatedly suggest dead-end solutions previously proven broken.

`agy-disciple` (**Antigravity Disciple**) breaks through this monetization wall with a **hierarchical multi-agent engineering workflow**. It positions the local session as a **Lead Architect**, seamlessly offloading heavy implementation to remote **Google Cloud Jules running Gemini 3.1 Pro on independent cloud quotas**—fully exploiting your rich Ultra Jules allowance without burning expensive local 4 Argon tokens—guarded by draft suffix isolation, double knowledge audits, and data-driven Kanban boards.

---

## 2. 🚦 Quick Start

Run the environment doctor anytime to verify your prerequisites:
```bash
python configure.py --doctor
```

### Option A: Standalone / Local-First Mode (Default)
**Best for**: Solo developers and teams working directly inside the Antigravity IDE who want local sub-agents or local Jules cloud offloading.

1. **Prerequisites**:
   * Git (`git`) & Python (>= 3.8).
   * *(Optional for Jules Dev)*: `export JULES_API_KEY="your-api-key"` or `jules` CLI.
   * *(Optional for Kanban MCP)*: `uv` (or `pip install mcp pyyaml`).
2. **Install Plugin**:
   ```bash
   cd ~/.gemini/config/plugins/
   git clone https://github.com/catclever/agy-disciple.git
   ```
   *(Or clone into your project's `.agents/plugins/agy-disciple`)*.
3. **Start Developing**:
   ```bash
   python configure.py --preset=standalone
   ```
   Open Antigravity IDE and chat naturally:
   * *"Help me break down the auth feature and delegate to dev"*
   * *"Dispatch this refactor to jules dev to save Antigravity tokens"*

---

### Option B: Remote Server & Jules Autonomous Mode
**Best for**: Power users with a dedicated Linux/PVE server for unattended 24/7 background development.

1. **Prerequisites**:
   * **Remote PVE / Linux Server**: Configured SSH alias in `~/.ssh/config` (e.g. `Host my-pve`), `agy` CLI installed and authenticated on the server, and `zellij` installed.
   * **Server-side Jules**: Configure `$JULES_API_KEY` on the remote server (`/root/.bashrc`).
2. **Activate Server Preset**:
   ```bash
   python configure.py --preset=server-centralized
   ```
3. **Execute Watchdogs**:
   Launch the remote PVE watchdog or server-side Jules watchdog:
   ```bash
   # Dispatch to Google Jules from server
   ssh my-pve "bash scripts/watchdogs/jules_watchdog.sh -t auth_001 -r owner/repo -p 'Fix concurrency bug' --auto-merge"

   # Dispatch to remote server agy agent
   bash scripts/watchdogs/pve_watchdog.sh -t auth_001 -a dev -d /root/Projects/my-app -p "Implement Redis cache" -h my-pve
   ```

---

## 3. ⚡ Core Capabilities (What agy-disciple Delivers)

### ★ 1. Jules Remote Dev & Quota Arbitrage (Gemini 3.1 Pro Empowerment)
* **The Commercial Reality (Unfiltered)**:
  * Google deliberately removed the workhorse **Gemini 3.1 Pro** from the Antigravity client to accelerate paid monetization;
  * Users inside Antigravity are left stranded between **Gemini 4 Argon (a notorious "Quota Assassin" with extreme thinking token consumption)** and **Gemini 3.8 Flash (affordable, but repeatedly falls short of 3.1 Pro on multi-step architectural logic)**;
  * Meanwhile, developers on Google Ultra or Cloud subscriptions have access to **copious, high-volume Google Cloud Jules quotas** that are completely locked out of Antigravity's native IDE workflow!
* **The agy-disciple Arbitrage Advantage**:
  * **Exploit Free/Ultra Cloud Quotas**: Offload heavy implementation tasks to Google Cloud Jules, draining your generous Ultra allowance while **keeping your local Antigravity 4 Argon token balance at zero cost**!
  * **Reclaim True Gemini 3.1 Pro Intelligence**: Jules natively operates on **Gemini 3.1 Pro**, crushing 3.8 Flash in cross-file refactoring, dependency tracking, and nuanced unit test generation.
  * **Dual Jules Topologies (Your Choice)**:
    * *Local-First Mode*: Runs Jules locally via `scripts/watchdogs/jules_watchdog.sh` using your local `$JULES_API_KEY`.
    * *Server Mode (PVE)*: Dispatches Jules to run on your remote PVE server as an unattended 24/7 background watchdog.
  * **Automated Cloud PRs**: Jules executes inside cloud VMs and submits clean Pull Requests directly to GitHub, supporting automatic squash merging via `gh pr merge --squash`.

### 2. Draft Suffix Isolation (Draft Suffix Rule)
When the local `dev` agent modifies code, it is strictly forbidden from touching original files. It generates task-suffixed drafts (e.g. `api_task_auth_001.py`):
* **100% IDE Native**: Preserves exact file extensions so syntax highlighting, linting, and autocomplete remain fully functional.
* **Zero Corruption**: Source files are never broken during trial-and-error attempts.
* **Atomic Rollback**: If a proposal fails verification, the draft is discarded without touching working trees.

### 3. Double Knowledge Base Audit & Graveyard Radar
* **Active Knowledge (`kb/knowledge.md`)**: Single Source of Truth for verified architectures, DB schemas, and API contracts.
* **Anti-Pattern Graveyard (`kb/graveyard/grave.md`)**: Systematically catalogs **negative knowledge** (failed approaches, dead ends, and post-mortems).
* **Pre-Presentation Radar**: Before presenting any solution to the user, the Lead Architect automatically scans the Graveyard to ensure historically failed attempts are never repeated.

### 4. Adaptive Kanban Engine
* **MCP Preferred**: Automatically leverages the bundled `kanban-task-manager` MCP server when available, providing strict enum validations and clickable session deep-links (`conversation://<uuid>`).
* **Native Fallback**: Gracefully falls back to managing Markdown task cards in `tasks/*.md` without requiring any external MCP setup.

---

## 4. 🏛️ Core Architecture

```
                       ┌────────────────────────────────┐
                       │     Lead Architect (Main)      │
                       │  • Task Breakdown & Plan Gate  │
                       │  • Double KB Audit & Graveyard │
                       │  • Kanban Board & DoD Gate     │
                       └───────────────┬────────────────┘
                                       │
         ┌─────────────────────────────┼─────────────────────────────┐
         ▼                             ▼                             ▼
┌─────────────────────────┐   ┌─────────────────┐           ┌─────────────────┐
│     Dev Sub-Agent       │   │  merger Agent   │           │    ops Agent    │
│  [Dual Engine Support]  │   │ • Atomic Backup │           │ • Non-Idempotent│
│ ┌─────────────────────┐ │   │ • Safe Renaming │           │ • Command Dict  │
│ │ A: Native IDE (dev) │ │──►│ • Zero Logic    │           │ • Host Scripts  │
│ ├─────────────────────┤ │   └─────────────────┘           └─────────────────┘
│ │ B: Jules (3.1 Pro)  │ │
│ └─────────────────────┘ │
└─────────────────────────┘
```

### The Squad
1. **Lead Architect (Main Agent)**: High-level system design, plan formulation, two-track user confirmation, and Definition-of-Done (DoD) gatekeeping.
2. **Dev Sub-Agent**:
   * **Engine A (Native `dev`)** ([agents/dev.yaml](agents/dev.yaml)): Local sandboxed coding and unit tests.
   * **Engine B (Google Jules `jules-dev`)** ([agents/jules-dev.yaml](agents/jules-dev.yaml)): Google Cloud Jules cloud worker running **Gemini 3.1 Pro** with zero Antigravity token cost.
3. **Merger Sub-Agent ([agents/merger.yaml](agents/merger.yaml))**: Creates `.bak` backups and swaps draft files into production.
4. **Ops Sub-Agent ([agents/ops.yaml](agents/ops.yaml))**: Executes production scripts, deployments, and packaging with mandatory command dictionary logging.

---

## 5. 🎛️ Dual-Mode System & Mode Switcher

`agy-disciple` provides seamless switching between local and server setups:

```bash
# Check current active configuration
python configure.py --status

# Diagnose environment prerequisites
python configure.py --doctor

# Apply default standalone / in-repo preset
python configure.py --preset=standalone

# Apply server-centralized / PVE preset
python configure.py --preset=server-centralized
```

---

## 6. 🧭 File Placement & MCP Setup Guide

### 1. Where do MCP Servers go?
* **Bundled Location**: The task manager MCP lives inside [mcp/kanban-task-manager/server.py](mcp/kanban-task-manager/server.py).
* **Global Registration**: Add to `~/.gemini/config/mcp_config.json`:
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
* **UI Alternative**: Add via Antigravity IDE: **... > MCP Servers > Add Server**.

### 2. Where do Custom Scripts go?
* **Repository Scripts**: All helper scripts are located under `scripts/`:
  - `scripts/watchdogs/jules_watchdog.sh`: Google Cloud Jules dispatcher.
  - `scripts/watchdogs/pve_watchdog.sh`: Remote server SSH/agy dispatcher.
  - `scripts/meta_resolver.py`: Centralized metadata path locator.
* **Global Symlinks (Optional)**:
  ```bash
  mkdir -p ~/.gemini/config/scripts
  ln -sf $(pwd)/scripts/watchdogs/jules_watchdog.sh ~/.gemini/config/scripts/
  ln -sf $(pwd)/scripts/watchdogs/pve_watchdog.sh ~/.gemini/config/scripts/
  ```

---

## 7. 📁 Repository Structure & License

```text
agy-disciple/
├── plugin.json                 # Antigravity plugin manifest
├── README.md                   # English documentation
├── README_zh.md                # 简体中文文档
├── LICENSE                     # MIT License
├── configure.py                # Preset switcher & environment doctor (--doctor)
│
├── agents/                     # Sub-Agent definitions
│   ├── dev.yaml                # Native Dev Agent (draft suffix & sandbox)
│   ├── jules-dev.yaml          # Google Cloud Jules Dev Agent (Gemini 3.1 Pro)
│   ├── merger.yaml             # Merger Agent (backup & file swap)
│   └── ops.yaml                # Ops Agent (script safety & command logging)
│
├── skills/                     # Modular skills library
│   ├── dev-manager/            # Development orchestration (local / server)
│   ├── project-manager/        # Project metadata & task boards (in-repo / centralized)
│   ├── task-breakdown/         # Task decomposition & two-track confirmation
│   ├── extract-knowledge/      # Knowledge extraction & Graveyard radar
│   ├── ops-manager/            # Operational script execution
│   ├── test-environment/      # Test servers and preview management
│   ├── night-shift/            # Autonomous unattended task handoff
│   ├── pve-dispatch/           # Remote SSH task dispatch
│   └── setup-mutagen/          # Smart language detection & Mutagen sync
│
├── mcp/                        # Bundled MCP server
│   └── kanban-task-manager/    # Standalone FastMCP task board
│
└── scripts/
    ├── watchdogs/              # Production watchdog dispatchers
    │   ├── jules_watchdog.sh   # Google Cloud Jules autonomous watchdog
    │   └── pve_watchdog.sh     # Remote SSH / agy CLI watchdog
    └── meta_resolver.py        # Centralized metadata path resolver
```

This project is licensed under the [MIT License](LICENSE).

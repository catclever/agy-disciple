# agy-disciple 🚀

<div align="center">

**A Production-Grade Multi-Agent Development Team Plugin for Google Antigravity (AGY)**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/catclever/agy-disciple?style=flat&color=yellow)](https://github.com/catclever/agy-disciple/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/catclever/agy-disciple?style=flat&color=orange)](https://github.com/catclever/agy-disciple/network/members)
[![GitHub Issues](https://img.shields.io/github/issues/catclever/agy-disciple?style=flat&color=red)](https://github.com/catclever/agy-disciple/issues)
[![Antigravity](https://img.shields.io/badge/Antigravity-Plugin-purple.svg)](https://antigravity.google)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/catclever/agy-disciple/pulls)

[English](README.md) | [简体中文](README_zh.md)

</div>

---

> **Transform your single-threaded AI pair programmer into a disciplined, hierarchical engineering organization:**  
> **Lead Architect** 🏛️ &nbsp;•&nbsp; **Dev Sub-Agents** 💻 &nbsp;•&nbsp; **Merger Agent** 🔀 &nbsp;•&nbsp; **Ops Sub-Agent** ⚙️

---

## 📑 Table of Contents

- [1. Why agy-disciple?](#1-why-agy-disciple)
  - [The Commercial Bottlenecks](#the-commercial-bottlenecks)
  - [Feature Comparison](#feature-comparison)
- [2. 🏛️ Architecture Overview](#2-️-architecture-overview)
  - [The Engineering Squad](#the-engineering-squad)
- [3. ⚡ Core Capabilities](#3--core-capabilities)
  - [1. Jules Cloud Delegation & Quota Arbitrage (Gemini 3.1 Pro)](#1-jules-cloud-delegation--quota-arbitrage-gemini-31-pro)
  - [2. Draft Suffix Isolation (Zero Source Corruption)](#2-draft-suffix-isolation-zero-source-corruption)
  - [3. Double Knowledge Base Audit & Graveyard Radar](#3-double-knowledge-base-audit--graveyard-radar)
  - [4. Data-Driven FastMCP Kanban Board](#4-data-driven-fastmcp-kanban-board)
  - [5. 24/7 Unattended Night Shift & Smart Mutagen Sync](#5-247-unattended-night-shift--smart-mutagen-sync)
- [4. 🚦 Quick Start](#4--quick-start)
  - [Environment Health Check](#environment-health-check)
  - [Option A: Standalone / Local-First Mode (Default)](#option-a-standalone--local-first-mode-default)
  - [Option B: Remote Server Mode (Headless 24/7 Pipeline)](#option-b-remote-server-mode-headless-247-pipeline)
- [5. 🎛️ Preset Switcher (`configure.py`)](#5-️-preset-switcher-configurepy)
- [6. 🧭 Production Watchdogs & Automation](#6--production-watchdogs--automation)
- [7. 📁 Repository Structure](#7--repository-structure)
- [8. 🤝 Contributing](#8--contributing)
- [9. 📄 License](#9--license)

---

## 1. Why agy-disciple?

### The Commercial Bottlenecks

Standard AI coding assistants operate as monolithic single agents. When tackling complex real-world codebases, developers hit painful roadblocks:

1. **Google's Commercial Quota Dilemma**: In an aggressive push for paid monetization, Google removed the highly-balanced **Gemini 3.1 Pro** from the Antigravity IDE client. Developers are caught between:
   - **Gemini 4 Argon**: A notorious *"Quota Assassin"* whose extended thinking tokens burn through monthly subscription caps in minutes.
   - **Gemini 3.8 Flash**: Fast and cheap, but fundamentally underpowered for nuanced multi-file refactoring and architectural reasoning.
2. **Untapped Google Cloud Jules Quota**: Subscribers of **Google Ultra** possess generous allowances for **Google Cloud Jules** (which natively runs Gemini 3.1 Pro in cloud VMs). Yet, Antigravity provides zero native integration to dispatch workloads to Jules, leaving massive compute resources idle.
3. **Context Window Pollution**: Raw compilation dumps, failing test traces, and trial-and-error attempts quickly pollute the conversation context, leading to model degradation and hallucinations.
4. **Source Code Corruption**: Single-agent assistants mutate live production files directly, leading to broken syntax, deleted functions, and uncommitted git nightmares.
5. **Repetitive Anti-Patterns**: Without structured negative knowledge, models repeatedly suggest dead-end solutions previously proven defective.

### Feature Comparison

| Capability | Standard Antigravity | With `agy-disciple` |
| :--- | :--- | :--- |
| **Model Strategy** | 4 Argon (Expensive) or 3.8 Flash (Weak) | **Dual Engine**: Local Native Dev + **Cloud Jules (Gemini 3.1 Pro)** |
| **Quota Consumption** | Drains expensive local IDE thinking tokens | **Zero Local Token Cost** when offloading to Cloud Jules |
| **Code Modification** | In-place direct mutation (High risk of breakage) | **Draft Suffix Isolation** (`*_task_<id>.*`) with `.bak` rollback |
| **Task Management** | Ephemeral memory in chat history | **Data-driven Kanban** via FastMCP & Markdown fallback |
| **Failure Avoidance** | Blind trial-and-error repetitions | **Graveyard Radar (`grave.md`)** audits before proposing solutions |
| **24/7 Night Shift** | Stops when laptop lid closes or user sleeps | **Unattended Remote Server / Headless Jules Pipeline** with auto-PR |
| **VCS Baseline Alignment** | Prone to divergent cloud/local baselines | **Git Pre-Flight Sync (`-d`)** with 3-Layer Autonomous Defense |

---

## 2. 🏛️ Architecture Overview

`agy-disciple` establishes a clear hierarchical division of labor:

```text
                       ┌─────────────────────────────────────────┐
                       │          Lead Architect (Main)          │
                       │  • Task Breakdown & Confirmation Gate   │
                       │  • Double KB Audit & Graveyard Radar    │
                       │  • Data-driven Kanban & DoD Gatekeeper  │
                       └────────────────────┬────────────────────┘
                                            │
          ┌─────────────────────────────────┼─────────────────────────────────┐
          ▼                                 ▼                                 ▼
┌───────────────────────────┐   ┌───────────────────────┐   ┌───────────────────────────┐
│       Dev Sub-Agent       │   │     Merger Agent      │   │       Ops Sub-Agent       │
│   [Dual Engine Support]   │   │  • Draft File Swap    │   │  • Non-Idempotent Scripts │
│ ┌───────────────────────┐ │   │  • .bak Atomic Backup │   │  • Mandatory Command Dict │
│ │ Engine A: Native Dev  │ │──►│  • Zero Logic Polish  │   │  • Host Deploy & Mutagen  │
│ ├───────────────────────┤ │   └───────────────────────┘   └───────────────────────────┘
│ │ Engine B: Cloud Jules │ │
│ └───────────────────────┘ │
└───────────────────────────┘
```

### The Engineering Squad

1. **Lead Architect (Main Session)**: High-level system design, user communication, task decomposition, knowledge governance, and Definition-of-Done (DoD) verification.
2. **Dev Sub-Agent ([agents/dev.yaml](agents/dev.yaml))**:
   - **Engine A (Native Dev)**: Sandboxed local coding and test suite authoring.
   - **Engine B (Google Jules Dev)** ([agents/jules-dev.yaml](agents/jules-dev.yaml)): Offloaded to Google Cloud Jules running **Gemini 3.1 Pro** in dedicated cloud VMs.
3. **Merger Sub-Agent ([agents/merger.yaml](agents/merger.yaml))**: Creates `.bak` backups and executes atomic file swapping once draft verification passes.
4. **Ops Sub-Agent ([agents/ops.yaml](agents/ops.yaml))**: Executes production packaging, cross-workspace file transfers, and deployments with strict command-log tracking.

---

## 3. ⚡ Core Capabilities

### 1. Jules Cloud Delegation & Quota Arbitrage (Gemini 3.1 Pro)
- **Arbitrage Advantage**: Leverage your high-volume Google Ultra Jules quotas to execute heavy development while **preserving your local Antigravity 4 Argon balance at zero cost**!
- **Gemini 3.1 Pro Empowerment**: Reclaim the workhorse reasoning engine that outperforms 3.8 Flash in cross-file refactoring and edge-case handling.
- **Git Pre-Flight Synchronization (`-d <dir>`)**: Automatically inspects working trees before dispatch, commits dirty state, pulls, rebases, and pushes to ensure cloud VMs start with an aligned baseline.
- **3-Layer Autonomous Defense (`--autonomous`)**:
  - *Defense 1 (Plan Suppression)*: Disables `requirePlanApproval` during session initialization to prevent unwanted pauses.
  - *Defense 2 (Plan Auto-Approval)*: Intercepts `AWAITING_PLAN_APPROVAL` states via REST API and automatically approves.
  - *Defense 3 (Auto-Feedback Directives)*: Intercepts `AWAITING_USER_FEEDBACK` queries and issues directive resolution prompts (up to 3 times) to prevent pipeline stalls.
- **Out-of-the-Box Native Default**: All modes default to native local/remote `dev` agents; Jules is triggered **only upon explicit user request** (e.g. *"Dispatch this to jules dev"*).

### 2. Draft Suffix Isolation (Zero Source Corruption)
Local `dev` sub-agents are strictly forbidden from modifying production files directly.
- **Draft Pattern**: All edits produce suffixed files (e.g., `router_task_auth_001.py`).
- **100% IDE Native**: Preserves exact extensions for autocomplete, syntax linting, and type checking.
- **Atomic Rollback**: If tests fail, the draft is cleanly deleted without affecting working code.

### 3. Double Knowledge Base Audit & Graveyard Radar
- **Active Knowledge (`kb/knowledge.md`)**: Single Source of Truth for verified architectures, API schemas, and environment configs.
- **Graveyard Radar (`kb/graveyard/grave.md`)**: Catalogs negative knowledge (anti-patterns, failed implementations, dead ends).
- **Pre-Presentation Audit**: The Lead Architect automatically scans the Graveyard before proposing any plan to guarantee known failure modes are never repeated.

### 4. Data-Driven FastMCP Kanban Board
- **MCP Preferred**: Connects to the bundled FastMCP server ([mcp/kanban-task-manager/](mcp/kanban-task-manager/)) for status validation and clickable conversation deep-links (`conversation://<uuid>`).
- **Native Fallback**: Seamlessly falls back to managing markdown cards in `tasks/*.md` when running without MCP.

### 5. 24/7 Unattended Night Shift & Smart Mutagen Sync
- **Night Shift Protocol**: Transition ongoing sessions into overnight autonomous mode. Runs in terminal multiplexer tabs (Zellij/tmux) or Jules cloud pipelines with automatic pull request creation.
- **Smart Mutagen Inspector**: Automatically identifies project technology stacks (Go, Node, Python, Rust, Ruby, JVM, Wails desktop) and configures optimal ignore patterns.

---

## 4. 🚦 Quick Start

### Environment Health Check

Before beginning, run the built-in diagnostic tool to audit your local dependencies:

```bash
python configure.py --doctor
```

---

### Option A: Standalone / Local-First Mode (Default)

> **Best for**: Developers working directly in the Antigravity IDE on their local machine.

#### Step 1: Install Prerequisites

```bash
# macOS
brew install git python
# Ubuntu / Debian
sudo apt update && sudo apt install -y git python3 python3-pip
```

*(Optional: For Google Jules cloud delegation)*:
```bash
npm install -g @google/jules
jules login  # Browser authentication (or: export JULES_API_KEY="your-api-key")
brew install gh  # Optional: for automated PR merge
```

*(Optional: For FastMCP Kanban)*:
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
# Or via pip: pip install mcp pyyaml
```

#### Step 2: Install Plugin

```bash
# Global Antigravity plugin installation:
cd ~/.gemini/config/plugins/
git clone https://github.com/catclever/agy-disciple.git
```
*(Or clone into `.agents/plugins/agy-disciple` for project-scoped installation).*

#### Step 3: Configure Preset

```bash
cd agy-disciple
python configure.py --preset=standalone
```

#### Step 4: Start Developing

Launch Antigravity IDE. You can now chat naturally with your Lead Architect:
- *"Break down the user authentication feature and dispatch it to dev."*
- *"Dispatch this large database refactoring task to jules dev."*

---

### Option B: Remote Server Mode (Headless 24/7 Pipeline)

> **Best for**: Power users with a dedicated remote machine (Linux server, Mac mini, or cloud VPS) for 24/7 unattended autonomous development.

#### Step 1: Configure Remote Host (`~/.ssh/config`)

```ssh-config
Host my-server
    HostName 192.168.1.100
    User root
    IdentityFile ~/.ssh/id_rsa
```

#### Step 2: Install Server Dependencies

```bash
# Run on the remote server:
# 1. Install Zellij multiplexer
sudo apt update && sudo apt install -y zellij || cargo install --locked zellij
# 2. Authenticate agy CLI
agy auth login
# 3. Authenticate Jules CLI
npm install -g @google/jules && jules login
```

#### Step 3: Activate Server Preset

```bash
python configure.py --preset=server-centralized
```

#### Step 4: Dispatch Tasks

Tasks can be dispatched automatically via conversation or invoked from the CLI:

```bash
# Trigger Jules autonomous pipeline via SSH Heredoc (with pre-flight sync & autonomous defense):
ssh my-server 'bash -s' << 'EOF'
bash scripts/watchdogs/jules_watchdog.sh \
  -t auth_001 \
  -r owner/repo \
  -p 'Fix concurrency deadlock in user sessions' \
  -d /path/to/project \
  --autonomous \
  --auto-merge
EOF

# Or dispatch to resident agy agent session:
bash scripts/watchdogs/pve_watchdog.sh -t auth_001 -a dev -d /path/to/project -p "Implement Redis cache" -h my-server
```

---

## 5. 🎛️ Preset Switcher (`configure.py`)

`agy-disciple` includes an automated configuration manager to toggle between architectures:

```bash
# Display current active preset mapping
python configure.py --status

# Run full system diagnostics
python configure.py --doctor

# Set Standalone Local Preset (Local dev + In-repo metadata)
python configure.py --preset=standalone

# Set Remote Server Preset (Remote dev + Centralized metadata)
python configure.py --preset=server-centralized

# Fine-grained control:
python configure.py --topology=server    # Switch topology (local | server)
python configure.py --meta=centralized   # Switch metadata (in-repo | centralized)
```

---

## 6. 🧭 Production Watchdogs & Automation

Watchdog scripts live in `scripts/watchdogs/` and power headless execution:

- **`jules_watchdog.sh`**:
  - Handles Google Cloud Jules session lifecycle via REST API / CLI.
  - Implements **Git Pre-Flight Sync (`-d`)** and the **3-Layer Autonomous Defense System (`--autonomous`)**.
  - Polls session state and triggers auto-squash PR merge via `gh pr merge --squash`.
- **`pve_watchdog.sh`**:
  - Manages remote agent execution in dedicated Zellij tabs.
  - Monitors `/tmp/<Task_ID>.signal` for non-blocking asynchronous wakeup.

```bash
chmod +x scripts/watchdogs/*.sh
```

---

## 7. 📁 Repository Structure

```text
agy-disciple/
├── plugin.json                 # Antigravity plugin manifest
├── configure.py                # Preset switcher & doctor diagnostics
├── README.md                   # English documentation
├── README_zh.md                # 简体中文说明文档
├── LICENSE                     # MIT License
│
├── agents/                     # Sub-Agent prompt specifications
│   ├── dev.yaml                # Native Dev Agent (Draft suffix & sandbox tests)
│   ├── jules-dev.yaml          # Google Cloud Jules Dev Agent (Gemini 3.1 Pro)
│   ├── merger.yaml             # Merger Agent (Atomic .bak backup & file swap)
│   └── ops.yaml                # Ops Agent (Safe execution & command dictionary)
│
├── skills/                     # Modular engineering skills
│   ├── dev-manager/            # Dev engine orchestration (Local vs Server)
│   ├── project-manager/        # Metadata & task tracking (In-repo vs Centralized)
│   ├── task-breakdown/         # Task decomposition & two-track confirmation
│   ├── extract-knowledge/      # Knowledge extraction & Graveyard radar
│   ├── ops-manager/            # Operational script execution & tracking
│   ├── test-environment/      # Dev server & runtime preview management
│   ├── night-shift/            # Autonomous overnight handoff protocol
│   ├── pve-dispatch/           # Remote SSH execution routing
│   └── setup-mutagen/          # Smart language detection & Mutagen sync
│
├── mcp/                        # Model Context Protocol tools
│   └── kanban-task-manager/    # Standalone FastMCP task board server
│
└── scripts/
    ├── watchdogs/              # Production background watchdogs
    │   ├── jules_watchdog.sh   # Autonomous Google Jules cloud watchdog
    │   └── pve_watchdog.sh     # Remote SSH / agy CLI watchdog
    └── meta_resolver.py        # Centralized metadata path resolver
```

---

## 8. 🤝 Contributing

Contributions, feature requests, and bug reports are welcome!

1. Fork the Project: `git clone https://github.com/catclever/agy-disciple.git`
2. Create your Feature Branch: `git checkout -b feat/amazing-feature`
3. Commit your Changes: `git commit -m 'feat: add amazing feature'`
4. Push to the Branch: `git push origin feat/amazing-feature`
5. Open a Pull Request

---

## 9. 📄 License

Distributed under the **MIT License**. See [LICENSE](LICENSE) for more information.

<div align="center">

Made with ❤️ for the **Google Antigravity** community.

</div>

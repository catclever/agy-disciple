# agy-disciple 🚀

[English](README.md) | [简体中文](README_zh.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Antigravity](https://img.shields.io/badge/Antigravity-Plugin-purple.svg)](https://antigravity.google)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com)

> **面向 Google Antigravity (AGY) 的工业级多智能体协同研发团队插件**  
> 将单打独斗的 AI 助手转变为分工严谨、纪律完备的专业研发小队：主架构师、研发（支持本地与 Google Jules 双引擎）、合并与运维。

---

## 1. 📖 项目概述 (Overview)

传统的 AI 辅助编程通常采用“单单对话”模式。当开发者面对大型特性或复杂重构时，往往会遭遇几大致命瓶颈：
* **Google 的商业变现与模型断层**：Google 为了商业变现，在 Antigravity 客户端中直接砍掉了兼顾智商与性价比的 **Gemini 3.1 Pro**，只留下了 **Gemini 4 Argon（真正的“额度刺客”，深度思考 Token 极速烧穿配额）** 和 **Gemini 3.8 Flash（轻量廉价，但在复杂代码与重构推理上依然打不过 3.1 Pro）**。本地配额极易被重体力代码编写消耗殆尽；
* **沉睡的 Jules 宝藏无法利用**：许多开发者订阅了 Google Ultra ，账户里躺着大量极其充沛的 **Google Cloud Jules 额度**，但在 Antigravity 客户端内却**完全无法直接调用**，造成了巨大的算力闲置；
* **主会话上下文严重污染**：编译日志、单元测试报错和试错过程挤满上下文，迅速导致后续推理智商退化；
* **源码遭到意外破坏**：单 Agent 直接在原文件上大面积修改，极易导致语法破坏或关键逻辑丢失；
* **重复踩坑死循环**：缺乏负面知识沉淀，AI 在不同会话中往往反复尝试已被证实不可行的死胡同方案。

`agy-disciple`（**Antigravity 门徒**）通过**层级化多智能体工程工作流**破局：将本地会话塑造为沉稳调度全局的**主架构师**，直接打通这堵商业高墙——把具体重体力代码开发无缝分派给搭载了 **Gemini 3.1 Pro** 的 Google Cloud Jules，**充分利用 Ultra 订阅中充沛的 Jules 专属额度**，完全不烧本地 Antigravity 宝贵的 Token，并由草稿隔离法、双重知识库审查与数据看板提供全流程防错保护。

---

## 2. 🚦 快速开始 (Quick Start)

随时可通过内置的环境体检工具查看系统环境：
```bash
python configure.py --doctor
```

### 模式 A：本地单机模式 (Standalone / Local-First) —— 默认推荐
**适用对象**：在本地 Antigravity IDE 客户端中直接开发的大多数个人与团队，支持本地 Sub-Agent 与本地直接调用 Jules 云端算力。

1. **前置依赖安装（直接执行命令）**：
   * **基础运行环境 (Git & Python)**：
     ```bash
     # macOS
     brew install git python
     # Ubuntu / Debian
     sudo apt update && sudo apt install -y git python3 python3-pip
     ```
   * *(可选，用于 Jules 远程研发与额度套利)*：
     ```bash
     # 1. 安装官方 Jules CLI 工具
     npm install -g @google/jules

     # 2. 账号认证（二选一）：
     jules login   # 推荐：浏览器一键登录 Google 账号
     # 或直接导出 API Key（可写入 ~/.bashrc 或 ~/.zshrc 永久生效）：
     export JULES_API_KEY="your-api-key"

     # 3. (可选) 安装 GitHub CLI，用于 PR 自动合并
     brew install gh   # macOS
     # sudo apt install -y gh  # Linux
     ```
   * *(可选，用于任务看板 FastMCP 服务)*：
     ```bash
     # 推荐方式：安装 uv 工具
     curl -LsSf https://astral.sh/uv/install.sh | sh
     # 备选方式：直接 pip 安装依赖
     pip install mcp pyyaml
     ```
2. **安装插件**：
   ```bash
   cd ~/.gemini/config/plugins/
   git clone https://github.com/catclever/agy-disciple.git
   ```
   *(或克隆到具体项目的 `.agents/plugins/agy-disciple` 作为项目专属插件)*。
3. **开始使用**：
   ```bash
   cd agy-disciple
   python configure.py --preset=standalone
   ```
   在 Antigravity 对话框中自然交互：
   * *“帮我拆解这个登录功能，派发给 dev 编写草稿”*
   * *“把这个复杂重构派发给 jules dev”*

---

### 模式 B：远端服务器模式 (Remote Server & Jules Autonomous Mode)
**适用对象**：拥有独立远端服务器（如 Linux 服务器、Mac mini、家用主机或各类云 VPS 等）的用户，用于实现 7x24 小时全天候离线无人值守研发。

1. **前置依赖与环境配置（直接执行命令）**：
   * **步骤 1：本地 SSH 免密与别名配置 (`~/.ssh/config`)**：
     ```ssh-config
     Host my-server
         HostName 192.168.1.100       # 服务器局域网/公网 IP 或域名
         User root                    # 登录用户名（或日常账号）
         IdentityFile ~/.ssh/id_rsa   # 本地私钥路径
     ```
     测试免密连接：`ssh my-server`
   * **步骤 2：在服务器上安装终端复用器 (Zellij)**：
     ```bash
     # 在远端服务器上执行：
     # Linux (Ubuntu / Debian / CentOS)
     sudo apt update && sudo apt install -y zellij || cargo install --locked zellij
     # macOS (若将 Mac mini 用作独立构建服务器)
     brew install zellij
     ```
   * **步骤 3：在服务器上安装并认证 agy 命令行版**：
     ```bash
     # 在远端服务器上执行：安装 Antigravity CLI 并登录认证
     agy auth login
     ```
   * **步骤 4：在服务器上安装并认证 Jules**：
     ```bash
     # 在远端服务器上执行：
     npm install -g @google/jules
     jules login
     # 或直接写入环境变量并生效：
     echo 'export JULES_API_KEY="your-api-key"' >> ~/.bashrc && source ~/.bashrc
     ```
2. **激活服务器预设**：
   ```bash
   python configure.py --preset=server-centralized
   ```
3. **配置与调度看门狗脚本 (Watchdogs)**：
   看门狗脚本位于仓库的 `scripts/watchdogs/` 目录下，支持**智能体全自动托管**与**开发者手动执行**双轨调度：
   * **放置与就位**：
     * 确保本地或服务器上的脚本已赋予可执行权限：
       ```bash
       chmod +x scripts/watchdogs/*.sh
       ```
     * *(可选建议)*：将看门狗脚本软链接至用户全局 PATH 或集中式脚本目录（如 `~/.gemini/config/scripts/`），方便随处直接调用。
   * **运行方式 1：Antigravity 智能体全自动调度（推荐）**：
     在 Antigravity 对话框中，无需您手动敲命令，主架构师或 `night-shift` / `pve-dispatch` 技能在识别到需要夜间研发或服务器执行时，**会自动在后台远程唤醒并监控看门狗脚本**：
     * *“今晚下班后，把这个数据导出模块挂到服务器上跑，自测通过后自动合并”*
     * *“将这个重构任务派发给远端服务器的 Jules 进行夜间自主流水线开发”*
   * **运行方式 2：终端手动或 CI 流水线直接执行（备用）**：
     开发者亦可在本地终端直接执行脚本进行调试或集成到自动化流程：
     ```bash
     # 方式 A：从本地触发远端服务器派发至 Google Jules 云端流水线
     ssh my-server "bash scripts/watchdogs/jules_watchdog.sh -t auth_001 -r owner/repo -p '修复并发锁漏洞' --auto-merge"

     # 方式 B：派发至服务器常驻的 agy 智能体自执行会话
     bash scripts/watchdogs/pve_watchdog.sh -t auth_001 -a dev -d /path/to/project -p "实现 Redis 缓存" -h my-server
     ```

---

## 3. ⚡ 核心能力 (What agy-disciple Delivers)

### ★ 1. 核心王牌：Jules 远程研发与额度套利 (Gemini 3.1 Pro 赋能)
* **痛点直击（拒绝含蓄）**：
  * Google 为了追求商业利润，在 Antigravity 客户端中移除了最均衡实用的 **Gemini 3.1 Pro**；
  * 客户端内仅剩 **Gemini 4 Argon（真正的额度刺客，深度思考 Token 极速烧穿账单）** 和 **Gemini 3.8 Flash（廉价但复杂推理依然打不过 3.1 Pro）**；
  * 与此同时，开通了 Google Ultra 订阅的用户，账户里拥有**极其充沛的 Google Cloud Jules 专属额度**，却因为 Antigravity 官方闭环限制而**根本无法直接在开发中利用**！
* **破局利器（额度套利与算力解放）**：
  * **白嫖/唤醒 Ultra 沉睡额度**：通过 `agy-disciple`，将重体力开发任务外包给 Google Cloud Jules，直接榨干 Ultra 赠送的丰富云端配额，**完全不烧本地 Antigravity 昂贵的 4 Argon Token**！
  * **迎回 Gemini 3.1 Pro 真正智商**：Jules 标配 **Gemini 3.1 Pro**，在跨文件代码重构、架构理解和单元测试上全面碾压 3.8 Flash，代码质量断层领先；
  * **双部署形态（灵活选择）**：
    * *单机本地模式*：直接在本地调用 `scripts/watchdogs/jules_watchdog.sh`，读取本地 API Key 并发给 Jules；
    * *远端服务器模式*：通过 SSH 挂在独立服务器（Linux / Mac mini / 云主机）后台，作为 24 小时不间断的夜班看门狗。
  * **自动化云端 PR**：Jules 在云端虚拟机中自检代码并直接在 GitHub 上创建 Pull Request，支持配合 `gh pr merge --squash` 实现全自动合并。

### 2. 草稿后缀隔离法 (Draft Suffix Rule)
本地 `dev` 智能体在修改代码时，被严格禁止直接修改原始源码。所有改动必须创建带任务后缀的独立草稿文件（如 `api_task_auth_001.py`）：
* **原生 IDE 生态保留**：保持完整文件扩展名，IDE 语法高亮、自动补全、ESLint / Ruff 代码检查不受任何影响；
* **零污染零破坏**：在自测通过前，原版生产代码处于 100% 保护状态，互不干扰；
* **极速无损回滚**：如果方案不合格，直接删除草稿即可，工作树完全干净。

### 3. 双重知识库审查与防坑公墓 (Graveyard Radar)
* **活跃知识库 (`kb/knowledge.md`)**：仅收录已经拍板生效的硬核架构规范、数据表结构 (Schema) 与通信协议；
* **防坑公墓 (`kb/graveyard/grave.md`)**：专门沉淀**负面知识**（失败方案记录、技术死胡同、根因剖析与避坑教训）；
* **公墓雷达扫描**：主架构师在向用户汇报或输出方案前，强制触发双重审查，一旦发现方案命中历史公墓，立刻内部重构，彻底杜绝重蹈覆辙。

### 4. 自适应看板引擎 (Adaptive Kanban Engine)
* **MCP 优先**：如果当前环境已注册配套的 `kanban-task-manager` MCP 服务，享受强状态约束看板与 Antigravity 会话可点击跳转 (`conversation://<uuid>`)；
* **原生降级 (零配置)**：如果未配置 MCP，主架构师自动平滑降级为读写项目内的 Markdown 任务卡片（`tasks/*.md`），无需任何额外依赖。

---

## 4. 🏛️ 核心架构与职责分工 (Core Architecture)

```
                       ┌────────────────────────────────┐
                       │      主架构师 (Main Agent)      │
                       │  • 需求拆解与两轨确认机制      │
                       │  • 双重知识库审查与公墓雷达    │
                       │  • 数据看板管理与 DoD 门禁     │
                       └───────────────┬────────────────┘
                                       │
         ┌─────────────────────────────┼─────────────────────────────┐
         ▼                             ▼                             ▼
┌─────────────────────────┐   ┌─────────────────┐           ┌─────────────────┐
│     研发执行智能体      │   │   合并智能体    │           │   运维智能体    │
│    [双研发引擎支持]     │   │(`merger` Agent) │           │  (`ops` Agent)  │
│ ┌─────────────────────┐ │   │ • 原子化备份    │           │ • 高成本执行    │
│ │ 引擎A: 本地 dev     │ │──►│ • 安全替换草稿  │           │ • 强制命令字典  │
│ ├─────────────────────┤ │   │ • 不含业务逻辑  │           │ • 真实宿主环境  │
│ │ 引擎B: Jules (3.1P) │ │   └─────────────────┘           └─────────────────┘
│ └─────────────────────┘ │
└─────────────────────────┘
```

### 团队角色
1. **主架构师 (Lead Architect / Main Agent)**：顶层系统设计、方案确认、任务拆解与最终 DoD 验收。
2. **研发执行智能体 (Dev Sub-Agent)**：
   * **引擎 A (本地 `dev`)**（[agents/dev.yaml](agents/dev.yaml)）：在 Antigravity 内部以沙盒草稿模式快速编码与自测；
   * **引擎 B (Google Jules `jules-dev`)**（[agents/jules-dev.yaml](agents/jules-dev.yaml)）：派发至 Google Cloud Jules 云端 VM，依托 **Gemini 3.1 Pro** 深度思考，不耗费 Antigravity Token。
3. **合并智能体 (`merger` Sub-Agent)**（[agents/merger.yaml](agents/merger.yaml)）：创建 `.bak` 备份并原子化替换草稿，不包含业务逻辑。
4. **运维智能体 (`ops` Sub-Agent)**（[agents/ops.yaml](agents/ops.yaml)）：负责执行高成本、非幂等的宿主环境操作，强制核对命令字典。

---

## 5. 🎛️ 双模系统与模式切换 (Dual-Mode System)

`agy-disciple` 支持在本地单机与远端服务器之间随时一键切换：

```bash
# 查看当前激活状态
python configure.py --status

# 诊断本地与远端环境依赖
python configure.py --doctor

# 切换为默认单机模式 (In-Repo)
python configure.py --preset=standalone

# 切换为服务器模式 (Remote Server / Centralized)
python configure.py --preset=server-centralized
```

---

## 6. 🧭 MCP 服务与脚本放置规范指南

### 1. MCP 看板服务放哪里？
* **仓库内源码**：自带的 FastMCP 看板服务源码位于 [mcp/kanban-task-manager/server.py](mcp/kanban-task-manager/server.py)。
* **全局注册**：在全局配置文件 `~/.gemini/config/mcp_config.json` 注册：
  ```json
  {
    "mcpServers": {
      "kanban-task-manager": {
        "command": "uv",
        "args": [
          "run",
          "/绝对路径/agy-disciple/mcp/kanban-task-manager/server.py"
        ]
      }
    }
  }
  ```
* **界面添加方式**：亦可在 Antigravity IDE 右上角 **... (More) > MCP Servers > Add Server** 中填入上述命令。

### 2. 自定义脚本放哪里？
* **项目内脚本**：所有看门狗与调度工具均保存在仓库的 `scripts/` 目录下：
  - `scripts/watchdogs/jules_watchdog.sh`：Google Cloud Jules 云端流水线看门狗。
  - `scripts/watchdogs/pve_watchdog.sh`：远端服务器调度看门狗。
  - `scripts/meta_resolver.py`：集中式元数据路径寻址器。
* **全局快捷调用建议（可选）**：
  ```bash
  mkdir -p ~/.gemini/config/scripts
  ln -sf $(pwd)/scripts/watchdogs/jules_watchdog.sh ~/.gemini/config/scripts/
  ln -sf $(pwd)/scripts/watchdogs/pve_watchdog.sh ~/.gemini/config/scripts/
  ```

---

## 7. 📁 完整项目文件结构与许可证

```text
agy-disciple/
├── plugin.json                 # Antigravity 插件配置清单
├── README.md                   # 英文主文档
├── README_zh.md                # 简体中文文档
├── LICENSE                     # MIT 开源协议
├── configure.py                # 模式与变体一键切换工具 (含 --doctor)
│
├── agents/                     # Sub-Agents 定义
│   ├── dev.yaml                # 本地研发 Agent (草稿隔离法、沙盒自测)
│   ├── jules-dev.yaml          # Google Cloud Jules 研发 Agent (Gemini 3.1 Pro)
│   ├── merger.yaml             # 合并 Agent (安全备份、原子替换)
│   └── ops.yaml                # 运维 Agent (安全运维、命令字典)
│
├── skills/                     # 核心与进阶技能套件
│   ├── dev-manager/            # 研发流程调度 (支持 local / server / jules 引擎)
│   ├── project-manager/        # 项目元数据与看板管理 (in-repo / centralized)
│   ├── task-breakdown/         # 需求粒度拆解与两轨确认
│   ├── extract-knowledge/      # 知识提取与防坑公墓
│   ├── ops-manager/            # 运维脚本安全执行
│   ├── test-environment/      # 测试服务管理
│   ├── night-shift/            # 离线夜班自主接力
│   ├── pve-dispatch/           # 远端服务器与多机任务分发
│   └── setup-mutagen/          # 智能语言检测与 Mutagen 双向同步
│
├── mcp/                        # 配套 MCP 服务源码
│   └── kanban-task-manager/    # 任务看板 FastMCP 服务端
│
└── scripts/
    ├── watchdogs/              # 生产级自动化看门狗
    │   ├── jules_watchdog.sh   # Google Jules 云端流水线看门狗
    │   └── pve_watchdog.sh     # 远端 SSH / agy CLI 看门狗
    └── meta_resolver.py        # 集中式元数据路径解析工具
```

本项目基于 [MIT License](LICENSE) 协议开源。

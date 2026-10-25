# agy-disciple 🚀

<div align="center">

**面向 Google Antigravity (AGY) 的工业级多智能体协同研发团队插件**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/catclever/agy-disciple?style=flat&color=yellow)](https://github.com/catclever/agy-disciple/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/catclever/agy-disciple?style=flat&color=orange)](https://github.com/catclever/agy-disciple/network/members)
[![GitHub Issues](https://img.shields.io/github/issues/catclever/agy-disciple?style=flat&color=red)](https://github.com/catclever/agy-disciple/issues)
[![Antigravity](https://img.shields.io/badge/Antigravity-Plugin-purple.svg)](https://antigravity.google)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/catclever/agy-disciple/pulls)

[English](README.md) | [简体中文](README_zh.md)

</div>

---

> **将单打独斗的 AI 助手转变为分工严谨、纪律完备的专业研发工程小队：**  
> **主架构师** 🏛️ &nbsp;•&nbsp; **研发智能体 (Dev)** 💻 &nbsp;•&nbsp; **代码合并器 (Merger)** 🔀 &nbsp;•&nbsp; **运维智能体 (Ops)** ⚙️

---

## 📑 目录导航

- [1. 为什么选择 agy-disciple？](#1-为什么选择-agy-disciple)
  - [痛点直击：单智能体研发瓶颈](#痛点直击单智能体研发瓶颈)
  - [核心能力对比表](#核心能力对比表)
- [2. 🏛️ 团队架构概览](#2-️-团队架构概览)
  - [专业研发工程小队](#专业研发工程小队)
- [3. ⚡ 五大核心王牌能力](#3--五大核心王牌能力)
  - [1. Jules 云端研发与算力套利 (Gemini 3.1 Pro 赋能)](#1-jules-云端研发与算力套利-gemini-31-pro-赋能)
  - [2. 草稿后缀隔离法 (源码零破坏)](#2-草稿后缀隔离法-源码零破坏)
  - [3. 双重知识库审查与死胡同雷达 (Graveyard Radar)](#3-双重知识库审查与死胡同雷达-graveyard-radar)
  - [4. 数据驱动的 FastMCP 任务看板](#4-数据驱动的-fastmcp-任务看板)
  - [5. 7x24 小时无人值守夜班与智能 Mutagen 同步](#5-7x24-小时无人值守夜班与智能-mutagen-同步)
- [4. 🚦 快速开始](#4--快速开始)
  - [环境健康检查](#环境健康检查)
  - [模式 A：本地单机模式 (Standalone / Local-First) —— 默认推荐](#模式-a本地单机模式-standalone--local-first--默认推荐)
  - [模式 B：远端服务器模式 (Remote Server & 离线自主研发)](#模式-b远端服务器模式-remote-server--离线自主研发)
- [5. 🎛️ 架构预设切换器 (`configure.py`)](#5-️-架构预设切换器-configurepy)
- [6. 🧭 工业级看门狗与自动化流水线](#6--工业级看门狗与自动化流水线)
- [7. 📁 仓库代码结构](#7--仓库代码结构)
- [8. 🤝 参与贡献](#8--参与贡献)
- [9. 📄 开源许可证](#9--开源许可证)

---

## 1. 为什么选择 agy-disciple？

### 痛点直击：单智能体研发瓶颈

在面对中大型工程或复杂重构时，传统的单 Agent 辅助编程模式暴露出多项致命瓶颈：

1. **Google 的商业变现与模型断层**：Google 为了商业利益，在 Antigravity IDE 客户端中直接下架了表现最为均衡的 **Gemini 3.1 Pro**。开发者被卡在两极之间：
   - **Gemini 4 Argon**：真正的“额度刺客”，其深度思考 Token 会在短时间内迅速烧穿每月的配额上限；
   - **Gemini 3.8 Flash**：轻量且便宜，但在处理多文件协同重构和严谨架构推理时，表现显著落后于 3.1 Pro。
2. **沉睡的 Jules 算力宝藏无法调用**：大量订阅了 **Google Ultra** 的开发者，账户中拥有海量极其充沛的 **Google Cloud Jules 专属额度**（云端原生运行 Gemini 3.1 Pro），但在 Antigravity 客户端内却没有任何官方通道可以直接调用，造成巨大算力闲置浪费。
3. **主对话上下文严重污染**：编译错误、海量测试堆栈以及反复试错的过程塞满上下文，导致模型后期注意力涣散、智商骤降。
4. **原生产源码破坏风险**：单一 Agent 直接在生产源文件上试错修改，极易导致语法毁损、逻辑缺失甚至未经提交就丢失可用状态。
5. **在死胡同里循环踩坑**：由于缺乏对失败经验的系统沉淀，AI 在不同会话中往往反复尝试已被证实不可行的旧方案。

### 核心能力对比表

| 维度对比 | 原生 Antigravity 单 Agent | 搭载 `agy-disciple` 团队插件 |
| :--- | :--- | :--- |
| **模型调度策略** | 仅能在 4 Argon（贵）与 3.8 Flash（弱）二选一 | **双引擎自由调度**：本地原生 Dev + **Jules 云端 (Gemini 3.1 Pro)** |
| **Token 消耗** | 重体力编写消耗高昂的本地 IDE 深度思考配额 | 云端派发直接消耗 Ultra 专属额度，**本地 Token 零消耗** |
| **代码写入模式** | 原文件直接就地覆写（极易破坏生产源码） | **草稿后缀隔离法** (`*_task_<id>.*`)，辅以 `.bak` 原子回退 |
| **任务追踪** | 对话流中的临时记忆，刷新或分流即丢失 | **数据驱动看板**（支持 FastMCP 协议及 Markdown 本地双轨降级） |
| **避坑与经验** | 遗忘失败历史，反复尝试已知不可行方案 | **死胡同雷达 (`grave.md`)** 在提出方案前强制审计，杜绝复错 |
| **离线研发支持** | 关盖即停、断网即止 | **远端服务器常驻与无头云端流水线**，支持睡醒直接 `git pull` 合并 |
| **基线对齐保障** | 本地与云端基线易产生分叉冲突 | **Git 预检对齐 (`-d`)** 与 **全自主三重防御体系 (`--autonomous`)** |

---

## 2. 🏛️ 团队架构概览

`agy-disciple` 构建了一套清晰严密、权责分明的层级化工程小队：

```text
                       ┌─────────────────────────────────────────┐
                       │          主架构师 (Lead Architect)       │
                       │  • 任务原子拆解与方案双轨确认门禁       │
                       │  • 双重知识库审计与死胡同防错雷达       │
                       │  • 数据看板管理与 Definition-of-Done    │
                       └────────────────────┬────────────────────┘
                                            │
          ┌─────────────────────────────────┼─────────────────────────────────┐
          ▼                                 ▼                                 ▼
┌───────────────────────────┐   ┌───────────────────────┐   ┌───────────────────────────┐
│     研发智能体 (Dev)      │   │    代码合并器 (Merger)  │   │     运维智能体 (Ops)      │
│   [支持双研发引擎自由调度] │   │  • 草稿安全替换       │   │  • 非幂等/高成本脚本执行   │
│ ┌───────────────────────┐ │   │  • .bak 原子备份回退  │   │  • 命令执行字典强制记录   │
│ │ 引擎 A: 本地原生 Dev  │ │──►│  • 纯净替换，不碰业务 │   │  • 宿主机部署与 Mutagen   │
│ ├───────────────────────┤ │   └───────────────────────┘   └───────────────────────────┘
│ │ 引擎 B: Jules 云端 VM │ │
│ └───────────────────────┘ │
└───────────────────────────┘
```

### 专业研发工程小队

1. **主架构师 (Lead Architect / 主会话)**：负责高层方案设计、需求拆解、与用户沟通确认、死胡同雷达审查以及交付验收（DoD）把关。
2. **研发智能体 (Dev Sub-Agent)** ([agents/dev.yaml](agents/dev.yaml))：
   - **引擎 A (本地原生 Dev)**：在本地沙箱环境内编写代码与单元测试。
   - **引擎 B (Google Jules Dev)** ([agents/jules-dev.yaml](agents/jules-dev.yaml))：通过看门狗派发至 Google Cloud Jules 云端虚拟机，搭载 **Gemini 3.1 Pro** 纯算力运作。
3. **代码合并器 (Merger Sub-Agent)** ([agents/merger.yaml](agents/merger.yaml))：在草稿验证通过后，负责生成 `.bak` 备份并执行原子文件替换，确保源码始终可用。
4. **运维智能体 (Ops Sub-Agent)** ([agents/ops.yaml](agents/ops.yaml))：负责执行多环境代码同步、原生构建打包与发布部署，强制维护全局命令字典。

---

## 3. ⚡ 五大核心王牌能力

### 1. Jules 云端研发与算力套利 (Gemini 3.1 Pro 赋能)
- **额度套利**：将重体力代码编写无缝分流至 Google Cloud Jules，大量消耗 Ultra 会员内用不完的 Jules 额度，**保护您本地宝贵的 Antigravity 4 Argon 额度不被消耗**！
- **重拾 3.1 Pro 真正智商**：Jules 原生基于 **Gemini 3.1 Pro** 构建，在大规模跨文件重构与复杂逻辑实现上远超 3.8 Flash。
- **Git 预检对齐机制 (`-d <dir>`)**：派发前自动检测工作区变动，自动提交未存脏树、拉取远端更新、Rebase 对齐并推送，彻底杜绝本地与云端代码基线不同步问题。
- **全自主三重防御体系 (`--autonomous`)**：
  - *防御 1 (规划免审)*：建联阶段注入 `requirePlanApproval=false`，抑制无谓规划卡点；
  - *防御 2 (方案代签)*：轮询遇 `AWAITING_PLAN_APPROVAL` 时，自动调用 `:approvePlan` 接口批准执行；
  - *防御 3 (智能代答)*：轮询遇 `AWAITING_USER_FEEDBACK` 质询时，自动调用 `:sendMessage` 发送最佳实践指令打破死锁（上限 3 次）。
- **开箱即用默认原生，按需显式唤醒**：所有模式**默认始终优先调度本地/服务器的原生 `dev` / `agy` 智能体**（零配置即可运行）；只有当您在对话中显式要求使用 Jules 时（如：“*派发给 jules dev*”），主架构师才会唤醒 Jules 云端研发流水线。

### 2. 草稿后缀隔离法 (源码零破坏)
本地研发智能体严禁直接碰触原文件：
- **后缀规则**：所有变更均生成独立任务草稿（例如对 `router.py` 修改生成 `router_task_auth_001.py`）；
- **IDE 体验无缝保留**：保留完整的文件拓展名，语法高亮、Linter 提示与类型检查完全正常运作；
- **原子回滚能力**：一旦方案在测试中失败，直接丢弃草稿即可，主干代码毫发无损。

### 3. 双重知识库审查与死胡同雷达 (Graveyard Radar)
- **正面知识库 (`kb/knowledge.md`)**：收录经过验证的架构图解、数据字典与 API 规范。
- **死胡同坟场 (`kb/graveyard/grave.md`)**：系统性记录所有失败的尝试、弃用的方案与架构死胡同。
- **方案提出前置审查**：主架构师在向用户或小弟提出任何实施方案前，必须自动雷达扫描 Graveyard，杜绝历史性错误反复上演。

### 4. 数据驱动的 FastMCP 任务看板
- **MCP 优先调度**：无缝对接自带的独立 FastMCP 任务看板 ([mcp/kanban-task-manager/](mcp/kanban-task-manager/))，支持严格的任务状态约束与可点击的会话深层链接 (`conversation://<uuid>`)。
- **纯本地优雅降级**：在未配置 MCP 的环境下，全自动降级为直接管理 `tasks/*.md` Markdown 卡片。

### 5. 7x24 小时无人值守夜班与智能 Mutagen 同步
- **夜班移交协议 (Night Shift)**：下班或离线前一键将待办任务队列交接给远端复用器（Zellij/tmux）或 Jules 云端流水线，自动在 GitHub 上发起 Pull Request 并可选全自动 Merge。
- **智能语言生态检查器**：自动识别 Go、Node、Python、Rust、Ruby、JVM 以及 **Wails 桌面端**，自动生成最佳忽略规则，彻底避免打包中间产物回传造成 I/O 拥塞。

---

## 4. 🚦 快速开始

### 环境健康检查

开始前，随时可以执行内置的健康诊断工具审计当前机器依赖：

```bash
python configure.py --doctor
```

---

### 模式 A：本地单机模式 (Standalone / Local-First) —— 默认推荐

> **适用场景**：绝大多数在本地电脑使用 Antigravity IDE 客户端进行日常编码的个人与团队。

#### 步骤 1：安装前置依赖

```bash
# macOS
brew install git python
# Ubuntu / Debian
sudo apt update && sudo apt install -y git python3 python3-pip
```

*(可选：用于调用 Google Jules 云端研发)*：
```bash
npm install -g @google/jules
jules login  # 浏览器授权登录（或 export JULES_API_KEY="your-api-key"）
brew install gh  # 可选：用于 PR 自动合并
```

*(可选：用于任务看板 FastMCP 服务)*：
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
# 或直接通过 pip 安装：pip install mcp pyyaml
```

#### 步骤 2：安装插件

```bash
# 安装到 Antigravity 全局插件目录：
cd ~/.gemini/config/plugins/
git clone https://github.com/catclever/agy-disciple.git
```
*(亦可直接克隆到目标项目根目录的 `.agents/plugins/agy-disciple` 作为单项目专用插件)*。

#### 步骤 3：激活预设

```bash
cd agy-disciple
python configure.py --preset=standalone
```

#### 步骤 4：在 Antigravity 中开始开发

打开 Antigravity IDE，插件已就绪。在对话框中自然交流即可调度团队：
- *“帮我拆解用户注册登录模块，派发给 dev 编写草稿”*
- *“将这个复杂的跨文件重构派发给 jules dev”*

---

### 模式 B：远端服务器模式 (Remote Server & 离线自主研发)

> **适用场景**：拥有常驻远端服务器（Linux 主机、Mac mini 或各类云服务器）的用户，实现全天候离线无人值守开发。

#### 步骤 1：配置 SSH 免密登录 (`~/.ssh/config`)

```ssh-config
Host my-server
    HostName 192.168.1.100
    User root
    IdentityFile ~/.ssh/id_rsa
```

#### 步骤 2：在服务器安装依赖

```bash
# 在远端服务器上执行：
# 1. 安装 Zellij 终端复用器
sudo apt update && sudo apt install -y zellij || cargo install --locked zellij
# 2. 登录认证 agy 命令行版
agy auth login
# 3. 登录认证 Jules 命令行版
npm install -g @google/jules && jules login
```

#### 步骤 3：激活服务器预设

```bash
python configure.py --preset=server-centralized
```

#### 步骤 4：调度看门狗脚本

看门狗可通过对话自然调度，亦可在终端直接执行：

```bash
# 方式 A：通过 SSH Heredoc 派发至 Google Jules 云端流水线 (支持预检与全自主防御)
ssh my-server 'bash -s' << 'EOF'
bash scripts/watchdogs/jules_watchdog.sh \
  -t auth_001 \
  -r owner/repo \
  -p '修复并发锁死锁漏洞' \
  -d /path/to/project \
  --autonomous \
  --auto-merge
EOF

# 方式 B：派发至服务器常驻的 agy 智能体自执行会话
bash scripts/watchdogs/pve_watchdog.sh -t auth_001 -a dev -d /path/to/project -p "实现 Redis 缓存" -h my-server
```

---

## 5. 🎛️ 架构预设切换器 (`configure.py`)

`agy-disciple` 提供了一体化配置管理脚本，方便在本地模式与远端服务器模式之间瞬间无缝切换：

```bash
# 查看当前激活的技能与预设映射状态
python configure.py --status

# 运行完整环境诊断
python configure.py --doctor

# 切换为本地单机预设（本地 Dev + 代码库内元数据）
python configure.py --preset=standalone

# 切换为远端服务器预设（远端服务器调度 + 集中式元数据）
python configure.py --preset=server-centralized

# 精细化维度调整：
python configure.py --topology=server    # 仅调整运行拓扑 (local | server)
python configure.py --meta=centralized   # 仅调整元数据模式 (in-repo | centralized)
```

---

## 6. 🧭 工业级看门狗与自动化流水线

看门狗脚本位于 `scripts/watchdogs/`，为长周期研发保驾护航：

- **`jules_watchdog.sh`**：
  - 通过 REST API / CLI 托管 Google Cloud Jules 会话全生命周期；
  - 集成 **Git 预检对齐机制 (`-d`)** 与 **全自主三重防御体系 (`--autonomous`)**；
  - 自动轮询会话状态，并在验证通过后配合 GitHub CLI 自动完成 Squash 合并。
- **`pve_watchdog.sh`**：
  - 在远端服务器的独立 Zellij 标签页中拉起 `agy` 进程；
  - 轮询监控 `/tmp/<Task_ID>.signal` 信号文件，完成异步事件唤醒。

```bash
chmod +x scripts/watchdogs/*.sh
```

---

## 7. 📁 仓库代码结构

```text
agy-disciple/
├── plugin.json                 # Antigravity 插件配置清单
├── configure.py                # 预设切换器与体检诊断脚本 (--doctor)
├── README.md                   # 英文说明文档
├── README_zh.md                # 简体中文说明文档
├── LICENSE                     # MIT 开源许可证
│
├── agents/                     # 智能体 Prompt 角色规范
│   ├── dev.yaml                # 原生研发智能体 (草稿后缀与沙箱验证)
│   ├── jules-dev.yaml          # Google Cloud Jules 研发智能体 (Gemini 3.1 Pro)
│   ├── merger.yaml             # 合并智能体 (.bak 备份与原子文件替换)
│   └── ops.yaml                # 运维智能体 (命令字典记录与安全执行)
│
├── skills/                     # 模块化工程技能库
│   ├── dev-manager/            # 研发引擎调度 (本地 / 远端服务器)
│   ├── project-manager/        # 项目元数据与看板 (代码库内 / 集中式)
│   ├── task-breakdown/         # 任务原子拆解与双轨方案确认
│   ├── extract-knowledge/      # 知识沉淀与坟场雷达扫描
│   ├── ops-manager/            # 生产脚本与部署管控
│   ├── test-environment/      # 测试服务与预览环境管理
│   ├── night-shift/            # 离线无人值守夜班协议
│   ├── pve-dispatch/           # 远端服务器 SSH 调度分流
│   └── setup-mutagen/          # 智能生态识别与 Mutagen 同步初始化
│
├── mcp/                        # Model Context Protocol 工具服务
│   └── kanban-task-manager/    # 独立 FastMCP 任务看板服务端
│
└── scripts/
    ├── watchdogs/              # 工业级后台看门狗脚本
    │   ├── jules_watchdog.sh   # Google Cloud Jules 自主看门狗
    │   └── pve_watchdog.sh     # 远端 SSH / agy CLI 看门狗
    └── meta_resolver.py        # 集中式元数据路径解析器
```

---

## 8. 🤝 参与贡献

欢迎提出 Issue、提交 PR 或提出新功能设想！

1. Fork 本仓库：`git clone https://github.com/catclever/agy-disciple.git`
2. 创建您的特性分支：`git checkout -b feat/my-feature`
3. 提交代码变更：`git commit -m 'feat: add some feature'`
4. 推送至远端分支：`git push origin feat/my-feature`
5. 在 GitHub 上发起 Pull Request

---

## 9. 📄 开源许可证

本项目基于 **MIT License** 开源。详情参见 [LICENSE](LICENSE) 文件。

<div align="center">

Made with ❤️ for the **Google Antigravity** community.

</div>

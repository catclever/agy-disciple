# agy-disciple 🚀

[English](README.md) | [简体中文](README_zh.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Antigravity](https://img.shields.io/badge/Antigravity-Plugin-purple.svg)](https://antigravity.google)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com)

> **面向 Google Antigravity (AGY) 的工业级多智能体协同研发团队插件**  
> 将单打独斗的 AI 助手转变为分工严谨、纪律完备的专业研发小队：主架构师、研发、合并与运维。

---

## 📖 项目简介

传统的 AI 辅助编程通常采用“单单对话”模式。当面对较复杂的项目重构或多文件特性开发时，单智能体往往会陷入以下痛点：
1. **上下文严重污染**：编译报错、排错尝试与大量冗余日志挤占上下文窗口，导致后续推理智力下降；
2. **源码意外损坏**：AI 直接在生产源文件上“大刀阔斧”修改，极易导致语法破坏、误删关键逻辑；
3. **重复踩坑死循环**：缺乏负面知识沉淀，AI 在不同会话中往往反复尝试已经被证实不可行的死胡同方案。

`agy-disciple`（**Antigravity 门徒**）为 Antigravity 带来了一套**层级化多智能体工程研发工作流**。它通过严格的职责边界、草稿后缀隔离协议、双重知识库审查以及数据看板驱动，将 AI 研发变成一套可预测、可审计、零破坏的现代流水线。

---

## 🏛️ 核心架构与职责分工

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
┌─────────────────┐           ┌─────────────────┐           ┌─────────────────┐
│   研发智能体    │           │   合并智能体    │           │   运维智能体    │
│  (`dev` Agent)  │           │(`merger` Agent) │           │  (`ops` Agent)  │
│ • 沙盒编写与自测│           │ • 原子化备份    │           │ • 高成本执行    │
│ • 草稿后缀隔离法│──drafts──►│ • 安全替换草稿  │           │ • 强制命令字典  │
│ • 严禁触碰原代码│           │ • 不含业务逻辑  │           │ • 真实宿主环境  │
└─────────────────┘           └─────────────────┘           └─────────────────┘
```

### 1. 团队角色
* **主架构师 (Lead Architect / Main Agent)**：顶层系统设计、需求粒度拆解、双重知识库验证、用户决策对齐以及代码入库的最终 DoD 验收。
* **研发智能体 (`dev` Sub-Agent)**（[agents/dev.yaml](agents/dev.yaml)）：专注于具体业务代码编写与沙盒测试。**严格禁止直接修改原始源码**。
* **合并智能体 (`merger` Sub-Agent)**（[agents/merger.yaml](agents/merger.yaml)）：仅负责自动创建 `.bak` 备份并原子化重命名草稿替换原文件，不包含任何业务逻辑。
* **运维智能体 (`ops` Sub-Agent)**（[agents/ops.yaml](agents/ops.yaml)）：负责执行高成本、非幂等的宿主环境操作（数据生成、部署构建、Git 操作），强制核对命令字典。

---

## ⚡ 核心工程创新

### 1. 草稿后缀隔离法 (Draft Suffix Rule)
`dev` 智能体在修改代码时，必须将改动生成为带有任务后缀的独立草稿文件（例如修改 `api.py` 时生成 `api_task_auth_001.py`）：
* **原生 IDE 生态保留**：保持完整文件扩展名，IDE 语法高亮、自动补全、ESLint / Ruff 代码检查不受任何影响；
* **零污染零破坏**：在自测通过前，原版生产代码处于 100% 保护状态，互不干扰；
* **极速无损回滚**：如果方案不合格，直接删除草稿即可，工作树完全干净。

### 2. 双重知识库审查与防坑公墓 (Graveyard Radar)
* **活跃知识库 (`kb/knowledge.md`)**：仅收录已经拍板生效的硬核架构规范、数据表结构 (Schema) 与通信协议；
* **防坑公墓 (`kb/graveyard/grave.md`)**：专门沉淀**负面知识**（失败方案记录、技术死胡同、根因剖析与避坑教训）；
* **公墓雷达扫描**：主架构师在向用户汇报或输出方案前，强制触发双重审查，一旦发现方案命中历史公墓，立刻内部重构，彻底杜绝重蹈覆辙。

### 3. 自适应看板引擎 (Adaptive Kanban Engine)
* **MCP 优先**：如果当前环境已注册配套的 `kanban-task-manager` MCP 服务，享受强状态约束看板与 Antigravity 会话可点击跳转 (`conversation://<uuid>`)；
* **原生降级 (零配置)**：如果未配置 MCP，主架构师自动平滑降级为读写项目内的 Markdown 任务卡片（`tasks/*.md`），无需任何额外依赖。

---

## 🚦 快速上手：双工作流模式与环境指引

在开始前，可先运行内置的环境诊断体检：
```bash
python configure.py --doctor
```

### 模式一：本地单机模式 (Standalone / Local-First) —— 默认推荐
**适用对象**：在本地 Antigravity IDE 客户端中直接开发的大多数个人与团队。

#### 1. 前置依赖
* **Git** (`git`)
* **Python** (>= 3.8)
* *无需安装任何其他 CLI 命令行工具或云服务器！*

#### 2. 安装插件
克隆到您的全局插件目录：
```bash
cd ~/.gemini/config/plugins/
git clone https://github.com/<your-username>/agy-disciple.git
```
*(或克隆到具体项目的 `.agents/plugins/agy-disciple` 作为项目专属插件)*。

#### 3. 开始使用
1. 在 Antigravity IDE 中打开您的项目代码；
2. 确认当前为单机模式预设：
   ```bash
   python configure.py --preset=standalone
   ```
3. 在对话框中自然交互：
   * *“帮我拆解这个登录功能”*（自动触发 `task-breakdown`，派发 `dev` 编写草稿并验证）；
   * *“沉淀我们关于数据库选型的决定”*（自动触发 `extract-knowledge` 并落盘）；
   * *“我下班了”*（触发基于本地 `/goal` 提示词接力的无人值守夜班）。

---

### 模式二：远端服务器 (PVE) 与 Jules 云端自主模式
**适用对象**：拥有独立 Linux/PVE 构建服务器的高阶用户，或希望借助 Google Cloud Jules 实现离线自动提 PR 的自动化团队。

#### 1. 前置依赖与工具安装
* **远端服务器 (PVE / 云主机)**：
  - **Antigravity CLI (`agy`)**：必须在远端服务器上安装并认证命令行版本（安装指引见 [Antigravity CLI 文档](https://antigravity.google/docs/cli)）。
  - **SSH 配置**：在本地 `~/.ssh/config` 中配置好别名（如 `Host my-pve`），确保免密连接。
  - **Zellij 终端复用器**：在远端服务器安装（`cargo install zellij` 或系统包管理器），用于维持夜班后台会话。
* **Google Cloud Jules (用于 GitHub 项目离线自动化流水线)**：
  - 配置 API 密钥：`export JULES_API_KEY="AIzaSy..."`（或安装并登录 `jules` CLI）。
  - **GitHub CLI (`gh`)**：如需开启 PR 自动 Squash 合并（`--auto-merge`），需安装并完成 `gh auth login`。
* **Mutagen (可选)**：
  - 本地运行 `brew install mutagen-io/mutagen/mutagen`，用于本地与远端代码的双向亚秒级实时同步。

#### 2. 激活服务器预设
在插件根目录下运行：
```bash
python configure.py --preset=server-centralized
```

#### 3. 运行看门狗脚本 (Watchdogs)
本项目在 `scripts/watchdogs/` 下开源了两个工业级看门狗脚本：

##### 看门狗 A：远端 PVE 服务器调度 (`pve_watchdog.sh`)
通过 SSH 将任务分发至 PVE 服务器，利用后台守护进程或 Zellij 维持运行，并监听完成信号：
```bash
bash scripts/watchdogs/pve_watchdog.sh \
  -t auth_001 \
  -a dev \
  -d /root/Projects/my-app \
  -p "实现基于 Redis 的令牌黑名单" \
  -h my-pve
```

##### 看门狗 B：Google Jules 云端自动化调度 (`jules_watchdog.sh`)
直接调用 Google Cloud Jules 云端 VM 编写代码，捕获生成的 PR，并在测试通过后自动合并：
```bash
bash scripts/watchdogs/jules_watchdog.sh \
  -t auth_001 \
  -r "owner/repo" \
  -b "main" \
  -p "修复认证路由里的并发边界错误" \
  --auto-merge
```

---

## 🧭 MCP 服务与脚本放置规范指南

在 Antigravity 体系中，清晰理解各项资产的物理放置位置至关重要：

### 1. MCP 看板服务放哪里？
* **仓库内源码**：自带的 FastMCP 看板服务源码位于 [mcp/kanban-task-manager/server.py](mcp/kanban-task-manager/server.py)。
* **全局注册**：若想让它对 Antigravity 上的所有项目生效，将其注册在全局配置文件 `~/.gemini/config/mcp_config.json` 中：
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
* **界面添加方式**：亦可在 Antigravity IDE 右上角 **... (More) > MCP Servers > Add Server**，填入名称与上述执行命令即可。

### 2. 自定义脚本放哪里？
* **项目内脚本**：所有看门狗与调度工具均保存在仓库的 `scripts/` 目录下：
  - `scripts/watchdogs/`：远端 PVE 与 Google Jules 看门狗脚本。
  - `scripts/meta_resolver.py`：集中式元数据路径寻址器。
* **全局快捷调用建议（可选）**：如果希望在任意终端路径下直接调用看门狗，建议将它们软链接至全局配置目录：
  ```bash
  mkdir -p ~/.gemini/config/scripts
  ln -sf $(pwd)/scripts/watchdogs/pve_watchdog.sh ~/.gemini/config/scripts/
  ln -sf $(pwd)/scripts/watchdogs/jules_watchdog.sh ~/.gemini/config/scripts/
  ```

---

## 📁 完整项目文件结构

```text
agy-disciple/
├── plugin.json                 # Antigravity 插件配置清单
├── README.md                   # 英文主文档
├── README_zh.md                # 简体中文文档
├── LICENSE                     # MIT 开源协议
├── configure.py                # 模式与变体一键切换工具 (含 --doctor 环境体检)
│
├── agents/                     # 通用 Sub-Agents 定义
│   ├── dev.yaml                # 研发 Agent (草稿隔离法、沙盒自测)
│   ├── merger.yaml             # 合并 Agent (安全备份、原子替换)
│   └── ops.yaml                # 运维 Agent (安全运维、命令字典)
│
├── skills/                     # 核心与进阶技能套件
│   ├── task-breakdown/         # 需求粒度拆解与两轨确认
│   ├── dev-manager/            # 研发流程调度 (支持 local / server 变体)
│   ├── project-manager/        # 项目元数据与看板管理 (支持 in-repo / centralized 变体)
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
    │   ├── pve_watchdog.sh     # 远端 SSH / agy CLI 看门狗
    │   └── jules_watchdog.sh   # Google Jules 云端流水线看门狗
    └── meta_resolver.py        # 集中式元数据路径解析工具
```

---

## 📄 开源许可证

本项目基于 [MIT License](LICENSE) 协议开源。

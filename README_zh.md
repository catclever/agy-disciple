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

## 🎛️ 双模自适应架构 (Local vs. Server)

`agy-disciple` 同时适配**单机轻量开发**与**拥有专属服务器/PVE 的重度极客**：

| 核心特性 | 单机默认预设 (Standalone / In-Repo) | 进阶服务器预设 (Server-Centralized / PVE) |
| :--- | :--- | :--- |
| **适用人群** | 通用开源用户、单机开发、团队 Git 协同 | 拥有专属 PVE/Linux 构建服务器、追求代码树绝对纯净的用户 |
| **元数据存储** | 存放于当前项目仓库内 (`./kb`, `./tasks`, `./docs`) | 集中外置于用户家目录 (`~/.gemini/Projects/<name>`) |
| **计算拓扑** | 本地 IDE 内部的原生 Sub-agents 协同 | 本地主架构师 + 远程 SSH / Zellij 多智能体调度 |
| **夜间自主接力**| 本地基于原生 `/goal` 指令的无人值守循环 | 远端终端复用器 (Zellij) 狂暴离线自动化研发 |

### 秒级一键模式切换

通过项目内置的 `configure.py`，随时无损切换工作流模式：

```bash
# 查看当前激活的各技能模式
python configure.py --status

# 应用默认的单机/仓库内模式（适合绝大多数项目）
python configure.py --preset=standalone

# 应用服务器/集中式模式（适合 PVE 用户）
python configure.py --preset=server-centralized

# 亦可进行单项微调：
python configure.py --meta=in-repo          # in-repo 或 centralized
python configure.py --topology=local        # local 或 server
```

---

## 🚀 快速开始

### 插件安装

#### 方式一：作为全局插件安装（推荐）
将本仓库克隆至您的 Antigravity 全局插件目录：
```bash
cd ~/.gemini/config/plugins/
git clone https://github.com/<your-username>/agy-disciple.git
```
重启或刷新 Antigravity 客户端，插件将自动完成发现与加载。

#### 方式二：作为项目专属插件引入
将仓库克隆至具体项目的 `.agents/plugins/` 目录：
```bash
mkdir -p .agents/plugins
cd .agents/plugins
git clone https://github.com/<your-username>/agy-disciple.git
```

---

## 📦 可选扩展：启用任务看板 MCP 服务

本插件附带了一个使用 FastMCP 编写的独立轻量级任务看板服务端。

### 在 Antigravity 中添加
1. 打开 Antigravity 界面点击 **Additional Options (...)** > **MCP Servers**。
2. 添加一个新的 Stdio 服务：
   - **Name**: `kanban-task-manager`
   - **Command**: `uv`
   - **Args**: `run`, `/absolute/path/to/agy-disciple/mcp/kanban-task-manager/server.py`

或者直接写入全局配置文件 `~/.gemini/config/mcp_config.json`：
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

更多参数说明详见 [mcp/kanban-task-manager/README.md](mcp/kanban-task-manager/README.md)。

---

## 📁 项目文件树

```text
agy-disciple/
├── plugin.json                 # Antigravity 插件配置清单
├── README.md                   # 英文主文档
├── README_zh.md                # 简体中文文档
├── LICENSE                     # MIT 开源协议
├── configure.py                # 模式与变体一键切换工具
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
    └── meta_resolver.py        # 集中式元数据路径解析工具
```

---

## 📄 开源许可证

本项目基于 [MIT License](LICENSE) 协议开源。

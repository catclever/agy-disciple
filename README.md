# agy-disciple 🚀

> **Production-grade Multi-Agent Development Team Plugin for Google Antigravity (AGY)**  
> 面向 Google Antigravity 的工业级多智能体协同研发团队插件

`agy-disciple`（Antigravity 门徒）将原本单打独斗的 AI 助手转变为一支**分工明确、纪律严明、自闭环的专业研发小队**。通过「主架构师 + 研发 + 合并 + 运维」的分权架构，彻底解决 AI 编码过程中的上下文污染、代码误覆盖、以及盲目试错问题。

---

## ✨ 核心设计哲学 (Core Philosophy)

### 1. 角色分工架构 (Hierarchical Orchestration)
* **主架构师 (Main Agent / Lead Architect)**：统揽全局，负责需求拆解、方案确认、双重知识库审查、任务看板管理与 DoD 门禁验收。
* **研发智能体 (`dev` Agent)**：专门负责重体力编码与沙盒单元自测。严格遵守**只读原文件原则**。
* **合并智能体 (`merger` Agent)**：专司草稿替换与无损备份，不参与业务逻辑。
* **运维智能体 (`ops` Agent)**：专司高危、非幂等、真实环境部署与运行脚本，强制记录命令字典。

### 2. 草稿后缀隔离法 (Draft Suffix Rule)
`dev` 智能体在修改代码时，被严格禁止直接修改原始源码文件。所有改动必须创建带任务后缀的独立草稿文件（如 `api_task_auth_001.py`）：
* **保留原生语法支持**：文件扩展名未变，IDE 语法高亮、Linting、类型检查完好无损；
* **零污染零破坏**：只有在沙盒自测通过、主架构师确认后，才由 `merger` 执行原子化覆盖与 `.bak` 备份；
* **极速回滚**：任何缺陷均可无损还原。

### 3. 双重知识库审查与防坑公墓 (Double Knowledge Audit & Graveyard)
* **Active Knowledge (`kb/knowledge.md`)**：仅收录已拍板生效的硬核架构规范、数据 Schema、通信协议与环境配置。
* **防坑公墓 (`kb/graveyard/grave.md`)**：专门沉淀**负面知识**（试错失败记录、死胡同、反面教材）。主架构师在向用户呈现方案前，强制运行公墓雷达扫描，绝对不重蹈覆辙。

### 4. 任务引擎平滑降级 (Adaptive Kanban Engine)
* **MCP 优先**：如果当前环境已接入 `kanban-task-manager` MCP 工具，享受强校验看板状态与主会话可点击跳转 (`conversation://<uuid>`)；
* **原生降级**：若未配置 MCP，自动平滑降级为读写本地 Markdown 任务卡片，开箱即用零门槛。

---

## 🎛️ 双模自适应架构 (Dual-Mode System)

`agy-disciple` 同时完美支持**单机本地开发者**与**拥有专属服务器/PVE 的重度高阶玩家**：

| 维度 | 默认预设 (Standalone / In-Repo) | 进阶服务器预设 (Server-Centralized / PVE) |
| :--- | :--- | :--- |
| **适用人群** | 通用开源用户、单机开发、团队 Git 协同 | 拥有 PVE/Linux 服务器、追求源码绝对纯净的用户 |
| **元数据存储** | 存放于当前项目仓库内 (`./kb`, `./tasks`, `./docs`) | 集中外置于用户家目录 (`~/.gemini/Projects/<name>`) |
| **计算拓扑** | 纯本地单机 Sub-agents 协作 | 本地主控 + 远端 PVE 服务器（SSH / Zellij / Mutagen） |
| **夜间模式** | 本地无人值守 `/goal` 循环接力 | 远端终端复用器 (Zellij) 离线全自动研发 |

### 一键模式切换 (Mode Switcher)

项目内置了 `configure.py`，支持随时无损切换：

```bash
# 查看当前生效的模式
python configure.py --status

# 切换为默认：单机模式 + 仓库内管理（适合新人和团队项目）
python configure.py --preset=standalone

# 切换为进阶：远端服务器/PVE + 集中式外置元数据
python configure.py --preset=server-centralized

# 也支持单项精细调整：
python configure.py --meta=in-repo          # 仅切换元数据模式: in-repo 或 centralized
python configure.py --topology=server       # 仅切换计算环境模式: local 或 server
```

---

## 📂 项目结构全览 (Repository Structure)

```text
agy-disciple/
├── plugin.json                 # Antigravity 插件清单
├── README.md                   # 详细使用指南
├── LICENSE                     # MIT 开源许可
├── configure.py                # 模式与变体一键切换工具
│
├── agents/                     # 通用 Sub-Agents 定义
│   ├── dev.yaml                # 研发 Agent (草稿隔离、沙盒验证)
│   ├── merger.yaml             # 合并 Agent (备份与替换)
│   └── ops.yaml                # 运维 Agent (安全操作、命令字典)
│
├── skills/                     # 核心与进阶技能库
│   ├── task-breakdown/         # [核心] 需求拆解、知识库审查与两轨确认
│   │   └── SKILL.md
│   ├── dev-manager/            # [核心] 研发流程调度 (支持 local / server 切换)
│   │   ├── SKILL.md            # 当前生效
│   │   ├── SKILL.local.md      # 本地单机调度
│   │   └── SKILL.server.md     # 远端服务器协同调度
│   ├── project-manager/        # [核心] 项目生命周期与任务看板
│   │   ├── SKILL.md            # 当前生效
│   │   ├── SKILL.in-repo.md    # 仓库内管理
│   │   └── SKILL.centralized.md# 集中式外置管理
│   ├── extract-knowledge/      # [核心] 知识沉淀与防坑公墓 (Graveyard)
│   │   ├── SKILL.md            # 当前生效
│   │   ├── SKILL.in-repo.md
│   │   └── SKILL.centralized.md
│   ├── ops-manager/            # [核心] 运维与高成本脚本执行
│   │   └── SKILL.md
│   ├── test-environment/      # [核心] 测试环境与开发服务管理
│   │   ├── SKILL.md
│   │   ├── SKILL.local.md
│   │   └── SKILL.server.md
│   ├── night-shift/            # [进阶] 离线夜班自主接力
│   │   ├── SKILL.md
│   │   ├── SKILL.local.md
│   │   └── SKILL.server.md
│   ├── pve-dispatch/           # [进阶] 远端服务器与多机任务分发
│   │   └── SKILL.md
│   └── setup-mutagen/          # [进阶] 智能语言检测与 Mutagen 双向同步
│       ├── SKILL.md
│       └── scripts/setup_mutagen.py
│
├── mcp/                        # 配套可选 MCP 工具
│   └── kanban-task-manager/
│       ├── server.py           # 纯 Python FastMCP 任务看板服务
│       ├── mcp_config.example.json
│       └── README.md           # 30秒安装指引
│
└── scripts/
    └── meta_resolver.py        # 通用跨平台项目元数据寻址工具
```

---

## 🚀 安装与上手 (Quickstart)

### 方式一：作为全局插件安装 (Global Plugin)

将本仓库克隆至您的 Antigravity 全局插件目录：

```bash
cd ~/.gemini/config/plugins/
git clone https://github.com/<your-username>/agy-disciple.git
```

重启或刷新 Antigravity，即可自动发现并加载 `agy-disciple` 团队套件。

### 方式二：作为项目专属插件引入 (Workspace Plugin)

在具体项目根目录下创建 `.agents/plugins/` 并克隆：

```bash
mkdir -p .agents/plugins
cd .agents/plugins
git clone https://github.com/<your-username>/agy-disciple.git
```

---

## 🛠️ 可选配置：启用 Kanban MCP 看板

插件自带了开箱即用的轻量级任务看板服务端 [mcp/kanban-task-manager](mcp/kanban-task-manager/README.md)。

只需在 Antigravity 界面（**Additional Options ... > MCP Servers**）中添加，或在全局 `~/.gemini/config/mcp_config.json` 注册：

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

---

## 📜 许可证 (License)

本项目采用 [MIT License](LICENSE) 许可证。

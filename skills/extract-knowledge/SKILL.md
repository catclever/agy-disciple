---
name: extract-knowledge
description: 'AI 知识提取与沉淀超级指令 (In-Repository Mode)'
---
<system_instruction>
你现在进入了「项目知识提取与沉淀模式」。
这是一条最高优先级的 Meta-Prompt，旨在将当前对话中的价值信息提取并规范化为项目专属知识，直接落盘在仓库内。

### 1. 什么是知识库 (Knowledge Base)?
- **定位**：知识库 (`kb/`) 是整个项目的 **Single Source of Truth (唯一事实来源)**。
- **收录范围**：只收录**已经拍板生效**的硬核技术细节，包括：核心架构规范、数据库表结构 (Schema)、通信协议、环境配置步骤、以及踩过的坑和教训（Gotchas）。
- **排除范围**：不收录未决的脑洞、发散性讨论或暂时性结论（这些应归入 `design/` 目录）。知识库的内容必须是冰冷、客观、确定的技术陈述。

### 2. 提取分支 (Extraction Branches)
请根据用户的输入情况，走不同的提取路线，但后续的落盘机制完全一致。

**分支 1：自动归纳（用户仅唤起指令，无附加参数）**
- **动作**：全面分析当前的对话上下文，主动提炼出最有复用价值的技术点或排错经验。
- **命名**：自动为提炼的内容生成一个精准的英文文件名（如 `auth_gotchas.md`）。

**分支 2：定向提取（用户明确了提取方向）**
- **动作**：严格按照用户附加的方向进行定点提取。如果用户指定了参考卡片，必须严格模仿其格式。
- **命名**：优先使用用户指定的文件名；若未指定，则自动生成。

**分支 3：防坑公墓（Anti-Pattern / Graveyard）**
- **动作**：如果当前对话是在记录“失败的方案”、“死胡同”或“踩过的坑”，则属于**负面知识**。
- **格式**：提取出：1. 试图解决什么问题 2. 失败的方案是什么 3. 为什么失败 4. 绝对不要做什么。
- **路由**：此类知识**必须**落盘至 `kb/graveyard/[文件名].md`，并将其摘要更新至 `kb/graveyard/grave.md`。

### 3. 统一落盘与汇报逻辑 (Unified Save & Report)
准备好结构化内容后，**通过 `knowledge-manager` MCP 工具执行原子化沉淀**（若 MCP 未挂载，可回退为直接文件写入）：

1. **调用 `kb_record` 工具**：
   - **正面技术知识（分支 1 / 分支 2）**：
     调用 `kb_record(project="$PWD", scope="active", title="<标题>", summary="<一句话摘要>", content="<Markdown正文>", filename="<可选英文文件名.md>")`
   - **防坑公墓（分支 3）**：
     调用 `kb_record(project="$PWD", scope="grave", title="<反模式标题>", summary="<避坑摘要>", content="<排错教训与绝对不要做的事>", filename="<可选英文文件名.md>")`

2. **引擎自动闭环特性**：
   - 自动在 `<workspace>/kb/` 规范化文件名与 YAML Frontmatter 并落盘；
   - 自动原子化追加或更新 `kb/knowledge.md`（Active）或 `kb/graveyard/grave.md`（Grave）索引。

3. **极简汇报**：
   - 用最简短的话术向用户汇报：“知识已沉淀至 `[文件名]`，并已同步至索引。”
</system_instruction>

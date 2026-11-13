# Weekly Report

从工作记录整理中文周报，优先读取 **Codex 与 Kimi Code**，再按需用本地 Git、Cursor 等补充。按真实工作主题归并，理解项目的用途和阶段，提炼本周成果、重要问题与下一步。

## 使用

在已发现该技能的 Agent 中直接说“整理我这周的工作，写一份周报”，或使用：

```text
/weekly-report
/weekly-report last-week
/weekly-report 2026-10-12 2026-10-16
```

默认按配置时区从本周一统计到当前。也可以指定“只写业务项目”“包括个人项目”“给领导看，控制在一页”等范围与表达要求。

普通请求直接整理，已确认的项目范围沿用；`projectSelection=ask` 时先选择项目。报告按重要性分配篇幅，以成果为主线，自然省略重复主语，并区分本地修改、文档交付、发布和真实业务验收。

## 数据来源与读取

- **Codex**：本地会话索引、rollout 和可用的桌面会话工具，覆盖旧会话本周续作。
- **Kimi Code**：会话索引、状态元数据与主 Agent 转录，结合消息时间和回合结果判断进展。
- **补充来源**：优先检查已定位项目的 Git 与 Cursor；其他工具和远程 SSH 按需求或线索启用。

候选会话的标题和更新时间只用于定位。工作归属取决于实际目标与交付，完成程度取决于已有结果。记录缺失会明确说明，不自动等同于没有工作。日常周报不全面读源码、不重跑业务测试，也不固定启动多层 Agent。

## 配置与输出

配置入口为 [config/defaults.json](config/defaults.json)：

- `scan.primarySources`：主力来源，默认 Codex、Kimi Code。
- `scan.supplementalSources`：按实际线索补查的来源。
- `scan.remoteMode`：默认 `on_request_or_evidence`；远程条目的 `enabled` 仅表示允许使用，不触发每周固定连接。
- `report.projectSelection`：`auto` 默认直接整理；`ask` 先选择；`all` 纳入所有有证据的工作主题。用户明确范围始终优先。
- `report.targetChineseCharacters`：正文篇幅软目标，根据项目数量和用户要求调整。
- `report.sections`：默认板块；用户模板优先。
- `report.outputDirectory`、`filenameTemplate`：默认桌面“周报”，同名文件递增后缀；宿主的输出目录约定优先。
- `report.saveLocalFile`、`copyToDesktop`：允许的本地交付方式；用户只需聊天正文时可跳过文件。

详细职责分别见 [SKILL.md](SKILL.md)、[记录读取](agents/scout.md)、[项目提炼](agents/project-summarizer.md)、[成稿风格](agents/synthesizer.md)。现有额外来源路径与远程配置继续保留，可按当前环境调整。

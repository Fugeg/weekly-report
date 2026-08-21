# Weekly Report Skill

一键生成周报。同一份 `SKILL.md` 可在 **Claude Code**、**Codex**、**Cursor**、**Trae** 里调用。

扫描各编码工具的本周会话/日志、本地 Git 仓库，以及（可选）远程 SSH 项目，汇总成面向领导阅读的 Markdown 周报。

## 安装

克隆后执行安装脚本，会把本目录符号链接到各工具的 skills 目录：

```bash
git clone <your-fork-or-repo> weekly-report
cd weekly-report
cp config/defaults.example.json config/defaults.json   # 按本机路径改一版
bash install.sh
```

手动安装（任选需要的宿主）：

| 宿主 | 技能目录 | 调用 |
|---|---|---|
| 跨工具共享 | `~/.agents/skills/weekly-report` | 被 Claude / Trae 等软链引用 |
| Claude Code | `~/.claude/skills/weekly-report` | `/weekly-report` |
| Codex | `~/.codex/skills/weekly-report` | `$weekly-report` 或 `/weekly-report` |
| Cursor | `~/.cursor/skills/weekly-report` | Agent 对话里 `/weekly-report` |
| Trae | `~/.trae/skills/weekly-report` | `/weekly-report` |

Windows 下对应 `C:\Users\<you>\.claude\skills\` 等。目录里必须有 `SKILL.md`。

机器相关路径只放 `config/defaults.json`（已 gitignore）。仓库里的 `config/defaults.example.json` 只有占位符。

## 使用

```
/weekly-report
```

默认生成本周一至今天的周报。

扫描完成后会先列出本周有活动的项目清单（名称、路径、来源工具、活动数），让你勾选要写入周报的项目，确认后才生成正文。回复「全部」即包含所有项目，回复「无」则取消。若想跳过选择直接全量生成，把 `config/defaults.json` 里的 `report.projectSelection` 改为 `"all"`。

### 参数

- `/weekly-report` — 本周一至今
- `/weekly-report last-week` — 上周一至上周日
- `/weekly-report 2026-07-01 2026-07-06` — 自定义日期范围

无子智能体的宿主（部分 Trae / Cursor 模式）会在当前会话里按同样步骤顺序执行，不跳过。

## 输出

```
~/Desktop/周报/YYYY-MM-DD-周报.md
```

报告面向领导阅读：「本周工作总结」按项目组织，一个项目一段完整叙述（含项目定位、本周进展、结果与价值），不打碎成零散 bullet，也不堆砌技术细节。

## 数据来源

路径均可在 `config/defaults.json` 的 `scan` 段调整。某个数据源无法解析时会自动降级，不影响其他来源。

- Claude Code 会话（`~/.claude/projects`）
- Codex 会话（`~/.codex/sessions`）
- Kimi Code 会话（`~/.kimi-code/`）
- Zcode CLI 日志（`~/.zcode/cli/log`）
- Trae 工作区（`~/.trae`）
- Cursor 项目记录（`~/.cursor/projects`）
- GitHub Copilot 日志（`~/.copilot/logs`）
- DeepSeek 会话（`~/.deepseek/sessions`）
- Gemini / Antigravity 会话（`~/.gemini/antigravity/conversations`）
- 本地 Git 仓库及项目文件修改时间
- 远程 SSH 项目（`scan.remoteRoots`）

## 远程扫描配置

先配置免密 SSH，再在 `config/defaults.json` 的 `scan.remoteRoots` 里填写主机、用户和项目根目录：

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@your-host
ssh -o BatchMode=yes user@your-host "ls ~/your-project"
```

认证失败时周报会跳过远程项目并在汇总里说明原因。

不要把真实 IP、用户名或内网路径写进 README / 示例。

## 配置

`config/defaults.json` 可调整：

- 默认扫描目录与各工具路径
- 最大项目数
- 输出目录
- 是否先让用户勾选项目（`report.projectSelection`: `ask` / `all`）

# Weekly Report Skill

一键生成周报，汇总 Claude Code、Zcode、Trae 以及本地文件系统项目的本周活动。

## 安装

将本目录复制到 Claude Code 的 skills 目录：

```bash
# 实际路径取决于你的 .claude 目录位置
cp -r weekly-report "C:\Users\Administrator\.claude\skills\"
```

## 使用

在 Claude Code 中输入：

```
/weekly-report
```

默认生成本周一至今天的周报。

### 参数

- `/weekly-report` — 本周一至今
- `/weekly-report last-week` — 上周一至上周日
- `/weekly-report 2026-07-01 2026-07-06` — 自定义日期范围

## 输出

周报保存到：

```
~/Desktop/周报/YYYY-MM-DD-周报.md
```

## 数据来源

- Claude Code 会话与任务记录
- Zcode CLI 日志
- Trae 工作区记录
- 本地 Git 仓库及项目文件修改时间

## 配置

修改 `config/defaults.json` 可调整：

- 默认扫描目录
- 最大项目数
- 输出目录
- 周报板块标题

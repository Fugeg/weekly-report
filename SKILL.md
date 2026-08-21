---
name: weekly-report
description: "Generate a weekly Markdown work report by scanning Claude Code, Codex, Kimi Code, Zcode, Trae, Cursor, Copilot, DeepSeek, Gemini/Antigravity, local project activity, and remote SSH projects. Use when the user asks for 周报, weekly report, /weekly-report, or to summarize this week's work across coding tools."
---

# Weekly Report Skill

Portable Agent Skill. Runs on **Claude Code**, **Codex**, **Cursor**, and **Trae** from the same `SKILL.md`. The host is whichever tool the user invoked; data sources are configured separately in `config/defaults.json`.

## Trigger

`/weekly-report [this-week|last-week|YYYY-MM-DD YYYY-MM-DD]`

Default: `this-week` (本周一至今).

## Host notes

- If the host can spawn parallel subagents (Claude Code Agent, Codex spawn, Cursor/Trae subagent), run Scouts and Summarizers concurrently.
- If it cannot, run the same prompts sequentially in this session. Do not skip steps.
- Interactive project picking: use a multi-select question tool when available; otherwise ask in plain text and wait.
- Paths below are relative to **this skill directory** (the folder that contains this `SKILL.md`).

## Workflow

1. **Parse date range**
   - If no argument: start = this Monday, end = today.
   - If `last-week`: start = last Monday, end = last Sunday.
   - If two dates provided: use them directly.

2. **Load config**
   - Read `config/defaults.json` next to this `SKILL.md`.
   - If that file is missing, copy `config/defaults.example.json` to `config/defaults.json`, fill in local paths, and stop with a short note.

3. **Run Scout Agents concurrently**
   - One scout per tool using `agents/scout.md`.
   - Tools: `claude`, `codex`, `kimi`, `zcode`, `trae`, `cursor`, `copilot`, `deepseek`, `gemini`, `filesystem`, `remote`.
   - Each returns a JSON array of `ScoutResult` objects.
   - A missing data-source path is `status: "failed"` or empty `[]`, not a hard stop.

4. **Deduplicate and limit projects**
   - Normalize paths (lowercase, absolute).
   - Merge activities for the same project path.
   - Keep at most `scan.maxProjects` (50) projects, sorted by most recent activity.

5. **Let the user pick projects**
   - If `report.projectSelection` is `"ask"` (the default), present the merged project list as a numbered list: project name, path, contributing tools, activity count, and last activity time.
   - Accept: "全部" / "all", a comma-separated list of numbers or names, or "无" / "none" to abort.
   - Wait for the user's answer before continuing. If the user aborts, stop without writing a report.
   - If `report.projectSelection` is `"all"`, skip this step and use every project.

6. **Run Project Summarizer Agents concurrently**
   - One summarizer per SELECTED project using `agents/project-summarizer.md`.
   - Each returns a `ProjectSummary` JSON object.

7. **Run Synthesizer Agent**
   - Pass all `ProjectSummary` objects to one synthesizer using `agents/synthesizer.md`.
   - The synthesizer returns the final Markdown report.

8. **Save and report**
   - Ensure `~/Desktop/周报` exists (or `report.outputDirectory` if set).
   - Write `{endDate}-周报.md`. If the file already exists, use a suffixed name before the extension (`-2`, `-3`, …).
   - Reply with: saved path, which tools contributed, how many projects were summarized (and which the user selected), failures/skips, and the first 30 lines as a preview.

## Error Handling

- If a Scout fails, record `status: "failed"` and its `notes`, then continue.
- If the `remote` Scout cannot connect (e.g. SSH key not configured), treat as graceful degradation: record the failure in the final summary and continue.
- If a Project Summarizer fails, skip that project and note it in the final summary.
- If no projects are found, generate a report where every section says `本周无`.
- If the save directory cannot be created, report the error clearly.

## Privacy Rules

- Do NOT send full source code to any Agent.
- Only session metadata, commit messages, file modification times, and short activity summaries may be transmitted.
- Do NOT put real hostnames, IPs, usernames, or internal paths in README / scout examples. Machine-specific values live only in `config/defaults.json`.

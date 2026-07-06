---
name: weekly-report
description: "Generate a weekly Markdown work report by scanning Claude Code, Zcode, Trae, and local project activity."
---

# Weekly Report Skill

## Trigger

`/weekly-report [this-week|last-week|YYYY-MM-DD YYYY-MM-DD]`

Default: `this-week` (本周一至今).

## Workflow

1. **Parse date range**
   - If no argument: start = this Monday, end = today.
   - If `last-week`: start = last Monday, end = last Sunday.
   - If two dates provided: use them directly.

2. **Load config**
   - Read `E:\AI\.claude\skills\weekly-report\config\defaults.json`.

3. **Run Scout Agents concurrently**
   - Spawn one Agent per tool with the `agents/scout.md` prompt.
   - Tools: `claude`, `zcode`, `trae`, `filesystem`.
   - Each Agent returns a JSON array of `ScoutResult` objects.

4. **Deduplicate and limit projects**
   - Normalize paths (lowercase, absolute).
   - Merge activities for the same project path.
   - Keep at most `scan.maxProjects` (50) projects, sorted by most recent activity.

5. **Run Project Summarizer Agents concurrently**
   - Spawn one Agent per remaining project with the `agents/project-summarizer.md` prompt.
   - Each returns a `ProjectSummary` JSON object.

6. **Run Synthesizer Agent**
   - Pass all `ProjectSummary` objects to one Agent using `agents/synthesizer.md`.
   - The Agent returns the final Markdown report.

7. **Save and report**
   - Ensure `~/Desktop/周报` exists.
   - Write the Markdown to `~/Desktop/周报/{endDate}-周报.md`.
   - If the file already exists, append `-2` (or `-3`, etc.) before overwriting.
   - Reply to the user with:
     - The saved file path
     - A brief summary of which tools contributed and how many projects were summarized
     - Any failures or skipped items
     - The first 30 lines of the generated report as a preview

## Error Handling

- If a Scout Agent fails, record `status: "failed"` and its `notes`, then continue.
- If a Project Summarizer fails, skip that project and note it in the final summary.
- If no projects are found, generate a report where every section says `本周无`.
- If the save directory cannot be created, report the error clearly.

## Privacy Rules

- Do NOT send full source code to any Agent.
- Only session metadata, commit messages, file modification times, and short activity summaries may be transmitted.

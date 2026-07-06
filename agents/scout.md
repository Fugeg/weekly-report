# Scout Agent

You are a data scout for the weekly-report skill. Your job is to scan ONE data source and return a JSON array of project activities found within the requested date range.

## Input you will receive

- `tool`: one of `claude`, `zcode`, `trae`, `filesystem`
- `startDate`: ISO date string, e.g. `2026-07-01`
- `endDate`: ISO date string, e.g. `2026-07-06`
- `config`: the contents of `config/defaults.json`

## Tool-specific instructions

### claude
1. List directories under `config.scan.claudeProjectsPath`.
2. For each project directory, check the most recent file modification time.
3. If modified within the date range, read `MEMORY.md` or any task/session summary files to extract activity titles.
4. `project` = directory name; `path` = full project metadata path.

### zcode
1. Enumerate files in `config.scan.zcodeLogPath` matching `zcode-YYYY-MM-DD.jsonl`.
2. Only read files whose date is within the range.
3. Parse each line as JSON; extract `project`/`cwd`, `title`, and `timestamp` if present.
4. If JSON schema is unknown, read the first 20 lines to infer fields.

### trae
1. Read Trae config/state files under `config.scan.traeConfigPath` to find recently opened workspace paths.
2. For each workspace path, check if the project directory was modified this week.
3. If Trae config cannot be parsed, return `status: "failed"` with `notes` explaining the limitation.

### filesystem
1. Walk each root in `config.scan.filesystemRoots` up to `config.scan.maxRecursionDepth`.
2. Identify directories containing any marker in `config.projectMarkers`.
3. For Git repositories, run `git log --since=startDate --until=endDate --oneline` to get commits.
4. For non-Git projects, check directory mtime or key file mtime.
5. Only include projects with activity in the date range.

## Output schema

```json
[
  {
    "tool": "claude | zcode | trae | filesystem",
    "project": "human-readable project name",
    "path": "absolute path to the project or session",
    "activities": [
      {
        "type": "session | commit | edit | task",
        "title": "short title",
        "time": "2026-07-06T14:30:00+08:00",
        "summary": "one sentence describing what happened"
      }
    ],
    "status": "ok | partial | failed",
    "notes": "failure or fallback explanation, empty if ok"
  }
]
```

## Rules

- Do NOT read full source code files. Only session metadata, commit logs, file modification times, or tool logs.
- If the data source is unreadable, return one item with `status: "failed"` and a helpful `notes` string.
- If no activities are found, return an empty array `[]`.
- Normalize project paths using absolute paths for deduplication later.

# Scout Agent

You are a data scout for the weekly-report skill. Your job is to scan ONE data source and return a JSON array of project activities found within the requested date range.

## Input you will receive

- `tool`: one of `claude`, `codex`, `kimi`, `zcode`, `trae`, `cursor`, `copilot`, `deepseek`, `gemini`, `filesystem`, `remote`
- `startDate`: ISO date string, e.g. `2026-07-01`
- `endDate`: ISO date string, e.g. `2026-07-06`
- `config`: the contents of `config/defaults.json`

## Tool-specific instructions

### claude
1. List directories under `config.scan.claudeProjectsPath`.
2. For each project directory, check the most recent file modification time.
3. If modified within the date range, read session metadata or task summary files to extract activity titles and the actual project working directory (`cwd`).
4. `project` = the actual project folder name (from `cwd` if available, otherwise from the metadata directory name).
5. `path` = the actual project `cwd` path (NOT the `.claude/projects/...` metadata path). This is required for correct deduplication with other tools.

### codex
1. Sessions live under `config.scan.codexSessionsPath` in a date hierarchy: `YYYY/MM/DD/rollout-YYYY-MM-DDTHH-MM-SS-<uuid>.jsonl`. Enumerate only the date directories within the range.
2. For each rollout file, read ONLY the first line and parse it as JSON: `type == "session_meta"`, `payload.cwd`, `payload.timestamp`, `payload.originator`.
3. To get a title, you may read up to 5 more lines looking for the first user message text. Do NOT read the whole file.
4. `project` = folder name of `payload.cwd`; `path` = `payload.cwd` (the real working directory, required for dedup).
5. Skip sessions whose `cwd` equals `config.scan.userHomePath` — those are scratch sessions, not projects.

### kimi
1. Read `config.scan.kimiSessionIndexPath` (JSONL). Each line has `sessionId`, `sessionDir`, `workDir`.
2. For each line, check the modification time of `sessionDir` (a directory under `config.scan.kimiSessionsPath`). Keep sessions modified within the date range.
3. If the index file is missing, fall back to listing `config.scan.kimiSessionsPath/wd_*/session_*` directories directly and filter by mtime; the `wd_*` parent name encodes the working directory.
4. `project` = folder name of `workDir`; `path` = `workDir`.
5. Skip sessions whose `workDir` equals `config.scan.userHomePath` — those are scratch sessions, not projects.

### zcode
1. Enumerate files in `config.scan.zcodeLogPath` matching `zcode-YYYY-MM-DD.jsonl`.
2. Only read files whose date is within the range.
3. Parse each line as JSON; extract `project`/`cwd`, `title`, and `timestamp` if present.
4. If JSON schema is unknown, read the first 20 lines to infer fields.

### trae
1. Read Trae config/state files under `config.scan.traeConfigPath` to find recently opened workspace paths.
2. For each workspace path, check if the project directory was modified this week.
3. If Trae config cannot be parsed, return `status: "failed"` with `notes` explaining the limitation.

### cursor
1. List subdirectories of `config.scan.cursorProjectsPath`. Ignore names starting with `.` (e.g. `.agent-data-cleanup-*` backup dirs).
2. Keep project directories whose mtime is within the date range.
3. Try to resolve the real workspace path from `config.scan.cursorAgentStatePath` (if set) and any small metadata files inside the project directory (e.g. under `terminals/`) for a cwd/workspace hint.
4. If the workspace path cannot be resolved, include the entry with `status: "partial"`, `path` = the `.cursor/projects/<id>` directory, and a `notes` explanation.

### copilot
1. Enumerate `process-*.log` files under `config.scan.copilotLogsPath`, filtered by mtime within the date range.
2. Grep the logs for workspace/cwd hints (e.g. lines containing `workspace` or an absolute path).
3. If no workspace can be extracted, return one item with `status: "partial"` and `notes` explaining that Copilot logs do not record project directories reliably.

### deepseek
1. List `config.scan.deepseekSessionsPath`. If it is empty or missing, return `[]`.
2. Otherwise parse session metadata files for working directory and timestamps, filter by the date range, and extract activities.

### gemini
1. List `config.scan.geminiConversationsPath` (Antigravity IDE conversation records). If empty or missing, return `[]`.
2. Filter by mtime within the date range; extract the workspace path from conversation metadata if recorded.
3. If the workspace cannot be resolved, use `status: "partial"` with a `notes` explanation.

### filesystem
1. Walk each root in `config.scan.filesystemRoots` up to `config.scan.maxRecursionDepth`.
2. Identify directories containing any marker in `config.projectMarkers`.
   - Note: `.git` is a directory marker; all other markers are files.
3. For Git repositories, run `git log --since=<startDate> --until=<endDate> --oneline` to get commits (replace `<startDate>` and `<endDate>` with the provided ISO date strings).
4. For non-Git projects, check directory mtime or key file mtime.
5. Only include projects with activity in the date range.

### remote
1. Iterate over `config.scan.remoteRoots` and process entries where `enabled` is `true`.
2. For each entry, test connectivity first: `ssh -o BatchMode=yes -o ConnectTimeout=8 <user>@<host> "echo ok"`.
   - If this fails, return one ScoutResult with `status: "failed"` and `notes` explaining that key-based auth is not configured (e.g. "请运行 ssh-copy-id -i ~/.ssh/id_ed25519.pub user@your-host 配置免密登录"), then continue with the next remote root.
3. Resolve the remote root to an absolute path: `ssh ... "cd <root> && pwd"`.
4. List subdirectories under the remote root: `ssh ... "ls -1 <abs_root>"`.
5. For each subdirectory that is a project (contains any marker from `config.projectMarkers`):
   - If it contains `.git`, run `ssh ... "git -C <dir> log --since=<startDate> --until=<endDate> --oneline"`.
   - Otherwise, check whether any file was modified in range using `ssh ... "find <dir> -maxdepth 2 -type f -newermt '<startDate>' ! -newermt '<endDate_next_day>'"`.
6. Only include projects with activity in the date range.
7. `project` = the remote folder name; `path` = `<user>@<host>:<abs_dir>` (e.g. `user@host:/home/user/project`). This format prevents collisions with local paths during deduplication.

## Output schema

```json
[
  {
    "tool": "claude | codex | kimi | zcode | trae | cursor | copilot | deepseek | gemini | filesystem | remote",
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
- Do NOT hardcode machine IPs, usernames, or home paths; always read them from `config`.

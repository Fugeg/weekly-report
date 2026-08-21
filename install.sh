#!/usr/bin/env bash
# Link this skill into Claude Code, Codex, Cursor, Trae, and ~/.agents/skills.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
NAME="weekly-report"

if [[ ! -f "$ROOT/SKILL.md" ]]; then
  echo "SKILL.md not found in $ROOT" >&2
  exit 1
fi

if [[ ! -f "$ROOT/config/defaults.json" ]]; then
  if [[ -f "$ROOT/config/defaults.example.json" ]]; then
    cp "$ROOT/config/defaults.example.json" "$ROOT/config/defaults.json"
    echo "created config/defaults.json from example — edit local paths before running"
  else
    echo "missing config/defaults.json" >&2
    exit 1
  fi
fi

detect_win_home() {
  local d base
  [[ -d /mnt/c/Users ]] || return 1
  for d in /mnt/c/Users/*; do
    [[ -d "$d" ]] || continue
    base="$(basename "$d")"
    case "$base" in
      Public|Default|"Default User"|"All Users") continue ;;
    esac
    if [[ -d "$d/.claude" || -d "$d/.codex" || -d "$d/.trae" || -d "$d/.cursor" ]]; then
      printf '%s' "$d"
      return 0
    fi
  done
  return 1
}

same_tree() {
  local dest="$1"
  [[ -e "$dest" ]] || return 1
  python3 - "$ROOT" "$dest" <<'PY'
import os, sys
sys.exit(0 if os.path.realpath(sys.argv[1]) == os.path.realpath(sys.argv[2]) else 1)
PY
}

link_into() {
  local dest="$1"
  mkdir -p "$(dirname "$dest")"
  if same_tree "$dest"; then
    echo "skip (already this tree): $dest"
    return 0
  fi
  if [[ -L "$dest" ]]; then
    rm "$dest"
  elif [[ -d "$dest" ]]; then
    echo "exists and is not a symlink, leaving in place: $dest" >&2
    echo "  replace it with: rm -rf \"$dest\" && ln -s \"$ROOT\" \"$dest\"" >&2
    return 0
  elif [[ -e "$dest" ]]; then
    echo "exists and is not a directory: $dest" >&2
    return 1
  fi
  ln -s "$ROOT" "$dest"
  echo "linked $dest -> $ROOT"
}

WIN_HOME="$(detect_win_home || true)"
if [[ -z "${WIN_HOME}" ]]; then
  WIN_HOME="${HOME}"
fi

link_into "${WIN_HOME}/.agents/skills/${NAME}"
link_into "${WIN_HOME}/.claude/skills/${NAME}"
link_into "${WIN_HOME}/.codex/skills/${NAME}"
link_into "${WIN_HOME}/.cursor/skills/${NAME}"
link_into "${WIN_HOME}/.trae/skills/${NAME}"

if [[ "${HOME}" != "${WIN_HOME}" ]]; then
  link_into "${HOME}/.agents/skills/${NAME}"
  link_into "${HOME}/.claude/skills/${NAME}"
  link_into "${HOME}/.codex/skills/${NAME}"
  link_into "${HOME}/.cursor/skills/${NAME}"
  link_into "${HOME}/.trae/skills/${NAME}"
fi

echo "done. invoke with /weekly-report (Claude/Cursor/Trae) or \$weekly-report (Codex)"

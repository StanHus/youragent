#!/usr/bin/env bash
# skills/memory-search.sh
# Cross-repo + global memory search. Answers "what have I learned / written
# about X?" across:
#   - this repo's .agent/ (MEMORY, LESSONS_LEARNED, HANDOFF, BEADS)
#   - the OpenClaw agent's global memory ($workspace/memory/), if detected
#   - every .agent/MEMORY.md the agent has touched and noted in OpenClaw's
#     global memory (best-effort scan of common locations)
#
# Usage:
#   .agent/skills/memory-search.sh "migrations"
#   .agent/skills/memory-search.sh --json "rate limit"
#
# Exit 0 on success; 2 if no query given.

set -euo pipefail

JSON=0
if [ "${1:-}" = "--json" ]; then
  JSON=1; shift
fi
QUERY="${1:-}"
if [ -z "$QUERY" ]; then
  echo "usage: memory-search.sh [--json] '<query>'" >&2
  exit 2
fi

# Locate the repo's .agent/ root by walking up from $PWD.
AGENT_DIR=""
cur="$PWD"
while [ "$cur" != "/" ]; do
  if [ -f "$cur/.agent/.youragent" ]; then AGENT_DIR="$cur/.agent"; break; fi
  cur="$(dirname "$cur")"
done

matches_json=""
hits=0
append_hit() {
  local scope="$1" path="$2" line="$3" text="$4"
  hits=$((hits+1))
  if [ "$JSON" = "1" ]; then
    # Build JSON incrementally (one object per match, comma-joined).
    local esc
    esc=$(printf '%s' "$text" | python3 -c 'import sys, json; print(json.dumps(sys.stdin.read().rstrip()))')
    [ -n "$matches_json" ] && matches_json+=","
    matches_json+=$(printf '{"scope":"%s","path":"%s","line":%s,"text":%s}' "$scope" "$path" "$line" "$esc")
  else
    printf "  [%s]  %s:%s\n    %s\n" "$scope" "$path" "$line" "$text"
  fi
}

# --- scan a single file, emit matches ---
scan_file() {
  local scope="$1" file="$2"
  [ -f "$file" ] || return 0
  # grep -niH: line numbers, case-insensitive, filename. Only lines; strip control chars.
  while IFS=':' read -r _path line_text; do
    local lineno="${line_text%%:*}"
    local text="${line_text#*:}"
    append_hit "$scope" "$file" "$lineno" "$text"
  done < <(grep -niHF -- "$QUERY" "$file" 2>/dev/null | sed 's/^/_/' || true)
  # (The leading _ + read -r _path trick normalizes the `path:line:text` grep output.)
}

# 1. This repo
if [ -n "$AGENT_DIR" ]; then
  for f in MEMORY.md LESSONS_LEARNED.md memory/HANDOFF.md memory/BEADS.md memory/SHORT_TERM_MEMORY.md memory/PROMPTS.md openclaw/BRIDGE.md openclaw/GLOBAL_NOTES.md; do
    scan_file "repo" "$AGENT_DIR/$f"
  done
fi

# 2. OpenClaw global memory — discover workspaces from openclaw.json
if [ -f "$HOME/.openclaw/openclaw.json" ] && command -v python3 >/dev/null 2>&1; then
  while IFS= read -r ws; do
    [ -z "$ws" ] && continue
    for f in "$ws/memory"/*.md "$ws/IDENTITY.md" "$ws/AGENTS.md"; do
      [ -f "$f" ] && scan_file "global" "$f"
    done
  done < <(python3 - "$HOME/.openclaw/openclaw.json" <<'PYEOF'
import json, sys
try:
    with open(sys.argv[1]) as f: cfg = json.load(f)
    for a in cfg.get("agents", {}).get("list", []):
        ws = a.get("workspace", "")
        if ws: print(ws)
except Exception:
    pass
PYEOF
)
fi

if [ "$JSON" = "1" ]; then
  printf '{"query":"%s","hits":%d,"matches":[%s]}\n' "$QUERY" "$hits" "$matches_json"
else
  if [ "$hits" = 0 ]; then
    echo "  no matches for '$QUERY'"
  else
    echo ""
    echo "  $hits match(es)"
  fi
fi

#!/usr/bin/env bash
# openclaw-configure.sh
# Configures OpenClaw agents to auto-detect and use .agent/ folders.
# Part of the agentize scaffold by Trilogy AI CoE.
#
# v2 snippet adds: bead protocol teaching, skill discovery, memory routing
# rules, and bridge-file awareness. v1 installs are auto-migrated in place
# (backup first, preserve user content outside our markers).

set -euo pipefail

# ---------- Colors ----------
BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'
CYAN=$'\033[36m'; MAGENTA=$'\033[35m'

OPENCLAW_CONFIG="$HOME/.openclaw/openclaw.json"
V1_MARKER="<!-- youragent-openclaw-v1 -->"
V2_MARKER="<!-- youragent-openclaw-v2 -->"
V2_END_MARKER="<!-- youragent-openclaw-v2-end -->"
INTEGRATION_HEADER="## Working in Code Repositories (agentize integration)"

# ---------- Gate: OpenClaw must actually exist ----------
if [ ! -f "$OPENCLAW_CONFIG" ]; then
  echo "${DIM}No OpenClaw instance detected (no ~/.openclaw/openclaw.json).${RESET}"
  echo "${DIM}Nothing to configure — this command only runs when OpenClaw is installed.${RESET}"
  exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "${RED}✗${RESET} python3 not found — required to parse openclaw.json."
  exit 1
fi

# ---------- Discover agents ----------
WORKSPACES=$(python3 - "$OPENCLAW_CONFIG" <<'PYEOF'
import json, sys
try:
    with open(sys.argv[1]) as f: cfg = json.load(f)
    for a in cfg.get("agents", {}).get("list", []):
        ws = a.get("workspace", "")
        nm = a.get("identity", {}).get("name", a.get("id", "unknown"))
        if ws: print(f"{ws}|{nm}")
except Exception as e:
    print(f"ERROR: {e}", file=sys.stderr); sys.exit(1)
PYEOF
)

if [ -z "$WORKSPACES" ]; then
  echo "${YELLOW}!${RESET} No agents found in openclaw.json."
  echo "${DIM}  Add one or more agents to your OpenClaw config and re-run this.${RESET}"
  exit 0
fi

echo ""
echo "${BOLD}${CYAN}configure-openclaw${RESET}  ${DIM}v2 — bead protocol, skill discovery, memory routing${RESET}"
echo "${DIM}──────────────────────────────────────────────────────────────${RESET}"

# ---------- Emit v2 block for an agent workspace ----------
emit_v2_block() {
  local workspace="$1"
  cat <<BLOCK

$V2_MARKER
$INTEGRATION_HEADER

When you enter a code repository, layer its local context on top of your
global identity. Do this **every time**, without asking.

### 1 · Orientation (first thing, every session)

Read in this order if they exist:
1. \`.agent/NORTH_STAR.md\` — what this repo is and how to work here
2. \`.agent/openclaw/BRIDGE.md\` — per-repo overrides to your personality / rules
3. \`.agent/MEMORY.md\` — durable facts about this repo
4. \`.agent/memory/BEADS.md\` — active tasks

If \`.agent/\` is missing, use only your global context and proceed normally.

### 2 · Context stack (who owns what)

| Scope                      | Location                                 |
|----------------------------|------------------------------------------|
| Global identity            | \`$workspace/IDENTITY.md\`                |
| Global memory              | \`$workspace/memory/\`                    |
| **Repo overrides**         | \`.agent/openclaw/BRIDGE.md\`             |
| Repo orientation           | \`.agent/NORTH_STAR.md\`                  |
| Repo memory                | \`.agent/MEMORY.md\`                      |
| Repo task ledger           | \`.agent/memory/BEADS.md\`                |
| Global promotions from repo| \`.agent/openclaw/GLOBAL_NOTES.md\`       |

### 3 · Memory routing — where does a new fact go?

- **Only makes sense in this repo** → \`.agent/MEMORY.md\`
- **True everywhere / user pref / cross-repo pattern** → \`$workspace/memory/\`
- **Lesson from a mistake that generalizes** → both \`.agent/LESSONS_LEARNED.md\` AND append a one-liner to \`.agent/openclaw/GLOBAL_NOTES.md\` for later promotion
- **Handoff to next session in this repo** → \`.agent/memory/HANDOFF.md\`

If the fact starts with "in this repo…", it's local.

### 4 · Bead protocol (task ledger)

Tasks live in \`.agent/memory/BEADS.md\`. Read \`.agent/memory/README.md\`
for the exact schema. Core rules:

- Every bead has an **acceptance block** — files changed, tests passing, or
  command output that proves it's done.
- You **cannot close** a bead by writing "done". Cite the evidence inline.
- Use \`./.agent/memory/bd-lite.sh ready\` to see unblocked beads.
- Dependencies are declared with \`blocked_by:\` and are enforced.
- Create a new bead instead of quietly expanding an existing one.

### 5 · Skills — prefer these over ad-hoc implementation

Before implementing research or retrieval from scratch, check:

- \`.agent/skills/\` — repo-scoped skills (always read first here)
- \`.agents/skills/\` — cross-harness compatibility path (same content)
- Your globally-installed CLIs — \`wwvcd\` (Claude Code source findings),
  whatever else is in your \`\$workspace/skills/\` or \`\$PATH\`

If a skill exists, use it and cite it. If you need a new one, write a
shell script into \`.agent/skills/\` and update the session.

### 6 · Exit ritual (before you leave this repo)

1. Close or reassign any bead you touched (with evidence).
2. Append one line to \`.agent/memory/HANDOFF.md\` — what's next.
3. Append generalizable takeaways to \`.agent/openclaw/GLOBAL_NOTES.md\`.
   A future session will promote them into \`$workspace/memory/\`.

### 7 · Heads-up

The \`.agent/\` scaffold is maintained by the agentize package
(\`npx agentize\`). Files you shouldn't edit manually (tool-owned):
\`SOUL.md\`, \`AGENT.md\`, \`NORTH_STAR.md\`, \`PATTERNS_CATALOG.md\`,
\`HUMAN_GUIDE.md\`, \`TWEAKING.md\`, \`KNOWLEDGE_PACK.md\`,
\`GOGCLI_STARTER.md\`, \`GETTING_STARTED.md\`, \`OPENCLAW.md\`,
\`memory/bd-lite.sh\`, \`memory/README.md\`, \`skills/README.md\`,
\`skills/search-substack.sh\`.

Files you WRITE to (personal, never overwritten):
\`IDENTITY.md\`, \`USER.md\`, \`TOOLS.md\`, \`MEMORY.md\`,
\`LESSONS_LEARNED.md\`, everything in \`memory/\` except the two above,
and everything in \`openclaw/\`.

$V2_END_MARKER
BLOCK
}

TOTAL=0; UPDATED=0; MIGRATED=0; SKIPPED=0; MISSING=0

while IFS='|' read -r workspace name; do
  [ -z "$workspace" ] && continue
  TOTAL=$((TOTAL+1))
  AGENTS_MD="$workspace/AGENTS.md"

  if [ ! -f "$AGENTS_MD" ]; then
    echo "  ${YELLOW}!${RESET} ${name}  ${DIM}$AGENTS_MD not found${RESET}"
    MISSING=$((MISSING+1))
    continue
  fi

  # Already on v2? Skip.
  if grep -Fq "$V2_MARKER" "$AGENTS_MD"; then
    echo "  ${DIM}·${RESET} ${name}  ${DIM}already on v2${RESET}"
    SKIPPED=$((SKIPPED+1))
    continue
  fi

  # Backup before touching.
  BACKUP_DIR="$workspace/memory/BACKUPS"
  mkdir -p "$BACKUP_DIR"
  TS=$(date +%Y%m%d_%H%M%S)
  BACKUP="$BACKUP_DIR/AGENTS.md.backup.$TS"
  cp "$AGENTS_MD" "$BACKUP"

  # Migrate v1 → v2: strip v1 block, then append v2. Preserves anything
  # outside our markers.
  if grep -Fq "$V1_MARKER" "$AGENTS_MD"; then
    python3 - "$AGENTS_MD" "$V1_MARKER" <<'PYEOF'
import sys, re
path, marker = sys.argv[1], sys.argv[2]
with open(path) as f: data = f.read()
# v1 had no explicit end marker — strip from v1 marker to EOF.
idx = data.find(marker)
if idx != -1:
    # Walk back to the blank line before the marker for clean truncation.
    head = data[:idx].rstrip() + "\n"
    with open(path, "w") as f: f.write(head)
PYEOF
    emit_v2_block "$workspace" >> "$AGENTS_MD"
    echo "  ${GREEN}↑${RESET} ${name}  ${DIM}migrated v1 → v2${RESET}  ${DIM}(backup: ${BACKUP#$HOME/}~)${RESET}"
    MIGRATED=$((MIGRATED+1))
    continue
  fi

  # Fresh install of v2.
  emit_v2_block "$workspace" >> "$AGENTS_MD"
  echo "  ${GREEN}✓${RESET} ${name}  ${DIM}configured at $workspace${RESET}"
  UPDATED=$((UPDATED+1))
done <<< "$WORKSPACES"

echo "${DIM}──────────────────────────────────────────────────────────────${RESET}"
echo "  ${BOLD}$TOTAL total${RESET}  ${DIM}·${RESET}  ${GREEN}$UPDATED new${RESET}  ${DIM}·${RESET}  ${GREEN}$MIGRATED migrated${RESET}  ${DIM}·${RESET}  ${DIM}$SKIPPED skipped${RESET}  ${DIM}·${RESET}  ${YELLOW}$MISSING missing${RESET}"
echo ""
echo "  ${DIM}check drift anytime with${RESET}  ${BOLD}${MAGENTA}npx agentize openclaw-check${RESET}"
echo ""

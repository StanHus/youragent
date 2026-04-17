#!/usr/bin/env bash
# openclaw-configure.sh
# Configures OpenClaw agents to auto-detect and use .agent/ folders
# Part of the youragent scaffold by Trilogy AI COE

set -euo pipefail

# Colors
BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'
CYAN=$'\033[36m'

OPENCLAW_CONFIG="$HOME/.openclaw/openclaw.json"
INTEGRATION_MARKER="## Working in Code Repositories (YourAgent Integration)"
VERSION_MARKER="<!-- youragent-openclaw-v1 -->"

# Check if OpenClaw is installed
if [ ! -f "$OPENCLAW_CONFIG" ]; then
  echo "${DIM}OpenClaw not detected (no ~/.openclaw/openclaw.json)${RESET}"
  echo "${DIM}Skipping OpenClaw integration.${RESET}"
  exit 0
fi

echo ""
echo "${BOLD}${CYAN}Configuring OpenClaw agents for .agent/ folder integration${RESET}"
echo ""
echo "${DIM}This adds a section to each agent's AGENTS.md that tells them to:${RESET}"
echo "${DIM}  • Check for .agent/NORTH_STAR.md when entering repos${RESET}"
echo "${DIM}  • Load project-specific context and memory${RESET}"
echo "${DIM}  • Combine global + project knowledge${RESET}"
echo ""

# Parse agents from openclaw.json using python
# We need python3 which should be available (bd-lite already requires it)
if ! command -v python3 >/dev/null 2>&1; then
  echo "${RED}✗${RESET} python3 not found - needed to parse openclaw.json"
  exit 1
fi

echo ""
echo "${BOLD}Scanning OpenClaw agents...${RESET}"

# Extract workspaces from openclaw.json
WORKSPACES=$(python3 - "$OPENCLAW_CONFIG" <<'PYEOF'
import json
import sys

try:
    with open(sys.argv[1]) as f:
        config = json.load(f)

    agents = config.get("agents", {}).get("list", [])
    for agent in agents:
        workspace = agent.get("workspace", "")
        name = agent.get("identity", {}).get("name", agent.get("id", "unknown"))
        if workspace:
            print(f"{workspace}|{name}")
except Exception as e:
    print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF
)

if [ -z "$WORKSPACES" ]; then
  echo "${YELLOW}!${RESET} No agents found in openclaw.json"
  exit 0
fi

# Function to generate integration snippet with dynamic workspace path
generate_integration_snippet() {
  local workspace="$1"
  cat <<EOF

$VERSION_MARKER
$INTEGRATION_MARKER

When working in any repository, **automatically check for project-specific context**:

1. **Check for \`.agent/NORTH_STAR.md\`** - if exists, read it first for project orientation
2. **Check for \`.agent/MEMORY.md\`** - if exists, read it for persistent project facts
3. **Check for \`.agent/memory/BEADS.md\`** - if exists, check for active project tasks

**Context Stack** (layered approach):
- **Global identity**: \`$workspace/IDENTITY.md\` (who you are)
- **Global memory**: \`$workspace/memory/\` (your accumulated knowledge)
- **Project context**: \`.agent/NORTH_STAR.md\` (what this repo is)
- **Project memory**: \`.agent/MEMORY.md\` (facts about this repo)
- **Project tasks**: \`.agent/memory/BEADS.md\` (active work in this repo)

**Example workflow**:
\`\`\`
User: "Work on the openclaw repo"

You:
1. Load global identity from $workspace/IDENTITY.md
2. Load global memory from $workspace/memory/
3. cd ~/Documents/GitHub/openclaw
4. Check if .agent/NORTH_STAR.md exists → yes, read it
5. Check if .agent/MEMORY.md exists → yes, read it
6. Check if .agent/memory/BEADS.md exists → yes, check for tasks
7. Combine all context and proceed with work
\`\`\`

**Note**: The \`.agent/\` folder is created by the YourAgent scaffold (\`npx youragent\`). If it doesn't exist in a repo, skip this step and use only your global context.
EOF
}

TOTAL_COUNT=0
UPDATED_COUNT=0
SKIPPED_COUNT=0

# Process each workspace
while IFS='|' read -r workspace name; do
  TOTAL_COUNT=$((TOTAL_COUNT + 1))
  AGENTS_MD="$workspace/AGENTS.md"

  if [ ! -f "$AGENTS_MD" ]; then
    echo "  ${YELLOW}!${RESET} $name: ${DIM}$AGENTS_MD not found${RESET}"
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    continue
  fi

  # Check if integration already exists (check both markers for idempotency)
  if grep -Fq "$INTEGRATION_MARKER" "$AGENTS_MD" || grep -Fq "$VERSION_MARKER" "$AGENTS_MD"; then
    echo "  ${DIM}·${RESET} $name: ${DIM}already configured${RESET}"
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    continue
  fi

  # Create backup before modifying
  BACKUP_DIR="$workspace/memory/BACKUPS"
  mkdir -p "$BACKUP_DIR"
  TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  BACKUP_FILE="$BACKUP_DIR/AGENTS.md.backup.$TIMESTAMP"
  cp "$AGENTS_MD" "$BACKUP_FILE"

  # Add integration snippet with dynamic workspace path
  generate_integration_snippet "$workspace" >> "$AGENTS_MD"

  echo "  ${GREEN}✓${RESET} $name: ${DIM}configured at $workspace${RESET}"
  echo "     ${DIM}Backup: $BACKUP_FILE${RESET}"
  UPDATED_COUNT=$((UPDATED_COUNT + 1))
done <<< "$WORKSPACES"

echo ""
echo "${BOLD}Summary:${RESET}"
echo "  ${GREEN}✓${RESET} Updated: $UPDATED_COUNT agent(s)"
echo "  ${DIM}·${RESET} Skipped: $SKIPPED_COUNT agent(s) (already configured or missing AGENTS.md)"
echo "  ${BOLD}Total: $TOTAL_COUNT agent(s)${RESET}"
echo ""
echo "${GREEN}Done!${RESET} Your OpenClaw agents will now auto-detect .agent/ folders."
echo ""

#!/usr/bin/env bash
# youragent/install.sh
# Your first agent, done right. By Trilogy AI Center of Excellence.
# Drops .agent/ into the current repo — personality, memory, bead ledger,
# 130-pattern knowledge catalog from 14 COE articles.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/stanhus/youragent/main/install.sh | bash
#   npx youragent
#   BOOTSTRAP_LOCAL_SRC=/path/to/repo bash install.sh   # local testing

set -euo pipefail

# ---------- config ----------
# Non-tech one-liner:
#   curl -fsSL https://raw.githubusercontent.com/stanhus/youragent/main/install.sh | bash
# Requires only: curl + bash. No git, no npm, no python (except bd-lite at runtime).
RAW_BASE="${BOOTSTRAP_RAW_BASE:-https://raw.githubusercontent.com/stanhus/youragent/main}"
SRC_DIR="${BOOTSTRAP_LOCAL_SRC:-}"
TARGET_DIR="${BOOTSTRAP_TARGET:-$PWD/.agent}"
FORCE="${BOOTSTRAP_FORCE:-0}"
NO_ANIM="${NO_ANIM:-0}"

# File manifest — used by both local-copy and remote-curl modes.
TEMPLATES=(SOUL AGENT IDENTITY USER TOOLS MEMORY NORTH_STAR HUMAN_GUIDE TWEAKING KNOWLEDGE_PACK PATTERNS_CATALOG GOGCLI_STARTER LESSONS_LEARNED GETTING_STARTED)
MEMORY_FILES=(BEADS.md README.md bd-lite.sh PROMPTS.md HANDOFF.md SHORT_TERM_MEMORY.md)
SKILLS_FILES=(search-substack.sh README.md)

# ---------- colors ----------
if [ -t 1 ] && [ "$NO_ANIM" != "1" ]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
  RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'
  BLUE=$'\033[34m'; MAGENTA=$'\033[35m'; CYAN=$'\033[36m'
else
  BOLD=""; DIM=""; RESET=""; RED=""; GREEN=""; YELLOW=""; BLUE=""; MAGENTA=""; CYAN=""
fi

# ---------- animations ----------
spin() {
  local pid=$1 msg=$2
  local chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0
  if [ "$NO_ANIM" = "1" ]; then
    echo "  ${CYAN}→${RESET} $msg"
    wait "$pid"
    return
  fi
  while kill -0 "$pid" 2>/dev/null; do
    i=$(( (i+1) % 10 ))
    printf "\r  ${CYAN}%s${RESET} %s" "${chars:$i:1}" "$msg"
    sleep 0.08
  done
  wait "$pid"
  printf "\r  ${GREEN}✓${RESET} %s\n" "$msg"
}

bar() {
  local label="$1" total="${2:-20}"
  [ "$NO_ANIM" = "1" ] && { echo "  $label"; return; }
  local width=30
  for i in $(seq 1 "$total"); do
    local filled=$(( i * width / total ))
    local empty=$(( width - filled ))
    printf "\r  ${CYAN}[${RESET}"
    printf "%0.s█" $(seq 1 $filled) 2>/dev/null || true
    printf "%0.s░" $(seq 1 $empty) 2>/dev/null || true
    printf "${CYAN}]${RESET} %s" "$label"
    sleep 0.02
  done
  printf "\r  ${GREEN}[${RESET}"
  printf "%0.s█" $(seq 1 $width)
  printf "${GREEN}]${RESET} %s ${GREEN}✓${RESET}\n" "$label"
}

say() { printf "  %s\n" "$1"; }
hr() { printf "  ${DIM}────────────────────────────────────────────────────────${RESET}\n"; }

banner() {
  cat <<EOF

${BOLD}${MAGENTA}
   ┌─────────────────────────────────────────────────────┐
   │                                                     │
   │           y o u r   a g e n t                       │
   │                                                     │
   │   ${CYAN}Your first agent, done right.${MAGENTA}                     │
   │   ${DIM}By the Trilogy AI Center of Excellence.${MAGENTA}            │
   │                                                     │
   └─────────────────────────────────────────────────────┘
${RESET}
  ${DIM}You're in the right place. This takes about 60 seconds.${RESET}
  ${DIM}Nothing leaves your machine. Nothing runs in the background.${RESET}
  ${DIM}When it's done, your repo has an agent with memory + opinions.${RESET}
EOF
}

# ---------- preflight ----------
banner
say "${DIM}Target:${RESET} ${BOLD}${TARGET_DIR}${RESET}"
hr

if [ -e "$TARGET_DIR" ] && [ "$FORCE" != "1" ]; then
  say "${RED}✗${RESET} ${BOLD}$TARGET_DIR already exists.${RESET}"
  say "  Re-run with ${BOLD}BOOTSTRAP_FORCE=1${RESET} to overwrite, or ${BOLD}rm -rf $TARGET_DIR${RESET} first."
  exit 1
fi

say "${BOLD}What's about to happen (all local, all markdown):${RESET}"
say "  ${CYAN}1.${RESET} Give your agent a ${BOLD}personality${RESET} (SOUL.md) — opinionated, brief, no corporate tone"
say "  ${CYAN}2.${RESET} Give your agent an ${BOLD}operating manual${RESET} (AGENT.md) — plan-first, evidence-on-close"
say "  ${CYAN}3.${RESET} Build a ${BOLD}memory system${RESET} (long-term + short-term + handoff)"
say "  ${CYAN}4.${RESET} Install a ${BOLD}task ledger${RESET} (bd-lite) — beads with dependency + acceptance"
say "  ${CYAN}5.${RESET} Drop a ${BOLD}130-pattern catalog${RESET} from 14 COE articles for the agent to absorb"
say "  ${CYAN}6.${RESET} Add ${BOLD}skills${RESET} — substack search, source retrieval, attribution"
say "  ${CYAN}7.${RESET} Write the ${BOLD}north star${RESET} doc every new session reads first"
hr

# ---------- source resolution ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"
SOURCE_MODE=""  # "local" | "remote"

resolve_src() {
  if [ -n "$SRC_DIR" ]; then
    say "${BOLD}Source:${RESET} local override → ${SRC_DIR}"
    if [ ! -d "$SRC_DIR/templates" ]; then
      say "${RED}✗${RESET} BOOTSTRAP_LOCAL_SRC set but $SRC_DIR/templates/ is missing"
      exit 1
    fi
    SOURCE_MODE="local"
    return
  fi

  # Package-local (npx or cloned repo): script sits next to templates/
  if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/templates" ] && [ -d "$SCRIPT_DIR/memory-scaffold" ]; then
    say "${BOLD}Source:${RESET} package-local → ${SCRIPT_DIR}"
    SRC_DIR="$SCRIPT_DIR"
    SOURCE_MODE="local"
    return
  fi

  # Remote curl mode — the non-tech one-liner path.
  say "${BOLD}Source:${RESET} remote (curl) → ${RAW_BASE}"
  if ! command -v curl >/dev/null 2>&1; then
    say "${RED}✗${RESET} curl not found. Install curl (it's on basically every system)."
    exit 1
  fi
  SOURCE_MODE="remote"
}

# fetch_file <repo-relative-source> <target-path>
fetch_file() {
  local rel="$1" dest="$2"
  if [ "$SOURCE_MODE" = "local" ]; then
    cp "$SRC_DIR/$rel" "$dest"
  else
    curl -fsSL "$RAW_BASE/$rel" -o "$dest" || {
      say "${RED}✗${RESET} failed to fetch $rel"
      exit 1
    }
  fi
}

resolve_src
hr

# ---------- do the work ----------
mkdir -p "$TARGET_DIR/memory/BACKUPS" "$TARGET_DIR/memory/archives"

template_desc() {
  case "$1" in
    SOUL) echo "SOUL.md (personality, 8 vibe rules)" ;;
    AGENT) echo "AGENT.md (operating manual)" ;;
    IDENTITY) echo "IDENTITY.md (name + purpose)" ;;
    USER) echo "USER.md (who you are)" ;;
    TOOLS) echo "TOOLS.md (expected + recommended tools)" ;;
    MEMORY) echo "MEMORY.md (long-term facts, append-only)" ;;
    NORTH_STAR) echo "NORTH_STAR.md (session orientation)" ;;
    HUMAN_GUIDE) echo "HUMAN_GUIDE.md (read me first)" ;;
    TWEAKING) echo "TWEAKING.md (how to adjust)" ;;
    KNOWLEDGE_PACK) echo "KNOWLEDGE_PACK.md (article index w/ attribution)" ;;
    PATTERNS_CATALOG) echo "PATTERNS_CATALOG.md (130 patterns from 14 COE articles)" ;;
    GOGCLI_STARTER) echo "GOGCLI_STARTER.md (Google Workspace next-step)" ;;
    LESSONS_LEARNED) echo "LESSONS_LEARNED.md (append-only log)" ;;
    GETTING_STARTED) echo "GETTING_STARTED.md (agentic onboarding)" ;;
    *) echo "$1.md" ;;
  esac
}

memory_desc() {
  case "$1" in
    BEADS.md) echo "memory/BEADS.md (task ledger)" ;;
    README.md) echo "memory/README.md (bead rules)" ;;
    bd-lite.sh) echo "memory/bd-lite.sh (bead CLI)" ;;
    PROMPTS.md) echo "memory/PROMPTS.md (human-instruction log)" ;;
    HANDOFF.md) echo "memory/HANDOFF.md (session-to-session state)" ;;
    SHORT_TERM_MEMORY.md) echo "memory/SHORT_TERM_MEMORY.md (scratch pad)" ;;
    *) echo "memory/$1" ;;
  esac
}

skill_desc() {
  case "$1" in
    search-substack.sh) echo "skills/search-substack.sh (source article retrieval)" ;;
    README.md) echo "skills/README.md (skill rules + attribution)" ;;
    *) echo "skills/$1" ;;
  esac
}

say "${BOLD}Installing templates${RESET}"
for t in "${TEMPLATES[@]}"; do
  bar "$(template_desc "$t")" 12
  fetch_file "templates/${t}.md" "$TARGET_DIR/${t}.md"
done

hr
say "${BOLD}Initializing memory scaffold${RESET}"
for f in "${MEMORY_FILES[@]}"; do
  bar "$(memory_desc "$f")" 10
  fetch_file "memory-scaffold/${f}" "$TARGET_DIR/memory/${f}"
done
chmod +x "$TARGET_DIR/memory/bd-lite.sh"

hr
say "${BOLD}Installing skills${RESET}"
mkdir -p "$TARGET_DIR/skills"
for f in "${SKILLS_FILES[@]}"; do
  bar "$(skill_desc "$f")" 10
  fetch_file "skills-scaffold/${f}" "$TARGET_DIR/skills/${f}"
done
chmod +x "$TARGET_DIR/skills/search-substack.sh"

hr

# ---------- tool probes ----------
say "${BOLD}Tool probes${RESET}"
if command -v npx >/dev/null 2>&1; then
  say "  ${GREEN}✓${RESET} npx available — ${BOLD}npx wwvcd${RESET} retrieval skill ready"
else
  say "  ${YELLOW}!${RESET} npx not found — install Node.js for WWVCD retrieval (${DIM}npx wwvcd${RESET})"
fi

if command -v git >/dev/null 2>&1; then
  say "  ${GREEN}✓${RESET} git available"
else
  say "  ${YELLOW}!${RESET} git missing — install for version control + repo recovery"
fi

if command -v gog >/dev/null 2>&1; then
  say "  ${GREEN}✓${RESET} gog CLI detected — Google Workspace ready"
else
  say "  ${DIM}·${RESET} gog CLI not installed — see ${BOLD}.agent/GOGCLI_STARTER.md${RESET} when ready"
fi

hr

# ---------- final message ----------
cat <<EOF

${BOLD}${GREEN}  Done. Your repo has an agent.${RESET}

${BOLD}You're set. Three things to do:${RESET}
  ${CYAN}1.${RESET} Open your agentic tool in this repo ${DIM}(Claude Code, Codex, Cursor, Aider, Windsurf, OpenClaw — any of them)${RESET}
  ${CYAN}2.${RESET} Paste this line to the agent:
       ${BOLD}"Read .agent/NORTH_STAR.md to orient, then ask me what I need."${RESET}
  ${CYAN}3.${RESET} Give it a real task. Watch it close beads with evidence.

${DIM}First time? Read .agent/HUMAN_GUIDE.md (2 min) and .agent/GETTING_STARTED.md (10 min).${RESET}
${DIM}Curious what the agent knows? .agent/PATTERNS_CATALOG.md — 130 patterns it inherited.${RESET}

${BOLD}Autonomous mode${RESET} ${DIM}(once you trust the agent — usually after 2-3 tasks)${RESET}
  Claude Code:     ${BOLD}claude --dangerously-skip-permissions${RESET}
  Codex:           ${BOLD}codex --yolo${RESET}
  Aider:           ${BOLD}aider --yes${RESET}
  Cursor/Windsurf: agent mode with auto-approve in settings
  ${YELLOW}Warning:${RESET} only under version control, only with a bead graph with acceptance criteria.
  First few runs: watch the agent close beads with real evidence. Trust is earned.

${BOLD}Next level${RESET}
  ${BOLD}.agent/GOGCLI_STARTER.md${RESET} wires the agent into your Gmail / Docs / Calendar.
  This is where "neat" becomes "runs my inbox while I sleep."

${DIM}Personality too sharp? Too soft? .agent/TWEAKING.md shows how to dial it.${RESET}
${DIM}Built by Trilogy AI COE — trilogyai.substack.com.${RESET}

EOF

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
#
# Re-running on a repo that already has our scaffold → safe update (your
# personal files are preserved; only tool-authored files refresh).
# BOOTSTRAP_FORCE=1 = nuke-and-overwrite escape hatch.

set -euo pipefail

# ---------- subcommand dispatch ----------
SUBCOMMAND="${1:-install}"

# ---------- config ----------
SCAFFOLD_VERSION="1.3.0"
RAW_BASE="${BOOTSTRAP_RAW_BASE:-https://raw.githubusercontent.com/stanhus/youragent/main}"
SRC_DIR="${BOOTSTRAP_LOCAL_SRC:-}"
TARGET_DIR="${BOOTSTRAP_TARGET:-$PWD/.agent}"
FORCE="${BOOTSTRAP_FORCE:-0}"
NO_ANIM="${NO_ANIM:-0}"
MARKER_FILE="$TARGET_DIR/.youragent"

# File manifest — split by ownership.
# SCAFFOLD = we own them, refresh on every install/update.
# USER = we initialize once, then never touch (skip-if-exists).
SCAFFOLD_TEMPLATES=(SOUL AGENT TOOLS NORTH_STAR HUMAN_GUIDE TWEAKING KNOWLEDGE_PACK PATTERNS_CATALOG GOGCLI_STARTER GETTING_STARTED)
USER_TEMPLATES=(IDENTITY USER MEMORY LESSONS_LEARNED)
SCAFFOLD_MEMORY=(README.md bd-lite.sh)
USER_MEMORY=(BEADS.md PROMPTS.md HANDOFF.md SHORT_TERM_MEMORY.md)
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

# ---------- status subcommand ----------
cmd_status() {
  local agent_dir="$PWD/.agent"
  local marker="$agent_dir/.youragent"

  if [ ! -d "$agent_dir" ] || [ ! -f "$marker" ]; then
    cat <<EOF

  ${DIM}No agent installed in this directory.${RESET}

  ${BOLD}Run:${RESET}   npx youragent
  ${BOLD}Help:${RESET}  https://github.com/stanhus/youragent

EOF
    exit 0
  fi

  # Gather facts (python3 does the heavy lifting, same as bd-lite)
  python3 - "$agent_dir" "$SCAFFOLD_VERSION" "$BOLD" "$DIM" "$RESET" "$GREEN" "$YELLOW" "$CYAN" "$MAGENTA" <<'PY'
import sys, os, re
from datetime import datetime, timezone

agent_dir, current_version, BOLD, DIM, RESET, GREEN, YELLOW, CYAN, MAGENTA = sys.argv[1:10]

def read_lines(path, n=10):
    try:
        with open(path) as f:
            return [l.rstrip() for l in f.readlines()[:n]]
    except FileNotFoundError:
        return []

def marker_info():
    try:
        with open(os.path.join(agent_dir, ".youragent")) as f:
            kv = {}
            for line in f:
                if "=" in line:
                    k, v = line.strip().split("=", 1)
                    kv[k] = v
            return kv
    except FileNotFoundError:
        return {}

def is_placeholder(line):
    """Template scaffolding we shouldn't treat as user content."""
    if not line: return True
    if "_(" in line: return True                                       # italic placeholder: _(fill me in)_
    if line.startswith(("#", ">", "-", "*", "_", "|")): return True   # any markdown prefix
    stripped = re.sub(r'[*_`~]+', '', line).strip()                   # strip bold/italic markers
    if not stripped: return True
    if stripped.endswith(":") and len(stripped) < 40: return True     # label like "Example:" or "**In scope:**"
    return False

def extract_identity():
    """Pull name + purpose from IDENTITY.md if the human filled them in."""
    lines = read_lines(os.path.join(agent_dir, "IDENTITY.md"), 80)
    name = None
    purpose = None
    for i, line in enumerate(lines):
        s = line.strip()
        if name is None and s.startswith("## Name"):
            for j in range(i+1, min(i+6, len(lines))):
                v = lines[j].strip()
                if v and not is_placeholder(v):
                    name = v.lstrip("*_ ").rstrip("*_ ")
                    break
        if purpose is None and s.startswith("## Purpose"):
            for j in range(i+1, min(i+10, len(lines))):
                v = lines[j].strip()
                if v and not is_placeholder(v):
                    purpose = v.strip(" >").rstrip(".")
                    if len(purpose) > 53:
                        purpose = purpose[:50] + "..."
                    break
    return name, purpose

def count_beads():
    """Parse memory/BEADS.md, count by status."""
    path = os.path.join(agent_dir, "memory", "BEADS.md")
    counts = {"pending": 0, "in_progress": 0, "blocked": 0, "done": 0, "cancelled": 0}
    try:
        with open(path) as f:
            for line in f:
                m = re.match(r'^\| B\d{4} \| \S+ \| (\S+) \|', line)
                if m:
                    status = m.group(1)
                    if status in counts:
                        counts[status] += 1
    except FileNotFoundError:
        pass
    return counts

def count_memory_facts():
    """Count lines in MEMORY.md that look like user-added facts.
    Skip markdown scaffolding, numbered rules, placeholder italics, HR dividers."""
    path = os.path.join(agent_dir, "MEMORY.md")
    count = 0
    try:
        with open(path) as f:
            for line in f:
                s = line.strip()
                if not s: continue
                if s.startswith(("#", ">", "-", "*", "|", "~", "_")): continue
                if re.match(r"^\d+\.", s): continue          # numbered list item
                if re.match(r"^-{3,}$", s): continue          # horizontal rule
                if "_(" in s: continue                        # template placeholder
                count += 1
    except FileNotFoundError:
        pass
    return count

def count_lessons():
    """Count '## YYYY' sections in LESSONS_LEARNED.md."""
    lessons = 0
    try:
        with open(os.path.join(agent_dir, "LESSONS_LEARNED.md")) as f:
            for line in f:
                if re.match(r'^##\s+20\d{2}-', line):
                    lessons += 1
    except FileNotFoundError:
        pass
    return lessons

def age_of(iso_ts):
    try:
        ts = datetime.fromisoformat(iso_ts.replace("Z", "+00:00"))
        now = datetime.now(timezone.utc)
        delta = now - ts
        s = int(delta.total_seconds())
        if s < 60: return f"{s}s ago"
        if s < 3600: return f"{s//60}m ago"
        if s < 86400: return f"{s//3600}h ago"
        return f"{s//86400}d ago"
    except Exception:
        return ""

marker = marker_info()
version = marker.get("version", "?")
installed = marker.get("installed", "")
installed_age = age_of(installed) if installed else ""

name, purpose = extract_identity()
name = name or "(unnamed — edit IDENTITY.md)"
purpose = purpose or "(no purpose set — edit IDENTITY.md)"

beads = count_beads()
open_count = beads["pending"] + beads["in_progress"]
blocked = beads["blocked"]
done = beads["done"]

facts = count_memory_facts()
lessons = count_lessons()

# version drift hint
version_hint = ""
if version != current_version:
    version_hint = f" {YELLOW}(update available → v{current_version}){RESET}"

# layout
W = 57  # inner width
def row(content=""):
    # content may include ANSI codes; we can't measure visually, so we just pad with spaces up to a visual count.
    # Strip ANSI for length calc.
    visible = re.sub(r'\x1b\[[0-9;]*m', '', content)
    pad = max(0, W - len(visible))
    print(f"  {MAGENTA}│{RESET} {content}{' ' * pad} {MAGENTA}│{RESET}")

def divider(label=""):
    if label:
        line = f"├─ {label} "
        dashes = "─" * (W - len(line) + 2)
        print(f"  {MAGENTA}{line}{dashes}┤{RESET}")
    else:
        print(f"  {MAGENTA}├{'─' * (W+2)}┤{RESET}")

print()
print(f"  {MAGENTA}╭─ your agent {'─' * (W - 11)}╮{RESET}")
row()
row(f"  {BOLD}{name}{RESET}")
row(f"  {DIM}{purpose}{RESET}")
row()
divider("beads")
row()
row(f"  {GREEN}●{RESET}  {open_count} open       {DIM}ready to claim{RESET}")
row(f"  {YELLOW}○{RESET}  {blocked} blocked    {DIM}waiting on something{RESET}")
row(f"  {DIM}✓{RESET}  {done} done       {DIM}closed with evidence{RESET}")
row()
divider("signals")
row()
row(f"  Memory:     {facts} facts logged")
row(f"  Lessons:    {lessons} captured")
row(f"  Scaffold:   v{version}{version_hint}  {DIM}({installed_age}){RESET}")
row()
print(f"  {MAGENTA}╰{'─' * (W+2)}╯{RESET}")
print()

# Action line
if open_count > 0:
    print(f"  {BOLD}Next:{RESET}  ./.agent/memory/bd-lite.sh ready")
elif blocked > 0:
    print(f"  {BOLD}Next:{RESET}  Unblock a bead — see ./.agent/memory/BEADS.md")
elif done == 0:
    print(f"  {BOLD}Next:{RESET}  Open your agentic tool, give it a task")
else:
    print(f"  {BOLD}Next:{RESET}  All beads drained. Give your agent something new.")

print(f"  {DIM}Help:  cat .agent/HUMAN_GUIDE.md{RESET}")
print()
PY
  exit 0
}

if [ "$SUBCOMMAND" = "status" ]; then
  cmd_status
fi

# ---------- configure-openclaw subcommand ----------
cmd_configure_openclaw() {
  if [ ! -f "$HOME/.openclaw/openclaw.json" ]; then
    cat <<EOF

  ${DIM}OpenClaw not detected (no ~/.openclaw/openclaw.json)${RESET}

  ${BOLD}What is this?${RESET}
    This command configures persistent OpenClaw agents to automatically
    read .agent/ folders when they enter repositories with youragent.

  ${BOLD}Install OpenClaw:${RESET}  https://github.com/openclaw/openclaw

EOF
    exit 1
  fi

  # Determine source mode
  local src_dir="${BOOTSTRAP_LOCAL_SRC:-}"
  local script_path

  if [ -n "$src_dir" ]; then
    # Local mode - use local openclaw-configure.sh
    script_path="$src_dir/openclaw-configure.sh"
    if [ ! -f "$script_path" ]; then
      say "${RED}✗${RESET} Local source specified but openclaw-configure.sh not found at $script_path"
      exit 1
    fi
  else
    # Remote mode - fetch from GitHub
    script_path="/tmp/.openclaw-configure-$$.sh"
    curl -fsSL "$RAW_BASE/openclaw-configure.sh" -o "$script_path" || {
      say "${RED}✗${RESET} Failed to fetch openclaw-configure.sh"
      exit 1
    }
    chmod +x "$script_path"
  fi

  # Run the configuration script
  "$script_path"
  local exit_code=$?

  # Clean up temp file if we created one
  if [ -z "$src_dir" ]; then
    rm -f "$script_path"
  fi

  exit $exit_code
}

if [ "$SUBCOMMAND" = "configure-openclaw" ]; then
  cmd_configure_openclaw
fi

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
  ${DIM}Nothing leaves your machine. Nothing runs in the background.${RESET}
EOF
}

# ---------- preflight + mode detection ----------
banner
say "${DIM}Target:${RESET} ${BOLD}${TARGET_DIR}${RESET}"
hr

INSTALL_MODE="fresh"
if [ -e "$TARGET_DIR" ]; then
  if [ "$FORCE" = "1" ]; then
    INSTALL_MODE="force"
  elif [ -f "$MARKER_FILE" ]; then
    INSTALL_MODE="update"
  else
    INSTALL_MODE="refuse"
  fi
fi

if [ "$INSTALL_MODE" = "refuse" ]; then
  say "${YELLOW}!${RESET} Found an existing ${BOLD}$TARGET_DIR${RESET} folder we don't recognize."
  say "  It's missing our marker file, so we won't touch it — your setup is safe."
  say ""
  say "  ${BOLD}What you can do:${RESET}"
  say "    • Pick a different location: ${BOLD}BOOTSTRAP_TARGET=./.myagent bash install.sh${RESET}"
  say "    • Remove the folder first: ${BOLD}rm -rf $TARGET_DIR${RESET}"
  say "    • Back it up and re-run."
  exit 1
fi

# Mode-specific intro
case "$INSTALL_MODE" in
  fresh)
    say "${BOLD}What's about to happen (all local, all markdown):${RESET}"
    say "  ${CYAN}1.${RESET} Give your agent a ${BOLD}personality${RESET} (SOUL.md) — opinionated, brief, no corporate tone"
    say "  ${CYAN}2.${RESET} Give your agent an ${BOLD}operating manual${RESET} (AGENT.md) — plan-first, evidence-on-close"
    say "  ${CYAN}3.${RESET} Build a ${BOLD}memory system${RESET} (long-term + short-term + handoff)"
    say "  ${CYAN}4.${RESET} Install a ${BOLD}task ledger${RESET} (bd-lite) — beads with dependency + acceptance"
    say "  ${CYAN}5.${RESET} Drop a ${BOLD}130-pattern catalog${RESET} from 14 COE articles"
    say "  ${CYAN}6.${RESET} Add ${BOLD}skills${RESET} — substack search with attribution"
    say "  ${CYAN}7.${RESET} ${BOLD}Wire auto-loads${RESET} — CLAUDE.md / AGENTS.md / .cursorrules / .windsurfrules so your tool reads .agent/ automatically"
    ;;
  update)
    say "${BOLD}${GREEN}✓${RESET} Found an existing agent (installed by youragent). Running a safe update."
    say "  ${DIM}Scaffold files → refreshed to v${SCAFFOLD_VERSION}.${RESET}"
    say "  ${DIM}Your personal files (IDENTITY, USER, MEMORY, BEADS, LESSONS_LEARNED, ...) → left untouched.${RESET}"
    ;;
  force)
    say "${YELLOW}!${RESET} ${BOLD}BOOTSTRAP_FORCE=1${RESET} — overwriting everything including your personal files."
    ;;
esac
hr

# ---------- source resolution ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"
SOURCE_MODE=""

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

  if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/templates" ] && [ -d "$SCRIPT_DIR/memory-scaffold" ]; then
    say "${BOLD}Source:${RESET} package-local → ${SCRIPT_DIR}"
    SRC_DIR="$SCRIPT_DIR"
    SOURCE_MODE="local"
    return
  fi

  say "${BOLD}Source:${RESET} remote (curl) → ${RAW_BASE}"
  if ! command -v curl >/dev/null 2>&1; then
    say "${RED}✗${RESET} curl not found. Install curl (it's on basically every system)."
    exit 1
  fi
  SOURCE_MODE="remote"
}

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

# ---------- install ----------
mkdir -p "$TARGET_DIR/memory/BACKUPS" "$TARGET_DIR/memory/archives" "$TARGET_DIR/skills"

template_desc() {
  case "$1" in
    SOUL) echo "SOUL.md (personality)" ;;
    AGENT) echo "AGENT.md (operating manual)" ;;
    IDENTITY) echo "IDENTITY.md (your agent's name + purpose)" ;;
    USER) echo "USER.md (about you)" ;;
    TOOLS) echo "TOOLS.md (expected + recommended tools)" ;;
    MEMORY) echo "MEMORY.md (long-term facts)" ;;
    NORTH_STAR) echo "NORTH_STAR.md (session orientation)" ;;
    HUMAN_GUIDE) echo "HUMAN_GUIDE.md (read me first)" ;;
    TWEAKING) echo "TWEAKING.md (how to adjust)" ;;
    KNOWLEDGE_PACK) echo "KNOWLEDGE_PACK.md (article index)" ;;
    PATTERNS_CATALOG) echo "PATTERNS_CATALOG.md (130 patterns)" ;;
    GOGCLI_STARTER) echo "GOGCLI_STARTER.md (Google Workspace on-ramp)" ;;
    LESSONS_LEARNED) echo "LESSONS_LEARNED.md (mistake log)" ;;
    GETTING_STARTED) echo "GETTING_STARTED.md (agentic onboarding)" ;;
    *) echo "$1.md" ;;
  esac
}

memory_desc() {
  case "$1" in
    BEADS.md) echo "memory/BEADS.md (task ledger)" ;;
    README.md) echo "memory/README.md (bead rules)" ;;
    bd-lite.sh) echo "memory/bd-lite.sh (bead CLI)" ;;
    PROMPTS.md) echo "memory/PROMPTS.md (instruction log)" ;;
    HANDOFF.md) echo "memory/HANDOFF.md (session handoff)" ;;
    SHORT_TERM_MEMORY.md) echo "memory/SHORT_TERM_MEMORY.md (scratch pad)" ;;
    *) echo "memory/$1" ;;
  esac
}

skill_desc() {
  case "$1" in
    search-substack.sh) echo "skills/search-substack.sh (source retrieval)" ;;
    README.md) echo "skills/README.md (skill rules)" ;;
    *) echo "skills/$1" ;;
  esac
}

# install_file <source-rel-path> <dest-path> <is_user_file>
# USER files are skip-if-exists unless FORCE=1.
install_file() {
  local rel="$1" dest="$2" is_user="$3"
  if [ "$is_user" = "1" ] && [ -f "$dest" ] && [ "$FORCE" != "1" ]; then
    return 1  # skipped
  fi
  fetch_file "$rel" "$dest"
  return 0  # installed
}

COUNT_REFRESHED=0
COUNT_KEPT=0
COUNT_INSTALLED=0

say "${BOLD}Installing scaffold (tool-owned files)${RESET}"
for t in "${SCAFFOLD_TEMPLATES[@]}"; do
  bar "$(template_desc "$t")" 10
  fetch_file "templates/${t}.md" "$TARGET_DIR/${t}.md"
  COUNT_REFRESHED=$((COUNT_REFRESHED+1))
done

for f in "${SCAFFOLD_MEMORY[@]}"; do
  bar "$(memory_desc "$f")" 8
  fetch_file "memory-scaffold/${f}" "$TARGET_DIR/memory/${f}"
  COUNT_REFRESHED=$((COUNT_REFRESHED+1))
done
chmod +x "$TARGET_DIR/memory/bd-lite.sh"

for f in "${SKILLS_FILES[@]}"; do
  bar "$(skill_desc "$f")" 8
  fetch_file "skills-scaffold/${f}" "$TARGET_DIR/skills/${f}"
  COUNT_REFRESHED=$((COUNT_REFRESHED+1))
done
chmod +x "$TARGET_DIR/skills/search-substack.sh"

hr
if [ "$INSTALL_MODE" = "update" ]; then
  say "${BOLD}Checking your personal files (we don't touch these)${RESET}"
else
  say "${BOLD}Initializing your personal files (one-time, we'll never touch these again)${RESET}"
fi

for t in "${USER_TEMPLATES[@]}"; do
  dest="$TARGET_DIR/${t}.md"
  if install_file "templates/${t}.md" "$dest" "1"; then
    bar "$(template_desc "$t")" 8
    COUNT_INSTALLED=$((COUNT_INSTALLED+1))
  else
    say "  ${DIM}· kept:${RESET} $(template_desc "$t")"
    COUNT_KEPT=$((COUNT_KEPT+1))
  fi
done

for f in "${USER_MEMORY[@]}"; do
  dest="$TARGET_DIR/memory/${f}"
  if install_file "memory-scaffold/${f}" "$dest" "1"; then
    bar "$(memory_desc "$f")" 8
    COUNT_INSTALLED=$((COUNT_INSTALLED+1))
  else
    say "  ${DIM}· kept:${RESET} $(memory_desc "$f")"
    COUNT_KEPT=$((COUNT_KEPT+1))
  fi
done

# Write marker
printf "youragent-scaffold\nversion=%s\ninstalled=%s\n" "$SCAFFOLD_VERSION" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$MARKER_FILE"

hr

# ---------- tool auto-wire hooks ----------
REPO_ROOT="${TARGET_DIR%/.agent}"
say "${BOLD}Wiring tool auto-loads${RESET}"

hook_install() {
  local hookfile="$1" tool="$2"
  local dest="$REPO_ROOT/$hookfile"
  if [ -e "$dest" ]; then
    if grep -qE "youragent|NORTH_STAR\.md|\.agent/" "$dest" 2>/dev/null; then
      say "  ${GREEN}✓${RESET} $hookfile ${DIM}(already linked to the scaffold)${RESET}"
    else
      say "  ${YELLOW}!${RESET} $hookfile exists but doesn't reference .agent/."
      say "     ${DIM}Add this line so $tool reads the scaffold:${RESET}"
      say "         ${BOLD}See .agent/NORTH_STAR.md first.${RESET}"
    fi
    return
  fi
  fetch_file "hooks-scaffold/$hookfile" "$dest"
  say "  ${GREEN}✓${RESET} $hookfile ${DIM}($tool reads this automatically)${RESET}"
}

hook_install "CLAUDE.md" "Claude Code"
hook_install "AGENTS.md" "Codex"
hook_install ".cursorrules" "Cursor"
hook_install ".windsurfrules" "Windsurf"

hr

# ---------- runtime dep probes ----------
say "${BOLD}Runtime checks${RESET}"
if command -v python3 >/dev/null 2>&1; then
  say "  ${GREEN}✓${RESET} python3 available — bd-lite ready"
else
  say "  ${RED}!${RESET} ${BOLD}python3 not found${RESET} — bd-lite needs it. Install python3 before using the bead ledger."
fi

if command -v npx >/dev/null 2>&1; then
  say "  ${GREEN}✓${RESET} npx available — ${BOLD}npx wwvcd${RESET} retrieval skill ready"
else
  say "  ${YELLOW}!${RESET} npx not found — install Node.js for WWVCD retrieval"
fi

if command -v git >/dev/null 2>&1; then
  say "  ${GREEN}✓${RESET} git available"
else
  say "  ${YELLOW}!${RESET} git missing — install for version control + rollback safety"
fi

hr

# ---------- OpenClaw integration prompt ----------
if [ -f "$HOME/.openclaw/openclaw.json" ] && [ "$INSTALL_MODE" = "fresh" ]; then
  say "${BOLD}OpenClaw Detected${RESET}"
  say ""
  say "  ${DIM}Configure your OpenClaw agents to auto-read .agent/ folders:${RESET}"
  say "  ${BOLD}npx youragent configure-openclaw${RESET}"
  say ""
  hr
fi

# ---------- final message ----------
if [ "$INSTALL_MODE" = "update" ]; then
  cat <<EOF

${BOLD}${GREEN}  Done. Scaffold updated to v${SCAFFOLD_VERSION}.${RESET}

  ${BOLD}Refreshed:${RESET} ${COUNT_REFRESHED} tool-authored files
  ${BOLD}Kept safe:${RESET} ${COUNT_KEPT} personal files ${DIM}(your agent's name, memory, beads, lessons)${RESET}

  ${DIM}Re-run \`npx youragent\` anytime — updates are always safe.${RESET}

EOF
else
  cat <<EOF

${BOLD}${GREEN}  Done. Your repo has an agent.${RESET}

${BOLD}You're set. Two things to do:${RESET}
  ${CYAN}1.${RESET} Open your agentic tool in this repo ${DIM}(Claude Code / Codex / Cursor / Windsurf auto-load via the hook files)${RESET}
  ${CYAN}2.${RESET} Give it a real task. Watch it close beads with evidence.

${DIM}Aider: paste "Read .agent/NORTH_STAR.md to orient" at session start.${RESET}
${DIM}OpenClaw: run ${BOLD}npx youragent configure-openclaw${RESET}${DIM} to auto-configure all agents.${RESET}

${DIM}First time with agents? .agent/GETTING_STARTED.md (10 min).${RESET}
${DIM}Curious what the agent knows? .agent/PATTERNS_CATALOG.md — 130 patterns inherited from the COE.${RESET}

${BOLD}Autonomous mode${RESET} ${DIM}(once you trust it — usually after 2-3 tasks)${RESET}
  Claude Code:     ${BOLD}claude --dangerously-skip-permissions${RESET}
  Codex:           ${BOLD}codex --yolo${RESET}
  Aider:           ${BOLD}aider --yes${RESET}
  Cursor/Windsurf: agent mode with auto-approve in settings

${BOLD}Next level${RESET}
  ${BOLD}.agent/GOGCLI_STARTER.md${RESET} wires the agent into your Gmail / Docs / Calendar.
  This is where "neat" becomes "runs my inbox while I sleep."

${DIM}Personality too sharp? .agent/TWEAKING.md shows how to dial it.${RESET}
${DIM}Built by Trilogy AI COE — trilogyai.substack.com.${RESET}

EOF
fi

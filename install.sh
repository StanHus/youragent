#!/usr/bin/env bash
# agentize/install.sh
# Your first agent, done right. By Trilogy AI Center of Excellence.
# Drops .agent/ into the current repo — personality, memory, bead ledger,
# 130-pattern knowledge catalog from 14 COE articles.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/stanhus/youragent/main/install.sh | bash
#   npx agentize   (or: npx youragent — legacy alias, same package)
#   BOOTSTRAP_LOCAL_SRC=/path/to/repo bash install.sh   # local testing
#
# Re-running on a repo that already has our scaffold → safe update (your
# personal files are preserved; only tool-authored files refresh).
# BOOTSTRAP_FORCE=1 = nuke-and-overwrite escape hatch.

set -euo pipefail

# ---------- subcommand dispatch ----------
SUBCOMMAND="${1:-install}"

# ---------- config ----------
SCAFFOLD_VERSION="2.1.0"
RAW_BASE="${BOOTSTRAP_RAW_BASE:-https://raw.githubusercontent.com/stanhus/youragent/main}"
SRC_DIR="${BOOTSTRAP_LOCAL_SRC:-}"
TARGET_DIR="${BOOTSTRAP_TARGET:-$PWD/.agent}"
FORCE="${BOOTSTRAP_FORCE:-0}"
NO_ANIM="${NO_ANIM:-0}"
MARKER_FILE="$TARGET_DIR/.youragent"

# v2.0: hook profile scales scaffold strictness without editing files.
# minimal  = only load-bearing instincts/hooks (least context, least friction)
# standard = default
# strict   = every guard on (verify required, no FIFO bd ready, no vague closes)
AGENTIZE_PROFILE="${AGENTIZE_PROFILE:-standard}"
case "$AGENTIZE_PROFILE" in
  minimal|standard|strict) ;;
  *) AGENTIZE_PROFILE="standard" ;;
esac

# File manifest — split by ownership.
# SCAFFOLD = we own them, refresh on every install/update.
# USER = we initialize once, then never touch (skip-if-exists).
SCAFFOLD_TEMPLATES=(SOUL AGENT TOOLS NORTH_STAR HUMAN_GUIDE TWEAKING KNOWLEDGE_PACK PATTERNS_CATALOG GOGCLI_STARTER GETTING_STARTED)
USER_TEMPLATES=(IDENTITY USER MEMORY LESSONS_LEARNED)
SCAFFOLD_MEMORY=(README.md bd.sh bd-rank.sh)
USER_MEMORY=(BEADS.md PROMPTS.md HANDOFF.md SHORT_TERM_MEMORY.md)
# v2.0: instincts/ — short operational reflexes (trigger/action/evidence)
SCAFFOLD_INSTINCTS=(README.md bd-rank-first.md evidence-or-die.md retrieve-before-invent.md plan-before-touch.md lessons-on-mistake.md dont-narrate.md)
SKILLS_FILES=(search-substack.sh memory-search.sh plan.sh verify.sh learn.sh README.md)
# v2.1: mesh — filesystem inbox/outbox so agentize nodes in one tree can talk
# (opt-in per node). We own these; config.json is per-node and skip-if-exists.
MESH_FILES=(mesh.sh README.md)

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

# ---------- status + validate subcommands ----------
run_agent_audit() {
  local mode="$1" missing_exit="${2:-0}"
  local agent_dir="$PWD/.agent"
  local marker="$agent_dir/.youragent"

  if [ ! -d "$agent_dir" ] || [ ! -f "$marker" ]; then
    cat <<EOF

  ${DIM}No agent installed in this directory.${RESET}

  ${BOLD}Run:${RESET}   npx agentize
  ${BOLD}Help:${RESET}  https://github.com/stanhus/youragent

EOF
    exit "$missing_exit"
  fi

  python3 - "$mode" "$agent_dir" "$SCAFFOLD_VERSION" "$BOLD" "$DIM" "$RESET" "$GREEN" "$YELLOW" "$CYAN" "$MAGENTA" <<'PY'
import sys, os, re
from datetime import datetime, timezone

mode, agent_dir, current_version, BOLD, DIM, RESET, GREEN, YELLOW, CYAN, MAGENTA = sys.argv[1:11]
repo_root = os.path.dirname(agent_dir)

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
    raw = line.strip()
    if not raw: return True
    if "_(" in raw: return True                                       # italic placeholder: _(fill me in)_
    stripped = re.sub(r'[*_`~]+', '', raw).strip()                    # strip bold/italic markers
    if not stripped: return True
    if raw.startswith(("#", ">", "|")): return True                   # headings, quotes, tables
    if re.match(r'^[-*]\s+', raw): return True                        # bullet markers only
    if stripped.endswith(":") and len(stripped) < 40: return True     # label like "Example:" or "**In scope:**"
    return False

def clean_inline_markdown(text):
    return re.sub(r'[*_`~]+', '', text).strip()

def extract_name_value(text):
    cleaned = clean_inline_markdown(text).lstrip("> ").strip()
    primary = re.split(r'\s+[—-]\s+|\s+\|\s+', cleaned, maxsplit=1)[0].strip()
    return primary or cleaned

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
                    name = extract_name_value(v)
                    break
        if purpose is None and s.startswith("## Purpose"):
            for j in range(i+1, min(i+10, len(lines))):
                v = lines[j].strip()
                if v and not is_placeholder(v):
                    purpose = clean_inline_markdown(v).strip(" >").rstrip(".")
                    if len(purpose) > 53:
                        purpose = purpose[:50] + "..."
                    break
    return name, purpose

def has_placeholder_identity():
    lines = read_lines(os.path.join(agent_dir, "IDENTITY.md"), 80)
    for line in lines:
        if "_(" in line:
            return True
    return False

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

def required_paths():
    return [
        "SOUL.md",
        "AGENT.md",
        "NORTH_STAR.md",
        "IDENTITY.md",
        "USER.md",
        "MEMORY.md",
        "LESSONS_LEARNED.md",
        os.path.join("memory", "BEADS.md"),
        os.path.join("memory", "PROMPTS.md"),
        os.path.join("memory", "HANDOFF.md"),
        os.path.join("memory", "SHORT_TERM_MEMORY.md"),
        os.path.join("memory", "bd.sh"),
        os.path.join("memory", "bd-rank.sh"),
        os.path.join("skills", "search-substack.sh"),
        os.path.join("mesh", "mesh.sh"),
    ]

def hook_targets():
    return [
        "CLAUDE.md",
        "AGENTS.md",
        ".cursorrules",
        ".windsurfrules",
    ]

def file_contains_scaffold_ref(path):
    try:
        with open(path) as f:
            content = f.read()
        return any(token in content for token in ("agentize", "youragent", "NORTH_STAR.md", ".agent/"))
    except FileNotFoundError:
        return False

def validate():
    failures = []
    warnings = []
    passes = []

    marker = marker_info()
    version = marker.get("version", "?")
    installed = marker.get("installed", "")

    if version == current_version:
        passes.append(f"Scaffold marker version matches v{current_version}")
    else:
        warnings.append(f"Scaffold marker version is v{version}; installer ships v{current_version}")

    if installed:
        passes.append(f"Marker install timestamp present ({installed})")
    else:
        failures.append("Scaffold marker is missing install timestamp")

    missing = [rel for rel in required_paths() if not os.path.exists(os.path.join(agent_dir, rel))]
    if missing:
        failures.append("Missing required scaffold files: " + ", ".join(missing))
    else:
        passes.append(f"Required scaffold files present ({len(required_paths())} checked)")

    name, purpose = extract_identity()
    if name:
        passes.append(f"Identity name resolves to '{name}'")
    elif has_placeholder_identity():
        warnings.append("IDENTITY.md still contains placeholder text; status will show unnamed until filled")
    else:
        failures.append("IDENTITY.md exists but status could not extract a name")

    if purpose:
        passes.append("Identity purpose resolves for status output")
    else:
        warnings.append("IDENTITY.md purpose is still unset or unreadable")

    hook_states = []
    for hook in hook_targets():
        hook_path = os.path.join(repo_root, hook)
        if not os.path.exists(hook_path):
            warnings.append(f"Hook file missing at repo root: {hook}")
            continue
        if file_contains_scaffold_ref(hook_path):
            hook_states.append(hook)
        else:
            warnings.append(f"Hook file exists but does not reference .agent/: {hook}")
    if hook_states:
        passes.append(f"Hook files referencing scaffold: {', '.join(hook_states)}")

    bead_path = os.path.join(agent_dir, "memory", "BEADS.md")
    bead_count = 0
    try:
        with open(bead_path) as f:
            for line in f:
                if re.match(r'^\| B\d{4} \|', line):
                    bead_count += 1
    except FileNotFoundError:
        pass
    if bead_count:
        passes.append(f"Bead ledger parseable ({bead_count} beads)")
    else:
        failures.append("Bead ledger contains no parseable beads")

    memory_facts = count_memory_facts()
    if memory_facts == 0:
        warnings.append("MEMORY.md has no durable facts yet")
    else:
        passes.append(f"MEMORY.md has {memory_facts} durable fact lines")

    return passes, warnings, failures

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

if mode == "status":
    name, purpose = extract_identity()
    name = name or "(unnamed — edit IDENTITY.md)"
    purpose = purpose or "(no purpose set — edit IDENTITY.md)"

    beads = count_beads()
    open_count = beads["pending"] + beads["in_progress"]
    blocked = beads["blocked"]
    done = beads["done"]

    facts = count_memory_facts()
    lessons = count_lessons()

    version_hint = ""
    if version != current_version:
        version_hint = f" {YELLOW}(update available → v{current_version}){RESET}"

    W = 57
    def row(content=""):
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

    if open_count > 0:
        print(f"  {BOLD}Next:{RESET}  ./.agent/memory/bd-rank.sh ready  {DIM}# ranked by importance + impact{RESET}")
    elif blocked > 0:
        print(f"  {BOLD}Next:{RESET}  Unblock a bead — see ./.agent/memory/BEADS.md")
    elif done == 0:
        print(f"  {BOLD}Next:{RESET}  Open your agentic tool, give it a task")
    else:
        print(f"  {BOLD}Next:{RESET}  All beads drained. Give your agent something new.")

    print(f"  {DIM}Help:  cat .agent/HUMAN_GUIDE.md{RESET}")
    print()
elif mode == "validate":
    passes, warnings, failures = validate()

    print()
    print(f"  {BOLD}agentize validate{RESET}")
    print(f"  {DIM}{agent_dir}{RESET}")
    print()
    for msg in passes:
        print(f"  {GREEN}PASS{RESET}  {msg}")
    for msg in warnings:
        print(f"  {YELLOW}WARN{RESET}  {msg}")
    for msg in failures:
        print(f"  {RED}FAIL{RESET}  {msg}")
    print()

    if failures:
        print(f"  {RED}{BOLD}Result:{RESET} validation failed ({len(failures)} failure(s), {len(warnings)} warning(s))")
        sys.exit(1)
    if warnings:
        print(f"  {YELLOW}{BOLD}Result:{RESET} validation passed with warnings ({len(warnings)})")
    else:
        print(f"  {GREEN}{BOLD}Result:{RESET} validation passed cleanly")
    print()
else:
    raise SystemExit(f"Unknown audit mode: {mode}")
PY
}

cmd_status() {
  # v2.0: --markdown emits a portable handoff doc instead of the dashboard
  if [ "${2:-}" = "--markdown" ] || [ "${2:-}" = "-m" ]; then
    cmd_status_markdown "${3:-}"
    exit 0
  fi
  run_agent_audit "status" 0
  exit 0
}

cmd_validate() {
  run_agent_audit "validate" 1
  exit $?
}

# v2.0: liveness audit — score the scaffold 0..100 (different from `validate`,
# which checks structural correctness). Audit checks signs of life: IDENTITY
# filled, instincts present, lessons non-empty, bead close rate, recency.
cmd_audit() {
  local agent_dir="$PWD/.agent"
  if [ ! -d "$agent_dir" ] || [ ! -f "$agent_dir/.youragent" ]; then
    printf "\n  ${DIM}No agent installed here. Run ${BOLD}npx agentize${RESET}${DIM} first.${RESET}\n\n"
    exit 0
  fi
  python3 - "$agent_dir" "$BOLD" "$DIM" "$RESET" "$GREEN" "$YELLOW" "$RED" "$CYAN" <<'PY'
import sys, os, re
from datetime import datetime, timezone

agent_dir, BOLD, DIM, RESET, GREEN, YELLOW, RED, CYAN = sys.argv[1:9]

def read(p):
    try: return open(p).read()
    except: return ""

def lines_of(p):
    return [l for l in read(p).splitlines() if l.strip()]

def non_placeholder(p):
    """Count lines that aren't markdown chrome or fill-me-in markers."""
    out = 0
    for line in read(p).splitlines():
        s = line.strip()
        if not s: continue
        if s.startswith(("#", ">", "|", "-", "*")): continue
        if "_(" in s or "fill me in" in s.lower(): continue
        out += 1
    return out

checks = []

# 1. Identity filled (15 pts)
idn = non_placeholder(os.path.join(agent_dir, "IDENTITY.md"))
checks.append(("identity",     min(15, idn * 3), 15, f"{idn} non-placeholder lines"))

# 2. Memory non-empty (10 pts)
mem = non_placeholder(os.path.join(agent_dir, "MEMORY.md"))
checks.append(("memory",       min(10, mem * 2), 10, f"{mem} lines"))

# 3. Lessons learned (15 pts) — proves the agent learns from mistakes
les = non_placeholder(os.path.join(agent_dir, "LESSONS_LEARNED.md"))
checks.append(("lessons",      min(15, les * 3), 15, f"{les} lessons"))

# 4. Instincts present (15 pts)
idir = os.path.join(agent_dir, "memory", "instincts")
ic = len([f for f in os.listdir(idir) if f.endswith(".md") and f != "README.md"]) if os.path.isdir(idir) else 0
checks.append(("instincts",    min(15, ic * 3), 15, f"{ic} reflexes"))

# 5. Bead close rate (20 pts)
beads = []
for line in read(os.path.join(agent_dir, "memory", "BEADS.md")).splitlines():
    m = re.match(r'^\| (B\d{4}) \| (P\d) \| (\w+) \|', line)
    if m: beads.append(m.group(3))
total_b = len([b for b in beads if b != "cancelled"])
done_b = len([b for b in beads if b == "done"])
rate = (done_b / total_b) if total_b else 0
checks.append(("close-rate",   int(20 * rate), 20, f"{done_b}/{total_b} closed ({int(rate*100)}%)"))

# 6. Recency (10 pts) — marker timestamp
marker = read(os.path.join(agent_dir, ".youragent"))
m = re.search(r'installed=(\S+)', marker)
recency = 0
detail = "no marker"
if m:
    try:
        ts = datetime.fromisoformat(m.group(1).replace("Z","+00:00"))
        age_days = (datetime.now(timezone.utc) - ts).days
        recency = max(0, 10 - age_days // 7)   # full marks within 1 week, decay weekly
        detail = f"{age_days}d old"
    except: pass
checks.append(("recency",      recency, 10, detail))

# 7. Hook profile present (5 pts) — proves v2.0+ scaffold
profile = ""
m = re.search(r'profile=(\w+)', marker)
if m: profile = m.group(1)
checks.append(("profile",      5 if profile else 0, 5, profile or "(v1, no profile)"))

# 8. Active skills (10 pts)
sdir = os.path.join(agent_dir, "skills")
shs = [f for f in os.listdir(sdir) if f.endswith(".sh")] if os.path.isdir(sdir) else []
checks.append(("skills",       min(10, len(shs) * 2), 10, f"{len(shs)} active"))

total = sum(s for _, s, _, _ in checks)
total_max = sum(m for _, _, m, _ in checks)
pct = int(100 * total / total_max)

verdict_color = GREEN if pct >= 80 else (YELLOW if pct >= 50 else RED)
verdict = "alive" if pct >= 80 else ("breathing" if pct >= 50 else "stale")

print()
print(f"  {BOLD}{CYAN}agentize audit{RESET}  {DIM}— is this agent alive?{RESET}")
print(f"  {DIM}─────────────────────────────────────────────────────────{RESET}")
for name, score, mx, detail in checks:
    bar_full = score * 12 // mx
    bar_empty = 12 - bar_full
    color = GREEN if score == mx else (YELLOW if score >= mx//2 else RED)
    print(f"  {DIM}{name:<11}{RESET} {color}{'█' * bar_full}{DIM}{'░' * bar_empty}{RESET}  {score:>2}/{mx:<2}  {DIM}{detail}{RESET}")
print(f"  {DIM}─────────────────────────────────────────────────────────{RESET}")
print(f"  {BOLD}liveness  {verdict_color}{pct}/100  {verdict}{RESET}")
print()
sys.exit(0 if pct >= 50 else 2)
PY
}

# v2.0: status --markdown emits a portable handoff doc
cmd_status_markdown() {
  local out="${1:-}"
  local agent_dir="$PWD/.agent"
  if [ ! -d "$agent_dir" ] || [ ! -f "$agent_dir/.youragent" ]; then
    printf "# Handoff\n\n_No agent installed at %s._\n" "$PWD"
    return 0
  fi
  python3 - "$agent_dir" <<'PY' > "${out:-/dev/stdout}"
import sys, os, re
from datetime import datetime, timezone
agent_dir = sys.argv[1]

def read(p):
    try: return open(p).read()
    except: return ""

def first_section(p, header):
    txt = read(p)
    m = re.search(rf'^##\s+{re.escape(header)}\s*$\n(.*?)(?=^##\s|\Z)', txt, re.M|re.S)
    return m.group(1).strip() if m else ""

def head_lines(p, n=5):
    return "\n".join(l for l in read(p).splitlines() if l.strip())[:n*100]

marker = read(os.path.join(agent_dir, ".youragent"))
mver = re.search(r'version=(\S+)', marker); ver = mver.group(1) if mver else "?"
mpro = re.search(r'profile=(\w+)', marker); prof = mpro.group(1) if mpro else "(unset)"
mins = re.search(r'installed=(\S+)', marker); ins = mins.group(1) if mins else "?"

# Identity
ident = read(os.path.join(agent_dir, "IDENTITY.md"))
name = "(unset)"
m = re.search(r'^##\s+Name\s*\n+(.+?)(?=\n##|\Z)', ident, re.M|re.S)
if m:
    for line in m.group(1).splitlines():
        s = re.sub(r'[*_`~]+', '', line).strip()
        if s and "_(" not in s and "fill me in" not in s.lower():
            name = s; break

# Beads
beads_lines = []
for line in read(os.path.join(agent_dir, "memory", "BEADS.md")).splitlines():
    m = re.match(r'^\| (B\d{4}) \| (P\d) \| (\w+) \| ([^|]+) \| ([^|]+) \|', line)
    if m:
        bid, prio, status, blocked, subj = m.groups()
        beads_lines.append((bid, prio, status, blocked.strip(), subj.strip()))

pending = [b for b in beads_lines if b[2] == "pending"]
in_prog = [b for b in beads_lines if b[2] == "in_progress"]
done    = [b for b in beads_lines if b[2] == "done"]

# Instincts
idir = os.path.join(agent_dir, "memory", "instincts")
instincts = sorted([f[:-3] for f in os.listdir(idir) if f.endswith(".md") and f != "README.md"]) if os.path.isdir(idir) else []

# Lessons (last 5)
les = [l for l in read(os.path.join(agent_dir, "LESSONS_LEARNED.md")).splitlines() if l.strip().startswith("- ")][-5:]

print(f"# Handoff — {name}")
print()
print(f"_Generated {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')}_  ")
print(f"_Scaffold: agentize v{ver} · profile: `{prof}` · installed {ins}_")
print()
print("## Active work")
print()
if in_prog:
    print("**In progress**")
    for b in in_prog: print(f"- `{b[0]}` {b[1]} — {b[4]}")
    print()
print(f"**Pending** ({len(pending)})")
for b in pending[:10]: print(f"- `{b[0]}` {b[1]} {'(blocked)' if b[3] not in ('—','-','') else ''} — {b[4]}")
if len(pending) > 10: print(f"- _… {len(pending)-10} more in BEADS.md_")
print()
print(f"**Closed** ({len(done)})")
print()
print("## Instincts active")
print()
for i in instincts: print(f"- `{i}`")
print()
print("## Recent lessons")
print()
for l in les: print(l)
if not les: print("_(none yet)_")
print()
print("## How to resume")
print()
print(f"1. Read `.agent/NORTH_STAR.md`, `.agent/SOUL.md`, `.agent/AGENT.md`")
print(f"2. Read instincts in `.agent/memory/instincts/`")
print(f"3. Run `./.agent/memory/bd-rank.sh ready` to see prioritized work")
print(f"4. Closing a bead requires evidence — run `./.agent/skills/verify.sh <id>` after")
PY
  return 0
}

if [ "$SUBCOMMAND" = "status" ]; then
  cmd_status "$@"
fi

if [ "$SUBCOMMAND" = "audit" ]; then
  cmd_audit
  exit $?
fi

# ---------- mesh subcommand (delegates to installed .agent/mesh/mesh.sh) ----------
cmd_mesh() {
  local mesh_sh="$PWD/.agent/mesh/mesh.sh"
  if [ ! -f "$mesh_sh" ]; then
    printf "\n  ${DIM}No mesh installed here. Run ${BOLD}npx agentize${RESET}${DIM} first, then ${BOLD}npx agentize mesh init${RESET}${DIM}.${RESET}\n\n"
    exit 1
  fi
  shift  # drop 'mesh'; forward the rest (init | send | peers | inbox | poll | …)
  exec bash "$mesh_sh" "$@"
}

if [ "$SUBCOMMAND" = "mesh" ]; then
  cmd_mesh "$@"
fi

# ---------- configure-openclaw subcommand ----------
find_openclaw_configure_script() {
  local script_entry package_dir target
  script_entry="${BASH_SOURCE[0]}"

  while [ -L "$script_entry" ]; do
    target="$(readlink "$script_entry")"
    case "$target" in
      /*) script_entry="$target" ;;
      *) script_entry="$(cd "$(dirname "$script_entry")" 2>/dev/null && pwd)/$target" ;;
    esac
  done

  package_dir="$(cd "$(dirname "$script_entry")" 2>/dev/null && pwd -P || echo "")"

  if [ -n "$SRC_DIR" ]; then
    local local_override="$SRC_DIR/openclaw-configure.sh"
    if [ -f "$local_override" ]; then
      printf '%s\n' "$local_override"
      return 0
    fi
    say "${RED}✗${RESET} Local source specified but openclaw-configure.sh not found at $local_override"
    return 1
  fi

  if [ -n "$package_dir" ] && [ -f "$package_dir/openclaw-configure.sh" ]; then
    printf '%s\n' "$package_dir/openclaw-configure.sh"
    return 0
  fi

  if ! command -v curl >/dev/null 2>&1; then
    say "${RED}✗${RESET} curl not found and no local openclaw-configure.sh available"
    return 1
  fi

  local fetched="/tmp/.openclaw-configure-$$.sh"
  curl -fsSL "$RAW_BASE/openclaw-configure.sh" -o "$fetched" || {
    say "${RED}✗${RESET} Failed to fetch openclaw-configure.sh"
    return 1
  }
  chmod +x "$fetched"
  printf '%s\n' "$fetched"
}

cmd_configure_openclaw() {
  if [ ! -f "$HOME/.openclaw/openclaw.json" ]; then
    cat <<EOF

  ${DIM}OpenClaw not detected (no ~/.openclaw/openclaw.json)${RESET}

  ${BOLD}What is this?${RESET}
    This command configures persistent OpenClaw agents to automatically
    read .agent/ folders when they enter repositories with agentize.

  ${BOLD}Install OpenClaw:${RESET}  https://github.com/openclaw/openclaw

EOF
    exit 1
  fi

  local script_path
  script_path="$(find_openclaw_configure_script)" || exit 1

  "$script_path"
  local exit_code=$?

  if [ "${script_path#/tmp/.openclaw-configure-}" != "$script_path" ]; then
    rm -f "$script_path"
  fi

  exit $exit_code
}

if [ "$SUBCOMMAND" = "configure-openclaw" ]; then
  cmd_configure_openclaw
fi

if [ "$SUBCOMMAND" = "validate" ]; then
  cmd_validate
fi

cmd_uninstall() {
  # colors for uninstall output (set -e is already active; color block below
  # mirrors the one further down for interactive UX)
  if [ -t 1 ] && [ "${NO_ANIM:-0}" != "1" ]; then
    BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
    RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; CYAN=$'\033[36m'
  else
    BOLD=""; DIM=""; RESET=""; RED=""; GREEN=""; YELLOW=""; CYAN=""
  fi
  local agent_dir="$PWD/.agent"
  local repo_root="$PWD"
  local marker="$agent_dir/.youragent"

  if [ ! -d "$agent_dir" ] || [ ! -f "$marker" ]; then
    printf "\n  ${YELLOW}nothing to uninstall${RESET} — no agentize scaffold found at ${BOLD}%s${RESET}\n\n" "$agent_dir"
    exit 0
  fi

  # What will be touched?
  local hook_files=() hook
  for hook in CLAUDE.md AGENTS.md .cursorrules .windsurfrules; do
    if [ -f "$repo_root/$hook" ] && grep -qE "agentize|youragent|NORTH_STAR\.md|\.agent/" "$repo_root/$hook" 2>/dev/null; then
      hook_files+=("$hook")
    fi
  done
  local compat_link=""
  if [ -L "$repo_root/.agents/skills" ] && [ "$(readlink "$repo_root/.agents/skills" 2>/dev/null)" = "../.agent/skills" ]; then
    compat_link="$repo_root/.agents/skills"
  fi

  printf "\n  ${BOLD}AGENTIZE · uninstall preview${RESET}\n"
  printf "  ${DIM}────────────────────────────────────────────────────────${RESET}\n"
  printf "  ${RED}remove${RESET}  ${BOLD}%s${RESET}  ${DIM}(scaffold — includes your IDENTITY, USER, MEMORY, BEADS, LESSONS_LEARNED)${RESET}\n" ".agent/"
  for hook in "${hook_files[@]}"; do
    printf "  ${RED}remove${RESET}  ${BOLD}%s${RESET}  ${DIM}(tool hook that references .agent/)${RESET}\n" "$hook"
  done
  if [ -n "$compat_link" ]; then
    printf "  ${RED}remove${RESET}  ${BOLD}%s${RESET}  ${DIM}(our symlink — only ours, user content untouched)${RESET}\n" ".agents/skills"
  fi
  printf "  ${DIM}────────────────────────────────────────────────────────${RESET}\n"
  printf "  ${YELLOW}personal content in .agent/ will be lost${RESET} ${DIM}(beads, lessons, identity notes)${RESET}\n"
  printf "  ${DIM}back up ${BOLD}.agent/memory/BEADS.md${RESET}${DIM} and ${BOLD}.agent/LESSONS_LEARNED.md${RESET}${DIM} first if you want to keep them${RESET}\n\n"

  # Confirm (skip with --yes, AGENTIZE_YES=1, or non-TTY)
  local confirm="no"
  if [ "${2:-}" = "--yes" ] || [ "${AGENTIZE_YES:-0}" = "1" ]; then
    confirm="yes"
  elif [ -t 0 ]; then
    printf "  ${BOLD}type 'uninstall' to confirm:${RESET} "
    read -r confirm
  fi
  if [ "$confirm" != "uninstall" ] && [ "$confirm" != "yes" ]; then
    printf "\n  ${YELLOW}cancelled${RESET}  ${DIM}nothing removed${RESET}\n\n"
    exit 0
  fi

  # Execute
  rm -rf "$agent_dir"
  for hook in "${hook_files[@]}"; do
    rm -f "$repo_root/$hook"
  done
  [ -n "$compat_link" ] && rm -f "$compat_link"
  # Prune empty .agents/ dir if we created it and nothing else is there
  [ -d "$repo_root/.agents" ] && rmdir "$repo_root/.agents" 2>/dev/null || true

  printf "\n  ${GREEN}${BOLD}uninstalled${RESET}  ${DIM}→  scaffold, hooks, compat link removed. your repo is yours again.${RESET}\n"
  printf "  ${DIM}re-run anytime · ${BOLD}npx agentize${RESET}${DIM} · installs fresh${RESET}\n\n"
  exit 0
}

if [ "$SUBCOMMAND" = "uninstall" ] || [ "$SUBCOMMAND" = "remove" ]; then
  cmd_uninstall "$@"
fi

cmd_plan() {
  # enable colors for pretty output
  if [ -t 1 ] && [ "${NO_ANIM:-0}" != "1" ]; then
    BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
    GREEN=$'\033[32m'; YELLOW=$'\033[33m'; CYAN=$'\033[36m'
  else
    BOLD=""; DIM=""; RESET=""; GREEN=""; YELLOW=""; CYAN=""
  fi
  local agent_dir="$PWD/.agent"
  local repo_root="$PWD"
  local mode="fresh"
  [ -f "$agent_dir/.youragent" ] && mode="update"

  printf "\n  ${BOLD}AGENTIZE · plan (dry-run)${RESET}  ${DIM}v%s · %s · mode=%s${RESET}\n" "$SCAFFOLD_VERSION" "${agent_dir/#$HOME/~}" "$mode"
  printf "  ${DIM}────────────────────────────────────────────────────────${RESET}\n"
  printf "  ${DIM}this is a preview. no files will be written.${RESET}\n\n"

  printf "  ${BOLD}scaffold templates${RESET}  ${DIM}(refreshed every run)${RESET}\n"
  local t
  for t in "${SCAFFOLD_TEMPLATES[@]}"; do
    printf "    ${GREEN}+${RESET} .agent/%s.md\n" "$t"
  done
  for t in "${SCAFFOLD_MEMORY[@]}"; do
    printf "    ${GREEN}+${RESET} .agent/memory/%s\n" "$t"
  done
  for t in "${SKILLS_FILES[@]}"; do
    printf "    ${GREEN}+${RESET} .agent/skills/%s\n" "$t"
  done
  for t in "${MESH_FILES[@]}"; do
    printf "    ${GREEN}+${RESET} .agent/mesh/%s\n" "$t"
  done

  printf "\n  ${BOLD}agent mesh${RESET}  ${DIM}(inbox/outbox — opt-in per node)${RESET}\n"
  if [ -f "$agent_dir/mesh/config.json" ]; then
    printf "    ${DIM}·${RESET} .agent/mesh/config.json  ${DIM}kept (node already initialised)${RESET}\n"
  else
    printf "    ${DIM}·${RESET} .agent/mesh/config.json  ${DIM}created on 'agentize mesh init'${RESET}\n"
  fi

  printf "\n  ${BOLD}personal files${RESET}  ${DIM}(created once · never overwritten)${RESET}\n"
  for t in "${USER_TEMPLATES[@]}"; do
    if [ -f "$agent_dir/${t}.md" ]; then
      printf "    ${DIM}·${RESET} .agent/%s.md  ${DIM}kept (already exists)${RESET}\n" "$t"
    else
      printf "    ${GREEN}+${RESET} .agent/%s.md  ${DIM}new${RESET}\n" "$t"
    fi
  done
  for t in "${USER_MEMORY[@]}"; do
    if [ -f "$agent_dir/memory/${t}" ]; then
      printf "    ${DIM}·${RESET} .agent/memory/%s  ${DIM}kept (already exists)${RESET}\n" "$t"
    else
      printf "    ${GREEN}+${RESET} .agent/memory/%s  ${DIM}new${RESET}\n" "$t"
    fi
  done

  printf "\n  ${BOLD}repo-root hook files${RESET}  ${DIM}(so your tool reads .agent/ automatically)${RESET}\n"
  local hook
  for hook in CLAUDE.md AGENTS.md .cursorrules .windsurfrules; do
    if [ -f "$repo_root/$hook" ]; then
      if grep -qE "agentize|youragent|NORTH_STAR\.md|\.agent/" "$repo_root/$hook" 2>/dev/null; then
        printf "    ${DIM}·${RESET} %s  ${DIM}already linked — left alone${RESET}\n" "$hook"
      else
        printf "    ${YELLOW}!${RESET} %s  ${YELLOW}exists, unlinked${RESET}  ${DIM}you'll get a warning + manual fix suggestion${RESET}\n" "$hook"
      fi
    else
      printf "    ${GREEN}+${RESET} %s  ${DIM}new${RESET}\n" "$hook"
    fi
  done

  printf "\n  ${BOLD}cross-harness compat${RESET}\n"
  if [ -e "$repo_root/.agents/skills" ]; then
    printf "    ${DIM}·${RESET} .agents/skills  ${DIM}already exists — left alone${RESET}\n"
  else
    printf "    ${GREEN}+${RESET} .agents/skills  ${DIM}symlink → ../.agent/skills (codex, opencode, copilot, gemini cli, …)${RESET}\n"
  fi

  printf "\n  ${BOLD}runtime deps${RESET}  ${DIM}(checked · not installed by us)${RESET}\n"
  for cmd in python3 npx git; do
    if command -v "$cmd" >/dev/null 2>&1; then
      printf "    ${GREEN}✓${RESET} %s\n" "$cmd"
    else
      printf "    ${YELLOW}!${RESET} %s  ${DIM}missing — you'll get a heads-up${RESET}\n" "$cmd"
    fi
  done

  printf "\n  ${DIM}run${RESET}  ${BOLD}npx agentize${RESET}  ${DIM}to apply this plan.${RESET}\n\n"
  exit 0
}

if [ "$SUBCOMMAND" = "plan" ] || [ "$SUBCOMMAND" = "dry-run" ]; then
  cmd_plan
fi

# Read installed scaffold version from marker (returns empty if not installed).
installed_scaffold_version() {
  local marker="$PWD/.agent/.youragent"
  [ -f "$marker" ] || return 0
  awk -F= '/^version=/{print $2; exit}' "$marker"
}

# Fetch latest npm-published version of agentize (2s timeout, silent on failure).
fetch_latest_npm_version() {
  command -v curl >/dev/null 2>&1 || return 0
  curl -fsSL --max-time 2 https://registry.npmjs.org/agentize/latest 2>/dev/null \
    | awk -F'"version":"' 'NF>1{split($2,a,"\""); print a[1]; exit}'
}

# ---------- OpenClaw detection gate ----------
# Single source of truth: "is there a real OpenClaw instance to link up with?"
# Every OpenClaw-aware code path must check this first. If false, bail cleanly.
# Returns 0 if an OpenClaw config exists at the default path AND has >= 1 agent.
openclaw_present() {
  local cfg="$HOME/.openclaw/openclaw.json"
  [ -f "$cfg" ] || return 1
  command -v python3 >/dev/null 2>&1 || return 1
  python3 - "$cfg" <<'PYEOF' >/dev/null 2>&1 || return 1
import json, sys
with open(sys.argv[1]) as f: cfg = json.load(f)
agents = cfg.get("agents", {}).get("list", [])
sys.exit(0 if any(a.get("workspace") for a in agents) else 1)
PYEOF
  return 0
}

# Iterate OpenClaw agents (workspace|name per line). Silent if none.
openclaw_agents() {
  local cfg="$HOME/.openclaw/openclaw.json"
  [ -f "$cfg" ] || return 0
  command -v python3 >/dev/null 2>&1 || return 0
  python3 - "$cfg" <<'PYEOF'
import json, sys
try:
    with open(sys.argv[1]) as f: cfg = json.load(f)
    for a in cfg.get("agents", {}).get("list", []):
        ws = a.get("workspace", "")
        nm = a.get("identity", {}).get("name", a.get("id", "unknown"))
        if ws: print(f"{ws}|{nm}")
except Exception:
    pass
PYEOF
}

cmd_update_check() {
  if [ -t 1 ] && [ "${NO_ANIM:-0}" != "1" ]; then
    BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
    GREEN=$'\033[32m'; YELLOW=$'\033[33m'; CYAN=$'\033[36m'
  else
    BOLD=""; DIM=""; RESET=""; GREEN=""; YELLOW=""; CYAN=""
  fi
  local installed latest
  installed="$(installed_scaffold_version)"
  latest="$(fetch_latest_npm_version)"

  if [ -z "$installed" ]; then
    printf "\n  ${YELLOW}no scaffold installed here${RESET}  ${DIM}run ${BOLD}npx agentize${RESET}${DIM} to install${RESET}\n\n"
    exit 0
  fi
  if [ -z "$latest" ]; then
    printf "\n  ${DIM}could not reach npm (offline?). installed scaffold: v%s${RESET}\n\n" "$installed"
    exit 0
  fi
  if [ "$installed" = "$latest" ]; then
    printf "\n  ${GREEN}up to date${RESET}  ${DIM}scaffold v%s · matches npm latest${RESET}\n\n" "$installed"
    exit 0
  fi
  printf "\n  ${YELLOW}${BOLD}update available${RESET}  ${DIM}scaffold v%s → v%s${RESET}\n" "$installed" "$latest"
  printf "  ${DIM}run${RESET}  ${BOLD}npx agentize${RESET}  ${DIM}to refresh. your personal files stay untouched.${RESET}\n\n"
  exit 0
}

if [ "$SUBCOMMAND" = "update-check" ] || [ "$SUBCOMMAND" = "check-updates" ]; then
  cmd_update_check
fi

cmd_openclaw_check() {
  if [ -t 1 ] && [ "${NO_ANIM:-0}" != "1" ]; then
    BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
    GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; CYAN=$'\033[36m'; MAGENTA=$'\033[35m'
  else
    BOLD=""; DIM=""; RESET=""; GREEN=""; YELLOW=""; RED=""; CYAN=""; MAGENTA=""
  fi
  if ! openclaw_present; then
    printf "\n  ${DIM}no openclaw instance detected at ~/.openclaw/openclaw.json${RESET}\n"
    printf "  ${DIM}(nothing to check — this subcommand only runs when openclaw is installed)${RESET}\n\n"
    exit 0
  fi

  printf "\n  ${BOLD}openclaw-check${RESET}  ${DIM}drift report (read-only)${RESET}\n"
  printf "  ${DIM}───────────────────────────────────────────────────────${RESET}\n"

  local total=0 wired=0 drift=0 missing=0 outdated=0
  while IFS='|' read -r workspace name; do
    [ -z "$workspace" ] && continue
    total=$((total+1))
    local agents_md="$workspace/AGENTS.md"
    if [ ! -f "$agents_md" ]; then
      printf "  ${RED}missing${RESET}  %-20s  ${DIM}%s/AGENTS.md not found${RESET}\n" "$name" "$workspace"
      missing=$((missing+1))
      continue
    fi
    # Look for any of our markers (v1, v2…)
    if grep -Fq '<!-- youragent-openclaw-v2 -->' "$agents_md" 2>/dev/null; then
      printf "  ${GREEN}ok${RESET}       %-20s  ${DIM}v2 marker present${RESET}\n" "$name"
      wired=$((wired+1))
    elif grep -Fq '<!-- youragent-openclaw-v1 -->' "$agents_md" 2>/dev/null; then
      printf "  ${YELLOW}outdated${RESET} %-20s  ${DIM}v1 marker — run configure-openclaw to upgrade${RESET}\n" "$name"
      outdated=$((outdated+1))
    elif grep -Fq '## Working in Code Repositories (YourAgent Integration)' "$agents_md" 2>/dev/null; then
      printf "  ${YELLOW}drift${RESET}    %-20s  ${DIM}integration header present but no version marker${RESET}\n" "$name"
      drift=$((drift+1))
    else
      printf "  ${RED}unwired${RESET}  %-20s  ${DIM}no integration markers${RESET}\n" "$name"
      missing=$((missing+1))
    fi
  done < <(openclaw_agents)

  printf "  ${DIM}───────────────────────────────────────────────────────${RESET}\n"
  printf "  ${DIM}%d total · %d ok · %d outdated · %d drifted · %d unwired${RESET}\n" "$total" "$wired" "$outdated" "$drift" "$missing"
  if [ "$outdated" -gt 0 ] || [ "$missing" -gt 0 ]; then
    printf "  ${DIM}fix with${RESET}  ${BOLD}${MAGENTA}npx agentize configure-openclaw${RESET}\n\n"
    exit 1
  fi
  printf "\n"
  exit 0
}

if [ "$SUBCOMMAND" = "openclaw-check" ] || [ "$SUBCOMMAND" = "check-openclaw" ]; then
  cmd_openclaw_check
fi

cmd_from_openclaw() {
  # Reverse install: run this inside an OpenClaw agent's workspace to seed
  # a .agent/ scaffold using the agent's identity + purpose as defaults.
  # Gate: openclaw.json MUST exist AND current $PWD MUST be a known workspace.
  if [ -t 1 ] && [ "${NO_ANIM:-0}" != "1" ]; then
    BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
    GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; CYAN=$'\033[36m'; MAGENTA=$'\033[35m'
  else
    BOLD=""; DIM=""; RESET=""; GREEN=""; YELLOW=""; RED=""; CYAN=""; MAGENTA=""
  fi
  if ! openclaw_present; then
    printf "\n  ${RED}no openclaw instance detected${RESET}  ${DIM}~/.openclaw/openclaw.json missing or empty${RESET}\n"
    printf "  ${DIM}this subcommand is only for users who already have openclaw running${RESET}\n\n"
    exit 1
  fi
  local agent_name="" agent_purpose="" pyline=""
  # Resolve current workspace → agent identity from openclaw.json.
  if command -v python3 >/dev/null 2>&1; then
    pyline=$(python3 - "$HOME/.openclaw/openclaw.json" "$PWD" <<'PYEOF' || true
import json, os, sys
try:
    cfg_path, pwd = sys.argv[1], os.path.realpath(sys.argv[2])
    with open(cfg_path) as f: cfg = json.load(f)
    for a in cfg.get("agents", {}).get("list", []):
        ws = a.get("workspace", "")
        if ws and os.path.realpath(ws) == pwd:
            ident = a.get("identity", {})
            nm = ident.get("name", a.get("id", ""))
            pp = ident.get("purpose") or ident.get("role") or ""
            print(f"{nm}\t{pp}")
            break
except Exception:
    pass
PYEOF
    )
    if [ -n "$pyline" ]; then
      agent_name="${pyline%%$'\t'*}"
      agent_purpose="${pyline#*$'\t'}"
      [ "$agent_purpose" = "$pyline" ] && agent_purpose=""
    fi
  fi
  if [ -z "$agent_name" ]; then
    printf "\n  ${YELLOW}cwd isn't a registered openclaw workspace${RESET}\n"
    printf "  ${DIM}run ${BOLD}npx agentize from-openclaw${RESET}${DIM} from inside one of your agents' workspace dirs${RESET}\n"
    printf "  ${DIM}or use ${BOLD}${MAGENTA}npx agentize${RESET}${DIM} for a regular install${RESET}\n\n"
    exit 1
  fi

  printf "\n  ${BOLD}from-openclaw${RESET}  ${DIM}seeding .agent/ with identity from${RESET} ${BOLD}%s${RESET}\n" "$agent_name"
  # Run a normal install, then patch IDENTITY.md with agent's name + purpose.
  export AGENTIZE_FROM_OPENCLAW_NAME="$agent_name"
  export AGENTIZE_FROM_OPENCLAW_PURPOSE="$agent_purpose"
  # Re-exec ourselves as a normal install with the env vars set; the install
  # flow (below) will see them and seed IDENTITY.md.
  SUBCOMMAND="install"
  # fall through
}

if [ "$SUBCOMMAND" = "from-openclaw" ]; then
  cmd_from_openclaw
fi

cmd_help() {
  if [ -t 1 ] && [ "${NO_ANIM:-0}" != "1" ]; then
    BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
    MAGENTA=$'\033[35m'; CYAN=$'\033[36m'
  else
    BOLD=""; DIM=""; RESET=""; MAGENTA=""; CYAN=""
  fi
  cat <<EOF

  ${BOLD}agentize${RESET}  ${DIM}v${SCAFFOLD_VERSION} · subcommand reference${RESET}
  ${DIM}────────────────────────────────────────────────────────────${RESET}

  ${BOLD}install / update${RESET}
    ${MAGENTA}npx agentize${RESET}                 ${DIM}install or safely update the scaffold${RESET}
    ${MAGENTA}npx agentize plan${RESET}            ${DIM}dry-run preview (writes nothing)${RESET}
    ${MAGENTA}npx agentize update-check${RESET}    ${DIM}installed vs npm latest${RESET}
    ${MAGENTA}npx agentize uninstall${RESET}       ${DIM}clean removal (preview + confirm)${RESET}

  ${BOLD}inspect${RESET}
    ${MAGENTA}npx agentize status${RESET}              ${DIM}single-screen dashboard of agent state${RESET}
    ${MAGENTA}npx agentize status --markdown${RESET}   ${DIM}portable handoff doc (pipe to file or PR)${RESET}
    ${MAGENTA}npx agentize validate${RESET}            ${DIM}scaffold health check (non-zero on breakage)${RESET}
    ${MAGENTA}npx agentize audit${RESET}               ${DIM}liveness score 0-100 (alive · breathing · stale)${RESET}

  ${BOLD}openclaw${RESET}  ${DIM}(only available when ~/.openclaw/openclaw.json exists)${RESET}
    ${MAGENTA}npx agentize configure-openclaw${RESET}  ${DIM}wire global agents to auto-read .agent/${RESET}
    ${MAGENTA}npx agentize openclaw-check${RESET}      ${DIM}drift report for wired agents${RESET}
    ${MAGENTA}npx agentize from-openclaw${RESET}       ${DIM}reverse install: seed from agent's identity${RESET}

  ${BOLD}mesh${RESET}  ${DIM}(agent-to-agent inbox/outbox across the repo tree)${RESET}
    ${MAGENTA}npx agentize mesh init${RESET}          ${DIM}opt this node into the mesh${RESET}
    ${MAGENTA}npx agentize mesh peers${RESET}         ${DIM}peer nodes in scope (1 up · 2 down) + liveness${RESET}
    ${MAGENTA}npx agentize mesh send <p> "…"${RESET}  ${DIM}drop a message into a peer's inbox${RESET}
    ${MAGENTA}npx agentize mesh inbox${RESET}         ${DIM}what other agents sent you${RESET}
    ${MAGENTA}npx agentize mesh install-loop${RESET}  ${DIM}auto-wake a session on new mail (launchd/cron)${RESET}
    ${MAGENTA}npx agentize mesh doctor${RESET}        ${DIM}peer liveness report${RESET}

  ${BOLD}skills${RESET}  ${DIM}(installed at .agent/skills/ — run directly)${RESET}
    ${CYAN}.agent/skills/plan.sh${RESET}              ${DIM}perfect-plan checklist + validator${RESET}
    ${CYAN}.agent/skills/verify.sh${RESET}            ${DIM}evidence-truth bead close-reasons (anti-bullshit)${RESET}
    ${CYAN}.agent/skills/learn.sh${RESET}             ${DIM}propose instincts from session memory${RESET}
    ${CYAN}.agent/skills/memory-search.sh${RESET}     ${DIM}cross-repo + global memory search${RESET}
    ${CYAN}.agent/skills/search-substack.sh${RESET}   ${DIM}CoE + Stan article search${RESET}
    ${MAGENTA}npx wwvcd${RESET}                        ${DIM}1,191 findings from Claude Code source${RESET}

  ${BOLD}profile${RESET}  ${DIM}(scale scaffold strictness without editing files)${RESET}
    ${MAGENTA}AGENTIZE_PROFILE=minimal${RESET}   ${DIM}only load-bearing instincts (least context)${RESET}
    ${MAGENTA}AGENTIZE_PROFILE=standard${RESET}  ${DIM}default — most instincts active${RESET}
    ${MAGENTA}AGENTIZE_PROFILE=strict${RESET}    ${DIM}every guard on (verify mandatory, no FIFO)${RESET}

  ${BOLD}task ledger${RESET}
    ${CYAN}.agent/memory/bd.sh${RESET} ${DIM}{ create | claim <id> | close <id> --reason "..." | block | list }${RESET}
    ${CYAN}.agent/memory/bd-rank.sh${RESET} ${DIM}{ ready | score <id> | stale <id> --reason "..." | boost <id> N }${RESET}

  ${DIM}full agent-facing catalog: .agent/TOOLS.md (after install)${RESET}
  ${DIM}source: ${RESET}https://github.com/stanhus/youragent

EOF
  exit 0
}

if [ "$SUBCOMMAND" = "help" ] || [ "$SUBCOMMAND" = "-h" ] || [ "$SUBCOMMAND" = "--help" ]; then
  cmd_help
fi

greet() {
  local target_short="${TARGET_DIR/#$HOME/~}"
  printf "\n"
  printf "  ${BOLD}${CYAN}agentize${RESET}  ${DIM}v%s · profile=%s${RESET}\n" "$SCAFFOLD_VERSION" "$AGENTIZE_PROFILE"
  printf "  ${DIM}─────────────────────────────────────────────────────${RESET}\n"
  printf "  ${BOLD}Hey. Welcome.${RESET}  ${DIM}Dropping a v2 agent into this repo.${RESET}\n"
  printf "  ${DIM}beads · instincts · verify · learn · audit · markdown handoff${RESET}\n"
  printf "  ${DIM}target → %s · reversible with${RESET} ${BOLD}${MAGENTA}npx agentize uninstall${RESET}\n" "$target_short"
}

# ---------- v2.0: dense matrix dashboard ----------
# Replaces v1's row-by-row reveal with a single boxed module grid that
# animates fill bars in place. Same dash_init / dash_add / dash_update API
# so the rest of install.sh doesn't change.
DASH_MODULES=()
DASH_DESCS=()
DASH_BOX_WIDTH=58

dash_init() {
  printf "\n"
  if [ "$NO_ANIM" = "1" ] || [ ! -t 1 ]; then
    DASH_MODULES=()
    DASH_DESCS=()
    return
  fi
  # Top of box
  printf "  ${CYAN}╭"
  local i=0
  while [ $i -lt $DASH_BOX_WIDTH ]; do printf "─"; i=$((i+1)); done
  printf "╮${RESET}\n"
  DASH_MODULES=()
  DASH_DESCS=()
}

dash_add() {
  local mod="$1" what="$2"
  DASH_MODULES+=("$mod")
  DASH_DESCS+=("$what")
  if [ "$NO_ANIM" = "1" ] || [ ! -t 1 ]; then
    return
  fi
  # Empty row with placeholder bar
  printf "  ${CYAN}│${RESET} ${DIM}%-10s ░░░░░░░░░░░░  %-30s${RESET} ${CYAN}│${RESET}\n" "$mod" "queued…"
}

# Animated fill: 12 blocks, paint them L→R in ~120ms.
_dash_paint_bar() {
  local mod="$1" desc="$2" color="$3" final_block="$4"
  local row_idx=-1 i
  for ((i=0; i<${#DASH_MODULES[@]}; i++)); do
    if [ "${DASH_MODULES[$i]}" = "$mod" ]; then row_idx=$i; break; fi
  done
  [ "$row_idx" -lt 0 ] && return
  local total=${#DASH_MODULES[@]}
  local up=$((total - row_idx))
  # Animate 12 blocks
  local b
  for b in 1 2 3 4 5 6 7 8 9 10 11 12; do
    local empty=$((12 - b))
    printf "\033[${up}A\r"
    printf "  ${CYAN}│${RESET} ${BOLD}%-10s${RESET} ${color}" "$mod"
    local k=0
    while [ $k -lt $b ]; do printf "${final_block}"; k=$((k+1)); done
    printf "${RESET}${DIM}"
    k=0
    while [ $k -lt $empty ]; do printf "░"; k=$((k+1)); done
    printf "${RESET}  ${DIM}%-30s${RESET} ${CYAN}│${RESET}\033[K\n" "${desc:0:30}"
    printf "\033[$((up - 1))B\r" 2>/dev/null || true
    sleep 0.012
  done
}

dash_update() {
  local mod="$1" state="$2" detail="${3:-}"
  if [ "$NO_ANIM" = "1" ] || [ ! -t 1 ]; then
    printf "  %-10s  %-40s  %s\n" "$mod" "${detail:-—}" "$state"
    return
  fi
  local row_idx=-1 i
  for ((i=0; i<${#DASH_MODULES[@]}; i++)); do
    if [ "${DASH_MODULES[$i]}" = "$mod" ]; then row_idx=$i; break; fi
  done
  [ "$row_idx" -lt 0 ] && return
  local desc="${DASH_DESCS[$row_idx]}"
  [ -n "$detail" ] && desc="$detail"
  case "$state" in
    ready) _dash_paint_bar "$mod" "$desc" "$GREEN" "█" ;;
    warn)  _dash_paint_bar "$mod" "$detail · ${DASH_DESCS[$row_idx]}" "$YELLOW" "▓" ;;
    skip)  _dash_paint_bar "$mod" "${detail:-skipped}" "$DIM" "─" ;;
  esac
  return 0
}

# Close the box (called after the last dash_update)
dash_close() {
  if [ "$NO_ANIM" = "1" ] || [ ! -t 1 ]; then return; fi
  printf "  ${CYAN}╰"
  local i=0
  while [ $i -lt $DASH_BOX_WIDTH ]; do printf "─"; i=$((i+1)); done
  printf "╯${RESET}\n"
}

# ---------- preflight + mode detection ----------
greet

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

# Mode-specific intro (one line max)
case "$INSTALL_MODE" in
  update)
    PREV_VERSION="$(installed_scaffold_version)"
    if [ -n "$PREV_VERSION" ] && [ "$PREV_VERSION" != "$SCAFFOLD_VERSION" ]; then
      say "${CYAN}↑${RESET} ${DIM}mode · update · scaffold v${PREV_VERSION} → ${BOLD}v${SCAFFOLD_VERSION}${RESET}${DIM}, personal files untouched${RESET}"
    else
      say "${DIM}mode · update · scaffold → v${SCAFFOLD_VERSION}, personal files untouched${RESET}"
    fi
    ;;
  force)  say "${YELLOW}!${RESET} ${DIM}mode · force · overwriting everything${RESET}" ;;
esac

# ---------- source resolution ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"
SOURCE_MODE=""

resolve_src() {
  if [ -n "$SRC_DIR" ]; then
    if [ ! -d "$SRC_DIR/templates" ]; then
      say "${RED}✗${RESET} BOOTSTRAP_LOCAL_SRC set but $SRC_DIR/templates/ is missing"
      exit 1
    fi
    SOURCE_MODE="local"
    return
  fi

  if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/templates" ] && [ -d "$SCRIPT_DIR/memory-scaffold" ]; then
    SRC_DIR="$SCRIPT_DIR"
    SOURCE_MODE="local"
    return
  fi

  say "  ${DIM}Fetching from GitHub…${RESET}"
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
    bd.sh) echo "memory/bd.sh (bead CLI)" ;;
    bd-rank.sh) echo "memory/bd-rank.sh (bead ranker)" ;;
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

# ---------- dashboard + silent install ----------
# One-line pitch a non-techie can grok before the table lights up.
printf "\n  ${BOLD}v2.0 · agent in a box${RESET}  ${DIM}beads · instincts · verify · learn · audit${RESET}\n"

dash_init
dash_add "scaffold"  "soul · agent · north_star · 130 patterns"
dash_add "memory"    "beads + ledger + bd-rank prioritizer"
dash_add "instincts" "${#SCAFFOLD_INSTINCTS[@]} reflex patterns (v2)"
dash_add "skills"    "plan · verify · learn · memory · substack"
dash_add "mesh"      "inbox/outbox · peers 1 up · 2 down"
dash_add "profile"   "$AGENTIZE_PROFILE"
dash_add "hooks"     "claude · codex · cursor · windsurf"
dash_add "runtime"   "python · npx · git"

# scaffold: core templates
for t in "${SCAFFOLD_TEMPLATES[@]}"; do
  fetch_file "templates/${t}.md" "$TARGET_DIR/${t}.md"
  COUNT_REFRESHED=$((COUNT_REFRESHED+1))
done
# scaffold: personal (skip-if-exists)
for t in "${USER_TEMPLATES[@]}"; do
  if install_file "templates/${t}.md" "$TARGET_DIR/${t}.md" "1"; then
    COUNT_INSTALLED=$((COUNT_INSTALLED+1))
    # If we just created IDENTITY.md AND we were invoked via from-openclaw,
    # seed the file with the agent's name + purpose instead of the generic
    # template. Only writes on fresh creation; never overwrites.
    if [ "$t" = "IDENTITY" ] && [ -n "${AGENTIZE_FROM_OPENCLAW_NAME:-}" ]; then
      {
        printf '# IDENTITY.md\n\n## Name\n\n**%s**\n\n## Purpose\n\n' "$AGENTIZE_FROM_OPENCLAW_NAME"
        if [ -n "${AGENTIZE_FROM_OPENCLAW_PURPOSE:-}" ]; then
          printf '%s\n' "$AGENTIZE_FROM_OPENCLAW_PURPOSE"
        else
          printf '(seeded from openclaw workspace — edit to taste)\n'
        fi
        printf '\n<!-- seeded-from-openclaw -->\n'
      } > "$TARGET_DIR/${t}.md"
    fi
  else
    COUNT_KEPT=$((COUNT_KEPT+1))
  fi
done
sleep 0.08
dash_update "scaffold" ready "personality + operating rules + identity"

# memory: scaffold files + user memory
# Migrate: pre-1.6 installs had bd-lite.sh; remove it (replaced by bd.sh).
if [ -f "$TARGET_DIR/memory/bd-lite.sh" ]; then
  rm -f "$TARGET_DIR/memory/bd-lite.sh"
fi
for f in "${SCAFFOLD_MEMORY[@]}"; do
  fetch_file "memory-scaffold/${f}" "$TARGET_DIR/memory/${f}"
  COUNT_REFRESHED=$((COUNT_REFRESHED+1))
done
chmod +x "$TARGET_DIR/memory/bd.sh"
chmod +x "$TARGET_DIR/memory/bd-rank.sh"
for f in "${USER_MEMORY[@]}"; do
  if install_file "memory-scaffold/${f}" "$TARGET_DIR/memory/${f}" "1"; then
    COUNT_INSTALLED=$((COUNT_INSTALLED+1))
  else
    COUNT_KEPT=$((COUNT_KEPT+1))
  fi
done
sleep 0.08
dash_update "memory" ready "long-term, short-term, handoff, ledger"

# v2.0: instincts — reflex patterns
mkdir -p "$TARGET_DIR/memory/instincts"
for f in "${SCAFFOLD_INSTINCTS[@]}"; do
  fetch_file "memory-scaffold/instincts/${f}" "$TARGET_DIR/memory/instincts/${f}"
  COUNT_REFRESHED=$((COUNT_REFRESHED+1))
done
dash_update "instincts" ready "$((${#SCAFFOLD_INSTINCTS[@]} - 1)) reflex patterns active"

# skills
for f in "${SKILLS_FILES[@]}"; do
  fetch_file "skills-scaffold/${f}" "$TARGET_DIR/skills/${f}"
  COUNT_REFRESHED=$((COUNT_REFRESHED+1))
done
chmod +x "$TARGET_DIR/skills/search-substack.sh"
chmod +x "$TARGET_DIR/skills/memory-search.sh" 2>/dev/null || true
chmod +x "$TARGET_DIR/skills/plan.sh" 2>/dev/null || true
chmod +x "$TARGET_DIR/skills/verify.sh" 2>/dev/null || true
chmod +x "$TARGET_DIR/skills/learn.sh" 2>/dev/null || true

# Ensure wwvcd (retrieval skill) is available. Try global install first;
# fall back to warming the npx cache; silently accept if neither works
# (user can still `npx wwvcd` on demand, just with first-run latency).
WWVCD_STATE="missing"
if command -v wwvcd >/dev/null 2>&1; then
  WWVCD_STATE="already-installed"
elif command -v npm >/dev/null 2>&1; then
  if npm install -g wwvcd --silent --no-fund --no-audit >/dev/null 2>&1; then
    WWVCD_STATE="global"
  elif command -v npx >/dev/null 2>&1; then
    # No global perms — warm npx cache so first call isn't cold.
    if npx --yes wwvcd --help >/dev/null 2>&1; then
      WWVCD_STATE="npx-cached"
    fi
  fi
fi

sleep 0.08
case "$WWVCD_STATE" in
  already-installed) dash_update "skills" ready "substack retrieval (cited), wwvcd ready" ;;
  global)            dash_update "skills" ready "substack retrieval (cited), wwvcd installed globally" ;;
  npx-cached)        dash_update "skills" ready "substack retrieval (cited), wwvcd via npx (cached)" ;;
  *)                 dash_update "skills" ready "substack retrieval (cited)" ;;
esac

# v2.1: mesh — inbox/outbox scaffold (opt-in; files refreshed, config kept)
mkdir -p "$TARGET_DIR/mesh"
for f in "${MESH_FILES[@]}"; do
  fetch_file "mesh-scaffold/${f}" "$TARGET_DIR/mesh/${f}"
  COUNT_REFRESHED=$((COUNT_REFRESHED+1))
done
chmod +x "$TARGET_DIR/mesh/mesh.sh" 2>/dev/null || true
sleep 0.05
dash_update "mesh" ready "opt-in with 'agentize mesh init'"

# Write marker
printf "youragent-scaffold\nversion=%s\ninstalled=%s\nprofile=%s\n" "$SCAFFOLD_VERSION" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$AGENTIZE_PROFILE" > "$MARKER_FILE"

# --- OpenClaw-aware extras (only if there's an openclaw instance to link to) ---
# Drops .agent/OPENCLAW.md (guidance) + .agent/openclaw/{BRIDGE,GLOBAL_NOTES}.md
# (bidirectional bridge). Non-breaking: skipped entirely when openclaw isn't
# installed. Personal files never overwritten.
OPENCLAW_SCAFFOLDED="no"
if openclaw_present; then
  mkdir -p "$TARGET_DIR/openclaw"
  # OPENCLAW.md — scaffold-level guidance (tool-authored, refresh-safe)
  cat > "$TARGET_DIR/OPENCLAW.md" <<'OCLAW'
# OPENCLAW.md

This repo was scaffolded with agentize on a machine running OpenClaw.
Your agent (from ~/.openclaw/openclaw.json) has global identity + memory;
this repo adds a local operating context that layers on top of it.

## Memory routing

| Scope                                | File                                                 |
|--------------------------------------|------------------------------------------------------|
| Global (user prefs, cross-repo)      | `$openclaw_workspace/memory/`                        |
| Local to this repo                   | `.agent/MEMORY.md`                                   |
| Session scratch / handoff            | `.agent/memory/HANDOFF.md`                           |
| Lessons applicable everywhere        | Both: `.agent/LESSONS_LEARNED.md` + global memory    |

When in doubt: if the fact starts with "in this repo…", it's local.

## Bridge files

- `.agent/openclaw/BRIDGE.md` — per-repo overrides to global personality.
- `.agent/openclaw/GLOBAL_NOTES.md` — write things here that the agent
  should push into its global memory at session end (think HANDOFF for
  the OpenClaw layer).

## Cross-session protocol

1. On entering this repo, read `.agent/NORTH_STAR.md` → `.agent/openclaw/BRIDGE.md`.
2. Work beads from `.agent/memory/BEADS.md` with evidence-on-close.
3. Before exiting, append anything globally useful to `.agent/openclaw/GLOBAL_NOTES.md`.
4. The next session picks up where you left off — in this repo or the next.
OCLAW

  # BRIDGE.md (personal, skip-if-exists)
  if [ ! -f "$TARGET_DIR/openclaw/BRIDGE.md" ]; then
    cat > "$TARGET_DIR/openclaw/BRIDGE.md" <<'BRIDGE'
# BRIDGE.md

Per-repo overrides to your OpenClaw agent's global personality + rules.
Agent reads this on entry to layer on top of its workspace identity.

## Personality overrides for THIS repo

<!-- Examples — delete or replace with your actual rules:
- extra paranoid about database migrations
- strict about evidence in bead closes — require test output, not just "passed"
- never run destructive git commands without explicit confirmation
-->
(none — using global defaults)

## Tool / skill overrides

<!-- Example: - prefer `rg` over `grep` here; `wwvcd` over ad-hoc research -->
(none)

## Handoff expectations

<!-- Example: - always update memory/HANDOFF.md before ending session -->
(none)
BRIDGE
    COUNT_INSTALLED=$((COUNT_INSTALLED+1))
  else
    COUNT_KEPT=$((COUNT_KEPT+1))
  fi

  # GLOBAL_NOTES.md (personal, skip-if-exists)
  if [ ! -f "$TARGET_DIR/openclaw/GLOBAL_NOTES.md" ]; then
    cat > "$TARGET_DIR/openclaw/GLOBAL_NOTES.md" <<'GNOTES'
# GLOBAL_NOTES.md

Things learned HERE that belong in the agent's GLOBAL memory
($openclaw_workspace/memory/). Append-only during the session; the
agent should flush these to global memory before exiting the repo.

## Session log

<!-- Format: `YYYY-MM-DD · one-line takeaway that generalizes beyond this repo` -->

(empty)

## Promoted to global on

<!-- Last time the agent actually pushed entries upstream: `YYYY-MM-DD` -->

(never)
GNOTES
    COUNT_INSTALLED=$((COUNT_INSTALLED+1))
  else
    COUNT_KEPT=$((COUNT_KEPT+1))
  fi
  COUNT_REFRESHED=$((COUNT_REFRESHED+1))  # OPENCLAW.md itself
  OPENCLAW_SCAFFOLDED="yes"
fi

# hooks: auto-wire (silent, collect warnings)
REPO_ROOT="${TARGET_DIR%/.agent}"
HOOK_WARN=()
hook_install() {
  local hookfile="$1" tool="$2"
  local dest="$REPO_ROOT/$hookfile"
  if [ -e "$dest" ]; then
    if grep -qE "agentize|youragent|NORTH_STAR\.md|\.agent/" "$dest" 2>/dev/null; then
      return  # already linked
    fi
    HOOK_WARN+=("$hookfile exists but doesn't reference .agent/ — add: ‘See .agent/NORTH_STAR.md first.’")
    return
  fi
  fetch_file "hooks-scaffold/$hookfile" "$dest"
}
hook_install "CLAUDE.md"    "Claude Code"
hook_install "AGENTS.md"    "Codex"
hook_install ".cursorrules" "Cursor"
hook_install ".windsurfrules" "Windsurf"

# .agents/skills/ — cross-harness skills compat path (Codex, OpenCode, OpenHands,
# Copilot, Gemini CLI, Amp, Cursor-compat, Kilo-compat, pi). Non-breaking:
# only creates if nothing exists at that path, and prefers a symlink to
# .agent/skills/ so there's one source of truth.
AGENTS_COMPAT_STATE="skipped"
if [ ! -e "$REPO_ROOT/.agents/skills" ]; then
  mkdir -p "$REPO_ROOT/.agents"
  if (cd "$REPO_ROOT/.agents" && ln -s "../.agent/skills" skills) 2>/dev/null; then
    AGENTS_COMPAT_STATE="linked"
  else
    mkdir -p "$REPO_ROOT/.agents/skills"
    cp -R "$TARGET_DIR/skills/." "$REPO_ROOT/.agents/skills/" 2>/dev/null && AGENTS_COMPAT_STATE="copied"
  fi
fi

sleep 0.08
if [ ${#HOOK_WARN[@]} -gt 0 ]; then
  dash_update "hooks" warn "${#HOOK_WARN[@]} hook(s) need a manual line"
else
  dash_update "hooks" ready "claude, codex, cursor, windsurf, .agents/skills"
fi

# profile
sleep 0.05
dash_update "profile" ready "$AGENTIZE_PROFILE"

# runtime
RUNTIME_WARN=()
command -v python3 >/dev/null 2>&1 || RUNTIME_WARN+=("python3")
command -v npx     >/dev/null 2>&1 || RUNTIME_WARN+=("npx")
command -v git     >/dev/null 2>&1 || RUNTIME_WARN+=("git")
sleep 0.08
if [ ${#RUNTIME_WARN[@]} -gt 0 ]; then
  dash_update "runtime" warn "missing: ${RUNTIME_WARN[*]}"
else
  dash_update "runtime" ready "python3 · npx · git"
fi

# close the dashboard box
dash_close

# surface any hook warnings below the dashboard
if [ ${#HOOK_WARN[@]} -gt 0 ]; then
  printf "\n"
  for w in "${HOOK_WARN[@]}"; do
    printf "  ${YELLOW}!${RESET} ${DIM}%s${RESET}\n" "$w"
  done
fi

# ---------- condensed reference (v2.0) ----------
row_reveal() { printf "%s\n" "$1"; [ "$NO_ANIM" = "1" ] || [ ! -t 1 ] || sleep 0.012; }

# Single 3-line ref panel — `agentize status` is the full surface map now.
printf "\n"
row_reveal "  ${BOLD}.agent/${RESET}  ${DIM}identity · soul · agent · 130 patterns · instincts/ · skills/ · mesh/ · memory/${RESET}"
row_reveal "  ${BOLD}wired${RESET}    ${DIM}CLAUDE.md · AGENTS.md · .cursorrules · .windsurfrules · .agents/skills (cross-harness)${RESET}"
row_reveal "  ${BOLD}mesh${RESET}     ${DIM}agent-to-agent inbox/outbox — ${RESET}${MAGENTA}npx agentize mesh init${RESET}${DIM} to opt in${RESET}"
case "$WWVCD_STATE" in
  already-installed|global|npx-cached)
    row_reveal "  ${BOLD}runtime${RESET}  ${DIM}python · npx · git · wwvcd (retrieval skill, 1,191 Claude Code findings)${RESET}" ;;
  *)
    row_reveal "  ${BOLD}runtime${RESET}  ${DIM}python · npx · git · wwvcd (lazy-loaded — ${BOLD}npx wwvcd${RESET}${DIM} on demand)${RESET}" ;;
esac

# --- next steps ---
printf "\n"
if [ "$INSTALL_MODE" = "update" ]; then
  row_reveal "  ${GREEN}${BOLD}→ updated to v${SCAFFOLD_VERSION}${RESET}  ${DIM}safe re-run · personal files preserved${RESET}"
else
  row_reveal "  ${CYAN}1${RESET}  ${BOLD}open${RESET} claude / codex / cursor / windsurf  ${DIM}(auto-reads .agent/)${RESET}"
  row_reveal "  ${CYAN}2${RESET}  ${BOLD}./.agent/memory/bd-rank.sh ready${RESET}  ${DIM}(prioritized next task)${RESET}"
  row_reveal "  ${CYAN}3${RESET}  ${BOLD}npx agentize audit${RESET}  ${DIM}(liveness score 0-100, run anytime)${RESET}"
  if [ -f "$HOME/.openclaw/openclaw.json" ]; then
    row_reveal "  ${CYAN}4${RESET}  ${BOLD}npx agentize configure-openclaw${RESET}  ${DIM}(wire global agents)${RESET}"
  fi
fi

row_reveal ""
row_reveal "  ${DIM}autonomous: ${RESET}${MAGENTA}claude --dangerously-skip-permissions${RESET}${DIM} · ${RESET}${MAGENTA}codex --yolo${RESET}${DIM} · ${RESET}${MAGENTA}aider --yes${RESET}"
row_reveal "  ${DIM}more:       ${RESET}${MAGENTA}npx agentize help${RESET}${DIM} · ${RESET}${MAGENTA}npx agentize status --markdown${RESET}${DIM} (handoff doc)${RESET}"

printf "\n  ${DIM}Built by Trilogy AI Center of Excellence · trilogyai.substack.com${RESET}\n\n"

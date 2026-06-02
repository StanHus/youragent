#!/usr/bin/env bash
# learn.sh — propose new instincts from session memory.
#
# Scans SHORT_TERM_MEMORY.md + LESSONS_LEARNED.md for repeated patterns
# (same fix-shape applied 2+ times, same correction received 2+ times,
# same retrieval miss 2+ times) and emits proposed instinct files. Does NOT
# auto-write them — the proposal goes to stdout. Pipe to a file and review,
# then move into memory/instincts/ if you accept.
#
# Usage:
#   ./skills/learn.sh                       # propose new instincts
#   ./skills/learn.sh --apply               # write proposals as draft files in instincts/proposed/
#   ./skills/learn.sh --window 30           # only consider the last 30 days

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENT_DIR="$(dirname "$SCRIPT_DIR")"
LESSONS="$AGENT_DIR/LESSONS_LEARNED.md"
STM="$AGENT_DIR/memory/SHORT_TERM_MEMORY.md"
INSTINCTS_DIR="$AGENT_DIR/memory/instincts"

APPLY=0
WINDOW=90
while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --window) WINDOW="$2"; shift 2 ;;
    -h|--help)
      sed -n '/^# /p' "$0" | sed 's/^# //'; exit 0 ;;
    *) shift ;;
  esac
done

python3 - "$LESSONS" "$STM" "$INSTINCTS_DIR" "$APPLY" "$WINDOW" <<'PY'
import sys, os, re, datetime
from collections import Counter

lessons, stm, instincts_dir, apply, window = sys.argv[1:6]
apply = apply == "1"
window = int(window)

def read(p):
    try:
        return open(p).read()
    except FileNotFoundError:
        return ""

text = read(lessons) + "\n" + read(stm)

if not text.strip():
    print("  · no SHORT_TERM_MEMORY or LESSONS_LEARNED content — nothing to learn from")
    sys.exit(0)

# Naive but useful: look for verbs that suggest reflexes
trigger_patterns = [
    (r'\b(forgot|skipped|missed|didn\'t check)\s+([\w-]+)',         "you skipped {1}",            "Always check {1} first."),
    (r'\b(should have|should\'ve)\s+([\w\s-]{5,30}?)\b(?:\.|,|$)', "you should have {1}",        "Default to {1}."),
    (r'\b(corrected|told me|reminded me)\s+(?:to|that)\s+([\w\s-]{5,40})', "human corrected: {1}", "Do {1} without being asked."),
    (r'\b(don\'t|never|stop)\s+([\w-]+ing)\b',                    "don't {1}",                   "Don't {1}."),
    (r'\bre-?(?:learn|invent|build)\s+([\w-]+)',                  "re-invented {0}",             "Retrieve {0} before building it again."),
]

proposals = []  # (id, trigger, action, why)
for rx, trig_t, act_t in trigger_patterns:
    hits = re.findall(rx, text, flags=re.I)
    cnt = Counter()
    for h in hits:
        key = " ".join(h if isinstance(h, tuple) else (h,)).lower().strip()
        cnt[key] += 1
    for key, n in cnt.items():
        if n < 2: continue   # need recurrence
        parts = key.split()
        verb = parts[0] if parts else ""
        rest = " ".join(parts[1:]) if len(parts) > 1 else parts[0]
        iid = re.sub(r'[^a-z0-9]+', '-', rest)[:30].strip("-") or "auto-instinct"
        trig = trig_t.format(verb, rest)
        act = act_t.format(verb, rest)
        proposals.append((iid, trig, act, f"Seen {n}× in memory in the last {window} days."))

if not proposals:
    print("  · no recurring patterns found — your memory is either clean or too short")
    sys.exit(0)

print(f"\n  Proposed instincts ({len(proposals)} found, recurrence ≥ 2):\n")
os.makedirs(os.path.join(instincts_dir, "proposed"), exist_ok=True) if apply else None
for iid, trig, act, why in proposals:
    body = f"""---
id: {iid}
trigger: {trig}
profile: standard
---

## Action
{act}

## Evidence
You explicitly note in your response that you applied this — or you can point
to a file/command/test that proves it.

## Why
{why}
"""
    if apply:
        outp = os.path.join(instincts_dir, "proposed", f"{iid}.md")
        with open(outp, "w") as f: f.write(body)
        print(f"  ✓ proposed/{iid}.md")
    else:
        print(f"  ─── {iid} ───")
        print(body)
        print()

if not apply:
    print(f"\n  Rerun with --apply to write these into {instincts_dir}/proposed/")
    print(f"  Review each, then `mv` accepted ones into the instincts root.")
PY

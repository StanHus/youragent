#!/usr/bin/env bash
# bd-rank.sh — priority + impact + validity ranking for bd-lite beads.
#
# Why this exists: bd-lite.sh `ready` returns pending+unblocked beads in file order
# (effectively newest-or-oldest depending on how they were appended). That is not
# how a smart agent should pick the next thing to do. This script ranks beads by:
#
#   score = priority_weight                   (importance)
#         + unblock_fanout * 15               (impact: how many beads this unblocks)
#         + manual_boost                      (sticky override via `boost`)
#         - stale_penalty                     (validity: marked-stale beads sink)
#
# Survives `npx agentize` refreshes because it is a NEW file (bd-lite.sh itself is
# tool-authored and would be clobbered).
#
# Commands:
#   ready                       — ranked list of pending+unblocked beads with score breakdown
#   score <id>                  — show scoring for one bead
#   stale <id> --reason "..."   — mark a bead low-validity (drops to bottom of ready)
#   unstale <id>                — clear stale flag
#   boost <id> <N>              — add N to score (e.g. 25 to surface a low-priority urgent task)
#
# Markers live in the existing `reason` field (column 7) for pending/blocked rows
# so we never break compatibility with bd-lite.sh schema:
#   STALE: <reason>             — validity flag
#   BOOST=<N>                   — manual override (combinable with STALE)

set -euo pipefail

LEDGER="${BD_LEDGER:-$(dirname "$0")/BEADS.md}"

usage() {
  cat <<EOF
bd-rank — score-based bead prioritization

Commands:
  ready                       ranked pending+unblocked beads (score + breakdown)
  score <id>                  show scoring breakdown for one bead
  stale <id> --reason "..."   mark a bead low-validity (sinks to bottom)
  unstale <id>                clear stale flag
  boost <id> <N>              manual score nudge (signed integer)

Score = priority_weight + unblock_fanout*15 + boost - stale_penalty
  Priority weights: P0=100, P1=50, P2=20
  Stale penalty: 1000 (effectively bottom of list)

Ledger: $LEDGER
EOF
}

cmd_ready() {
  python3 - "$LEDGER" <<'PY'
import sys, re
path = sys.argv[1]
beads = []
fanout = {}
with open(path) as f:
    for line in f:
        if not re.match(r'^\| B[0-9]{4}', line): continue
        parts = [p.strip() for p in line.strip().strip('|').split('|')]
        if len(parts) < 7: continue
        bid, prio, status, blocked, subj, claimed, reason = parts[:7]
        beads.append({"id": bid, "prio": prio, "status": status,
                      "blocked": blocked, "subj": subj, "reason": reason})
        if blocked not in ("—","-",""):
            for dep in re.split(r'[,\s]+', blocked):
                if dep: fanout[dep] = fanout.get(dep, 0) + 1

PRIO_W = {"P0": 100, "P1": 50, "P2": 20}

def score(b):
    base = PRIO_W.get(b["prio"], 30)
    fan = fanout.get(b["id"], 0) * 15
    stale = 1000 if b["reason"].startswith("STALE:") else 0
    m = re.search(r'BOOST=(-?\d+)', b["reason"])
    boost = int(m.group(1)) if m else 0
    return base, fan, boost, stale, base + fan + boost - stale

ready = [b for b in beads if b["status"] == "pending" and b["blocked"] in ("—","-","")]
ranked = sorted(ready, key=lambda b: -score(b)[4])

if not ranked:
    print("(no ready beads)")
    sys.exit(0)

print(f"{'SCORE':>6}  {'ID':<6} {'PRIO':<4} {'FAN':>3} {'BOOST':>5} {'STALE':>5}  SUBJECT")
print("-" * 80)
for b in ranked:
    base, fan, boost, stale, total = score(b)
    stale_mark = "yes" if stale else ""
    print(f"{total:>6}  {b['id']:<6} {b['prio']:<4} {fan:>3} {boost:>5} {stale_mark:>5}  {b['subj'][:60]}")
PY
}

cmd_score() {
  local id="$1"
  python3 - "$LEDGER" "$id" <<'PY'
import sys, re
path, target = sys.argv[1], sys.argv[2]
beads = []
fanout = {}
target_b = None
with open(path) as f:
    for line in f:
        if not re.match(r'^\| B[0-9]{4}', line): continue
        parts = [p.strip() for p in line.strip().strip('|').split('|')]
        if len(parts) < 7: continue
        bid, prio, status, blocked, subj, claimed, reason = parts[:7]
        b = {"id": bid, "prio": prio, "status": status,
             "blocked": blocked, "subj": subj, "reason": reason}
        beads.append(b)
        if bid == target: target_b = b
        if blocked not in ("—","-",""):
            for dep in re.split(r'[,\s]+', blocked):
                if dep: fanout[dep] = fanout.get(dep, 0) + 1

if not target_b:
    print(f"ERROR: {target} not found"); sys.exit(1)

PRIO_W = {"P0": 100, "P1": 50, "P2": 20}
b = target_b
base = PRIO_W.get(b["prio"], 30)
fan = fanout.get(b["id"], 0) * 15
stale = 1000 if b["reason"].startswith("STALE:") else 0
m = re.search(r'BOOST=(-?\d+)', b["reason"])
boost = int(m.group(1)) if m else 0
total = base + fan + boost - stale

print(f"{b['id']}: {b['subj']}")
print(f"  priority {b['prio']:<3}  base       = {base}")
print(f"  unblocks {fanout.get(b['id'],0)} beads  fanout*15  = {fan}")
print(f"  manual boost          = {boost}")
print(f"  stale penalty         = -{stale}")
print(f"  -----------------------")
print(f"  TOTAL                 = {total}")
print(f"  status: {b['status']}, blocked_by: {b['blocked']}")
print(f"  reason field: {b['reason']}")
PY
}

# Mutate the reason column for a bead. Used by stale/unstale/boost.
# Args: id, transform_fn_name (passed as env var)
_update_reason() {
  local id="$1" mode="$2" payload="${3:-}"
  python3 - "$LEDGER" "$id" "$mode" "$payload" <<'PY'
import sys, re
path, target, mode, payload = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
with open(path) as f: lines = f.readlines()
out = []
hit = False
for line in lines:
    if not re.match(r'^\| ' + re.escape(target) + r' \|', line):
        out.append(line); continue
    parts = [p.strip() for p in line.strip().strip('|').split('|')]
    if len(parts) < 7:
        out.append(line); continue
    if parts[2] == "done":
        print(f"ERROR: {target} is done; refusing to modify reason field"); sys.exit(1)
    reason = parts[6] if parts[6] not in ("—","-") else ""
    # Strip existing markers
    reason_clean = re.sub(r'^STALE:[^|]*?(?=( BOOST=|$))', '', reason).strip()
    reason_clean = re.sub(r'\s*BOOST=-?\d+', '', reason_clean).strip()

    if mode == "stale":
        new_reason = f"STALE: {payload}"
        if reason_clean: new_reason += f" (was: {reason_clean})"
    elif mode == "unstale":
        new_reason = reason_clean or "—"
    elif mode == "boost":
        n = int(payload)
        if n == 0:
            new_reason = reason_clean or "—"
        else:
            new_reason = (reason_clean + f" BOOST={n}").strip()
    else:
        print(f"ERROR: unknown mode {mode}"); sys.exit(1)

    parts[6] = new_reason if new_reason else "—"
    out.append("| " + " | ".join(parts) + " |\n")
    hit = True

if not hit:
    print(f"ERROR: {target} not found"); sys.exit(1)
with open(path, "w") as f: f.writelines(out)
print(f"{mode} {target}: {payload}")
PY
}

cmd_stale() {
  local id="$1"; shift
  local reason=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --reason) reason="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  if [ -z "$reason" ] || [ ${#reason} -lt 10 ]; then
    echo "ERROR: stale requires --reason '<why this is no longer load-bearing>' (>=10 chars)" >&2
    exit 1
  fi
  _update_reason "$id" stale "$reason"
}

cmd_unstale() {
  local id="$1"
  _update_reason "$id" unstale ""
}

cmd_boost() {
  local id="$1" n="$2"
  if ! [[ "$n" =~ ^-?[0-9]+$ ]]; then
    echo "ERROR: boost amount must be a signed integer (e.g. 25 or -10)" >&2
    exit 1
  fi
  _update_reason "$id" boost "$n"
}

cmd="${1:-help}"; shift || true
case "$cmd" in
  ready)        cmd_ready ;;
  score)        cmd_score "$@" ;;
  stale)        cmd_stale "$@" ;;
  unstale)      cmd_unstale "$@" ;;
  boost)        cmd_boost "$@" ;;
  help|-h|--help) usage ;;
  *)            echo "Unknown command: $cmd"; usage; exit 1 ;;
esac

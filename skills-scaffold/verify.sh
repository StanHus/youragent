#!/usr/bin/env bash
# verify.sh — evidence-truthing layer for bead close-reasons.
#
# Reads the close-reason for a bead, extracts cited filenames / test names /
# command-output markers, and checks whether they actually exist in the repo.
# Returns 0 if all citations resolve, 1 if any fail. Soft-warn mode by default
# (always exits 0 but prints warnings) so it can be wired into a hook without
# blocking. Set VERIFY_STRICT=1 to make it fail.
#
# Usage:
#   ./skills/verify.sh <bead-id>            # check one bead
#   ./skills/verify.sh --all                # check every "done" bead
#   ./skills/verify.sh --last               # check the most recently closed bead
#
# The point: stop "done", "works", "looks good" from sneaking past bd.sh's
# vague-reason filter dressed up in slightly less obvious words.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENT_DIR="$(dirname "$SCRIPT_DIR")"
LEDGER="${BD_LEDGER:-$AGENT_DIR/memory/BEADS.md}"
REPO_ROOT="$(dirname "$AGENT_DIR")"
STRICT="${VERIFY_STRICT:-0}"

usage() {
  cat <<EOF
verify — evidence-truthing for bead close-reasons

Usage:
  verify <bead-id>     check one bead
  verify --all         check every closed bead
  verify --last        check the most recently closed bead

Exits 0 on success. Exits 1 on failure when VERIFY_STRICT=1.

Ledger: $LEDGER
EOF
}

[ $# -lt 1 ] && { usage; exit 0; }

check_one() {
  local bid="$1"
  python3 - "$LEDGER" "$bid" "$REPO_ROOT" "$STRICT" <<'PY'
import sys, re, os, subprocess
path, target, repo, strict = sys.argv[1:5]
strict = strict == "1"

def row_for(bid):
    with open(path) as f:
        for line in f:
            if re.match(rf'^\| {re.escape(bid)} ', line):
                parts = [p.strip() for p in line.strip().strip('|').split('|')]
                if len(parts) >= 7:
                    return parts[:7]
    return None

row = row_for(target)
if not row:
    print(f"  ! {target} not in ledger"); sys.exit(0 if not strict else 2)

bid, prio, status, blocked, subj, claimed, reason = row
if status != "done":
    print(f"  · {bid} status={status}; nothing to verify"); sys.exit(0)

# Extract citation candidates from reason.
file_candidates = re.findall(r'[\w./-]+\.[a-zA-Z]{1,6}(?::\d+)?', reason)
test_candidates = re.findall(r'\btest_[\w]+\b|\b[\w]+_test\b|\bit\(["\'][^"\']+["\']', reason)
port_candidates = re.findall(r':\d{2,5}\b', reason)
hash_candidates = re.findall(r'\b[0-9a-f]{7,40}\b', reason)

found = []
missing = []

for f in file_candidates:
    fpath = f.split(":")[0]
    full = os.path.join(repo, fpath)
    if os.path.exists(full):
        found.append(("file", f))
    else:
        missing.append(("file", f))

vague = re.fullmatch(r'\s*(done|works|works fine|looks good|fixed|ok|good|complete|all set)\s*\.?\s*', reason, re.I)

print(f"  {bid} · {subj[:50]}")
print(f"    reason: {reason[:100]}")
if vague:
    print(f"    ✗ VAGUE reason — bd.sh should have rejected this; verify did")
    sys.exit(1 if strict else 0)
if not (found or test_candidates or port_candidates or hash_candidates):
    print(f"    ! no citations found in reason (no file, no test, no port, no hash)")
    sys.exit(1 if strict else 0)
for kind, c in found:
    print(f"    ✓ {kind}: {c}")
for kind, c in missing:
    print(f"    ✗ {kind} cited but NOT FOUND: {c}")
for c in test_candidates:
    print(f"    · test cited: {c}  (not auto-resolved)")
for c in port_candidates:
    print(f"    · port cited: {c}")
for c in hash_candidates:
    print(f"    · hash cited: {c}")
sys.exit(1 if (missing and strict) else 0)
PY
}

case "$1" in
  -h|--help) usage; exit 0 ;;
  --all)
    python3 - "$LEDGER" <<'PY' | while read bid; do check_one "$bid"; done
import sys, re
path = sys.argv[1]
with open(path) as f:
    for line in f:
        m = re.match(r'^\| (B\d{4}) \| .* \| done \|', line)
        if m: print(m.group(1))
PY
    ;;
  --last)
    last=$(grep -Eo '^\| B[0-9]{4} \| [^|]+ \| done \|' "$LEDGER" 2>/dev/null | tail -1 | awk '{print $2}')
    [ -z "$last" ] && { echo "  no closed beads"; exit 0; }
    check_one "$last"
    ;;
  B[0-9]*) check_one "$1" ;;
  *) usage; exit 1 ;;
esac

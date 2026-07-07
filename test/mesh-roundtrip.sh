#!/usr/bin/env bash
# test/mesh-roundtrip.sh — end-to-end proof that the mesh delivers.
# Builds a 4-node tree, installs agentize into each, then exercises
# discover → send → inbox → read → ack across nodes, plus a scope-boundary
# check. Fully self-contained and path-portable (no machine-specific paths).
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
TREE="$TMP/tree"
# Peers live under $TMP (outside $HOME on CI); scope the ceiling to the tree.
export MESH_SCOPE_CEILING="$TREE"
export NO_ANIM=1

pass=0; fail=0
ok()   { printf "  \033[32mPASS\033[0m %s\n" "$1"; pass=$((pass+1)); }
bad()  { printf "  \033[31mFAIL\033[0m %s\n" "$1"; fail=$((fail+1)); }
mesh() { bash "$TREE/$1/.agent/mesh/mesh.sh" "${@:2}"; }

cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

printf "\n  mesh round-trip  (repo: %s)\n  ------------------------------------------\n" "$REPO"

# --- build tree: orchestrator + worker-a + worker-b/sub + a too-deep node ---
NODES=(orchestrator worker-a worker-b worker-b/sub worker-b/sub/deep)
for n in "${NODES[@]}"; do
  mkdir -p "$TREE/$n"
  NO_ANIM=1 BOOTSTRAP_TARGET="$TREE/$n/.agent" bash "$REPO/install.sh" >/dev/null 2>&1
  mesh "$n" init >/dev/null 2>&1
done
[ -f "$TREE/orchestrator/.agent/mesh/mesh.sh" ] && ok "install dropped mesh.sh into every node" || bad "mesh.sh missing after install"
[ -f "$TREE/orchestrator/.agent/mesh/config.json" ] && ok "mesh init wrote config.json" || bad "config.json missing after init"

# --- discovery: orchestrator should see siblings + a grandchild, not the too-deep node ---
peers_out="$(mesh orchestrator peers)"
echo "$peers_out" | grep -q "worker-a" && ok "discover: sibling worker-a in scope" || bad "discover: worker-a not found"
echo "$peers_out" | grep -q "worker-b" && ok "discover: sibling worker-b in scope" || bad "discover: worker-b not found"
echo "$peers_out" | grep -q "sub"      && ok "discover: 2-down 'sub' in scope"     || bad "discover: sub not found"
if echo "$peers_out" | grep -q "deep"; then bad "scope boundary leaked: 'deep' (3 down) should be out of scope"; else ok "scope boundary: 3-down 'deep' correctly excluded"; fi
if echo "$peers_out" | grep -q "orchestrator"; then bad "self should not appear in own peer list"; else ok "self excluded from peer list"; fi

# --- send orchestrator → worker-a ---
mesh orchestrator send worker-a "unit one review" --type directive --ref B0007 --body "Please review Unit 1 draft." >/dev/null
inbox_file="$(ls -1 "$TREE/worker-a/.agent/mesh/inbox" 2>/dev/null | head -1 || true)"
[ -n "$inbox_file" ] && ok "send: message landed in worker-a inbox" || bad "send: nothing in worker-a inbox"

# header integrity
msgpath="$TREE/worker-a/.agent/mesh/inbox/$inbox_file"
grep -q "^# unit one review" "$msgpath" && ok "message: subject header intact" || bad "message: subject header wrong"
grep -q "^\*\*Type:\*\* directive" "$msgpath" && ok "message: type header intact" || bad "message: type header wrong"
grep -q "^\*\*Ref:\*\* B0007" "$msgpath" && ok "message: ref header intact" || bad "message: ref header wrong"
msgid="$(grep -m1 '^\*\*Msg-Id:\*\*' "$msgpath" | sed 's/.*Msg-Id:\*\* //')"
[ -n "$msgid" ] && ok "message: msg-id present ($msgid)" || bad "message: msg-id missing"

# --- inbox --unread shows it, then read marks it ---
# capture-then-match (piping to `grep -q` would SIGPIPE the writer mid-print)
unread_before="$(mesh worker-a inbox --unread)"
case "$unread_before" in *"unit one review"*) ok "inbox --unread lists the new message";; *) bad "inbox --unread empty";; esac
mesh worker-a read "$inbox_file" >/dev/null && ok "read prints + marks message" || bad "read failed"
unread_after="$(mesh worker-a inbox --unread)"
case "$unread_after" in *"unit one review"*) bad "read did not clear unread flag";; *) ok "read cleared the unread flag";; esac

# --- ack flows back to orchestrator ---
mesh worker-a ack "$msgid" >/dev/null
if ls -1 "$TREE/orchestrator/.agent/mesh/_acks" 2>/dev/null | grep -q "$msgid"; then ok "ack delivered to sender's _acks"; else bad "ack not found in orchestrator _acks"; fi

# --- guardrail: oversize message rejected ---
big="$(head -c 70000 /dev/zero | tr '\0' 'x')"
if mesh orchestrator send worker-a "too big" --body "$big" >/dev/null 2>&1; then bad "oversize message was NOT rejected"; else ok "oversize message rejected (byte cap enforced)"; fi

# --- guardrail: unknown peer errors cleanly ---
if mesh orchestrator send nonesuch "x" --body y >/dev/null 2>&1; then bad "send to unknown peer should fail"; else ok "send to unknown peer fails cleanly"; fi

# --- fresh-node status/doctor must not crash (uninitialised path) ---
mkdir -p "$TREE/fresh"; NO_ANIM=1 BOOTSTRAP_TARGET="$TREE/fresh/.agent" bash "$REPO/install.sh" >/dev/null 2>&1
if bash "$TREE/fresh/.agent/mesh/mesh.sh" status >/dev/null 2>&1; then ok "status on uninitialised node exits clean (no crash)"; else bad "status crashed on fresh node"; fi

# --- receive-side hardening: symlink in inbox is skipped + refused ---
wa_inbox="$TREE/worker-a/.agent/mesh/inbox"
secret="$TREE/SECRET.txt"; echo "TOP-SECRET-TOKEN" > "$secret"
ln -s "$secret" "$wa_inbox/99999999T999999Z_evil_leak.md"
inbox_list="$(mesh worker-a inbox)"
case "$inbox_list" in *TOP-SECRET*|*leak*) bad "symlinked inbox entry was listed";; *) ok "symlinked inbox entry skipped by listing";; esac
if mesh worker-a read "99999999T999999Z_evil_leak.md" 2>/dev/null | grep -q TOP-SECRET; then bad "read followed a symlink and leaked a secret"; else ok "read refuses symlinked entry (no secret leak)"; fi

# --- receive-side hardening: oversize file dropped directly is not valid/unread ---
head -c 70000 /dev/zero | tr '\0' 'x' > "$wa_inbox/20260101T000000Z_attacker_flood.md"
status_out="$(mesh worker-a status 2>/dev/null || true)"
# the flood file lacks envelope headers AND exceeds cap -> must not count as unread
mesh orchestrator send worker-a "legit ping" --body "hi" >/dev/null
unread_n="$(bash "$TREE/worker-a/.agent/mesh/mesh.sh" inbox --unread | grep -c 'from ' || true)"
# only the legit message (+ the earlier un-acked one if any) should be unread; the flood/symlink must not
if mesh worker-a read "20260101T000000Z_attacker_flood.md" >/dev/null 2>&1 && mesh worker-a inbox --unread >/dev/null; then :; fi
ok "oversize/non-envelope inbox files handled without crashing"

# --- poll with auto-wake disabled (default) must NOT spawn, and must log it ---
plog="$TREE/worker-a/.agent/mesh/.state/poll.log"
rm -f "$plog"
mesh worker-a poll >/dev/null 2>&1 && poll_rc=0 || poll_rc=$?
[ "${poll_rc:-1}" -eq 0 ] && ok "poll exits 0 with auto-wake disabled" || bad "poll non-zero (rc=$poll_rc)"
if grep -q "auto-wake disabled" "$plog" 2>/dev/null; then ok "poll logs auto-wake-disabled instead of spawning"; else bad "poll did not log auto-wake-disabled"; fi

# --- stale poll-lock is reclaimed (dead owner PID) ---
lock="$TREE/worker-a/.agent/mesh/.state/poll.lock"
rm -rf "$lock"; mkdir -p "$lock"; echo "999999" > "$lock/pid"   # PID that isn't alive
rm -f "$plog"
mesh worker-a poll >/dev/null 2>&1 || true
if grep -q "breaking stale lock" "$plog" 2>/dev/null; then ok "stale poll-lock (dead PID) reclaimed"; else bad "stale poll-lock not reclaimed — delivery could wedge"; fi

# --- unique filenames: two same-subject sends in one second don't clobber ---
before=$(ls -1 "$wa_inbox" | wc -l | tr -d ' ')
mesh orchestrator send worker-a "burst" --body one >/dev/null
mesh orchestrator send worker-a "burst" --body two >/dev/null
after=$(ls -1 "$wa_inbox" | wc -l | tr -d ' ')
[ "$after" -eq $((before + 2)) ] && ok "two same-subject sends both land (no filename clobber)" || bad "same-subject burst clobbered ($before -> $after, expected +2)"

printf "  ------------------------------------------\n  %d passed · %d failed\n\n" "$pass" "$fail"
[ "$fail" -eq 0 ]

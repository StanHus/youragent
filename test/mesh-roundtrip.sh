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

printf "  ------------------------------------------\n  %d passed · %d failed\n\n" "$pass" "$fail"
[ "$fail" -eq 0 ]

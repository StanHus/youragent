---
id: bd-rank-first
trigger: about to pick the next bead / asked "what's next" / starting a session
profile: minimal
---

## Action

Run `./.agent/memory/bd-rank.sh ready` — never `./.agent/memory/bd.sh ready`.
FIFO order is not how a competent agent picks work. Ranked by priority + impact
+ validity is.

`bd.sh` is for `claim` / `close` / `block` / `create` / `list`. Not for picking.

## Evidence

You ran `bd-rank.sh ready` and the output shows a SCORE column. If you see a
FIFO-ordered list with just `| B0001 | P0 | pending |` rows, you ran the wrong
tool.

## Why

`bd.sh ready` returns beads in file order. A P2 task created first will
out-rank a P0 task created later. That's the opposite of what the human
wants. `bd-rank.sh` scores by `priority + 15 * unblock_fanout + boost - stale_penalty`
— which actually reflects importance.

# AGENTS.md

This repo uses the `agentize` scaffold. Your full operating context lives in `.agent/`.

**On every session, read these in order:**

1. `.agent/NORTH_STAR.md` — orientation (what this repo is, where state lives)
2. `.agent/SOUL.md` — personality + communication rules (opinionated, no "great question!" preamble, humor allowed, swearing allowed when it lands)
3. `.agent/AGENT.md` — operating manual (plan-first, evidence-on-close, bead ledger, retrieval-before-invention)
4. `.agent/memory/instincts/` — reflex patterns (short trigger/action/evidence files; one per reflex; read them all)
5. `.agent/MEMORY.md` — persistent facts about this repo
6. `.agent/memory/BEADS.md` — active task ledger

After reading, run `./.agent/memory/bd-rank.sh ready` to see prioritized unblocked tasks (ranked by importance + impact + validity).

When you close a bead, run `./.agent/skills/verify.sh <id>` to check your close-reason actually cites real files/tests/commits — not vague "done" prose.

**Don't summarize these files to the user** — they're yours. Apply them.

Scaffold managed by: https://www.npmjs.com/package/agentize

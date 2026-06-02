---
id: retrieve-before-invent
trigger: about to write code, a plan, or a doc from scratch
profile: standard
---

## Action

Before inventing, check existing artifacts in this order:

1. `.agent/memory/MEMORY.md` and `.agent/MEMORY.md` — facts already known
2. `.agent/memory/LESSONS_LEARNED.md` — mistakes already made
3. `.agent/PATTERNS_CATALOG.md` — 130 named patterns from CoE articles
4. `.agent/skills/memory-search.sh "<topic>"` — cross-repo memory grep
5. `.agent/skills/search-substack.sh "<topic>"` — cited CoE retrieval
6. `npx wwvcd "<topic>" --json` — Claude Code source findings (if installed)

Only invent after retrieval comes up empty.

## Evidence

Your final response cites at least one retrieved artifact (a memory line, a
pattern ID like `P-PLAN-03`, a lesson, an article URL, or a wwvcd hit) — OR
you explicitly say "retrieval came up empty, inventing fresh."

## Why

Most "new" problems already have a recorded answer. Inventing without
retrieving wastes tokens, drifts from the team's conventions, and re-introduces
bugs you previously fixed.

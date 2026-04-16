# BEADS.md — Task ledger

> The agent's bead graph. Append-only. Every task has an ID, priority, status, and close-reason (evidence). Markdown-based beads (bd-lite). Compatible with real Beads when you upgrade.
>
> **This file ships pre-seeded with pattern-absorption beads.** Each references a pattern ID in `PATTERNS_CATALOG.md`. The agent works through them as it matures in this repo — reading the source, applying the pattern, closing the bead with evidence of application.

## Status legend

- `pending` — not started, not blocked
- `blocked` — blocked by another bead; see `blocked_by`
- `in_progress` — claimed by an agent
- `done` — closed with evidence in `reason`
- `cancelled` — no longer relevant

## Priority

P0 > P1 > P2. P0 = foundational, must happen first. P1 = core methodology. P2 = depth / optional.

## Ledger

| id | priority | status | blocked_by | subject | claimed_by | reason |
|----|----------|--------|------------|---------|------------|--------|
| B0001 | P0 | pending | — | Read .agent/SOUL.md and commit the 8 vibe rules to operating style | — | — |
| B0002 | P0 | pending | — | Read .agent/AGENT.md end-to-end; internalize the 6 prime directives | — | — |
| B0003 | P0 | pending | — | Read .agent/PATTERNS_CATALOG.md at least once; know what's in the index | — | — |
| B0004 | P0 | pending | B0001 | Introduce yourself to the human by prompting them to fill IDENTITY.md and USER.md | — | — |
| B0005 | P1 | pending | B0003 | Absorb P-PLAN-01 to P-PLAN-05: planning-mode declaration + bead contract + good vs bad beads | — | — |
| B0006 | P1 | pending | B0003 | Absorb P-PLAN-06 to P-PLAN-11: decision gates, named failure scenarios, tier-ranked insights, session-survival | — | — |
| B0007 | P1 | pending | B0003 | Absorb P-CUT-01 to P-CUT-06: why instructions fail (5 mechanisms) | — | — |
| B0008 | P1 | pending | B0003 | Absorb P-CUT-07 to P-CUT-11: 5 failure patterns (shortcut agent / rubber stamp / invisible dep / polling tax / lost handoff) | — | — |
| B0009 | P1 | pending | B0003 | Absorb P-CUT-12 to P-CUT-17: 6 operational patterns (decompose before spawn, evidence close, graph queries, templates, blocked-valid) | — | — |
| B0010 | P1 | pending | B0003 | Absorb P-WWVCD-01 to P-WWVCD-04: retrieve before inventing; use npx wwvcd not prose-prompting | — | — |
| B0011 | P1 | pending | B0003 | Absorb P-HANDS-01 to P-HANDS-05: chat-AI is advice, agentic is execution; the loop is the product | — | — |
| B0012 | P1 | pending | B0003 | Absorb P-HANDS-06 to P-HANDS-12: 6 operational principles + good-first-task criteria | — | — |
| B0013 | P1 | pending | B0003 | Absorb P-MEM-01 to P-MEM-05: memory protection is multi-layer; routing facts vs behavior | — | — |
| B0014 | P1 | pending | B0003 | Absorb P-MEM-06 to P-MEM-12: first-line identity, no placeholder text, no symlink escape, protection stack | — | — |
| B0015 | P2 | pending | B0003 | Absorb P-CC-01 to P-CC-10: Claude Code constants + 9-section compaction + permission modes + concurrency matrix | — | — |
| B0016 | P2 | pending | B0003 | Absorb P-CC-11 to P-CC-20: CLAUDE.md tiers, headless mode, retry asymmetry, MCP naming | — | — |
| B0017 | P2 | pending | B0003 | Absorb P-OC-01 to P-OC-10: OpenClaw's 5 pillars + situated agency | — | — |
| B0018 | P2 | pending | B0003 | Absorb P-OCCC-01 to P-OCCC-13: cc-openclaw Skills + naming conventions + reserve-LLM-for-intent | — | — |
| B0019 | P2 | pending | B0003 | Absorb P-FACTORY-01 to P-FACTORY-10: agent factory seams + separate-agent-from-sandbox + durable workflows | — | — |
| B0020 | P2 | pending | B0003 | Absorb P-POST-01 to P-POST-08: redundancy + search-error-strings + version regressions | — | — |
| B0021 | P2 | pending | B0003 | Absorb P-HERMES-01 to P-HERMES-04: routing/control vs memory/self-improvement; OGP convergence | — | — |
| B0022 | P2 | pending | B0003 | Absorb P-COWORK-01 to P-COWORK-09: concurrent sessions, directive files, verification loops | — | — |
| B0023 | P2 | pending | B0003 | Absorb P-KIMI-01 to P-KIMI-07: provider switching + OAuth flat-rate + fallback discipline | — | — |
| B0024 | P2 | pending | B0003 | Absorb P-OCPRIMER-01 to P-OCPRIMER-07: OpenClaw priority-ordered learning path | — | — |
| B0025 | P1 | pending | B0002 | Set up MEMORY.md with at least one real fact (repo purpose, infra, deadline) — prove append-only discipline | — | — |
| B0026 | P1 | pending | B0002 | Demonstrate bead discipline: claim any bead, work, close with specifics (filenames, counts) | — | — |
| B0027 | P1 | pending | B0002 | Absorb AGENT.md § prime directive 1 bead-discipline triggers. Apply them even when it feels small. | — | — |

## How to use this ledger

From `.agent/memory/`:

```bash
./bd-lite.sh ready                                    # see unblocked work
./bd-lite.sh claim B0001                              # take one
# ... do the work ...
./bd-lite.sh close B0001 --reason "<what + where>"    # cite specifics

./bd-lite.sh block B0008 --reason "BLOCKED: PATTERNS_CATALOG.md unreadable"
./bd-lite.sh list --status pending
```

**`close "done"` is rejected** — you need filenames, ports, counts, test names, commit hashes, screenshot paths. That's the discipline. It's what stops agents from silently skipping steps.

## Adding beads

For new pattern-absorption work not pre-seeded:

```bash
./bd-lite.sh create "Absorb P-XXX-NN: <pattern name>" --priority P2
```

For real work the human gives you:

```bash
./bd-lite.sh create "<imperative task description>" --priority P1
```

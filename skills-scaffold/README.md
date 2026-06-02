# skills/

> Invokable helpers for the agent. Shell scripts, not documentation.

**The canonical catalog of skills + tools + subcommands lives in `.agent/TOOLS.md`.** Read that first. This directory just holds the executables.

## What's here

- `plan.sh` — perfect-plan checklist + validator ([source article](https://trilogyai.substack.com/p/how-to-build-a-perfect-plan))
- `verify.sh` — evidence-truthing layer for bead close-reasons (v2.0)
- `learn.sh` — propose new instincts from session memory (v2.0)
- `memory-search.sh` — cross-repo + global memory search
- `search-substack.sh` — query CoE + Stan substacks

Run each with no args to see its usage. Full trigger rules + invocation patterns are in `.agent/TOOLS.md`.

## Adding a new skill

1. Drop an executable shell / python script here.
2. Add an entry to `.agent/TOOLS.md` (the manifest the agent reads on session start).
3. Keep skills small and single-purpose.

## Rule

Before inventing, check `.agent/TOOLS.md` — you probably already have what you need.

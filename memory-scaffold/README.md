# memory/README.md — How beads work here

> This folder is the agent's persistent task graph. It uses `bd-lite.sh` — a markdown-file-based bead tracker mimicking the semantics of [Beads by Steve Yegge](https://github.com/steveyegge/beads). When you're ready for the real Go-binary version, swap `bd-lite` → `bd` with no workflow change.

## Why beads

LLMs silently skip steps under load. A bead graph makes "done" atomic and dependency-ordered. Closing requires evidence.

Two sources shaped this:
- **The tool** — [Beads by Steve Yegge](https://github.com/steveyegge/beads). Original Go CLI, Dolt-backed, what `bd-lite` emulates. Announcement: [steve-yegge.medium.com/introducing-beads-a-coding-agent-memory-system](https://steve-yegge.medium.com/introducing-beads-a-coding-agent-memory-system-637d7d92514a).
- **The methodology** — "How to Fix Your AI Agents Skipping Steps" (Trilogy AI COE) popularized using Beads for agent orchestration.

## Files

- `BEADS.md` — the ledger (human-readable + grep-friendly)
- `PROMPTS.md` — verbatim log of human instructions
- `HANDOFF.md` — written at end of each session for the next one
- `BACKUPS/` — rotating backups of memory files (created as needed)
- `bd-lite.sh` — CLI helper (create / claim / close / block / list)
- `bd-rank.sh` — score-based prioritizer (ready / score / stale / unstale / boost)

## Commands

All run from `.agent/memory/`.

```bash
./bd-lite.sh create "Task subject" --priority P1 --blocked-by B0003
./bd-lite.sh claim B0007               # mark as in_progress, set claimed_by
./bd-lite.sh close B0007 --reason "Dev server on :3000, test_login.py passes"
./bd-lite.sh block B0007 --reason "BLOCKED: CLIENT_ID missing from .env.example"
./bd-lite.sh list                      # show everything
./bd-lite.sh list --status in_progress
```

### Picking what to work on next — `bd-rank.sh`

`bd-lite ready` is FIFO. `bd-rank ready` ranks pending+unblocked beads by
**importance + impact + validity** so you don't just grab the newest one:

```
score = priority_weight        (P0=100, P1=50, P2=20)
      + unblock_fanout * 15    (how many beads this one unblocks)
      + manual_boost           (sticky override per bead)
      - stale_penalty          (1000 if marked stale → sinks to bottom)
```

```bash
./bd-rank.sh ready                              # ranked next-up list
./bd-rank.sh score B0007                        # full breakdown for one bead
./bd-rank.sh stale B0042 --reason "premise gone — superseded by B0050"
./bd-rank.sh unstale B0042                      # clear the flag
./bd-rank.sh boost B0007 25                     # surface a low-priority urgent task
./bd-rank.sh boost B0007 0                      # remove the boost
```

Markers live in the existing `reason` column (`STALE: ...`, `BOOST=N`) so
the ledger schema stays compatible with `bd-lite` and with real Beads.

## Rules (for the agent — non-negotiable)

1. **Never close without a reason.** The `--reason` string is proof of work. "done" is not acceptable.
2. **Be specific.** Include filenames, ports, counts, test names, screenshots. "fixed bug" is not specific.
3. **Blocked is valid.** If stuck, `block` the bead with a specific blocker. Don't fake completion.
4. **Never edit BEADS.md by hand.** Use the CLI. Hand-edits break the append-only discipline.
5. **Check `ready` before claiming.** Dependencies matter. Prefer `bd-rank.sh ready` (ranked) over `bd-lite.sh ready` (FIFO).
6. **One in-progress bead per agent.** Don't claim a second until the first is closed or blocked.

## Upgrading to real Beads (Steve Yegge's tool)

When markdown gets in the way, switch to the real thing. Three install paths (pick one):

```bash
# Homebrew (recommended):
brew install beads

# npm:
npm install -g @beads/bd

# Universal install script:
curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash
```

Then:
1. `bd init` in your project root (or `bd init --stealth` to hide in .beads/).
2. Migrate existing bd-lite beads by hand or run a one-shot script.
3. The workflow loop is identical — `bd ready` / `bd update <id> --claim` / `bd close <id> --reason "..."` — so agent behavior doesn't change.

Full docs: [github.com/steveyegge/beads](https://github.com/steveyegge/beads).

## Session handoff

End of session: update `HANDOFF.md` with what's in flight, what's next, what's blocked. Next session reads it first.

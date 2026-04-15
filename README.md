# youragent

> **Your first agent, done right.** One line. Any repo. Works with whatever agentic tool you already have — Claude Code, Codex, Cursor, OpenClaw, Aider, Windsurf.
>
> This isn't "set up a folder." This ships the **[Trilogy AI Center of Excellence](https://trilogyai.substack.com/) methodology** on top of a bead-graph task system inspired by **[Steve Yegge's Beads](https://github.com/steveyegge/beads)** — spiky takes, evidence-on-close, and a 130-pattern knowledge base your agent inherits on install.

[![npm](https://img.shields.io/npm/v/youragent.svg)](https://www.npmjs.com/package/youragent)
[![downloads](https://img.shields.io/npm/dm/youragent.svg)](https://npm-stat.com/charts.html?package=youragent)
[![license](https://img.shields.io/npm/l/youragent.svg)](./LICENSE)

---

## Install

```bash
# Recommended:
npx youragent

# Fallback (no Node required):
curl -fsSL https://raw.githubusercontent.com/stanhus/youragent/main/install.sh | bash
```

Run it in any repo. Sixty seconds. That's it.

## What gets auto-wired (so your tool actually reads the scaffold)

The install drops hook files at repo root that each tool auto-loads on session start:

| File | Tool that reads it automatically |
|---|---|
| `CLAUDE.md` | Claude Code |
| `AGENTS.md` | Codex |
| `.cursorrules` | Cursor |
| `.windsurfrules` | Windsurf |

Each is a short redirect pointing the agent at `.agent/NORTH_STAR.md`. If you already have one of these files, it's left alone and the install prints a note so you can add the redirect yourself.

For Aider, OpenClaw, or anything else: paste `"Read .agent/NORTH_STAR.md to orient"` at session start.

---

## What happens

A `.agent/` folder lands in your repo with everything your agent needs to stop being a chatbot and start being a collaborator:

- **Personality** that doesn't hedge. No "great question!" No corporate voice. Commits to takes.
- **Memory** that survives across sessions. Facts, personality, active task, lessons learned — each in its own file.
- **Task ledger** (beads) with **evidence required to close**. `close "done"` is rejected. You get specifics or you don't close.
- **130 patterns** from 14 COE articles pre-catalogued. Your agent reads them, cites them, applies them.
- **Tool-agnostic.** Same files work in Claude Code, Codex, Cursor, OpenClaw, Aider, Windsurf.

Full file tree lives in `.agent/HUMAN_GUIDE.md` after install. Read it (2 min).

---

## After install

1. Open your tool in the repo.
2. Tell it: *"Read `.agent/NORTH_STAR.md` to orient, then ask what I need."*
3. Go.

---

## Autonomous mode

Once you trust the bead graph (usually after 2–3 tasks):

| Tool | Command |
|---|---|
| Claude Code | `claude --dangerously-skip-permissions` |
| Codex | `codex --yolo` |
| Aider | `aider --yes` |
| Cursor / Windsurf | agent mode, auto-approve in settings |

Safe with: git + acceptance criteria in beads. See `.agent/HUMAN_GUIDE.md`.

---

## Credits (the short version)

- **Methodology + articles** — [Trilogy AI Center of Excellence](https://trilogyai.substack.com/)
- **Beads (the real tool)** — [Steve Yegge](https://github.com/steveyegge/beads). This bootstrap's `bd-lite.sh` is a markdown fallback that mimics his semantics.
- **WWVCD + packaging** — [Stan Huseletov](https://huseletov.substack.com/)

Full split with every source URL and verified claims in **[CREDITS.md](./CREDITS.md)**.

---

## License

MIT — see [LICENSE](./LICENSE). Contributions: [CONTRIBUTING.md](./CONTRIBUTING.md).

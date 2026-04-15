# youragent

> **Your first agent, done right.** One line. Any repo. Works with whatever agentic tool you already have — Claude Code, Codex, Cursor, OpenClaw, Aider, Windsurf.
>
> This isn't "set up a folder." This is the **Trilogy AI Center of Excellence methodology**, shipped as a bootstrap — spiky takes, a real task system with evidence-on-close, and a 130-pattern knowledge base your agent inherits on install. You pick the tool, we do the thinking.

[![npm](https://img.shields.io/npm/v/youragent.svg)](https://www.npmjs.com/package/youragent)
[![downloads](https://img.shields.io/npm/dm/youragent.svg)](https://npm-stat.com/charts.html?package=youragent)
[![license](https://img.shields.io/npm/l/youragent.svg)](./LICENSE)

---

## Install

```bash
# The one-liner (needs only curl + bash):
curl -fsSL https://raw.githubusercontent.com/stanhus/youragent/main/install.sh | bash

# Or via npx:
npx youragent
```

Run it in any repo. Sixty seconds. That's it.

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

## Built by

**[Trilogy AI Center of Excellence](https://trilogyai.substack.com/)** — methodology, articles, patterns.
Packaging by [Stan Huseletov](https://huseletov.substack.com/).

Every pattern has a source. See **[CREDITS.md](./CREDITS.md)**.

---

## License

MIT — see [LICENSE](./LICENSE). Contributions: [CONTRIBUTING.md](./CONTRIBUTING.md).

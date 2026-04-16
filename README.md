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

### OpenClaw Integration

If you use **[OpenClaw](https://github.com/openclaw/openclaw)** with persistent agents, the installer detects it and offers to configure all your agents automatically.

When you run `npx youragent`, if `~/.openclaw/openclaw.json` exists, you'll see:

```
OpenClaw detected!

Configure your OpenClaw agents to auto-read .agent/ folders?
```

Say **yes** and the installer:
- Scans all agents from your OpenClaw config
- Adds YourAgent integration to each agent's `AGENTS.md`
- Configures them to automatically detect and read `.agent/` folders in any repo

**Result**: Your OpenClaw agents (Junior, Scribe, etc.) will automatically combine their global identity with project-specific context from `.agent/` whenever they enter a repo.

For Aider or other tools: paste `"Read .agent/NORTH_STAR.md to orient"` at session start.

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
2. Tell it: *"Read `.agent/NORTH_STAR.md` to orient, then ask what I need."* (Claude Code, Codex, Cursor, and Windsurf auto-pick it up via the hook files — you can skip this step.)
3. Go.

---

## Check on your agent

Run this in a repo that has `.agent/`:

```bash
npx youragent status
```

You get a single-screen view: agent name + purpose, bead counts (open / blocked / done), memory facts, lessons learned, scaffold version, and one actionable next step. Read-only — nothing changes.

## Updates are safe

Run `npx youragent` again anytime. The scaffold files (`SOUL.md`, `AGENT.md`, the pattern catalog, etc.) get refreshed to the latest version. Your personal files (`IDENTITY.md`, `USER.md`, `MEMORY.md`, `BEADS.md`, `LESSONS_LEARNED.md`) are never touched.

Output looks like this:

```
Refreshed: 14 tool-authored files
Kept safe: 8 personal files (your agent's name, memory, beads, lessons)
```

If `.agent/` already exists but wasn't installed by us (another tool, or hand-rolled), we refuse to touch it and tell you exactly what to do. Your setup is always safe.

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

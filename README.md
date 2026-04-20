# agentize

> **Your first agent, done right.** One line. Any repo. Works with whatever agentic tool you already have — Claude Code, Codex, Cursor, OpenClaw, Aider, Windsurf.
>
> This isn't "set up a folder." This ships the **[Trilogy AI Center of Excellence](https://trilogyai.substack.com/) methodology** on top of a bead-graph task system inspired by **[Steve Yegge's Beads](https://github.com/steveyegge/beads)** — spiky takes, evidence-on-close, and a 130-pattern knowledge base your agent inherits on install.

[![npm](https://img.shields.io/npm/v/agentize.svg)](https://www.npmjs.com/package/agentize)
[![downloads](https://img.shields.io/npm/dm/agentize.svg)](https://npm-stat.com/charts.html?package=agentize)
[![license](https://img.shields.io/npm/l/agentize.svg)](./LICENSE)

## Demo

<!-- After recording with scripts/record-demo.sh and uploading via `asciinema upload`,
     replace the two URLs below with the cast URL you got back. -->
[![asciicast](https://asciinema.org/a/DEMO_ID_PLACEHOLDER.svg)](https://asciinema.org/a/DEMO_ID_PLACEHOLDER)

*60 seconds: warm greeting, live install dashboard, the scaffold lands, your agent is ready.*

---

## For the curious (non-technical)

You run one command. A folder called `.agent/` appears in your project. The next time you open Claude / Cursor / Codex / Windsurf in that project, it's already oriented — it knows the project, knows how to behave, remembers what happened last time, and can't cheat its way through tasks.

That's it. That's the whole pitch.

```bash
npx agentize
```

Don't like it? One command to remove it:

```bash
npx agentize uninstall
```

No background processes. No network calls after install. Nothing leaves your machine.

---

## For developers

### Install

```bash
# Standard (recommended):
npx agentize

# No Node? curl fallback:
curl -fsSL https://raw.githubusercontent.com/stanhus/youragent/main/install.sh | bash

# Legacy alias (same package, forwards to agentize):
npx youragent
```

### Subcommands

| Command | What it does |
|---|---|
| `npx agentize` | Install / update the scaffold. Idempotent. Safe to re-run. |
| `npx agentize plan` | Dry-run. Prints what would be written/kept. Writes nothing. |
| `npx agentize status` | Single-screen dashboard of the installed agent (name, beads, memory, lessons). Read-only. |
| `npx agentize validate` | Scaffold health check. Exits non-zero on breakage. |
| `npx agentize update-check` | Compares installed scaffold version to npm latest. |
| `npx agentize uninstall` | Preview → confirm → removes `.agent/`, hook files, compat symlink. |
| `npx agentize configure-openclaw` | Wires OpenClaw persistent agents to auto-read `.agent/` on repo entry. |

### What lands in your repo

```
<repo>/
├── .agent/                        # the scaffold — agent's operating context
│   ├── NORTH_STAR.md              # session orientation (first thing the agent reads)
│   ├── SOUL.md                    # personality: opinionated, brief, no hedging
│   ├── AGENT.md                   # operating manual (plan-first, evidence-on-close)
│   ├── IDENTITY.md                # your agent's name + purpose (yours)
│   ├── USER.md                    # about you (yours)
│   ├── MEMORY.md                  # long-term facts (yours)
│   ├── LESSONS_LEARNED.md         # mistake log (yours)
│   ├── HUMAN_GUIDE.md             # read me first (for you)
│   ├── TWEAKING.md                # how to adjust personality
│   ├── TOOLS.md                   # recommended tools
│   ├── KNOWLEDGE_PACK.md          # index into the 14 CoE articles
│   ├── PATTERNS_CATALOG.md        # 130 patterns your agent inherits
│   ├── GOGCLI_STARTER.md          # Gmail / Docs / Calendar on-ramp
│   ├── GETTING_STARTED.md         # 10-min onboarding
│   ├── memory/
│   │   ├── BEADS.md               # task ledger (yours)
│   │   ├── bd-lite.sh             # bead CLI (python3)
│   │   ├── HANDOFF.md             # session handoff notes (yours)
│   │   ├── PROMPTS.md             # instruction log (yours)
│   │   ├── SHORT_TERM_MEMORY.md   # scratch pad (yours)
│   │   └── README.md              # bead rules
│   └── skills/
│       ├── search-substack.sh     # source retrieval w/ attribution
│       └── README.md
├── .agents/                       # cross-harness compat (Codex, Copilot, Gemini CLI, …)
│   └── skills → ../.agent/skills  # symlink to the real skills dir
├── CLAUDE.md                      # → Claude Code auto-reads this
├── AGENTS.md                      # → Codex auto-reads this
├── .cursorrules                   # → Cursor auto-reads this
└── .windsurfrules                 # → Windsurf auto-reads this
```

**Tool-authored files** (`SOUL.md`, `AGENT.md`, `NORTH_STAR.md`, etc.) are refreshed on every `npx agentize`. **Personal files** (`IDENTITY.md`, `USER.md`, `MEMORY.md`, `LESSONS_LEARNED.md`, everything in `memory/*.md` except `README.md`) are created once and never overwritten.

### Why it works: structure over prompting

Most "make AI reliable" advice is about prompt engineering. That's a dead end for non-trivial tasks. Agents fail not because your prompt isn't good enough, but because the prompt is the only thing they have:

- **No persistent identity** → they hedge, wander, adopt whatever tone the chat history pushes them into.
- **No memory** → every session is session zero.
- **No task structure** → "done" is a declarative statement, not a verifiable one.

agentize gives the agent a **control system** instead of a better prompt:

1. `SOUL.md` — identity anchor. Opinionated. Tells the agent to commit to takes, not hedge.
2. `memory/` — facts that survive across sessions. The agent reads MEMORY.md on boot, updates LESSONS_LEARNED.md when it screws up, writes HANDOFF.md at session end.
3. `memory/BEADS.md` — task ledger with **acceptance criteria**. A bead can't close without cited evidence (files changed, tests passing, command output). The model's "just say done" reflex gets blocked by schema.
4. `PATTERNS_CATALOG.md` — 130 patterns extracted from 14 CoE articles on how agentic work actually holds up in production. The agent reads them, applies them, cites them.

The hook files (`CLAUDE.md`, `AGENTS.md`, etc.) are short redirects that each tool auto-loads on session start and point the agent at `.agent/NORTH_STAR.md`. That's how a single scaffold works across every tool.

### Environment variables

| Variable | Effect |
|---|---|
| `BOOTSTRAP_TARGET=<path>` | Install the scaffold at a non-default path (default: `$PWD/.agent`). |
| `BOOTSTRAP_LOCAL_SRC=<path>` | Use a local checkout as the source (for development). |
| `BOOTSTRAP_RAW_BASE=<url>` | Override the GitHub raw base for `curl` mode. |
| `BOOTSTRAP_FORCE=1` | Overwrite personal files too (nuke-and-reinstall). |
| `NO_ANIM=1` | Disable animations (useful in CI / non-TTY contexts). |
| `AGENTIZE_YES=1` | Skip the uninstall confirmation prompt. |

### Windows

`npx agentize` works on Windows if you have [Git Bash](https://git-scm.com/downloads) or WSL — the Node entry point (`bin/agentize.js`) finds a usable bash automatically. Pure PowerShell / CMD isn't supported yet.

### Programmatic use / CI

```bash
# Non-interactive install in CI
NO_ANIM=1 BOOTSTRAP_TARGET="$PWD/.agent" bash install.sh

# Validate existing scaffold (exits non-zero on breakage)
NO_ANIM=1 bash install.sh validate

# Uninstall without prompt
AGENTIZE_YES=1 NO_ANIM=1 bash install.sh uninstall
```

### Hook files auto-wired at repo root

| File | Tool that reads it automatically |
|---|---|
| `CLAUDE.md` | Claude Code |
| `AGENTS.md` | Codex |
| `.cursorrules` | Cursor |
| `.windsurfrules` | Windsurf |
| `.agents/skills/` | Codex, OpenCode, OpenHands, Copilot, Gemini CLI, Amp, Cursor (compat), Kilo (compat), pi (emerging cross-harness skills convention — we symlink this to `.agent/skills/`) |

Each hook is a short redirect. If a file at that path already exists and doesn't reference `.agent/`, we leave it alone and print a heads-up so you can add the redirect yourself.

### OpenClaw integration

If you run persistent OpenClaw agents (Junior, Scribe, Atlas, etc.) and want them to auto-ingest each repo's `.agent/` context on entry:

```bash
npx agentize configure-openclaw
```

Scans `~/.openclaw/openclaw.json`, backs up each agent's `AGENTS.md`, adds the integration snippet. Idempotent — re-run anytime.

### Updates are safe

`npx agentize` on an existing install refreshes tool-authored files to the latest version. Your personal files (identity, memory, beads, lessons) are never touched. The CLI prints a version-delta banner so you can see what's changing:

```
↑ mode · update · scaffold v1.3.8 → v1.4.1, personal files untouched
```

If `.agent/` exists but wasn't installed by us (another tool, hand-rolled), we refuse to touch it and tell you exactly what to do.

### Autonomous mode

Once you trust the bead graph (usually after 2–3 tasks closed with evidence):

| Tool | Command |
|---|---|
| Claude Code | `claude --dangerously-skip-permissions` |
| Codex | `codex --yolo` |
| Aider | `aider --yes` |
| Cursor / Windsurf | agent mode, auto-approve in settings |

Safe with: git + acceptance criteria in beads. Read `.agent/HUMAN_GUIDE.md` for the full picture before flipping the switch.

---

## Extending

### Add your own skills

Drop executable scripts in `.agent/skills/` (and/or `.agents/skills/` for cross-harness discovery). The agent is told about the skills directory in `NORTH_STAR.md` and will call them when relevant.

```bash
# Example: add a skill that greps the repo for TODO markers
cat > .agent/skills/find-todos.sh <<'EOF'
#!/usr/bin/env bash
grep -rn --include='*.{md,js,ts,py,go,rs}' 'TODO' .
EOF
chmod +x .agent/skills/find-todos.sh
```

### Add repo-specific patterns

`PATTERNS_CATALOG.md` is refreshed on every `npx agentize` — don't edit it directly. Instead, add repo-specific patterns to `MEMORY.md` (which agentize never overwrites). The agent reads both.

### Custom hook content

If you need `CLAUDE.md` / `AGENTS.md` / `.cursorrules` / `.windsurfrules` to say something more than "read `.agent/NORTH_STAR.md`", edit them after install. As long as the file contains the tokens `agentize`, `youragent`, `NORTH_STAR.md`, or `.agent/`, agentize will recognize it as linked and leave it alone on future runs.

### Contribute upstream

See [CONTRIBUTING.md](./CONTRIBUTING.md).

---

## Roadmap

The next step for `agentize` is not "more markdown". It's turning the scaffold into an actual repo-native operating layer: doctor/repair commands, workflow generators, profiles, composed context, CI enforcement.

See [ROADMAP.md](./ROADMAP.md).

---

## Credits

- **Methodology + articles** — [Trilogy AI Center of Excellence](https://trilogyai.substack.com/)
- **Beads (the real tool)** — [Steve Yegge](https://github.com/steveyegge/beads). This bootstrap's `bd-lite.sh` is a markdown fallback that mimics his semantics.
- **WWVCD + packaging** — [Stan Huseletov](https://huseletov.substack.com/)
- **OpenClaw auto-configuration** — [David Proctor](https://github.com/dp-pcs)

Full attribution with source URLs in [CREDITS.md](./CREDITS.md).

---

## License

MIT — see [LICENSE](./LICENSE).

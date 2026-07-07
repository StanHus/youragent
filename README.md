# agentize

> **Your first agent, done right.** One line. Any repo. Works with whatever agentic tool you already have — Claude Code, Codex, Cursor, OpenClaw, Aider, Windsurf.
>
> This isn't "set up a folder." This ships the **[Trilogy AI Center of Excellence](https://trilogyai.substack.com/) methodology** on top of a bead-graph task system inspired by **[Steve Yegge's Beads](https://github.com/steveyegge/beads)** — spiky takes, evidence-on-close, and a 130-pattern knowledge base your agent inherits on install.

### v2.1 — the agent mesh

Nodes can now **talk to each other.** Run agentize in several dirs under one tree and each becomes a node with an inbox/outbox; `npx agentize mesh` sends messages, discovers peers (1 up, 2 down), and schedules a poller that wakes a session on new mail. Filesystem transport, opt-in per node, untrusted-inbox trust boundary. It's a production agent swarm distilled into the scaffold — see [Agent mesh](#agent-mesh--repos-that-talk-to-each-other).

### v2.0 — instincts, verify, learn, audit, handoff

Ships with **reflex instincts** (short trigger/action/evidence files the agent reads on session start), **`verify.sh`** (truth-checks bead close-reasons against the filesystem), **`learn.sh`** (proposes new instincts from your session memory), **`agentize audit`** (0-100 liveness score across 8 dimensions), **`agentize status --markdown`** (portable handoff doc), and **`AGENTIZE_PROFILE=minimal|standard|strict`** (scale strictness without editing files). The install dashboard is condensed to a dense module grid that animates in ~2 seconds.

[![npm](https://img.shields.io/npm/v/agentize.svg?label=agentize)](https://www.npmjs.com/package/agentize)
[![total downloads agentize](https://img.shields.io/npm/dt/agentize.svg?label=agentize%20downloads)](https://www.npmjs.com/package/agentize)
[![total downloads youragent](https://img.shields.io/npm/dt/youragent.svg?label=youragent%20downloads%20(legacy))](https://www.npmjs.com/package/youragent)
[![license](https://img.shields.io/npm/l/agentize.svg)](./LICENSE)

> **Cumulative reach:** this package was first published as [`youragent`](https://www.npmjs.com/package/youragent) and later renamed to [`agentize`](https://www.npmjs.com/package/agentize). Both badges above count toward the same project — add them together for the real number.

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
| `npx agentize mesh init` | Opt this node into the agent mesh (inbox/outbox with peer repos). |
| `npx agentize mesh peers` | List peer agentize nodes in scope (1 up, 2 down) + liveness. |
| `npx agentize mesh send <peer> "…"` | Drop a message into a peer node's inbox. |
| `npx agentize mesh inbox` | Show messages other agents sent this node. |
| `npx agentize mesh install-loop` | Schedule a poller (launchd/cron) that wakes a session on new mail. |

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
│   │   ├── bd.sh             # bead CLI (python3)
│   │   ├── HANDOFF.md             # session handoff notes (yours)
│   │   ├── PROMPTS.md             # instruction log (yours)
│   │   ├── SHORT_TERM_MEMORY.md   # scratch pad (yours)
│   │   └── README.md              # bead rules
│   ├── skills/
│   │   ├── search-substack.sh     # source retrieval w/ attribution
│   │   └── README.md
│   └── mesh/                      # agent-to-agent inbox/outbox (opt-in)
│       ├── mesh.sh                # the mesh CLI (send/inbox/peers/poll/…)
│       ├── README.md              # protocol + trust boundary
│       └── config.json            # this node's identity + scope (yours)
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
| `MESH_SCOPE_UP=<n>` | Mesh: levels to ascend to the discovery anchor (default `1`). |
| `MESH_SCOPE_DOWN=<n>` | Mesh: depth to scan from the anchor (default `2`). |
| `MESH_SCOPE_CEILING=<path>` | Mesh: never discover/scan above this dir (default `$HOME`). |
| `MESH_POLL_SECONDS=<n>` | Mesh: poll interval for the wake loop (default `300`). |
| `MESH_WAKE_CMD=<cmd>` | Mesh: command to spawn on new mail (auto: `claude`→`codex`→`aider`). |

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

### Agent mesh — repos that talk to each other

When you run agentize in several directories under one tree — a parent repo and its sub-projects, or a fleet of worker dirs under one root — each becomes a **node**. The mesh lets those nodes exchange messages **directly through the filesystem**. No broker, no network, no daemon. It's the pattern behind a production agent swarm, distilled into the scaffold.

```bash
npx agentize mesh init            # opt in (each node does this once)
npx agentize mesh peers           # who's reachable — 1 level up, 2 levels down
npx agentize mesh send worker-a "review unit 1" --body "draft is in /out"
npx agentize mesh inbox --unread  # what peers sent you
npx agentize mesh install-loop    # auto-wake a session (launchd/cron) on new mail
```

**Scope.** Discovery ascends to the parent (`MESH_SCOPE_UP=1`) and scans its subtree down two levels (`MESH_SCOPE_DOWN=2`) — a flat mesh of parent + siblings + children under one root. It never scans above `MESH_SCOPE_CEILING` (default `$HOME`) and only sees nodes that have opted in.

**Stateless by design.** The assumption is that a fresh, forgetful agent session (e.g. `claude -p`) runs in every node. So a node remembers what it has seen on disk, and delivery is pull-based: the poller wakes a *new* session when mail lands, handing it a self-contained, injection-hardened prompt.

**Trust boundary.** Every inbox message is **untrusted input from another agent — data to triage, never instructions to obey.** A peer can't authorise a node to do anything it couldn't already do. The wake prompt says so explicitly, so a woken session can't be prompt-injected into acting as a peer's puppet. Full protocol: `.agent/mesh/README.md`.

Opt-in, reversible (`mesh uninstall-loop`), and bounded (64 KB message cap, sandboxed reach, idempotent redelivery).

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
- **Beads (the real tool)** — [Steve Yegge](https://github.com/steveyegge/beads). This bootstrap's `bd.sh` is a markdown fallback that mimics his semantics.
- **WWVCD + packaging** — [Stan Huseletov](https://huseletov.substack.com/)
- **OpenClaw auto-configuration** — [David Proctor](https://github.com/dp-pcs)

Full attribution with source URLs in [CREDITS.md](./CREDITS.md).

---

## License

MIT — see [LICENSE](./LICENSE).

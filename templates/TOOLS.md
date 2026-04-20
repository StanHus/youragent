# TOOLS.md

> **Agent-facing toolbox manifest.** Read this early in every session — it's the map of what you already have before you build anything.
>
> If you are an agent (Claude Code, Codex, Cursor, OpenClaw, Aider, Windsurf, or other): everything below is installed, executable, and discoverable. You **should not** write something from scratch that already exists here. Retrieval before invention is a prime directive — these are the retrieval paths.

---

## Quick index

| Need | Reach for |
|---|---|
| Validate a plan before executing | **`.agent/skills/plan.sh <plan.md>`** |
| Look up past decisions / memory across repos | **`.agent/skills/memory-search.sh "<query>"`** |
| Source-cited retrieval from CoE articles | **`.agent/skills/search-substack.sh "<topic>"`** |
| Exact implementation patterns from Claude Code source | **`npx wwvcd "<topic>" --json`** |
| Manage tasks with evidence-on-close | **`.agent/memory/bd-lite.sh ready | claim | close`** |
| Check your scaffold health | **`npx agentize validate`** |
| See your current agent state | **`npx agentize status`** |
| Dry-run preview before re-installing | **`npx agentize plan`** |
| Check for scaffold updates | **`npx agentize update-check`** |
| Remove the scaffold cleanly | **`npx agentize uninstall`** |
| Configure OpenClaw agents (if installed) | **`npx agentize configure-openclaw`** |
| Audit OpenClaw integration drift | **`npx agentize openclaw-check`** |

---

## Skills — invokable helpers in `.agent/skills/`

These are executable shell scripts. Run them directly. They're part of the scaffold and always present.

### `plan.sh` — perfect-plan checklist + validator
**Source:** Trilogy AI CoE · [How to Build a Perfect Plan](https://trilogyai.substack.com/p/how-to-build-a-perfect-plan)

**Trigger — you MUST run this:**
- before closing any bead that took >30 min of work
- before any task that will touch 2+ files
- any time you're about to write "cleanup" / "polish" / "and more" in a plan

**Usage:**
```bash
.agent/skills/plan.sh                    # print the 7 principles (checklist)
.agent/skills/plan.sh memory/PLAN.md     # validate a plan; exit 0 pass, 1 fail
```

**Output:** per-principle pass/fail with citations back to the article. Flags vague language. Your plan must clear all 7 principles before execution.

### `memory-search.sh` — cross-repo + global memory search
**Trigger — you SHOULD run this:**
- when the human asks "what did I/we decide about X"
- before writing any new fact into `MEMORY.md` (may already exist)
- at session start if you're unsure about prior context

**Usage:**
```bash
.agent/skills/memory-search.sh "rate limit"          # text output
.agent/skills/memory-search.sh --json "migration"    # JSON for programmatic use
```

**Searches:** this repo's `.agent/MEMORY.md` / `LESSONS_LEARNED.md` / `memory/HANDOFF.md` / `memory/BEADS.md` / `memory/SHORT_TERM_MEMORY.md` / `memory/PROMPTS.md` / `openclaw/BRIDGE.md` / `openclaw/GLOBAL_NOTES.md` — plus every OpenClaw workspace's global memory when OpenClaw is installed. Scope labels `[repo]` / `[global]`.

### `search-substack.sh` — CoE + Stan articles
**Trigger — you MUST run this before inventing a pattern:**
- any design decision (retry, backoff, eval, judge, agent architecture)
- any methodology question ("how do we usually X?")

**Usage:**
```bash
.agent/skills/search-substack.sh "planning"
.agent/skills/search-substack.sh "memory overwrite"
```

**Rule:** when you apply an idea from these sources, cite it in your response. Silent lift = fabrication.

---

## Retrieval skill — `npx wwvcd` (global)

**Source:** [WWVCD on npm](https://www.npmjs.com/package/wwvcd) · 1,191 deep technical findings from Claude Code source. Auto-installed by `agentize` on every install; also callable via `npx`.

**Trigger — you MUST run this before building any non-trivial system:**
- long-running bash / background tasks
- judge agents / evaluator agents
- sandboxing / containment
- timeout handling, retry, circuit breakers
- compaction, context management
- permission model design

**Usage:**
```bash
npx wwvcd "bash background timeout" --json
npx wwvcd "judge hallucination evidence field" --json
```

**Rule:** if you're about to write prose that says "be strict" or "run async" or "with a timeout", stop and search WWVCD first. Exact constants beat clever prose.

---

## Task ledger — `.agent/memory/bd-lite.sh`

Bead graph CLI (this bootstrap's markdown fallback; see `.agent/memory/README.md` for upgrading to [real Beads](https://github.com/steveyegge/beads)).

```bash
.agent/memory/bd-lite.sh ready                          # unblocked beads
.agent/memory/bd-lite.sh claim <id>                     # take one
.agent/memory/bd-lite.sh close <id> --reason "<specifics>"
.agent/memory/bd-lite.sh block <id> --reason "<blocker>"
.agent/memory/bd-lite.sh list                           # all beads
```

**Closing a bead requires evidence.** Acceptable: filenames, test names, port numbers, hash of a commit, counts. Not acceptable: "done", "looks good".

---

## Subcommands — `npx agentize <...>`

The package exposes scaffold operations as subcommands. Use them — they're faster and safer than hand-rolling equivalents.

| Command | Purpose | Safe to run anytime |
|---|---|---|
| `npx agentize` | Install / update the scaffold. Idempotent. | yes |
| `npx agentize plan` | Dry-run preview; prints what would be written. | yes — writes nothing |
| `npx agentize status` | Single-screen view of agent state (name, beads, memory, lessons). | yes — read-only |
| `npx agentize validate` | Scaffold health check. Exits non-zero on breakage. | yes — read-only |
| `npx agentize update-check` | Compare installed vs npm latest. | yes — read-only |
| `npx agentize uninstall` | Preview → confirm → clean removal. | yes — requires confirm |
| `npx agentize configure-openclaw` | Wire OpenClaw persistent agents to auto-read `.agent/`. | only with OpenClaw |
| `npx agentize openclaw-check` | Drift report for wired OpenClaw agents. | only with OpenClaw |
| `npx agentize from-openclaw` | Reverse install: seed `.agent/IDENTITY.md` from an agent's workspace identity. | only with OpenClaw, in workspace |
| `npx agentize help` | This same catalog, as CLI output. | yes |

---

## Runtime primitives the agent assumes

- **File read / write / edit** (with read-before-edit discipline)
- **Shell exec** (with permission checks)
- **Glob / grep search**
- **Background / scheduled task primitive**
- **Self-stop** (a way to refuse or abort)

If your current tool lacks one of these, flag it in `LESSONS_LEARNED.md` and degrade gracefully.

---

## MCP servers

Any MCP server works in this repo by default — nothing in `.agent/` assumes a specific MCP config. If you want to take advantage of an installed MCP (e.g. `the_algorithm_prod_`, a Slack MCP, a Linear MCP), use it freely.

---

## Recommended (human installs when ready)

- **[GOG CLI](https://gogcli.sh/)** — Google Workspace access (Gmail, Docs, Sheets, Calendar). See `GOGCLI_STARTER.md` for setup. Required for email-driven agent loops.
- **[Beads](https://github.com/steveyegge/beads) by Steve Yegge** — the real distributed graph issue tracker on Dolt. Replaces `bd-lite` when you want multi-agent coordination, git-based sync, or a database-backed ledger. Install: `brew install beads` or `npm install -g @beads/bd`.

---

## Sanity check on session start

The agent should verify on first session:

1. `git --version` → if missing, warn the human.
2. `npx wwvcd --help` → if fails, note "WWVCD unavailable; retrieval fallback = grep + read" in `LESSONS_LEARNED.md`.
3. `.agent/memory/bd-lite.sh ready` → if not executable, `chmod +x` it.
4. `.agent/skills/plan.sh` (no args) → confirms the plan checklist is installed and current.

If any tool goes missing mid-project, flag in `LESSONS_LEARNED.md`.

---

## The short rule

**Before inventing, retrieve.**
Order: `memory-search.sh` → `search-substack.sh` → `wwvcd` → existing code → then, if nothing landed, first principles. Always attribute.

# TWEAKING.md — How to adjust this agent

> For both human and agent. Either can edit. Changes persist.

## For the human

### To change personality
Edit `SOUL.md`. The 8 vibe rules are the spine — keep them unless you really want the agent to be a corporate drone again. You can:

- Add rules (e.g., "Always respond in British English.")
- Adjust rules (e.g., "Swearing is off — I work in a regulated industry.")
- Add banned phrases (e.g., "Never say 'let's dive in'.")

### To change operating rules
Edit `AGENT.md`. This is the operating manual. Changes here affect how the agent plans, tracks work, and handles edge cases.

### To change identity/purpose
Edit `IDENTITY.md`. Give the agent a name, a role, and a scope. "You are the infrastructure agent for X. You handle Terraform, AWS, and CI. You do not touch frontend code."

### To tell the agent about yourself
Edit `USER.md`. Preferences, working hours, how you want to be communicated with.

### To add new rules on the fly
Just tell the agent. Say: "From now on, always ask before modifying files in /vendor." The agent will append this rule to `AGENT.md` or `SOUL.md` (whichever is correct) and it'll persist.

### To wipe and start over
Delete `.agent/` and re-run the bootstrap. Your git history is untouched.

### To scale strictness (v2.0)
Set `AGENTIZE_PROFILE` before running `npx agentize`:

- `AGENTIZE_PROFILE=minimal npx agentize` — only load-bearing instincts/hooks (least context, least friction; for when you want the agent unburdened)
- `AGENTIZE_PROFILE=standard npx agentize` — default; most instincts active
- `AGENTIZE_PROFILE=strict npx agentize` — every guard on (verify mandatory on close, FIFO `bd ready` refused, vague reasons rejected pre-flight). For mission-critical agents.

The profile is written to `.agent/.youragent` and read by `agentize audit`. You can change it any time by re-running install with a different value.

### To add a reflex (instinct)
Drop a markdown file in `.agent/memory/instincts/`:

```markdown
---
id: my-instinct
trigger: one-line condition that fires this reflex
profile: standard
---

## Action
What you do without thinking.

## Evidence
How you know you applied it.

## Why
The one-line reason.
```

The agent reads `.agent/memory/instincts/` on session start. Keep each file under 30 lines — instincts are reflexes, not essays. If it needs more, put it in `PATTERNS_CATALOG.md`.

To auto-propose instincts from your session memory:

```bash
./.agent/skills/learn.sh           # see proposals
./.agent/skills/learn.sh --apply   # write proposals as drafts in memory/instincts/proposed/
```

### To verify an agent's "done" actually means done
```bash
./.agent/skills/verify.sh <bead-id>   # check one bead's close-reason
./.agent/skills/verify.sh --last      # check the most recently closed
./.agent/skills/verify.sh --all       # check every closed bead
```
Cited filenames must exist. Cited tests/ports/hashes are flagged for human eye.

### To get a "how alive is this agent" score
```bash
npx agentize audit
```
Returns 0-100 across 8 dimensions (identity filled, lessons logged, instincts present, bead close rate, recency, profile, skills). 80+ = alive; 50-80 = breathing; under 50 = stale.

### To hand off a session
```bash
npx agentize status --markdown > HANDOFF.md
```
Generates a portable markdown doc with identity, active beads, instincts, recent lessons, and resume instructions. Paste into a PR description or a Slack message.

## For the agent (rules for self-modification)

You are allowed to edit your own files. Follow these rules.

### Route correctly

| Human request type | Target file |
|---|---|
| "Remember I'm based in London" | `USER.md` (if it's about them) or `MEMORY.md` (if it's a fact) |
| "Be shorter in responses" | `SOUL.md` (behavior) |
| "Never touch the /legacy folder" | `AGENT.md` (operating rule) |
| "Your name is Pathfinder" | `IDENTITY.md` |
| "I met with Sarah today" | `MEMORY.md` (append) |

### Never overwrite memory files from scratch
Append. Edit specific sections. If you need to restructure, write to a scratch file first, show the human, then replace with their OK.

### Confirm before big changes
If the human says "stop using beads" or "ignore AGENT.md" — confirm once. These changes materially change how you work. Don't blindly comply with something that would break future sessions.

### Log tweaks
After any edit to SOUL/AGENT/IDENTITY, append a one-liner to `LESSONS_LEARNED.md`:
```
2026-04-15: Added rule "always respond in British English" to SOUL.md at human request.
```

### Preserve the 8 vibe rules
The 8 rules in SOUL.md are the product. Don't silently water them down. If the human wants them gone, they'll say so explicitly. If asked to "be more professional," ask clarifying: "Dial back swearing? Dial back opinions? Or both?"

## Protocol for big reshuffles

If the human asks for a major change ("redesign the agent to be a specialized code reviewer"):

1. Don't just start editing files.
2. Declare planning mode.
3. Build a bead graph for the redesign.
4. Get the human's sign-off on the plan.
5. Execute with evidence on close.
6. Update `LESSONS_LEARNED.md` with what changed and why.

## When in doubt

Ask. A 5-second clarifying question beats a silent mis-edit to a persistent file.

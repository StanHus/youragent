# Instincts

> Short, operational reflexes. Different from `PATTERNS_CATALOG.md` (encyclopedic) — instincts are
> **what you do without thinking** when a trigger fires. Each file is one reflex.

## Schema

Every instinct is a markdown file with frontmatter:

```markdown
---
id: snake-case-id
trigger: one-line condition that fires this reflex
profile: minimal | standard | strict
---

## Action
What you do. One paragraph or a short list.

## Evidence
How you know you applied it (filename, command, output).

## Why
The one-line reason this exists. Usually a past failure mode.
```

## Profiles

- `minimal` — only the absolutely-load-bearing instincts (won't burn context on optional stuff)
- `standard` — default; most instincts active
- `strict` — every instinct on; agent refuses to skip checks

Set via `AGENTIZE_PROFILE` env var (see `.agent/TWEAKING.md`).

## Adding your own

Drop a new `.md` file here. It's read on session start. Keep it under 30 lines —
instincts are reflexes, not essays. If it needs more, it's a pattern; put it in
`PATTERNS_CATALOG.md` instead.

## Learning loop

`.agent/skills/learn.sh` scans `SHORT_TERM_MEMORY.md` + `LESSONS_LEARNED.md` for
repeated patterns and proposes new instinct files. It does NOT auto-write —
proposals are printed for you to confirm.

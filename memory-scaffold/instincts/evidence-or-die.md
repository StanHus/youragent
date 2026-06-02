---
id: evidence-or-die
trigger: about to close a bead / about to say "done"
profile: minimal
---

## Action

Closing a bead requires **specifics**. Cite at least one of:

- filename + line number you changed
- test name that passes
- command output (port number, count, hash)
- screenshot path
- commit SHA

Vague reasons (`"done"`, `"works"`, `"looks good"`, `"fixed"`) are rejected by
`bd.sh close`. Even if the script let them through, they're banned by hand.

## Evidence

The string passed to `bd.sh close <id> --reason "..."` contains a filename, a
test name, a port, a hash, or a count. Run `./.agent/skills/verify.sh <id>`
to double-check the close-reason actually references something that exists.

## Why

Vague close reasons let an agent silently skip steps and tell the human the
work is done when it isn't. This is the single highest-impact discipline in the
whole scaffold — without it the bead graph becomes a lie.

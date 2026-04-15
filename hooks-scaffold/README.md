# hooks-scaffold/

Shim files that get copied to repo root on install. Each one is a file that a specific agentic tool auto-reads on session start, redirecting the agent to `.agent/NORTH_STAR.md`.

| File | Tool that auto-loads it |
|---|---|
| `CLAUDE.md` | Claude Code |
| `AGENTS.md` | Codex |
| `.cursorrules` | Cursor |
| `.windsurfrules` | Windsurf |

install.sh guards with skip-if-exists so it never overwrites user content.

If your tool isn't in this list, the scaffold still works — just paste "Read .agent/NORTH_STAR.md to orient, then ask me what I need." at session start.

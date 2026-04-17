# youragent Roadmap

`youragent` should become the package that turns "agent instructions" into a maintainable operating layer for real repos, not just a one-shot markdown drop.

## Current Position

Today the package is strongest at bootstrap:

- it installs a durable `.agent/` scaffold
- it wires common tool entrypoints (`AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `.windsurfrules`)
- it gives the agent memory, beads, and a knowledge pack

That is useful, but it is still mostly "initial structure". The next value is lifecycle: compose, validate, generate, migrate, and govern that structure over time.

## What The Market Is Telling Us

- Anthropic's Claude Code docs treat `CLAUDE.md` as the repo-level place for style rules, review criteria, and project conventions. That validates repo-scoped agent operating context as a real product surface, not a gimmick.
- Windsurf distinguishes between `AGENTS.md`, Rules, Workflows, and Skills. That is the clearest signal that one markdown file is not enough; teams need multiple context surfaces with different activation models.
- OpenAI's practical guide to building agents pushes workflow design, clear instructions, and explicit tools over vague prompting. That supports building generators and validators, not more prose.
- `agents-md` is proof that people already feel the pain of a single monolithic `AGENTS.md` and want composition, reporting, and automation.

## Product Thesis

The best version of `youragent` is:

1. A bootstrapper for agent-native repos.
2. A doctor/migrator that keeps the scaffold healthy.
3. A workflow generator that turns recurring work into concrete operating files.
4. A composition layer that emits tool-specific instruction surfaces from one source of truth.

If it tries to become a hosted agent platform, it will get bloated and lose the only thing that makes it sharp: it lives in the repo and works with the tools people already use.

## Priority Roadmap

### P1. Scaffold Health

Goal: make broken installs obvious and fixable.

Capabilities:

- Expand `youragent validate` into a real doctor command with machine-readable output.
- Add `youragent report --json` for CI and dashboards.
- Add upgrade diagnostics: version drift, stale hooks, missing files, invalid placeholders, oversize files.
- Add guided repair: `youragent fix` for safe, deterministic repairs.

Why first:

- This compounds every other feature.
- It follows the evidence-first discipline already baked into the package.
- It is the shortest path from "bootstrap" to "operating system".

### P2. Workflow Packs

Goal: package recurring agent work as executable scaffolds instead of advice.

Capabilities:

- `youragent workflow plan`
- `youragent workflow bugfix`
- `youragent workflow feature`
- `youragent workflow release`
- `youragent workflow review`

Each should generate the right files for the workflow:

- beads with dependencies and measurable closes
- prompt log entry stubs
- handoff/checklist templates
- validation instructions and failure cascades

Why second:

- The package already has the methodology.
- The missing piece is turning that methodology into repeatable project artifacts.

### P3. Profiles

Goal: make the scaffold feel native to the repo type instead of generic.

Capabilities:

- `youragent init --profile node-library`
- `youragent init --profile web-app`
- `youragent init --profile python-service`
- `youragent init --profile mono-repo`
- `youragent init --profile personal-ops`

Profiles should customize:

- initial `IDENTITY.md` and `TOOLS.md`
- starter beads
- workflow defaults
- tool wiring hints
- validation rules

Why third:

- This is the cleanest way to increase relevance without adding a hosted backend.

### P4. Composed Context

Goal: move from one giant static instruction file to generated, sustainable context.

Capabilities:

- introduce fragment-based source files for agent context
- generate `AGENTS.md`, `CLAUDE.md`, and Windsurf-facing rule surfaces from one canonical source
- add source annotations and deterministic ordering
- warn on token/size budgets before context files become sludge

Why this matters:

- Large repos do not sustain a single hand-edited instruction file.
- This is where `youragent` can move beyond "starter template" and become the repo-native control plane for agent context.

### P5. CI + Team Consistency

Goal: make agent discipline reviewable in teams.

Capabilities:

- CI checks for scaffold drift
- pre-commit hook setup for generated instruction surfaces
- PR annotations for invalid beads, broken handoffs, missing identity, or stale generated files
- optional policy modes: `solo`, `team`, `strict`

Why later:

- It is valuable, but only after the local authoring model is good.

## What Not To Build Yet

- A hosted memory backend.
- A custom multi-agent runner.
- A marketplace before the core workflow/doctor story is strong.
- Fancy telemetry dashboards without a strong validator underneath.

Those are seductive and mostly bullshit at this stage. The repo-local package still has more room to grow.

## Suggested Release Sequence

### Phase 2

- `validate --json`
- `report`
- `fix`
- README examples for doctor output

### Phase 3

- `workflow plan`
- `workflow bugfix`
- `workflow release`
- starter workflow templates in-package

### Phase 4

- profiles
- composition config
- generated multi-surface context files

### Phase 5

- CI action or reusable workflow
- pre-commit support
- team policy modes

## Success Metrics

- Fewer broken installs discovered manually.
- Faster time from install to first useful task completion.
- More repeatable non-trivial workflows without bespoke prompting.
- Smaller, cleaner repo instruction surfaces over time.
- Teams can review agent operating context like code.

## References

- Anthropic, Claude Code docs: `CLAUDE.md` for project conventions and review rules
  https://docs.anthropic.com/pt/docs/claude-code/github-actions
- Windsurf docs: distinction between Rules, `AGENTS.md`, Workflows, and Skills
  https://docs.windsurf.com/pt-BR/windsurf/cascade/memories
- OpenAI, practical guide to building agents
  https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf
- `agents-md`: composable `AGENTS.md` generation and reporting
  https://github.com/ivawzh/agents-md

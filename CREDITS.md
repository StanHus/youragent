# Credits

## Primary authorship

The methodology this bootstrap ships — the planning discipline, the bead-graph task system, the memory architecture, the anti-shortcut rules, the retrieval-before-invention principle — is the work of the **[Trilogy AI Center of Excellence](https://trilogyai.substack.com/)**. Every pattern in `templates/PATTERNS_CATALOG.md` has an exact source URL in the COE publication or adjacent author sites. This package is the delivery mechanism. The ideas are theirs.

Packaging, install flow, and the `bd-lite` markdown-bead fallback by [Stan Huseletov](https://huseletov.substack.com/).

If you use or fork this, keep these attributions visible. When the agent applies one of these ideas in a response, it cites the source — that's encoded as a rule in `templates/AGENT.md` and `skills-scaffold/README.md`.

---

## Source articles

Every file in `templates/` draws from one or more of these. The author of each article is credited below. Read the originals — they are already well-distilled and worth your time.

### Trilogy AI Center of Excellence — [trilogyai.substack.com](https://trilogyai.substack.com/)

1. **[How to Build a Perfect Plan](https://trilogyai.substack.com/p/how-to-build-a-perfect-plan)**
   The 9-step planning methodology, bead graphs with priority/blocked-by/acceptance/failure-pointer, decision gates with Pass/Adjust/Abort, named failure scenarios, tier-ranked insights. Core of `AGENT.md` § "Planning mode checklist".

2. **[How to Fix Your AI Agents Keep Cutting](https://trilogyai.substack.com/p/how-to-fix-your-ai-agents-keep-cutting)** *(also referenced as "Skipping Steps")*
   The anti-shortcut thesis: LLMs predict completions, not execute checklists. Beads with atomic claim → execute → close-with-evidence. Core of `memory/BEADS.md` and `memory/bd-lite.sh`'s reject-vague-reasons behavior.

3. **[How to Use Claude Code like a Claude Code Engineer](https://trilogyai.substack.com/p/how-to-use-claude-code-like-a-claude)**
   Every Claude Code constraint as a response to a production failure. 13k compaction buffer, denial circuit breakers, read-before-edit, CLAUDE.md tier order. Appendix of `AGENT.md`.

4. **[What Would Vin Claudel Do](https://trilogyai.substack.com/p/what-would-vin-claudel-do)**
   Mine proven implementations for exact constants; don't invent with prose. WWVCD (1,166 patterns from Claude Code TS source) as default retrieval skill. Baked into `AGENT.md` prime directive #6 and `TOOLS.md`.

5. **[Postmortem: When Your AI Tools OpenClaw](https://trilogyai.substack.com/p/postmortem-when-your-ai-tools-openclaw)**
   Redundancy = resilience. Search exact error strings first. Meta-debugging as valid resilience pattern. `AGENT.md` § "Debugging AI tools".

6. **[How to Manage Your OpenClaw Memory](https://trilogyai.substack.com/p/how-to-manage-your-openclaw-memory)**
   The 8 auto-loaded boot files convention (SOUL/AGENTS/USER/TOOLS/IDENTITY/HEARTBEAT/BOOTSTRAP/MEMORY). Multi-layer memory protection stack. No placeholder text. No symlinks escaping workspace. The naming scheme in `.agent/` comes from here.

7. **[Deep Dive: OpenClaw](https://trilogyai.substack.com/p/deep-dive-openclaw)**
   Situated identity, skills-over-tools, 7-layer policy, recursive agent spawning, mandatory graceful degradation. Informs the OpenClaw appendix in `AGENT.md`.

8. **[Managing OpenClaw with Claude Code](https://trilogyai.substack.com/p/managing-openclaw-with-claude-code)**
   "Non-deterministic systems need deterministic config management." The 9 OpenClaw Skills pattern. Informs the self-modification and tweaking protocols.

9. **[How-To: Claude Cowork](https://trilogyai.substack.com/p/how-to-claude-cowork)**
   Directive files (CLAUDE.md pattern), concurrent sessions with handover.md, pre-task folder duplication. Influences `memory/HANDOFF.md` and session-handoff protocol.

10. **[Power OpenClaw for Pennies with Kimi K2 & Codex](https://trilogyai.substack.com/p/power-openclaw-for-pennies-with-kimi)**
    Provider-switching for cost optimization. Listed in `KNOWLEDGE_PACK.md` priority 4.

11. **[How-To: Agent Factory](https://trilogyai.substack.com/p/how-to-agent-factory)**
    Focus on the seams. Separate agent from execution environment. Durable workflows. `AGENTS.md + lessons-learned.md` from day one — the reason `LESSONS_LEARNED.md` exists in this bootstrap.

12. **[Technical Deep Dive: Hermes vs. OpenClaw](https://trilogyai.substack.com/p/technical-deep-dive-hermes-vs-openclaw)**
    Two bets on personal AI: routing+control vs memory+self-improvement. Informs the tool-agnostic framing — both philosophies are valid, the patterns transcend the tool.

13. **[Give Your Brains Hands](https://trilogyai.substack.com/p/give-your-brains-hands)**
    The onboarding article. Chat-AI is advice; agentic AI is execution. The loop is the product. Six operational principles for effective implementation. Core of `GETTING_STARTED.md`.

### Stan Huseletov — [huseletov.substack.com](https://huseletov.substack.com/) · [huseletov.com](https://www.huseletov.com/)

14. **[How to OpenClaw](https://www.huseletov.com/posts/how-to-openclaw)**
    Priority-ordered learning path. Treat OpenClaw as an operating environment, not a tool suite. Informs the `KNOWLEDGE_PACK.md` priority-tier structure.

---

## Tools referenced

- **[WWVCD](https://github.com/StanHus/WWVCD)** — 1,166 architectural patterns from Claude Code's TypeScript source. Installed and used as the default retrieval skill in `AGENT.md`. Maintainer: [@StanHus](https://github.com/StanHus). NPM: [wwvcd](https://www.npmjs.com/package/wwvcd).

- **Beads** — distributed graph issue tracker on Dolt (version-controlled SQL). Originated in the Trilogy AI ecosystem. `bd-lite.sh` in this bootstrap is a markdown-file fallback that preserves the semantics (atomic claim → close-with-evidence, dependency ordering) without requiring the full install. Upgrade path documented in `memory/README.md`.

- **[GOG CLI](https://gogcli.sh/)** — Google Workspace CLI. Referenced as the on-ramp to personal-agent territory in `GOGCLI_STARTER.md`.

---

## Framework context

The bootstrap deliberately sits on top of — but does not require — the OpenClaw filename convention (SOUL.md / AGENTS.md / USER.md / TOOLS.md / IDENTITY.md / MEMORY.md). This is so that:

- Any agentic tool can read the files (they're just markdown).
- If you later adopt OpenClaw proper, the files are auto-injected without renaming most of them (only `AGENT.md` → `AGENTS.md`).

Credit for that naming convention: **[How to Manage Your OpenClaw Memory](https://trilogyai.substack.com/p/how-to-manage-your-openclaw-memory)**.

---

## Attribution rule for users of this bootstrap

When the agent in your repo applies an idea from one of these sources, it should cite the source in its response. Example:

> *"Per 'How to Build a Perfect Plan' (Trilogy AI COE), I'm declaring planning mode before touching code — here's the bead graph..."*

This is not decorative. It's how the human you're working with learns where the good patterns come from and can go deeper when they want to.

---

*If you authored one of these articles and want the attribution phrased differently, open an issue on this repo.*

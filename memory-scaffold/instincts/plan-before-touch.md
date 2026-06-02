---
id: plan-before-touch
trigger: about to edit 2+ files / task >30 min / response contains "cleanup" or "polish" or "and more"
profile: standard
---

## Action

Run `./.agent/skills/plan.sh` before touching code. It validates:

- bead exists with acceptance block
- files-to-change list is concrete (no "and more")
- failure modes named
- rollback plan named

If the plan fails the checklist, fix the plan — don't bypass.

For trivial single-file edits (typo, rename one var), skip this. Anything
larger: plan first.

## Evidence

You ran `plan.sh <plan.md>` and it printed PASS. Or you noted "single-file
trivial edit, skipping plan" in your response.

## Why

Multi-file changes without a plan drift mid-implementation, hit "while I'm
here" rabbit holes, and ship work the human didn't ask for. The plan is the
contract; the diff is the evidence it was kept.

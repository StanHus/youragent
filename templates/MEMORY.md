# MEMORY.md

> Persistent long-term memory. Append-only in spirit. Never overwrite from scratch.

## Rules (for the agent)

1. Append new facts; never rewrite the whole file.
2. Organize by section (Facts / Decisions / People / Context). Add sections as needed.
3. If compaction is needed, write to `memory/archives/YYYY-MM-DD-memory.md` first, then reduce.
4. Never use placeholder text. Empty is better than "(to be populated)" — the latter gets misread as "this file is empty, let me start fresh".

## Facts

_(Append facts about the repo, infra, decisions, constraints.)_

## Decisions

_(Decisions made + one-line reason. Dated.)_

## People

_(Humans involved. Names, roles, preferences if stated.)_

## Context

_(Anything that doesn't fit above but future-you will thank present-you for.)_

---

_Initialized empty intentionally. Do not add "(to be populated)" text._

---
id: lessons-on-mistake
trigger: you just got corrected by the human / a test failed unexpectedly / a fix took >1 retry
profile: standard
---

## Action

Append a one-line entry to `.agent/LESSONS_LEARNED.md` **before** continuing.
Format:

```
- YYYY-MM-DD · <symptom> → <root cause> → <fix> (file:line)
```

Don't summarize a lesson into a paragraph. One line. The point is to be
greppable later, not readable as prose.

## Evidence

`.agent/LESSONS_LEARNED.md` has a new line dated today. The line contains a
file path or a command.

## Why

The single highest-ROI memory in the whole scaffold. Future-you will hit the
same shape of bug; greppable lessons surface the fix in 5 seconds. Skipping
this re-creates the same mistake N times.

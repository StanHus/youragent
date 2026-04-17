# Contributing to youragent

## Publishing

```bash
# Test locally first
npm test

# Bump version
npm version patch   # or minor / major

# Publish to npm
npm publish

# Push to GitHub (install.sh is fetched from raw.githubusercontent.com/main)
git push && git push --tags
```

## Repo layout

```
youragent/
├── install.sh              one-liner entry
├── package.json            npm metadata
├── README.md               user-facing
├── CREDITS.md              every source cited
├── LICENSE                 MIT
├── CONTRIBUTING.md         you are here
├── templates/              → .agent/*.md
├── memory-scaffold/        → .agent/memory/
└── skills-scaffold/        → .agent/skills/
```

Every template is plain markdown. Edit freely — changes ship on the next `npm publish` and take effect immediately for `curl | bash` users on `main`.

## Testing

Local bootstrap test:

```bash
rm -rf /tmp/test-ya && mkdir -p /tmp/test-ya && cd /tmp/test-ya
NO_ANIM=1 bash /path/to/youragent/install.sh
find .agent -type f | wc -l    # expect 21
NO_ANIM=1 bash /path/to/youragent/install.sh validate
```

bd-lite sanity check:

```bash
cd /tmp/test-ya/.agent/memory
./bd-lite.sh ready
./bd-lite.sh close B0001 --reason "done"   # should FAIL (vague reason)
./bd-lite.sh claim B0001
./bd-lite.sh close B0001 --reason "Smoke test: verified CLI rejects vague close reasons"
```

Status extraction sanity check:

```bash
cat > /tmp/test-ya/.agent/IDENTITY.md <<'EOF'
# IDENTITY.md

## Name

**Scribe** — maintainer agent for the youragent package itself

## Purpose

This agent exists to keep the youragent scaffold correct, useful, and shippable.
EOF

NO_ANIM=1 bash /path/to/youragent/install.sh status | grep 'Scribe'
```

## PR checklist

Before merging a PR, review it from the consumer's point of view, not just the repo author's.

- Does `npm test` pass?
- Does `npm pack` succeed?
- Does the tarball include every new runtime file the feature needs?
- If a new script or asset is required at runtime, is it present in `package.json` `files`?
- If a new subcommand is added, did you test it through the packaged entrypoint, not only from a local checkout?
- If the change affects `npx youragent`, does it still work in non-interactive and non-TTY contexts?
- If the change modifies files outside the repo or user home config, is it explicitly opt-in and clearly explained?
- If the change claims to be idempotent, did you test a second run?
- If the change updates user-facing behavior, is `README.md` accurate and specific about commands, side effects, and rollback?
- If the package manifest is changed during publish by npm normalization, did you commit the normalized form back to the repo?

For features that touch installation or external config, also verify these concrete flows:

```bash
# Clean package smoke test
npm test
npm pack

# Inspect what will really ship
tar -tzf youragent-*.tgz

# Package-level execution check
npx youragent status || true
```

If a PR fails this checklist, don't merge it on vibes. Fix the consumer path first.

## Adding a template

1. Add `.md` to `templates/`.
2. Register in `install.sh` — add to `TEMPLATES=(...)` array and `template_desc()` case.
3. Bump version, publish.

## Adding a skill

1. Add script to `skills-scaffold/`.
2. Register in `install.sh` — add to `SKILLS_FILES=(...)` and `skill_desc()`.
3. Document in `skills-scaffold/README.md`.
4. Bump version, publish.

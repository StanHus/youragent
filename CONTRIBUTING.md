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
```

bd-lite sanity check:

```bash
cd /tmp/test-ya/.agent/memory
./bd-lite.sh ready
./bd-lite.sh close B0001 --reason "done"   # should FAIL (vague reason)
./bd-lite.sh claim B0001
./bd-lite.sh close B0001 --reason "Smoke test: verified CLI rejects vague close reasons"
```

## Adding a template

1. Add `.md` to `templates/`.
2. Register in `install.sh` — add to `TEMPLATES=(...)` array and `template_desc()` case.
3. Bump version, publish.

## Adding a skill

1. Add script to `skills-scaffold/`.
2. Register in `install.sh` — add to `SKILLS_FILES=(...)` and `skill_desc()`.
3. Document in `skills-scaffold/README.md`.
4. Bump version, publish.

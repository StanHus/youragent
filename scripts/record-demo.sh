#!/usr/bin/env bash
# Record a clean demo of `npx agentize` for the README.
#
# Prereqs:
#   brew install asciinema          # or: pipx install asciinema
#   asciinema auth                  # one-time, links your machine to asciinema.org
#
# Usage:
#   scripts/record-demo.sh
#
# Outputs:
#   docs/demo.cast                  # local recording (committed to repo)
# Afterwards:
#   asciinema upload docs/demo.cast # uploads and prints a public URL
#   update README.md with the returned URL + embed snippet

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$REPO_ROOT/docs"
OUT_CAST="$OUT_DIR/demo.cast"

command -v asciinema >/dev/null 2>&1 || {
  echo "asciinema not found. Install: brew install asciinema"
  exit 1
}

mkdir -p "$OUT_DIR"

# Clean demo repo (throwaway).
DEMO_DIR="$(mktemp -d -t agentize-demo.XXXX)"
trap 'rm -rf "$DEMO_DIR"' EXIT
cd "$DEMO_DIR"
git init -q 2>/dev/null || true

# Record the install run. We use BOOTSTRAP_LOCAL_SRC so we demo the *local*
# build, not whatever's on npm right now. Tight column width keeps GIF
# renders legible.
echo "Recording demo in $DEMO_DIR — do nothing, just watch."
echo
sleep 1

asciinema rec \
  --cols 90 --rows 30 \
  --title "agentize — drop an agent into any repo in 60 seconds" \
  --command "BOOTSTRAP_LOCAL_SRC='$REPO_ROOT' bash '$REPO_ROOT/install.sh'" \
  --overwrite \
  "$OUT_CAST"

echo
echo "Recorded → $OUT_CAST"
echo "Next:"
echo "  asciinema upload $OUT_CAST"
echo "  → paste the returned URL into README.md (replace the demo badge placeholder)"

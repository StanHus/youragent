#!/usr/bin/env bash
# skills/plan.sh
# Plan checklist + validator — encodes the 7 principles from:
#   "How to Build a Perfect Plan" · Trilogy AI CoE
#   https://trilogyai.substack.com/p/how-to-build-a-perfect-plan
#
# Usage:
#   plan.sh                  # print the checklist (what a perfect plan looks like)
#   plan.sh <plan.md>        # validate a plan file against the 7 principles
#
# Exit codes:
#   0  plan passes all principles
#   1  plan fails at least one principle
#   2  usage error (missing or unreadable file)

set -euo pipefail

# ---------- Colors ----------
if [ -t 1 ]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
  GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; CYAN=$'\033[36m'
else
  BOLD=""; DIM=""; RESET=""; GREEN=""; YELLOW=""; RED=""; CYAN=""
fi

ARTICLE="https://trilogyai.substack.com/p/how-to-build-a-perfect-plan"
CITE="Trilogy AI CoE · How to Build a Perfect Plan"

# ---------- Checklist (no-args mode) ----------
print_checklist() {
  cat <<EOF

  ${BOLD}plan.sh${RESET}  ${DIM}the 7 principles of a perfect plan${RESET}
  ${DIM}source: ${ARTICLE}${RESET}
  ${DIM}─────────────────────────────────────────────────────────────${RESET}

  ${BOLD}${CYAN}1.${RESET} ${BOLD}Plan-only mode${RESET}
     Declare explicitly: "do not execute — we are building a plan."
     Otherwise the agent starts writing code by minute two while you're
     still thinking. Pin it.

  ${BOLD}${CYAN}2.${RESET} ${BOLD}Research before designing${RESET}
     Make research beads the first chunk of the plan. Feed primary
     sources (articles, repos, docs) — not summaries. Every research
     bead completes before the first design decision is made.

  ${BOLD}${CYAN}3.${RESET} ${BOLD}Prompt log audit${RESET}
     Record every user prompt verbatim. At the end, audit the plan
     against the prompts to catch gaps before context compaction
     loses them. (The CoE team caught a 95% vs 99% success-target
     mismatch this way.)

  ${BOLD}${CYAN}4.${RESET} ${BOLD}Bead graph with real beads${RESET}
     Every bead has: ${BOLD}Priority${RESET} (P0/P1/P2), ${BOLD}Blocked by${RESET},
     ${BOLD}Done when${RESET} (a measurable condition, not "looks good"),
     and ${BOLD}If fails${RESET} (named recovery).
       bad:  "Prepare training data"
       good: "≥ 80% of examples get curriculum facts; if < 80%, F3"

  ${BOLD}${CYAN}5.${RESET} ${BOLD}Decision gates, not checkpoints${RESET}
     Between phases, explicit ${BOLD}Pass / Adjust / Abort${RESET} tables with
     concrete thresholds. "Looks good" is not a gate. "p95 < 4096"
     is a gate.

  ${BOLD}${CYAN}6.${RESET} ${BOLD}Named failure scenarios${RESET}
     Label each failure (F1, F2, F3…) with a detection mechanism and
     a numbered recovery cascade, cheapest fix first. An unnamed
     failure is a panic. A named failure is a procedure.

  ${BOLD}${CYAN}7.${RESET} ${BOLD}Tiered insights${RESET}
     Rank every research finding: ${BOLD}Tier 1${RESET} (plan fails without),
     ${BOLD}Tier 2${RESET} (material), ${BOLD}Tier 3${RESET} (nice-to-have). Don't treat
     all findings as equal. Hyperparameters live in Tier 1.

  ${DIM}─────────────────────────────────────────────────────────────${RESET}
  ${BOLD}draft your plan. then run:${RESET}  ${BOLD}${CYAN}plan.sh <your-plan.md>${RESET}

EOF
}

# ---------- Validator (with-file mode) ----------
validate() {
  local file="$1"
  [ -r "$file" ] || { echo "plan.sh: cannot read '$file'" >&2; exit 2; }

  # Read whole file once. Treat as case-insensitive for keyword checks.
  local content
  content="$(cat "$file")"

  local passes=0 fails=0
  local -a report=()

  check() {
    local ok="$1" label="$2" hint="$3"
    if [ "$ok" = "1" ]; then
      report+=("  ${GREEN}✓${RESET}  ${label}")
      passes=$((passes+1))
    else
      report+=("  ${RED}✗${RESET}  ${label}
       ${DIM}→ ${hint}${RESET}")
      fails=$((fails+1))
    fi
  }

  # ---- Principle 1: Plan-only mode declared ----
  local p1=0
  grep -qiE '(plan[- ]only|do not execute|no execution|planning mode|plan first)' <<<"$content" && p1=1
  check "$p1" "Plan-only mode declared" \
    "add a line stating 'plan-only — do not execute yet' so the agent doesn't start coding"

  # ---- Principle 2: Research beads exist ----
  local p2=0
  grep -qiE '(research|read\s+(the\s+)?(article|repo|docs|codebase)|fetch\s+primary)' <<<"$content" && p2=1
  check "$p2" "Research beads / research section present" \
    "add research beads before design (see principle 2 — primary sources, not summaries)"

  # ---- Principle 3: Prompt log / requirements ----
  local p3=0
  grep -qiE '(^|\n)#{1,3}\s*(requirements|prompt\s*log|user\s*(asked|said)|prompts)\b|PROMPTS\.md' <<<"$content" && p3=1
  check "$p3" "Prompt log / requirements section" \
    "add a Requirements or Prompt Log section listing what the user asked for (principle 3)"

  # ---- Principle 4: Bead structure (Priority + Blocked by + Done when + If fails) ----
  # Note: [[:space:]] for BSD grep (macOS) portability; \s is GNU-only.
  local has_priority=0 has_blocked=0 has_done=0 has_iffail=0
  grep -qiE '(^|[^a-z])priority[[:space:]]*:[[:space:]]*p[0-2]' <<<"$content" && has_priority=1
  grep -qiE '(^|[^a-z])blocked[[:space:]_-]*by[[:space:]]*:' <<<"$content" && has_blocked=1
  grep -qiE '(^|[^a-z])(done[[:space:]_-]*when|acceptance)[[:space:]]*:' <<<"$content" && has_done=1
  grep -qiE 'if[[:space:]]+(it[[:space:]]+)?fails?|if[[:space:]]*[<>=%]|on[[:space:]]+failure' <<<"$content" && has_iffail=1
  local p4_sum=$((has_priority + has_blocked + has_done + has_iffail))
  if [ "$p4_sum" = "4" ]; then
    check 1 "Bead graph complete (Priority + Blocked by + Done when + If fails)" ""
  else
    local miss=()
    [ "$has_priority" = "0" ] && miss+=("Priority: P0/P1/P2")
    [ "$has_blocked"  = "0" ] && miss+=("Blocked by:")
    [ "$has_done"     = "0" ] && miss+=("Done when:")
    [ "$has_iffail"   = "0" ] && miss+=("If fails:")
    local missing="${miss[*]}"
    check 0 "Bead graph complete (4 fields)" \
      "missing: ${missing} — every bead needs all four (principle 4)"
  fi

  # ---- Principle 5: Decision gates with Pass/Adjust/Abort ----
  local p5=0
  if grep -qiE 'gate[[:space:]]*[0-9]|pass[[:space:]]*:.*adjust|abort[[:space:]]*(:|→)|^#{1,3}[[:space:]]*gate' <<<"$content"; then
    p5=1
  fi
  check "$p5" "Decision gates with Pass/Adjust/Abort" \
    "add explicit gates between phases (principle 5). 'looks good' is not a gate; 'p95 < 4096' is."

  # ---- Principle 6: Named failure scenarios ----
  local p6=0
  grep -qiE 'scenario[[:space:]]*f[0-9]+|^#{1,3}[[:space:]]*f[0-9]+[[:space:]]*[:·-]' <<<"$content" && p6=1
  check "$p6" "Named failure scenarios (F1, F2, …)" \
    "name each failure with an ID + numbered recovery cascade (principle 6)"

  # ---- Principle 7: Tiered insights ----
  local p7=0
  grep -qiE 'tier[[:space:]]*[1-3]|^#{1,3}[[:space:]]*tier[[:space:]]' <<<"$content" && p7=1
  check "$p7" "Insights tiered (Tier 1 / 2 / 3)" \
    "rank research findings — tier 1 (plan fails without), tier 2 (material), tier 3 (nice) (principle 7)"

  # ---- Bonus check: vague/weasel language ----
  local vague_hits
  vague_hits=$(grep -inE '\b(cleanup|polish|various|etc\.|and more|basically|refactor\s+stuff|looks?\s+good|make\s+sure\s+(it|things)\s+work)\b' "$file" 2>/dev/null || true)
  local vague_count=0
  [ -n "$vague_hits" ] && vague_count=$(printf '%s\n' "$vague_hits" | wc -l | tr -d ' ')

  # ---- Output ----
  printf "\n  ${BOLD}plan.sh${RESET}  ${DIM}validating${RESET} ${BOLD}%s${RESET}\n" "$file"
  printf "  ${DIM}against: ${CITE}${RESET}\n"
  printf "  ${DIM}─────────────────────────────────────────────────────────────${RESET}\n"
  local line
  for line in "${report[@]}"; do
    printf "%s\n" "$line"
  done
  if [ "$vague_count" -gt 0 ]; then
    printf "\n  ${YELLOW}⚠${RESET}  %d vague phrase(s) — be concrete:\n" "$vague_count"
    printf "%s\n" "$vague_hits" | sed 's/^/       /'
  fi
  printf "  ${DIM}─────────────────────────────────────────────────────────────${RESET}\n"
  printf "  ${GREEN}%d pass${RESET}  ${DIM}·${RESET}  ${RED}%d fail${RESET}\n" "$passes" "$fails"

  if [ "$fails" = "0" ]; then
    printf "\n  ${GREEN}${BOLD}plan clears the 7 principles.${RESET}  ${DIM}proceed when ready.${RESET}\n\n"
    exit 0
  else
    printf "\n  ${RED}${BOLD}plan is not yet perfect.${RESET}  ${DIM}fix the ✗ items above and rerun.${RESET}\n"
    printf "  ${DIM}reference: ${ARTICLE}${RESET}\n\n"
    exit 1
  fi
}

# ---------- Dispatch ----------
if [ "$#" = "0" ]; then
  print_checklist
  exit 0
fi
validate "$1"

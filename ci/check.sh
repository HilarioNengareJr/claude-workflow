#!/usr/bin/env bash
# Structural and shape checks for this repo. One implementation, run both
# locally (`make check`) and in CI, so the two can never drift apart.
#
# WHAT THIS DOES NOT DO: it does not look for your real values. Those live in
# values.local.env, which is gitignored and must never reach a CI runner. A
# denylist of the real words would itself have to contain the real words, which
# defeats the point. So this checks *shape* and *structure* — things provable
# from the repo alone. `make check-local` adds the exact-value sweep.
#
# NOTHING HERE EVER PRINTS WHAT IT MATCHED. Violations are reported as
# file:line plus a type. A leak detector that echoes the leak writes it into the
# CI log, which is retained and world-readable on a public repo.
#
# Runs on bash 3.2 / BSD tools (macOS) and bash 5 / GNU tools (Ubuntu runner).

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

fails=0

# Everything that would actually ship: tracked files, plus untracked ones that
# are not gitignored. Scanning only collections/ left README.md, the Makefile,
# the workflow and context-template/ as blind spots — a secret pasted into any
# of them shipped silently.
shipping_files() {
  { git ls-files -z; git ls-files -z --others --exclude-standard; } \
    | tr '\0' '\n' | sort -u | grep -v '^$'
}

# Values reserved by RFC for documentation are allowed everywhere. This is what
# lets ci/fixture.values.env pass on merit rather than by exemption — an
# exempted file is a blind spot, and blind spots are the whole problem here.
# Unanchored on purpose: this is matched against "file:line:content", so the
# address is never at the start of the line.
RESERVED_IP='(192\.0\.2\.|198\.51\.100\.|203\.0\.113\.|127\.0\.0\.1|0\.0\.0\.0)'
RESERVED_TLD='invalid|example|test|localhost'

report() {
  # $1 = violation type, $2… = file:line locations
  local kind="$1"; shift
  echo "FAIL: $kind"
  for loc in "$@"; do echo "      $loc"; done
  fails=$((fails + 1))
}

pass() { echo "ok:   $1"; }

locations() { awk -F: '{print $1":"$2}'; }

# --- 1. no angle-bracket placeholders in collections/ ----------------------
# Scoped to collections/ on purpose: README.md legitimately discusses the
# <ANGLE_BRACKET> convention in prose, and context-template/ still uses it.
hits=$(grep -rInE '<[A-Z][A-Z0-9_]+>' collections 2>/dev/null | locations || true)
if [ -n "$hits" ]; then
  # shellcheck disable=SC2086 # deliberate: one location per argument
  report "angle-bracket placeholder (invisible when rendered; use {{KEY}})" $hits
else
  pass "no angle-bracket placeholders in collections/"
fi

# --- 2. every placeholder used is declared, and none are declared unused ---
used=$(grep -rIhoE '\{\{[A-Z][A-Z0-9_]+\}\}' collections README.md 2>/dev/null \
       | tr -d '{}' | sort -u)
declared=$(grep -oE '^[A-Z][A-Z0-9_]*=' values.example.env | tr -d '=' | sort -u)

undeclared=$(comm -23 <(echo "$used") <(echo "$declared") | tr '\n' ' ')
if [ -n "${undeclared// /}" ]; then
  report "placeholder used but not declared in values.example.env" "keys: $undeclared"
else
  pass "every placeholder used is declared"
fi

unused=$(comm -13 <(echo "$used") <(echo "$declared") | tr '\n' ' ')
if [ -n "${unused// /}" ]; then
  report "key declared in values.example.env but never used" "keys: $unused"
else
  pass "no dead keys"
fi

# --- 3. no DSN with literal credentials -----------------------------------
# A tokenized DSN looks like scheme://{{USER}}:{{PASSWORD}}@host. Anything else
# in the userinfo is a real credential.
#
# The scheme is required. Without it this also matches prose that *describes*
# the shape — scaffold/SKILL.md tells authors to grep for `://user:pass@`, which
# is documentation, not a credential.
hits=$(shipping_files | tr '\n' '\0' \
       | xargs -0 grep -InE '[a-z][a-z0-9+.-]*://[^[:space:]")]+:[^[:space:]")]*@' 2>/dev/null \
       | grep -vE '://\{\{[A-Z0-9_]+\}\}:\{\{[A-Z0-9_]+\}\}@' \
       | locations || true)
if [ -n "$hits" ]; then
  # shellcheck disable=SC2086
  report "DSN with non-placeholder credentials" $hits
else
  pass "all DSNs are fully tokenized"
fi

# --- 4. no literal IPv4 addresses -----------------------------------------
# Scans everything that ships. RFC 5737 documentation ranges are allowed.
hits=$(shipping_files | tr '\n' '\0' \
       | xargs -0 grep -InE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' 2>/dev/null \
       | grep -vE "$RESERVED_IP" \
       | locations || true)
if [ -n "$hits" ]; then
  # shellcheck disable=SC2086
  report "literal IPv4 address" $hits
else
  pass "no literal IPv4 addresses"
fi

# --- 5. no real hostnames -------------------------------------------------
# Case-insensitive on purpose: a case-sensitive sweep is exactly how nine
# lowercase leaks survived a manual pass once. The TLD list is what stops this
# matching Python attribute access (os.environ.get) or filenames
# (values.example.env); .internal/.corp/.lan/.local are included because those
# are the likeliest shape for an internal host.
TLDS='com|net|org|io|dev|co|za|uk|us|ai|sh|app|cloud|network|systems|tech|info|biz'
TLDS="$TLDS|internal|corp|lan|local|intranet|private"
hits=$(shipping_files | tr '\n' '\0' \
       | xargs -0 grep -IniE "\\b[a-z0-9]([a-z0-9-]*[a-z0-9])?(\\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+\\.($TLDS)\\b" 2>/dev/null \
       | grep -viE "\\.($RESERVED_TLD)\\b" \
       | locations || true)
if [ -n "$hits" ]; then
  # shellcheck disable=SC2086
  report "hostname with a real TLD" $hits
else
  pass "no real hostnames"
fi

# --- 6. hydration round-trip against the synthetic fixture ----------------
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
if VALUES_FILE="$ROOT/ci/fixture.values.env" ./hydrate.sh "$tmp/out" >"$tmp/log" 2>&1; then
  left=$(grep -rIhoE '\{\{[A-Z][A-Z0-9_]+\}\}' "$tmp/out" 2>/dev/null | sort -u | tr '\n' ' ' || true)
  if [ -n "${left// /}" ]; then
    report "hydration left placeholders unresolved" "keys: $left"
  else
    n=$(find "$tmp/out" -type f | wc -l | tr -d ' ')
    pass "hydration resolves every placeholder ($n files)"
  fi
else
  report "hydrate.sh failed against the CI fixture" "see ci/fixture.values.env"
fi

echo
if [ "$fails" -gt 0 ]; then
  echo "$fails check(s) failed."
  exit 1
fi
echo "All checks passed."

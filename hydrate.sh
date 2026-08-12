#!/usr/bin/env bash
# Fill every {{...}} in the skills with the real values from
# values.local.env, writing the result to a destination directory.
#
#   ./hydrate.sh ~/.claude/skills          # restore onto a machine
#   ./hydrate.sh /tmp/preview --dry-run    # see what would change
#
# The repo itself is never modified — placeholders stay placeholders here.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALUES="${VALUES_FILE:-$REPO/values.local.env}"
DEST="${1:-}"
DRY_RUN=false
[[ "${2:-}" == "--dry-run" ]] && DRY_RUN=true

if [[ -z "$DEST" ]]; then
  echo "usage: $0 <destination-dir> [--dry-run]" >&2
  exit 1
fi

if [[ ! -f "$VALUES" ]]; then
  echo "error: no values file at $VALUES" >&2
  echo "       cp values.example.env values.local.env, then fill it in." >&2
  exit 1
fi

# Read KEY=VALUE pairs, ignoring comments, blanks, and trailing inline comments.
declare -a KEYS VALS
while IFS= read -r line; do
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ "$line" =~ ^[[:space:]]*$ ]] && continue
  [[ "$line" != *=* ]] && continue
  key="${line%%=*}"
  val="${line#*=}"
  val="${val%%[[:space:]]#*}"          # strip inline comment
  val="$(printf '%s' "$val" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  key="$(printf '%s' "$key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  [[ -z "$val" ]] && continue          # unfilled key: leave its placeholder alone
  KEYS+=("$key")
  VALS+=("$val")
done < "$VALUES"

if [[ ${#KEYS[@]} -eq 0 ]]; then
  echo "error: $VALUES has no filled-in values." >&2
  exit 1
fi

echo "hydrating ${#KEYS[@]} placeholder(s) from $(basename "$VALUES")"
$DRY_RUN && echo "(dry run — nothing will be written)"

$DRY_RUN || mkdir -p "$DEST"
$DRY_RUN || cp -R "$REPO/collections/." "$DEST/"

# Build one sed program so each file is rewritten in a single pass.
SED_PROG=""
for i in "${!KEYS[@]}"; do
  esc="$(printf '%s' "${VALS[$i]}" | sed -e 's/[&|\\]/\\&/g')"
  SED_PROG+="s|{{${KEYS[$i]}}}|${esc}|g;"
done

if $DRY_RUN; then
  remaining=$(grep -rIhoE '\{\{[A-Z][A-Z0-9_]+\}\}' "$REPO/collections" \
    | sed "$SED_PROG" | grep -oE '\{\{[A-Z][A-Z0-9_]+\}\}' | sort -u || true)
else
  find "$DEST" -type f -name '*.md' -o -type f -name '*.sh' | while read -r f; do
    sed -i '' "$SED_PROG" "$f" 2>/dev/null || sed -i "$SED_PROG" "$f"
  done
  remaining=$(grep -rIhoE '\{\{[A-Z][A-Z0-9_]+\}\}' "$DEST" | sort -u || true)
fi

if [[ -n "$remaining" ]]; then
  echo
  echo "still unfilled (no value set in $(basename "$VALUES")):"
  # Read line by line rather than letting word splitting do it: a value
  # containing a space would otherwise be printed as two placeholders.
  # macOS ships bash 3.2, so mapfile is not available here.
  while IFS= read -r placeholder; do
    [[ -n "$placeholder" ]] && printf '  %s\n' "$placeholder"
  done <<< "$remaining"
fi

$DRY_RUN || echo -e "\ndone → $DEST"

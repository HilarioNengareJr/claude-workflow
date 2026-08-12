#!/bin/bash
# check-dev-docs.sh — block dev-work docs from being committed on ANY platform.
#
# Rule (2026-07-22): contracts and markdown written for dev work never
# get committed — not to GitLab, not to GitHub. They live on disk only.
#
# Usage:
#   check-dev-docs.sh            check what is STAGED (pre-commit hook mode)
#   check-dev-docs.sh --tracked  check what is already TRACKED (audit mode)
#
# Exit 0 = clean. Exit 1 = violations found (listed on stderr).

set -uo pipefail
MODE="${1:-staged}"

# Paths that are dev-work docs. Anchored so they match repo-relative paths.
is_dev_doc() {
  # NOTE: directory rules are ROOT-ANCHORED on purpose. An earlier version used
  # */context/* and matched {{WEB_REPO}}'s src/context/*.tsx — the React context
  # providers, i.e. application source. Never widen these to match any depth.
  case "$1" in
    # Working context + session state (repo root only)
    context/*|context-v1/*)             return 0 ;;
    memory.md)                          return 0 ;;
    # Dev-facing docs directory, markdown only (repo root only)
    docs/*.md)                          return 0 ;;
    # Unambiguous filenames — safe at any depth
    CLAUDE.md|*/CLAUDE.md)              return 0 ;;
    HANDOVER.md|*/HANDOVER.md)          return 0 ;;
    FINDS*.md|*/FINDS*.md)              return 0 ;;
    # Agent tooling
    .claude/*)                          return 0 ;;
    # Contracts + specs
    *_FRONTEND_CONTRACT.md|*_SPEC.md)   return 0 ;;
  esac
  return 1
}

# Per-repo exemptions. A repo may commit a `.devdocs-keep` file at its root
# listing path prefixes that stay tracked despite the rules above — one per
# line, blank lines and #comments ignored. It is committed on purpose so the
# exemption survives a re-clone, unlike a git hook or git config.
KEEP_FILE=".devdocs-keep"
KEEP_PREFIXES=""
if [ -f "$KEEP_FILE" ]; then
  KEEP_PREFIXES=$(grep -vE '^\s*(#|$)' "$KEEP_FILE" 2>/dev/null || true)
fi

# Never flag these, even if a rule above would match.
is_allowed() {
  case "$1" in
    README.md|*/README.md)      return 0 ;;  # repo front door
    .beads/*)                   return 0 ;;  # issue tracker, committed on purpose
    .devdocs-keep)              return 0 ;;  # this exemption list itself
    system_prompt.md)           return 0 ;;  # knowledgebase product content
    files/*)                    return 0 ;;  # knowledgebase product content
  esac
  # Repo-declared exemptions
  if [ -n "$KEEP_PREFIXES" ]; then
    while IFS= read -r p; do
      [ -z "$p" ] && continue
      case "$1" in "$p"*) return 0 ;; esac
    done <<< "$KEEP_PREFIXES"
  fi
  return 1
}

if [ "$MODE" = "--tracked" ]; then
  FILES=$(git ls-files)
  LABEL="tracked in this repo"
else
  FILES=$(git diff --cached --name-only --diff-filter=ACMR)
  LABEL="staged for commit"
fi

VIOLATIONS=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  is_allowed "$f" && continue
  is_dev_doc "$f" && VIOLATIONS="${VIOLATIONS}${f}"$'\n'
done <<< "$FILES"

if [ -n "$VIOLATIONS" ]; then
  {
    echo
    echo "✘ Dev-work docs $LABEL — these must never be committed:"
    echo
    printf '%s' "$VIOLATIONS" | sed 's/^/    /'
    echo
    if [ "$MODE" = "--tracked" ]; then
      echo "  Fix:  git rm --cached <file>   (keeps the file on disk)"
    else
      echo "  Fix:  git restore --staged <file>"
      echo "  These belong on disk only — not GitLab, not GitHub."
    fi
    echo
  } >&2
  exit 1
fi

exit 0

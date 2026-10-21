#!/usr/bin/env bash
# Survey every worktree of one repo against its default branch on origin.
#   survey.sh <any path inside the repo> [--no-fetch]
# Read only, except `git fetch --prune origin`, which only updates the
# remote tracking refs so the checks compare against today's main.
# Prints one block per worktree, then a repo block. /ultron-worktrees reads it.
#
# Why each check exists (sources in SKILL.md, "Why these checks"):
#   unique / picked  git cherry matches commits by patch, so a commit pushed by
#                    cherry pick from a scratch worktree counts as landed
#   content_on_main  catches squash and hand merges, which git cherry misses
#   same_as_main     dirty files whose edit already reached main another way
#   live / scratch   a worktree with a live session is never cleaned
set -uo pipefail

target="${1:-.}"
fetch=1
[ "${2:-}" = "--no-fetch" ] && fetch=0

common=$(git -C "$target" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || {
  echo "ERROR not a git repo: $target"; exit 2; }
repo=$(git -C "$target" rev-parse --show-toplevel)

if [ "$fetch" = 1 ]; then
  if git -C "$repo" fetch --prune --quiet origin 2>/dev/null; then fetched=yes; else fetched="failed (offline or no origin)"; fi
else
  fetched="skipped (--no-fetch)"
fi

base=$(git -C "$repo" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
if [ -z "$base" ]; then
  for b in origin/main origin/master main master; do
    git -C "$repo" rev-parse --verify --quiet "$b" >/dev/null && { base=$b; break; }
  done
fi
[ -z "$base" ] && { echo "ERROR no default branch found"; exit 2; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Live sessions: the working folder of every claude process.
for pid in $(pgrep -if claude 2>/dev/null); do
  lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | sed -n "s/^n//p" | sed "s/^/$pid	/"
done > "$tmp/cwds"

scratch_root="/private/tmp/claude-$(id -u)"
[ -d "$scratch_root" ] || scratch_root="/tmp/claude-$(id -u)"

git -C "$repo" worktree list --porcelain > "$tmp/wt"
paths=$(awk '/^worktree /{sub(/^worktree /,""); print}' "$tmp/wt")

echo "repo: $repo"
echo "base: $base"
echo "fetch: $fetched"
echo "surveyed: $(date '+%Y-%m-%d %H:%M')"
echo

IFS='
'
for wt in $paths; do
  echo "== $wt"
  flags=$(awk -v p="$wt" '$0=="worktree "p{on=1;next} /^worktree /{on=0} on && /^(locked|prunable|bare)/' "$tmp/wt" | tr '\n' ' ')
  [ -n "$flags" ] && echo "flags: $flags"
  if [ ! -d "$wt" ]; then
    echo "missing: folder is gone (prunable metadata)"
    echo; continue
  fi
  g() { git -C "$wt" "$@"; }

  branch=$(g symbolic-ref --quiet --short HEAD || echo "(detached)")
  echo "branch: $branch"
  echo "head: $(g log -1 --format='%h %cs %s')"
  echo "last_commit_age_days: $(( ( $(date +%s) - $(g log -1 --format=%ct) ) / 86400 ))"

  gd=$(g rev-parse --path-format=absolute --git-dir)
  op=""
  [ -d "$gd/rebase-merge" ] || [ -d "$gd/rebase-apply" ] && op="$op rebase"
  [ -f "$gd/MERGE_HEAD" ] && op="$op merge"
  [ -f "$gd/CHERRY_PICK_HEAD" ] && op="$op cherry-pick"
  [ -f "$gd/REVERT_HEAD" ] && op="$op revert"
  [ -f "$gd/BISECT_LOG" ] && op="$op bisect"
  op="${op# }"
  echo "operation: ${op:-none}"

  g status --porcelain=v1 > "$tmp/st"
  tracked=$(grep -vc '^??' "$tmp/st")
  untracked=$(grep -c '^??' "$tmp/st")
  echo "dirty: $tracked tracked, $untracked untracked"
  if [ $((tracked + untracked)) -gt 0 ]; then
    same=0
    newest=0
    while IFS= read -r line; do
      f="${line:3}"; f="${f#* -> }"; f="${f%\"}"; f="${f#\"}"
      [ -e "$wt/$f" ] || continue
      m=$(stat -f %m "$wt/$f" 2>/dev/null || stat -c %Y "$wt/$f")
      [ "$m" -gt "$newest" ] && newest=$m
      case "$line" in '??'*) ;; *)
        [ -f "$wt/$f" ] && [ "$(g hash-object -- "$f")" = "$(g rev-parse --quiet --verify "$base:$f" 2>/dev/null)" ] && same=$((same + 1)) ;;
      esac
      printf '%s\t%s\n' "$wt" "$f" >> "$tmp/dirtymap"
    done < "$tmp/st"
    echo "dirty_same_as_main: $same of $tracked tracked"
    [ "$newest" -gt 0 ] && echo "newest_edit: $(date -r "$newest" '+%Y-%m-%d %H:%M' 2>/dev/null || date -d "@$newest" '+%Y-%m-%d %H:%M')"
    echo "dirty_files:"
    sed 's/^/  /' "$tmp/st" | head -25
    [ "$(wc -l < "$tmp/st")" -gt 25 ] && echo "  ... $(( $(wc -l < "$tmp/st") - 25 )) more"
  fi

  g cherry "$base" HEAD > "$tmp/ch" 2>/dev/null
  uniq=$(grep -c '^+' "$tmp/ch")
  picked=$(grep -c '^-' "$tmp/ch")
  echo "unique_commits: $uniq (not on $base by patch)"
  echo "picked_commits: $picked (same patch already on $base)"
  if [ "$uniq" -gt 0 ]; then
    grep '^+' "$tmp/ch" | awk '{print $2}' | while read -r c; do echo "  + $(g log -1 --format='%h %cs %s' "$c")"; done
    mb=$(g merge-base "$base" HEAD)
    total=0; equal=0
    for f in $(g diff --name-only "$mb" HEAD); do
      total=$((total + 1))
      [ "$(g rev-parse --quiet --verify "HEAD:$f" 2>/dev/null)" = "$(g rev-parse --quiet --verify "$base:$f" 2>/dev/null)" ] && equal=$((equal + 1))
    done
    echo "content_on_main: $equal of $total files the branch changed already match $base"
  fi
  echo "behind_base: $(g rev-list --count "HEAD..$base")"

  if [ "$branch" != "(detached)" ]; then
    if g rev-parse --verify --quiet "refs/remotes/origin/$branch" >/dev/null; then
      echo "on_origin: yes, ahead $(g rev-list --count "origin/$branch..HEAD"), behind $(g rev-list --count "HEAD..origin/$branch")"
    else
      echo "on_origin: no"
    fi
  fi

  live=$(awk -F'\t' -v p="$wt" '$2==p || index($2, p"/")==1 {print $1}' "$tmp/cwds" | tr '\n' ' ')
  echo "live_session_pids: ${live:-none}"
  sdir="$scratch_root/$(printf '%s' "$wt" | tr '/' '-')"
  if [ -d "$sdir" ]; then
    echo "scratch_files_last_30_min: $(find "$sdir" -type f -mmin -30 2>/dev/null | wc -l | tr -d ' ')"
  fi
  echo
done

echo "== repo"
echo "stashes (shared by every worktree):"
git -C "$repo" stash list --format='  %gd %cs %s' | head -10
echo "prune_dry_run:"
git -C "$repo" worktree prune --dry-run --verbose 2>&1 | sed 's/^/  /'
echo "same_head (worktrees on one commit):"
awk '/^worktree /{p=$2} /^HEAD /{print $2" "p}' "$tmp/wt" | sort | awk '{c[$1]++; l[$1]=l[$1]" "$2} END{for(k in c) if(c[k]>1) print "  "substr(k,1,7)":"l[k]}'
echo "overlap (one file dirty in two or more worktrees):"
if [ -f "$tmp/dirtymap" ]; then
  awk -F'\t' '{n[$2]++; w[$2]=w[$2]" "$1} END{for(f in n) if(n[f]>1) print "  "f":"w[f]}' "$tmp/dirtymap" | sort
fi
echo "branches with no worktree, not on $base by patch:"
inwt=$(awk '/^branch /{sub("refs/heads/","",$2); print $2}' "$tmp/wt")
for b in $(git -C "$repo" for-each-ref --format='%(refname:short)' refs/heads); do
  printf '%s\n' "$inwt" | grep -qxF "$b" && continue
  n=$(git -C "$repo" cherry "$base" "$b" 2>/dev/null | grep -c '^+')
  [ "$n" -gt 0 ] && echo "  $b: $n unique, last $(git -C "$repo" log -1 --format=%cs "$b")"
done
exit 0

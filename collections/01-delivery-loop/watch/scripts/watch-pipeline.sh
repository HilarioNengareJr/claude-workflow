#!/usr/bin/env bash
# watch-pipeline.sh — watch a GitLab pipeline to completion, then scan every
# failed job's log for real failures and suspicious structured-log lines.
#
# Talks to the {{GITLAB_HOST}} REST API using the same personal access token
# the gitlab MCP is configured with (read from ~/.claude.json). That PAT can see
# all three {{REPO_PREFIX}} repos — service, web, and admin. Project is auto-detected
# from the current repo's origin remote.
#
# Usage:
#   watch-pipeline.sh                 # latest pipeline for the current branch
#   watch-pipeline.sh <pipeline_id>   # a specific pipeline
#   watch-pipeline.sh <sha|ref>       # latest pipeline for a commit/branch
#
# Run it in the BACKGROUND (it sleeps between polls) so the harness re-invokes
# Claude when the pipeline finishes. Env knobs: POLL_SECONDS (default 45),
# MAX_POLLS (default 120 → ~90 min ceiling), SCAN_ALL=1 (scan passing jobs too),
# GITLAB_TOKEN (override the token), CLAUDE_CONFIG (override ~/.claude.json path).
set -uo pipefail

POLL_SECONDS="${POLL_SECONDS:-45}"
MAX_POLLS="${MAX_POLLS:-120}"
SCAN_ALL="${SCAN_ALL:-0}"
conf="${CLAUDE_CONFIG:-$HOME/.claude.json}"

# Token + API base from the same source the gitlab MCP reads them — one source
# of truth. This is the user's PAT (not the project bot), so it sees every repo.
PAT=$(python3 -c "import json,os; d=json.load(open(os.path.expanduser('$conf'))); print(d.get('mcpServers',{}).get('gitlab',{}).get('env',{}).get('GITLAB_PERSONAL_ACCESS_TOKEN',''))" 2>/dev/null || true)
API=$(python3 -c "import json,os; d=json.load(open(os.path.expanduser('$conf'))); print(d.get('mcpServers',{}).get('gitlab',{}).get('env',{}).get('GITLAB_API_URL','https://{{GITLAB_HOST}}/api/v4'))" 2>/dev/null || echo 'https://{{GITLAB_HOST}}/api/v4')
TOKEN="${GITLAB_TOKEN:-$PAT}"
[ -z "$TOKEN" ] && { echo "No GitLab token (set GITLAB_TOKEN, or configure the gitlab MCP in $conf)."; exit 1; }

gl() { curl -s -H "PRIVATE-TOKEN: $TOKEN" "$API/$1"; }

remote=$(git remote get-url origin 2>/dev/null) || { echo "Not in a git repo."; exit 1; }
project_path=$(printf '%s' "$remote" | sed -E 's#^.*{{GITLAB_HOST_RE}}[:/]##; s#\.git$##')
project=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$project_path")

# Confirm the token can see this project before doing anything else.
if ! printf '%s' "$(gl "projects/$project")" | grep -q '"id"'; then
  echo "Token can't see '$project_path'. Check the PAT's scope/access. Aborting."
  exit 2
fi

# Resolve the pipeline id.
arg="${1:-}"
if [ -z "$arg" ]; then
  ref=$(git branch --show-current)
  pid=$(gl "projects/$project/pipelines?ref=$ref&per_page=1" \
        | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['id'] if isinstance(d,list) and d else '')")
elif printf '%s' "$arg" | grep -qE '^[0-9]+$'; then
  pid="$arg"
else
  # A ref or (short) sha. GitLab's sha filter needs the full 40-char sha, so
  # expand it locally first; fall back to treating the arg as a branch ref.
  full=$(git rev-parse "$arg" 2>/dev/null || printf '%s' "$arg")
  pid=$(gl "projects/$project/pipelines?sha=$full&per_page=1" \
        | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['id'] if isinstance(d,list) and d else '')")
  if [ -z "$pid" ]; then
    pid=$(gl "projects/$project/pipelines?ref=$arg&per_page=1" \
          | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['id'] if isinstance(d,list) and d else '')")
  fi
fi
[ -z "${pid:-}" ] && { echo "No pipeline found for '$project_path' (arg='$arg')."; exit 1; }

echo "== watching pipeline $pid on $project_path =="
gl "projects/$project/pipelines/$pid" \
  | python3 -c "import sys,json; w=json.load(sys.stdin).get('web_url',''); print('   '+w) if w else None"

# Poll until the pipeline reaches a terminal state.
status=""
for i in $(seq 1 "$MAX_POLLS"); do
  status=$(gl "projects/$project/pipelines/$pid" \
           | python3 -c "import sys,json; print(json.load(sys.stdin).get('status',''))")
  case "$status" in
    success|failed|canceled|skipped) break ;;
    manual) break ;;  # required jobs done, only manual gates remain
  esac
  echo "   [$(printf '%02d' "$i")] $status …"
  sleep "$POLL_SECONDS"
done
echo "== pipeline $pid finished: ${status:-unknown} =="

# List jobs (status, stage, name, allow_failure), oldest stage first.
jobs_json=$(gl "projects/$project/pipelines/$pid/jobs?per_page=100")
printf '%s' "$jobs_json" | python3 -c "
import sys,json
jobs=json.load(sys.stdin)
for j in reversed(jobs):
    flag=' (allow_failure)' if j.get('allow_failure') else ''
    print(f\"  {j['status']:9} {j['stage']:12} {j['name']}{flag}\")
"

# Which jobs to scan: failed by default; all if SCAN_ALL=1. Plain string list +
# read loop so this works on macOS bash 3.2 (no mapfile).
scan_list=$(printf '%s' "$jobs_json" | python3 -c "
import sys,json,os
jobs=json.load(sys.stdin)
scan_all=os.environ.get('SCAN_ALL')=='1'
for j in jobs:
    if scan_all or j['status']=='failed':
        print(j['id'], j['name'], 'allow_failure' if j.get('allow_failure') else 'blocking')
")
[ -z "$scan_list" ] && { echo; echo "No failed jobs. Nothing to scan."; echo; echo "== done =="; exit 0; }

# Patterns that flag failures and weird structured-log (slog) lines.
patterns='panic:|goroutine [0-9]+ \[|runtime error|invalid memory address|nil pointer|level=(error|warn)|"level":"(error|warn)"|\bFATAL\b|fatal error|\bpanic\b|command terminated with exit code|Job failed|OOMKilled|CrashLoopBackOff|ImagePullBackOff|context deadline exceeded|connection refused|no such host|i/o timeout|dial tcp|permission denied|DL[0-9]{4}|leak[s]? found|secret detected|Error response from daemon|npm ERR!|tsc: error|error TS[0-9]+|UnhandledPromiseRejection|segmentation|\bkilled\b'

echo
echo "== scanning logs =="
printf '%s\n' "$scan_list" | while IFS=' ' read -r jid jname jkind; do
  [ -z "$jid" ] && continue
  echo
  echo "--- $jname (job $jid, $jkind) ---"
  trace=$(gl "projects/$project/jobs/$jid/trace" \
          | sed -E 's/\x1b\[[0-9;]*[A-Za-z]//g; s/\r//g' \
          | grep -vE '^[0-9T:.Z-]+ [0-9]{2}O[+ ]?section_(start|end):' )
  hits=$(printf '%s' "$trace" | grep -nEi "$patterns" | grep -vEi 'section_(start|end)' | head -25)
  if [ -n "$hits" ]; then
    printf '%s\n' "$hits"
  else
    echo "  (no pattern hits — tail of the log:)"
    printf '%s\n' "$trace" | grep -vE '^[[:space:]]*$' | tail -12
  fi
done
echo
echo "== done =="

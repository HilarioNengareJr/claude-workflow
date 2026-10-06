#!/usr/bin/env bash
# watch-pipeline.sh: follow a GitLab pipeline to its final state, then pull the
# failing jobs' logs and flag the lines that explain the failure.
#
# Uses the personal access token the gitlab MCP is configured with (read from
# ~/.claude.json), so it sees every repo in the group. The project is worked
# out from the current repo's origin remote; run it from inside the repo.
#
# Usage:
#   watch-pipeline.sh                 # latest pipeline for the current branch
#   watch-pipeline.sh <pipeline_id>   # a specific pipeline
#   watch-pipeline.sh <sha|ref>       # latest pipeline for a commit or branch
#
# Run it in the background; it sleeps between polls. Env knobs: POLL_SECONDS
# (default 45), MAX_POLLS (default 120, about 90 minutes), SCAN_ALL=1 (scan
# passing jobs too), GITLAB_TOKEN (override), CLAUDE_CONFIG (override path).
set -uo pipefail

POLL_SECONDS="${POLL_SECONDS:-45}"
MAX_POLLS="${MAX_POLLS:-120}"
SCAN_ALL="${SCAN_ALL:-0}"
conf="${CLAUDE_CONFIG:-$HOME/.claude.json}"

PAT=$(python3 -c "import json,os; d=json.load(open(os.path.expanduser('$conf'))); print(d.get('mcpServers',{}).get('gitlab',{}).get('env',{}).get('GITLAB_PERSONAL_ACCESS_TOKEN',''))" 2>/dev/null || true)
API=$(python3 -c "import json,os; d=json.load(open(os.path.expanduser('$conf'))); print(d.get('mcpServers',{}).get('gitlab',{}).get('env',{}).get('GITLAB_API_URL',''))" 2>/dev/null || true)
TOKEN="${GITLAB_TOKEN:-$PAT}"
[ -z "$TOKEN" ] && { echo "No GitLab token (set GITLAB_TOKEN, or configure the gitlab MCP in $conf)."; exit 1; }

remote=$(git remote get-url origin 2>/dev/null) || { echo "Not in a git repo."; exit 1; }
host=$(printf '%s' "$remote" | sed -E 's#^(git@|ssh://git@|https?://)##; s#[:/].*$##')
[ -z "$API" ] && API="https://$host/api/v4"
project_path=$(printf '%s' "$remote" | sed -E 's#^(git@|ssh://git@|https?://)[^/:]+[:/]##; s#\.git$##')
project=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$project_path")

gl() { curl -s -H "PRIVATE-TOKEN: $TOKEN" "$API/$1"; }

if ! printf '%s' "$(gl "projects/$project")" | grep -q '"id"'; then
  echo "Token can't see '$project_path' on $API. Check the PAT's scope. Aborting."
  exit 2
fi

first_id() { python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['id'] if isinstance(d,list) and d else '')"; }

arg="${1:-}"
if [ -z "$arg" ]; then
  ref=$(git branch --show-current)
  pid=$(gl "projects/$project/pipelines?ref=$ref&per_page=1" | first_id)
elif printf '%s' "$arg" | grep -qE '^[0-9]+$'; then
  pid="$arg"
else
  full=$(git rev-parse "$arg" 2>/dev/null || printf '%s' "$arg")
  pid=$(gl "projects/$project/pipelines?sha=$full&per_page=1" | first_id)
  [ -z "$pid" ] && pid=$(gl "projects/$project/pipelines?ref=$arg&per_page=1" | first_id)
fi
[ -z "${pid:-}" ] && { echo "No pipeline found for '$project_path' (arg='$arg'). A fresh push takes 30 to 60 seconds to register; try again."; exit 1; }

echo "== watching pipeline $pid on $project_path =="
gl "projects/$project/pipelines/$pid" | python3 -c "import sys,json; w=json.load(sys.stdin).get('web_url',''); print('   '+w) if w else None"

status=""
for i in $(seq 1 "$MAX_POLLS"); do
  status=$(gl "projects/$project/pipelines/$pid" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status',''))")
  case "$status" in
    success|failed|canceled|skipped|manual) break ;;
  esac
  echo "   [$(printf '%02d' "$i")] $status …"
  sleep "$POLL_SECONDS"
done
echo "== pipeline $pid finished: ${status:-unknown} =="

jobs_json=$(gl "projects/$project/pipelines/$pid/jobs?per_page=100")
printf '%s' "$jobs_json" | python3 -c "
import sys,json
jobs=json.load(sys.stdin)
for j in reversed(jobs):
    flag=' (allow_failure)' if j.get('allow_failure') else ''
    print(f\"  {j['status']:9} {j['stage']:12} {j['name']}{flag}\")
"

scan_list=$(printf '%s' "$jobs_json" | python3 -c "
import sys,json,os
jobs=json.load(sys.stdin)
scan_all=os.environ.get('SCAN_ALL')=='1'
for j in jobs:
    if scan_all or j['status']=='failed':
        print(j['id'], j['name'], 'allow_failure' if j.get('allow_failure') else 'blocking')
")
[ -z "$scan_list" ] && { echo; echo "No failed jobs. Nothing to scan."; echo "== done =="; exit 0; }

patterns='panic:|goroutine [0-9]+ \[|runtime error|invalid memory address|nil pointer|level=(error|warn)|"level":"(error|warn)"|\bFATAL\b|fatal error|\bpanic\b|command terminated with exit code|Job failed|OOMKilled|CrashLoopBackOff|ImagePullBackOff|context deadline exceeded|connection refused|no such host|i/o timeout|dial tcp|permission denied|DL[0-9]{4}|leak[s]? found|secret detected|Error response from daemon|npm ERR!|tsc: error|error TS[0-9]+|UnhandledPromiseRejection|segmentation|\bkilled\b'

echo; echo "== scanning logs =="
printf '%s\n' "$scan_list" | while IFS=' ' read -r jid jname jkind; do
  [ -z "$jid" ] && continue
  echo; echo "--- $jname (job $jid, $jkind) ---"
  trace=$(gl "projects/$project/jobs/$jid/trace" | sed -E 's/\x1b\[[0-9;]*[A-Za-z]//g; s/\r//g' | grep -vE 'section_(start|end):')
  hits=$(printf '%s' "$trace" | grep -nEi "$patterns" | head -25)
  if [ -n "$hits" ]; then printf '%s\n' "$hits"; else
    echo "  (no pattern hits; tail of the log:)"; printf '%s\n' "$trace" | grep -vE '^[[:space:]]*$' | tail -12
  fi
done
echo; echo "== done =="

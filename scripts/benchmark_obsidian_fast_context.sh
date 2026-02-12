#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  benchmark_obsidian_fast_context.sh [options]

Options:
  --vault <path>       Obsidian vault root (optional)
  --repo-root <path>   Repo root (default: script parent)
  --runs <n>           Runs per query (default: 7)
  --engine <name>      Engine: auto|hybrid|base|fts|rg (default: auto)
  --refresh <mode>     Refresh: auto|force|skip (default: auto)
  --query <text>       Add query (repeatable)
  -h, --help           Show help
USAGE
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FAST_CONTEXT_SCRIPT="$SCRIPT_DIR/obsidian_fast_context.sh"

VAULT=""
RUNS=7
ENGINE="auto"
REFRESH="auto"
declare -a QUERIES=(
  "last_config_sync_date"
  "Review guidelines"
  "AGENT_NOTES*.md"
  "obsidian_fast_context.sh"
)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault)
      VAULT="$2"
      shift 2
      ;;
    --repo-root)
      REPO_ROOT="$2"
      shift 2
      ;;
    --runs)
      RUNS="$2"
      shift 2
      ;;
    --engine)
      ENGINE="$2"
      shift 2
      ;;
    --refresh)
      REFRESH="$2"
      shift 2
      ;;
    --query)
      QUERIES+=("$2")
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ ! "$RUNS" =~ ^[0-9]+$ ]] || [[ "$RUNS" -le 0 ]]; then
  echo "--runs must be a positive integer." >&2
  exit 1
fi

if [[ ! -x "$FAST_CONTEXT_SCRIPT" ]]; then
  echo "Missing executable: $FAST_CONTEXT_SCRIPT" >&2
  exit 1
fi

tmp_jsonl="$(mktemp)"
trap 'rm -f "$tmp_jsonl"' EXIT

for query in "${QUERIES[@]}"; do
  for i in $(seq 1 "$RUNS"); do
    "$FAST_CONTEXT_SCRIPT" \
      --repo-root "$REPO_ROOT" \
      ${VAULT:+--vault "$VAULT"} \
      --query "$query" \
      --engine "$ENGINE" \
      --refresh "$REFRESH" \
      --mode json >> "$tmp_jsonl"
  done
done

python3 - "$tmp_jsonl" <<'PY'
import json
import statistics
import sys
from collections import defaultdict

path = sys.argv[1]
rows = []
with open(path, "r", encoding="utf-8", errors="ignore") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            rows.append(json.loads(line))
        except json.JSONDecodeError:
            pass

if not rows:
    print("No benchmark samples captured.")
    raise SystemExit(1)

times = [r.get("took_ms", 0) for r in rows]
times = [int(t) for t in times if isinstance(t, (int, float))]
times.sort()

def percentile(sorted_values, p):
    if not sorted_values:
        return 0
    k = int(round((p / 100.0) * (len(sorted_values) - 1)))
    return sorted_values[k]

by_query = defaultdict(list)
by_engine = defaultdict(list)
for row in rows:
    by_query[str(row.get("query", ""))].append(int(row.get("took_ms", 0)))
    by_engine[str(row.get("engine", ""))].append(int(row.get("took_ms", 0)))

print("Overall")
print(f"- samples: {len(times)}")
print(f"- p50_ms: {percentile(times, 50)}")
print(f"- p95_ms: {percentile(times, 95)}")
print(f"- mean_ms: {round(statistics.mean(times), 2)}")
print()

print("By query")
for query, values in sorted(by_query.items()):
    values.sort()
    print(f"- {query}: p50={percentile(values, 50)}ms p95={percentile(values, 95)}ms n={len(values)}")
print()

print("By engine")
for engine, values in sorted(by_engine.items()):
    values.sort()
    print(f"- {engine}: p50={percentile(values, 50)}ms p95={percentile(values, 95)}ms n={len(values)}")
PY

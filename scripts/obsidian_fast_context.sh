#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  obsidian_fast_context.sh --query <text> [options]

Options:
  --query <text>       Search string (required)
  --vault <path>       Obsidian vault root (recommended for Base prefilter)
  --repo-root <path>   Repository root (default: script parent)
  --limit <n>          Max results to return (default: 8)
  --mode <mode>        Output mode: paths|context|json (default: paths)
  --engine <engine>    Query engine: auto|hybrid|base|fts|rg (default: auto)
  --refresh <mode>     Index refresh: auto|force|skip (default: auto)
  --base-path <path>   Base path in vault (default: agents-config/obsidian/agents-config-index.base)
  --view <name>        Base view name (default: Agent Fast Path)
  --cache-dir <path>   Cache directory for SQLite index
  -h, --help           Show help
USAGE
}

default_cache_dir() {
  if [[ "${OSTYPE:-}" == darwin* ]]; then
    printf '%s\n' "${HOME}/Library/Caches/agents-config/obsidian-fast"
    return
  fi
  if [[ -n "${XDG_CACHE_HOME:-}" ]]; then
    printf '%s\n' "${XDG_CACHE_HOME}/agents-config/obsidian-fast"
    return
  fi
  printf '%s\n' "${HOME}/.cache/agents-config/obsidian-fast"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INDEX_REFRESH_SCRIPT="$SCRIPT_DIR/obsidian_index_refresh.sh"

QUERY=""
VAULT=""
LIMIT=8
MODE="paths"
ENGINE="auto"
REFRESH="auto"
BASE_PATH="agents-config/obsidian/agents-config-index.base"
VIEW="Agent Fast Path"
CACHE_DIR="$(default_cache_dir)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --query)
      QUERY="$2"
      shift 2
      ;;
    --vault)
      VAULT="$2"
      shift 2
      ;;
    --repo-root)
      REPO_ROOT="$2"
      shift 2
      ;;
    --limit)
      LIMIT="$2"
      shift 2
      ;;
    --mode)
      MODE="$2"
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
    --base-path)
      BASE_PATH="$2"
      shift 2
      ;;
    --view)
      VIEW="$2"
      shift 2
      ;;
    --cache-dir)
      CACHE_DIR="$2"
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

if [[ -z "$QUERY" ]]; then
  echo "--query is required." >&2
  usage
  exit 1
fi
if [[ ! "$LIMIT" =~ ^[0-9]+$ ]] || [[ "$LIMIT" -le 0 ]]; then
  echo "--limit must be a positive integer." >&2
  exit 1
fi
if [[ "$MODE" != "paths" && "$MODE" != "context" && "$MODE" != "json" ]]; then
  echo "--mode must be one of: paths, context, json" >&2
  exit 1
fi
if [[ "$ENGINE" != "auto" && "$ENGINE" != "hybrid" && "$ENGINE" != "base" && "$ENGINE" != "fts" && "$ENGINE" != "rg" ]]; then
  echo "--engine must be one of: auto, hybrid, base, fts, rg" >&2
  exit 1
fi
if [[ "$REFRESH" != "auto" && "$REFRESH" != "force" && "$REFRESH" != "skip" ]]; then
  echo "--refresh must be one of: auto, force, skip" >&2
  exit 1
fi
if [[ ! -d "$REPO_ROOT" ]]; then
  echo "Invalid --repo-root: $REPO_ROOT" >&2
  exit 1
fi

if ! mkdir -p "$CACHE_DIR" 2>/dev/null; then
  CACHE_DIR="/tmp/agents-config/obsidian-fast"
  mkdir -p "$CACHE_DIR"
fi
DB_PATH="$CACHE_DIR/index.sqlite3"

resolve_rel_abs_pairs() {
  local out_file="$1"
  local candidate_file
  candidate_file="$(mktemp)"
  trap 'rm -f "$candidate_file"' RETURN

  local has_base_candidates=0
  if command -v obsidian >/dev/null 2>&1 && [[ -n "$VAULT" ]]; then
    if obsidian vault="$VAULT" base:query path="$BASE_PATH" view="$VIEW" format=paths > "$candidate_file" 2>/dev/null; then
      if [[ -s "$candidate_file" ]]; then
        has_base_candidates=1
      fi
    fi
  fi

  if [[ "$has_base_candidates" -eq 0 ]]; then
    git -C "$REPO_ROOT" ls-files | while IFS= read -r path; do
      case "$path" in
        templates/*|scripts/*|setup_instructions*.md|README.md|AGENTS.md|obsidian/*)
          printf '%s\n' "$path"
          ;;
      esac
    done > "$candidate_file"
  fi

  sort -u "$candidate_file" | while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    if [[ -f "$REPO_ROOT/$rel" ]]; then
      printf '%s\t%s\n' "$rel" "$REPO_ROOT/$rel"
      continue
    fi
    if [[ -n "$VAULT" && -f "$VAULT/$rel" ]]; then
      printf '%s\t%s\n' "$rel" "$VAULT/$rel"
      continue
    fi
    if [[ -f "$rel" ]]; then
      printf '%s\t%s\n' "$rel" "$rel"
      continue
    fi
  done > "$out_file"
}

query_fts_json() {
  local db="$1"
  local query="$2"
  local limit="$3"
  python3 - "$db" "$query" "$limit" <<'PY'
import datetime as dt
import json
import os
import re
import sqlite3
import sys

db_path = sys.argv[1]
query = sys.argv[2]
limit = int(sys.argv[3])

if not os.path.isfile(db_path):
    print("[]")
    raise SystemExit(0)

conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row


def fallback_scan() -> list[dict]:
    q = query.lower()
    out = []
    for row in conn.execute("SELECT path, title, headings, body, bucket, mtime FROM docs"):
        body = row["body"] or ""
        title = row["title"] or ""
        headings_raw = row["headings"] or ""
        headings = [h for h in headings_raw.splitlines() if h][:6]
        text = f"{title}\n{headings_raw}\n{body}".lower()
        if q not in text:
            continue
        occ = text.count(q)
        score = float(occ * 8)
        if q in os.path.basename(row["path"]).lower():
            score += 60.0
        if q in headings_raw.lower():
            score += 25.0
        bucket_boost = {"templates": 16.0, "scripts": 13.0, "setup": 11.0, "obsidian": 9.0}
        score += bucket_boost.get((row["bucket"] or "other"), 6.0)
        snippet = ""
        for line in body.splitlines():
            if q in line.lower():
                snippet = line.strip()
                break
        if not snippet:
            snippet = " ".join(body.split())[:260]
        out.append(
            {
                "path": row["path"],
                "score": round(score, 2),
                "source": "fts",
                "headings": headings,
                "snippet": snippet[:360],
                "mtime": float(row["mtime"] or 0),
            }
        )
    out.sort(key=lambda x: (-x["score"], x["path"]))
    return out[:limit]


def tokenize(q: str) -> str:
    parts = re.findall(r"[A-Za-z0-9_./:-]+", q)
    if not parts:
        return q
    return " OR ".join(parts)


results = []
match_query = tokenize(query)
try:
    rows = conn.execute(
        """
        SELECT d.path, d.title, d.headings, d.body, d.bucket, d.mtime, bm25(docs_fts) AS bm
        FROM docs_fts
        JOIN docs d ON d.id = docs_fts.rowid
        WHERE docs_fts MATCH ?
        LIMIT 300
        """,
        (match_query,),
    ).fetchall()
except sqlite3.Error:
    rows = []

if not rows:
    results = fallback_scan()
    print(json.dumps(results, ensure_ascii=True))
    conn.close()
    raise SystemExit(0)

now = dt.datetime.now().timestamp()
for row in rows:
    path = row["path"]
    title = row["title"] or ""
    headings_raw = row["headings"] or ""
    headings = [h for h in headings_raw.splitlines() if h][:6]
    body = row["body"] or ""
    bucket = row["bucket"] or "other"
    mtime = float(row["mtime"] or 0)
    bm = float(row["bm"] or 1000.0)
    if bm < 0:
        bm = 0.0

    base = max(0.0, 110.0 - (bm * 12.0))
    ql = query.lower()
    score = base

    if ql in os.path.basename(path).lower():
        score += 60.0
    if ql in title.lower():
        score += 30.0
    if ql in headings_raw.lower():
        score += 25.0

    bucket_boost = {"templates": 16.0, "scripts": 13.0, "setup": 11.0, "obsidian": 9.0}
    score += bucket_boost.get(bucket, 6.0)

    age_days = max(0.0, (now - mtime) / 86400.0)
    score += max(0.0, 8.0 - min(8.0, age_days / 30.0))

    snippet = ""
    for line in body.splitlines():
        if ql in line.lower():
            snippet = line.strip()
            break
    if not snippet:
        snippet = " ".join(body.split())[:260]

    results.append(
        {
            "path": path,
            "score": round(score, 2),
            "source": "fts",
            "headings": headings,
            "snippet": snippet[:360],
            "mtime": mtime,
        }
    )

results.sort(key=lambda x: (-x["score"], x["path"]))
print(json.dumps(results[:limit], ensure_ascii=True))
conn.close()
PY
}

query_scan_json() {
  local pairs_file="$1"
  local query="$2"
  local limit="$3"
  local source="$4"
  python3 - "$pairs_file" "$query" "$limit" "$source" <<'PY'
import json
import os
import re
import sys
import time

pairs_file = sys.argv[1]
query = sys.argv[2]
limit = int(sys.argv[3])
source = sys.argv[4]
ql = query.lower()

pairs: list[tuple[str, str]] = []
with open(pairs_file, "r", encoding="utf-8", errors="ignore") as f:
    for line in f:
        line = line.rstrip("\n")
        if not line:
            continue
        rel, abs_path = line.split("\t", 1)
        pairs.append((rel, abs_path))


def bucket_for(path: str) -> str:
    if path.startswith("templates/"):
        return "templates"
    if path.startswith("scripts/"):
        return "scripts"
    if path.startswith("obsidian/"):
        return "obsidian"
    if path.startswith("setup_instructions"):
        return "setup"
    return "other"


results = []
for rel, abs_path in pairs:
    if not os.path.isfile(abs_path):
        continue
    try:
        st = os.stat(abs_path)
    except OSError:
        continue
    if st.st_size > 2_000_000:
        continue
    ext = os.path.splitext(rel)[1].lower()
    if ext in {".png", ".jpg", ".jpeg", ".gif", ".webp", ".pdf", ".ico"}:
        continue
    try:
        with open(abs_path, "r", encoding="utf-8", errors="ignore") as f:
            text = f.read()
    except OSError:
        continue
    lower = text.lower()
    if ql not in lower:
        continue

    occ = lower.count(ql)
    headings = []
    for line in text.splitlines():
        if re.match(r"^\s{0,3}#{1,3}\s+.+", line):
            headings.append(re.sub(r"^\s{0,3}#{1,3}\s+", "", line).strip())
        if len(headings) >= 6:
            break
    snippet = ""
    for line in text.splitlines():
        if ql in line.lower():
            snippet = line.strip()
            break
    if not snippet:
        snippet = " ".join(text.split())[:260]

    score = float(occ * 8)
    if ql in os.path.basename(rel).lower():
        score += 60.0
    joined_headings = "\n".join(headings).lower()
    if ql in joined_headings:
        score += 25.0
    bucket_boost = {"templates": 16.0, "scripts": 13.0, "setup": 11.0, "obsidian": 9.0}
    score += bucket_boost.get(bucket_for(rel), 6.0)
    age_days = max(0.0, (time.time() - float(st.st_mtime)) / 86400.0)
    score += max(0.0, 8.0 - min(8.0, age_days / 30.0))

    results.append(
        {
            "path": rel,
            "score": round(score, 2),
            "source": source,
            "headings": headings,
            "snippet": snippet[:360],
            "mtime": float(st.st_mtime),
        }
    )

results.sort(key=lambda x: (-x["score"], x["path"]))
print(json.dumps(results[:limit], ensure_ascii=True))
PY
}

run_index_refresh() {
  local force_flag=""
  if [[ "$REFRESH" == "force" ]]; then
    force_flag="--force-full"
  fi

  if [[ ! -x "$INDEX_REFRESH_SCRIPT" ]]; then
    echo ""
    return
  fi

  if ! out="$("$INDEX_REFRESH_SCRIPT" \
      --repo-root "$REPO_ROOT" \
      --cache-dir "$CACHE_DIR" \
      --base-path "$BASE_PATH" \
      --view "$VIEW" \
      ${VAULT:+--vault "$VAULT"} \
      $force_flag 2>/dev/null)"; then
    echo ""
    return
  fi
  printf '%s\n' "$out"
}

read_refresh_date() {
  if [[ ! -f "$DB_PATH" ]]; then
    printf '%s\n' ""
    return
  fi
  sqlite3 "$DB_PATH" "SELECT value FROM meta WHERE key='last_refresh_date' LIMIT 1;" 2>/dev/null || true
}

t_start_ms="$(python3 - <<'PY'
import time
print(int(time.time() * 1000))
PY
)"

refreshed="false"
refresh_meta_json=""
today="$(date +%F)"
if [[ "$REFRESH" == "force" ]]; then
  refresh_meta_json="$(run_index_refresh || true)"
  [[ -n "$refresh_meta_json" ]] && refreshed="true"
elif [[ "$REFRESH" == "auto" && ( "$ENGINE" == "auto" || "$ENGINE" == "hybrid" || "$ENGINE" == "fts" ) ]]; then
  last_refresh_date="$(read_refresh_date)"
  if [[ "$last_refresh_date" != "$today" || ! -f "$DB_PATH" ]]; then
    refresh_meta_json="$(run_index_refresh || true)"
    [[ -n "$refresh_meta_json" ]] && refreshed="true"
  fi
fi

pairs_file="$(mktemp)"
trap 'rm -f "$pairs_file"' EXIT
resolve_rel_abs_pairs "$pairs_file"

actual_engine=""
results_json="[]"

if [[ "$ENGINE" == "base" ]]; then
  results_json="$(query_scan_json "$pairs_file" "$QUERY" "$LIMIT" "base")"
  actual_engine="base"
elif [[ "$ENGINE" == "rg" ]]; then
  results_json="$(query_scan_json "$pairs_file" "$QUERY" "$LIMIT" "rg")"
  actual_engine="rg"
elif [[ "$ENGINE" == "fts" ]]; then
  if [[ ! -f "$DB_PATH" ]]; then
    if [[ "$REFRESH" == "skip" ]]; then
      echo "FTS database not found. Re-run with --refresh auto|force or run obsidian_index_refresh.sh first." >&2
      exit 1
    fi
    refresh_meta_json="$(run_index_refresh || true)"
    [[ -n "$refresh_meta_json" ]] && refreshed="true"
  fi
  results_json="$(query_fts_json "$DB_PATH" "$QUERY" "$LIMIT")"
  actual_engine="fts"
elif [[ "$ENGINE" == "hybrid" || "$ENGINE" == "auto" ]]; then
  if [[ -f "$DB_PATH" ]]; then
    results_json="$(query_fts_json "$DB_PATH" "$QUERY" "$LIMIT")"
    if [[ "$results_json" != "[]" ]]; then
      actual_engine="hybrid"
    fi
  fi
  if [[ -z "$actual_engine" ]]; then
    results_json="$(query_scan_json "$pairs_file" "$QUERY" "$LIMIT" "rg")"
    actual_engine="rg"
  fi
fi

t_end_ms="$(python3 - <<'PY'
import time
print(int(time.time() * 1000))
PY
)"
took_ms=$((t_end_ms - t_start_ms))

if [[ "$MODE" == "paths" ]]; then
  python3 - "$results_json" <<'PY'
import json
import sys
results = json.loads(sys.argv[1])
for item in results:
    print(item["path"])
PY
  exit 0
fi

if [[ "$MODE" == "context" ]]; then
  python3 - "$results_json" <<'PY'
import json
import sys
results = json.loads(sys.argv[1])
if not results:
    print("No matches.")
    raise SystemExit(0)
for item in results:
    print(f"### {item['path']}")
    print(f"- score: {item['score']}")
    print(f"- source: {item['source']}")
    print("- headings:")
    headings = item.get("headings") or []
    if not headings:
        print("  (none)")
    else:
        for h in headings[:6]:
            print(f"  {h}")
    print("- snippet:")
    snippet = item.get("snippet", "").strip()
    print(snippet if snippet else "(none)")
    print()
PY
  exit 0
fi

python3 - "$actual_engine" "$QUERY" "$took_ms" "$refreshed" "$results_json" <<'PY'
import json
import sys
payload = {
    "engine": sys.argv[1],
    "query": sys.argv[2],
    "took_ms": int(sys.argv[3]),
    "refreshed": sys.argv[4].lower() == "true",
    "results": json.loads(sys.argv[5]),
}
print(json.dumps(payload, ensure_ascii=True))
PY

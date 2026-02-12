#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  obsidian_index_refresh.sh [options]

Options:
  --vault <path>       Obsidian vault root (optional)
  --repo-root <path>   Repository root (default: script parent)
  --base-path <path>   Base path in vault (default: agents-config/obsidian/agents-config-index.base)
  --view <name>        Base view name (default: Agent Fast Path)
  --cache-dir <path>   Cache directory for SQLite index
  --force-full         Rebuild index from scratch
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
VAULT=""
BASE_PATH="agents-config/obsidian/agents-config-index.base"
VIEW="Agent Fast Path"
CACHE_DIR="$(default_cache_dir)"
FORCE_FULL=0

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
    --force-full)
      FORCE_FULL=1
      shift
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

if [[ ! -d "$REPO_ROOT" ]]; then
  echo "Invalid --repo-root: $REPO_ROOT" >&2
  exit 1
fi

if ! mkdir -p "$CACHE_DIR" 2>/dev/null; then
  CACHE_DIR="/tmp/agents-config/obsidian-fast"
  mkdir -p "$CACHE_DIR"
fi
DB_PATH="$CACHE_DIR/index.sqlite3"

collect_base_candidates() {
  if ! command -v obsidian >/dev/null 2>&1; then
    return 1
  fi
  if [[ -z "$VAULT" ]]; then
    return 1
  fi
  obsidian vault="$VAULT" base:query path="$BASE_PATH" view="$VIEW" format=paths 2>/dev/null
}

collect_git_candidates() {
  git -C "$REPO_ROOT" ls-files | while IFS= read -r path; do
    case "$path" in
      templates/*|scripts/*|setup_instructions*.md|README.md|AGENTS.md|obsidian/*)
        printf '%s\n' "$path"
        ;;
    esac
  done
}

resolve_path() {
  local rel="$1"
  if [[ -f "$REPO_ROOT/$rel" ]]; then
    printf '%s\n' "$REPO_ROOT/$rel"
    return 0
  fi
  if [[ -n "$VAULT" && -f "$VAULT/$rel" ]]; then
    printf '%s\n' "$VAULT/$rel"
    return 0
  fi
  if [[ -f "$rel" ]]; then
    printf '%s\n' "$rel"
    return 0
  fi
  return 1
}

tmp_candidates="$(mktemp)"
tmp_resolved="$(mktemp)"
trap 'rm -f "$tmp_candidates" "$tmp_resolved"' EXIT

if ! collect_base_candidates > "$tmp_candidates" || [[ ! -s "$tmp_candidates" ]]; then
  collect_git_candidates > "$tmp_candidates"
fi

if [[ ! -s "$tmp_candidates" ]]; then
  echo "No candidate files were discovered for indexing." >&2
  exit 1
fi

while IFS= read -r rel; do
  [[ -z "$rel" ]] && continue
  abs="$(resolve_path "$rel" || true)"
  [[ -z "$abs" ]] && continue
  printf '%s\t%s\n' "$rel" "$abs"
done < <(sort -u "$tmp_candidates") > "$tmp_resolved"

if [[ ! -s "$tmp_resolved" ]]; then
  echo "No resolvable candidate files found." >&2
  exit 1
fi

python3 - "$DB_PATH" "$tmp_resolved" "$FORCE_FULL" <<'PY'
import hashlib
import json
import os
import re
import sqlite3
import sys
import time
from datetime import datetime

db_path = sys.argv[1]
resolved_path = sys.argv[2]
force_full = sys.argv[3] == "1"


def read_text(path: str) -> str:
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        return f.read()


def extract_title(text: str, rel_path: str) -> str:
    for line in text.splitlines():
        if re.match(r"^\s{0,3}#\s+.+", line):
            return re.sub(r"^\s{0,3}#\s+", "", line).strip()
    return os.path.basename(rel_path)


def extract_headings(text: str) -> list[str]:
    headings = []
    for line in text.splitlines():
        if re.match(r"^\s{0,3}#{1,3}\s+.+", line):
            headings.append(re.sub(r"^\s{0,3}#{1,3}\s+", "", line).strip())
        if len(headings) >= 12:
            break
    return headings


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


def sha1_text(text: str) -> str:
    return hashlib.sha1(text.encode("utf-8")).hexdigest()


pairs: list[tuple[str, str]] = []
with open(resolved_path, "r", encoding="utf-8", errors="ignore") as f:
    for line in f:
        line = line.rstrip("\n")
        if not line:
            continue
        rel, abs_path = line.split("\t", 1)
        pairs.append((rel, abs_path))

now_date = datetime.now().strftime("%Y-%m-%d")
conn = sqlite3.connect(db_path)
conn.execute("PRAGMA journal_mode=WAL")
conn.execute("PRAGMA synchronous=NORMAL")
conn.execute(
    """
    CREATE TABLE IF NOT EXISTS docs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      path TEXT NOT NULL UNIQUE,
      abs_path TEXT NOT NULL,
      mtime REAL NOT NULL,
      size INTEGER NOT NULL,
      hash TEXT NOT NULL,
      title TEXT NOT NULL,
      headings TEXT NOT NULL,
      bucket TEXT NOT NULL,
      body TEXT NOT NULL
    )
"""
)
conn.execute("CREATE VIRTUAL TABLE IF NOT EXISTS docs_fts USING fts5(path, title, headings, body)")
conn.execute("CREATE TABLE IF NOT EXISTS meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)")

if force_full:
    conn.execute("DELETE FROM docs_fts")
    conn.execute("DELETE FROM docs")

existing = {
    row[0]: {
        "id": row[1],
        "mtime": float(row[2]),
        "size": int(row[3]),
        "hash": row[4],
    }
    for row in conn.execute("SELECT path, id, mtime, size, hash FROM docs")
}

candidate_paths = {rel for rel, _ in pairs}
removed = 0
for old_path, old_meta in list(existing.items()):
    if old_path not in candidate_paths:
        conn.execute("DELETE FROM docs_fts WHERE rowid = ?", (old_meta["id"],))
        conn.execute("DELETE FROM docs WHERE id = ?", (old_meta["id"],))
        removed += 1

changed = 0
indexed = 0
for rel_path, abs_path in pairs:
    if not os.path.isfile(abs_path):
        continue
    if os.path.getsize(abs_path) > 2_000_000:
        continue
    ext = os.path.splitext(rel_path)[1].lower()
    if ext in {".png", ".jpg", ".jpeg", ".gif", ".webp", ".pdf", ".ico"}:
        continue

    st = os.stat(abs_path)
    mtime = float(st.st_mtime)
    size = int(st.st_size)
    current = existing.get(rel_path)

    if current and not force_full and current["mtime"] == mtime and current["size"] == size:
        indexed += 1
        continue

    text = read_text(abs_path)
    if len(text) > 200_000:
        text = text[:200_000]
    digest = sha1_text(text)

    if current and not force_full and current["hash"] == digest:
        conn.execute(
            "UPDATE docs SET abs_path = ?, mtime = ?, size = ? WHERE path = ?",
            (abs_path, mtime, size, rel_path),
        )
        indexed += 1
        continue

    title = extract_title(text, rel_path)
    headings = extract_headings(text)
    headings_blob = "\n".join(headings)
    bucket = bucket_for(rel_path)

    conn.execute(
        """
        INSERT INTO docs(path, abs_path, mtime, size, hash, title, headings, bucket, body)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(path) DO UPDATE SET
          abs_path=excluded.abs_path,
          mtime=excluded.mtime,
          size=excluded.size,
          hash=excluded.hash,
          title=excluded.title,
          headings=excluded.headings,
          bucket=excluded.bucket,
          body=excluded.body
    """,
        (rel_path, abs_path, mtime, size, digest, title, headings_blob, bucket, text),
    )
    doc_id = conn.execute("SELECT id FROM docs WHERE path = ?", (rel_path,)).fetchone()[0]
    conn.execute("DELETE FROM docs_fts WHERE rowid = ?", (doc_id,))
    conn.execute(
        "INSERT INTO docs_fts(rowid, path, title, headings, body) VALUES (?, ?, ?, ?, ?)",
        (doc_id, rel_path, title, headings_blob, text),
    )
    changed += 1
    indexed += 1

conn.execute(
    "INSERT INTO meta(key, value) VALUES('schema_version', '1') ON CONFLICT(key) DO UPDATE SET value=excluded.value"
)
conn.execute(
    "INSERT INTO meta(key, value) VALUES('last_refresh_date', ?) ON CONFLICT(key) DO UPDATE SET value=excluded.value",
    (now_date,),
)
conn.execute(
    "INSERT INTO meta(key, value) VALUES('last_refresh_epoch', ?) ON CONFLICT(key) DO UPDATE SET value=excluded.value",
    (str(time.time()),),
)
conn.commit()

summary = {
    "indexed": indexed,
    "changed": changed,
    "removed": removed,
    "db_path": db_path,
    "last_refresh_date": now_date,
    "force_full": force_full,
}
print(json.dumps(summary, ensure_ascii=True))
conn.close()
PY

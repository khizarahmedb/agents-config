#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  apply_repo_agent_policy.sh --workspace-root <path> --repo-root <path>

Description:
  Idempotently applies local AGENTS policy to a repository:
  - Ensures .gitignore contains /docs/, AGENT*.md, .agentsmd
  - Creates AGENTS.md and AGENT_NOTES.md if missing
  - Untracks already-tracked AGENT*.md/.agentsmd files
USAGE
}

WORKSPACE_ROOT=""
REPO_ROOT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace-root)
      WORKSPACE_ROOT="$2"
      shift 2
      ;;
    --repo-root)
      REPO_ROOT="$2"
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

if [[ -z "$WORKSPACE_ROOT" || -z "$REPO_ROOT" ]]; then
  echo "Both --workspace-root and --repo-root are required." >&2
  usage
  exit 1
fi

mkdir -p "$REPO_ROOT"

GITIGNORE="$REPO_ROOT/.gitignore"
touch "$GITIGNORE"

ensure_line() {
  local line="$1"
  if ! grep -Fxq "$line" "$GITIGNORE"; then
    printf '%s\n' "$line" >> "$GITIGNORE"
  fi
}

ensure_line "/docs/"
ensure_line "AGENT*.md"
ensure_line ".agentsmd"

if [[ ! -f "$REPO_ROOT/AGENTS.md" ]]; then
  cat > "$REPO_ROOT/AGENTS.md" <<TEMPLATE
# Repo Agent Instructions

1. At conversation start, read AGENT_NOTES.md before proposing or writing changes.
2. If skills.md exists, use relevant skills/workflows.
3. Prefer retrieval-led reasoning over pre-training-led reasoning for framework/version-sensitive tasks.
4. Keep instructions compact and fetch detailed docs on demand.
5. Append stable repo preferences to AGENT_NOTES.md with date and rationale.
6. Never store secrets in notes.
7. If repo notes are insufficient, consult $WORKSPACE_ROOT/AGENT_NOTES_GLOBAL.md.
8. Reference global notes instead of duplicating them in this repo.
TEMPLATE
fi

if [[ ! -f "$REPO_ROOT/AGENT_NOTES.md" ]]; then
  cat > "$REPO_ROOT/AGENT_NOTES.md" <<TEMPLATE
# Agent Notes

- $(date +%F): Repository bootstrapped with standard local AGENTS policy. Rationale: ensure deterministic agent behavior from first task.
- Reference: Shared/global preferences live in $WORKSPACE_ROOT/AGENT_NOTES_GLOBAL.md.
TEMPLATE
fi

if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  while IFS= read -r -d '' tracked_file; do
    git -C "$REPO_ROOT" rm --cached --ignore-unmatch -- "$tracked_file" >/dev/null 2>&1 || true
  done < <(git -C "$REPO_ROOT" ls-files -z -- 'AGENT*.md' '.agentsmd')
fi

echo "Applied policy to: $REPO_ROOT"
echo "- ensured .gitignore: /docs/, AGENT*.md, .agentsmd"
echo "- ensured AGENTS.md and AGENT_NOTES.md exist"
echo "- untracked AGENT*.md/.agentsmd where previously tracked"

#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  apply_repo_agent_policy.sh --workspace-root <path> --repo-root <path>

Description:
  Idempotently applies local AGENTS policy to a repository:
  - Ensures .gitignore contains /docs/, AGENT_NOTES*.md, .agentsmd
  - Creates AGENTS.md and AGENT_NOTES.md if missing
  - Untracks already-tracked AGENT_NOTES*.md/.agentsmd files
USAGE
}

WORKSPACE_ROOT=""
REPO_ROOT=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_REPO_AGENTS="$SCRIPT_DIR/../templates/repo/AGENTS.md.template"
TEMPLATE_REPO_NOTES="$SCRIPT_DIR/../templates/repo/AGENT_NOTES.md.template"

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

for template in "$TEMPLATE_REPO_AGENTS" "$TEMPLATE_REPO_NOTES"; do
  if [[ ! -f "$template" ]]; then
    echo "Missing required template: $template" >&2
    exit 1
  fi
done

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
ensure_line "AGENT_NOTES*.md"
ensure_line ".agentsmd"

escape_sed_replacement() {
  printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
}

render_template() {
  local template="$1"
  local output="$2"
  local escaped_workspace_root
  local escaped_date

  escaped_workspace_root="$(escape_sed_replacement "$WORKSPACE_ROOT")"
  escaped_date="$(escape_sed_replacement "$(date +%F)")"

  sed \
    -e "s/{{WORKSPACE_ROOT}}/${escaped_workspace_root}/g" \
    -e "s/{{DATE}}/${escaped_date}/g" \
    "$template" > "$output"
}

if [[ ! -f "$REPO_ROOT/AGENTS.md" ]]; then
  render_template "$TEMPLATE_REPO_AGENTS" "$REPO_ROOT/AGENTS.md"
fi

if [[ ! -f "$REPO_ROOT/AGENT_NOTES.md" ]]; then
  render_template "$TEMPLATE_REPO_NOTES" "$REPO_ROOT/AGENT_NOTES.md"
fi

if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  while IFS= read -r -d '' tracked_file; do
    git -C "$REPO_ROOT" rm --cached --ignore-unmatch -- "$tracked_file" >/dev/null 2>&1 || true
  done < <(git -C "$REPO_ROOT" ls-files -z -- 'AGENT_NOTES*.md' '**/AGENT_NOTES*.md' '.agentsmd' '**/.agentsmd')
fi

echo "Applied policy to: $REPO_ROOT"
echo "- ensured .gitignore: /docs/, AGENT_NOTES*.md, .agentsmd"
echo "- ensured AGENTS.md and AGENT_NOTES.md exist"
echo "- untracked AGENT_NOTES*.md/.agentsmd where previously tracked"

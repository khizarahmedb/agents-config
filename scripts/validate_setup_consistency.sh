#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required_files=(
  "$ROOT_DIR/setup_instructions.md"
  "$ROOT_DIR/setup_instructions_ubuntu.md"
  "$ROOT_DIR/setup_instructions_win.md"
  "$ROOT_DIR/scripts/apply_repo_agent_policy.sh"
  "$ROOT_DIR/scripts/apply_repo_agent_policy.ps1"
  "$ROOT_DIR/templates/global/AGENTS.md.template"
  "$ROOT_DIR/templates/global/AGENT_NOTES_GLOBAL.md.template"
  "$ROOT_DIR/templates/repo/AGENTS.md.template"
  "$ROOT_DIR/templates/repo/AGENT_NOTES.md.template"
  "$ROOT_DIR/README.md"
)

for f in "${required_files[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "Missing required file: $f" >&2
    exit 1
  fi
done

bash -n "$ROOT_DIR/scripts/apply_repo_agent_policy.sh"

required_tokens=(
  "AGENT_NOTES*.md"
  ".agentsmd"
  "/docs/"
  "last_config_sync_date"
  "last_global_config_review_date"
  "last_global_config_review_repo"
  "read-only"
  "Review guidelines"
)

for doc in "$ROOT_DIR/setup_instructions.md" "$ROOT_DIR/setup_instructions_ubuntu.md" "$ROOT_DIR/setup_instructions_win.md"; do
  for token in "${required_tokens[@]}"; do
    if ! grep -Fq "$token" "$doc"; then
      echo "Missing token '$token' in $doc" >&2
      exit 1
    fi
  done
done

if grep -n "<[^>]\+>/" "$ROOT_DIR/setup_instructions_win.md" >/dev/null; then
  echo "Windows setup doc contains Unix-style placeholder separators." >&2
  exit 1
fi

tmp_root="$(mktemp -d)"
workspace="$tmp_root/workspace"
repo="$workspace/sample-repo"
mkdir -p "$repo"

"$ROOT_DIR/scripts/apply_repo_agent_policy.sh" --workspace-root "$workspace" --repo-root "$repo" >/dev/null
"$ROOT_DIR/scripts/apply_repo_agent_policy.sh" --workspace-root "$workspace" --repo-root "$repo" >/dev/null

if [[ "$(grep -Fxc '/docs/' "$repo/.gitignore")" -ne 1 ]]; then
  echo "Non-idempotent /docs/ entry in generated .gitignore" >&2
  exit 1
fi
if [[ "$(grep -Fxc 'AGENT_NOTES*.md' "$repo/.gitignore")" -ne 1 ]]; then
  echo "Non-idempotent AGENT_NOTES*.md entry in generated .gitignore" >&2
  exit 1
fi
if [[ "$(grep -Fxc '.agentsmd' "$repo/.gitignore")" -ne 1 ]]; then
  echo "Non-idempotent .agentsmd entry in generated .gitignore" >&2
  exit 1
fi

if ! grep -Fq "$workspace/AGENT_NOTES_GLOBAL.md" "$repo/AGENTS.md"; then
  echo "Generated repo AGENTS.md does not interpolate workspace path." >&2
  exit 1
fi
if ! grep -Fq "$workspace/AGENT_NOTES_GLOBAL.md" "$repo/AGENT_NOTES.md"; then
  echo "Generated repo AGENT_NOTES.md does not interpolate workspace path." >&2
  exit 1
fi

# Verify recursive untracking removes nested AGENT_NOTES*.md but preserves AGENTS.md.
mkdir -p "$repo/sub"
printf 'nested note\n' > "$repo/sub/AGENT_NOTES_EXTRA.md"
git -C "$repo" init -q
git -C "$repo" config user.email "validate@example.com"
git -C "$repo" config user.name "validate"
git -C "$repo" add -f AGENTS.md AGENT_NOTES.md sub/AGENT_NOTES_EXTRA.md
git -C "$repo" commit -qm "seed tracked notes"

"$ROOT_DIR/scripts/apply_repo_agent_policy.sh" --workspace-root "$workspace" --repo-root "$repo" >/dev/null

if git -C "$repo" ls-files --error-unmatch AGENT_NOTES.md >/dev/null 2>&1; then
  echo "AGENT_NOTES.md should be untracked after policy application" >&2
  exit 1
fi
if git -C "$repo" ls-files --error-unmatch sub/AGENT_NOTES_EXTRA.md >/dev/null 2>&1; then
  echo "Nested AGENT_NOTES file should be untracked after policy application" >&2
  exit 1
fi
if ! git -C "$repo" ls-files --error-unmatch AGENTS.md >/dev/null 2>&1; then
  echo "AGENTS.md should remain tracked for Codex review guidance" >&2
  exit 1
fi

echo "setup consistency checks passed"

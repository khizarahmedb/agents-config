#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  install_grounded.sh [--scope repo|global] [--repo-root <path>] [--agents <csv>] [--with-global-git-template]

Examples:
  install_grounded.sh --scope global --agents all --with-global-git-template
  install_grounded.sh --scope repo --repo-root /path/to/repo --agents codex,opencode
USAGE
}

SCOPE="global"
REPO_ROOT=""
AGENTS="all"
WITH_GLOBAL_GIT_TEMPLATE="false"
GROUNDED_REPO="git+https://github.com/flow-grammer/grounded.git"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope)
      SCOPE="$2"
      shift 2
      ;;
    --repo-root)
      REPO_ROOT="$2"
      shift 2
      ;;
    --agents)
      AGENTS="$2"
      shift 2
      ;;
    --with-global-git-template)
      WITH_GLOBAL_GIT_TEMPLATE="true"
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

if ! command -v pipx >/dev/null 2>&1; then
  echo "pipx is required. Install pipx first." >&2
  exit 1
fi

pipx install --force "$GROUNDED_REPO"

if [[ "$SCOPE" == "global" ]]; then
  cmd=(grounded install --scope global --agents "$AGENTS")
  if [[ "$WITH_GLOBAL_GIT_TEMPLATE" == "true" ]]; then
    cmd+=(--global-git-template)
  fi
  "${cmd[@]}"
  exit 0
fi

if [[ -z "$REPO_ROOT" ]]; then
  echo "--repo-root is required when --scope repo" >&2
  exit 1
fi

grounded install --scope repo --path "$REPO_ROOT" --agents "$AGENTS"

# agents-config

Portable AGENTS.md configuration standard for local-first, cross-tool AI workflows.

## Quick Start

macOS/Linux:

```bash
bash ./scripts/apply_repo_agent_policy.sh \
  --workspace-root /path/to/workspace \
  --repo-root /path/to/repo
```

Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\apply_repo_agent_policy.ps1 \
  -WorkspaceRoot C:\path\to\workspace \
  -RepoRoot C:\path\to\repo
```

## Core Files

- `setup_instructions.md`: full setup profile (macOS/Linux)
- `setup_instructions_ubuntu.md`: Ubuntu-specific commands
- `setup_instructions_win.md`: Windows-specific commands
- `scripts/apply_repo_agent_policy.sh`: idempotent repo policy bootstrap (Unix)
- `scripts/apply_repo_agent_policy.ps1`: idempotent repo policy bootstrap (Windows)

## Design Principles

- Keep AGENTS guidance local and untracked by default (`AGENT*.md`, `.agentsmd`).
- Use read-only daily sync from this repo in consumer workspaces.
- Prefer compact docs indexes + retrieval-on-demand over long inline context.
- Convert repeated user feedback into dated notes immediately.

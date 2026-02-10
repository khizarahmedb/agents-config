# agents-config

This project is a portable AGENTS configuration system for setting up AI coding agents consistently across repositories.

The setup profile is designed so a user can copy and paste one markdown file into an AI agent and have the full config applied end-to-end.

## Primary Setup Method (Copy-Paste to AI)

1. Choose one file based on OS:
   - `setup_instructions.md` (macOS/Linux generic)
   - `setup_instructions_ubuntu.md` (Ubuntu)
   - `setup_instructions_win.md` (Windows)
2. Open your agent harness session in the target workspace.
3. Paste the entire chosen markdown file into the AI.
4. Ask the AI to execute it exactly and report created/updated files.

Recommended runtime profile:
- Model: prefer Codex GPT-5.3 class model if available.
- Access: full filesystem access preferred.
- Reasoning/effort: high or extra-high mode preferred.
- Harness: one that supports or is standardized around `AGENTS.md`.

## What The Setup Creates/Enforces

- Workspace-level canonical files:
  - `AGENTS.md`
  - `AGENT_NOTES_GLOBAL.md`
- Repo-level bootstrap behavior:
  - create `AGENTS.md` + `AGENT_NOTES.md` when missing
  - preserve existing repo AGENTS instructions when present
- Default local-only policy:
  - `.gitignore` includes `/docs/`, `AGENT*.md`, `.agentsmd`
  - agent notes/instructions are untracked unless explicitly requested otherwise
- Daily read-only sync from this repository on first conversation of a new date
- Compact docs-index + retrieval-led workflow to reduce token/context bloat
- Explicit behavioral adaptation loop (feedback -> note update -> immediate application)

## Automation Layer

The project includes idempotent bootstrap scripts for faster setup in new repositories.

Files:
- `scripts/apply_repo_agent_policy.sh` (macOS/Linux)
- `scripts/apply_repo_agent_policy.ps1` (Windows PowerShell)

These scripts:
- ensure `.gitignore` contains `/docs/`, `AGENT*.md`, `.agentsmd`
- create repo `AGENTS.md` and `AGENT_NOTES.md` if missing
- untrack already-tracked `AGENT*.md`/`.agentsmd` files without deleting local copies

macOS/Linux usage:

```bash
bash ./scripts/apply_repo_agent_policy.sh \
  --workspace-root /path/to/workspace \
  --repo-root /path/to/repo
```

Windows usage:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\apply_repo_agent_policy.ps1 \
  -WorkspaceRoot C:\path\to\workspace \
  -RepoRoot C:\path\to\repo
```

## File Map

- `setup_instructions.md`: main setup profile for macOS/Linux
- `setup_instructions_ubuntu.md`: Ubuntu-specific profile
- `setup_instructions_win.md`: Windows-specific profile
- `scripts/apply_repo_agent_policy.sh`: Unix bootstrap automation
- `scripts/apply_repo_agent_policy.ps1`: Windows bootstrap automation

## Operational Notes

- This repository is intended as a canonical reference for consumers.
- Consumer environments should pull updates read-only (daily), not auto-push.
- If your policy changes, update setup instruction files first, then scripts if needed.

## Updates

- 2026-02-10 | Added copy-paste-first setup guidance and runtime profile recommendations | Why: make onboarding deterministic across agent harnesses | Commit: `5259ef9`
- 2026-02-10 | Added idempotent bootstrap automation scripts (`.sh` + `.ps1`) and fast-path docs | Why: reduce setup drift, steps, and token usage | Commit: `1932bb0`
- 2026-02-10 | Added behavioral adaptation loop and token-efficiency protocol to setup docs | Why: improve iterative alignment and context efficiency | Commit: `8053028`
- 2026-02-10 | Hardened setup docs and local ignore defaults (`AGENT*.md`, `.agentsmd`) | Why: keep local agent memory private and standardized | Commit: `16754e9`

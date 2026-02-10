# agents-config

This project is a portable AGENTS configuration system for setting up AI coding agents consistently across repositories with deterministic terminal commands.

## Primary Setup Method (Terminal-First with Bun)

1. Clone this repository:

```bash
git clone https://github.com/khizarahmedb/agents-config.git
cd agents-config
```

2. Run deterministic setup:

```bash
bun run agents setup --workspace-root /path/to/workspace --repo-root /path/to/target-repo
```

3. Validate setup:

```bash
bun run agents validate
```

## Secondary Method (Copy-Paste to AI)

Use this only when direct terminal execution is unavailable.

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
- Canonical template sources (committed in this repo):
  - `templates/global/AGENTS.md.template`
  - `templates/global/AGENT_NOTES_GLOBAL.md.template`
  - `templates/repo/AGENTS.md.template`
  - `templates/repo/AGENT_NOTES.md.template`
- Repo-level bootstrap behavior:
  - create `AGENTS.md` + `AGENT_NOTES.md` when missing
  - preserve existing repo AGENTS instructions when present
- Default tracking policy:
  - `AGENTS.md` stays tracked in each repository for Codex review guidance
  - `.gitignore` includes `/docs/`, `AGENT_NOTES*.md`, `.agentsmd`
  - tracked local notes (`AGENT_NOTES*.md`, `.agentsmd`) are untracked unless explicitly requested otherwise
- Daily read-only sync from this repository on first conversation of a new date
- Compact docs-index + retrieval-led workflow to reduce token/context bloat
- Explicit behavioral adaptation loop (feedback -> note update -> immediate application)
- Repo `AGENTS.md` template includes mandatory `## Review guidelines` for `@codex review`

## Automation Layer

The project includes a Bun CLI for cross-platform setup, plus shell/PowerShell fallbacks.

Files:
- `cli.ts` (Bun CLI, cross-platform)
- `package.json` (Bun scripts)
- `scripts/apply_repo_agent_policy.sh` (macOS/Linux)
- `scripts/apply_repo_agent_policy.ps1` (Windows PowerShell)
- `scripts/validate_setup_consistency.sh` (macOS/Linux validation)
- `scripts/validate_setup_consistency.ps1` (Windows validation)

The Bun CLI:
- `bun run agents setup --workspace-root <path> --repo-root <path>`
- `bun run agents workspace-init --workspace-root <path>`
- `bun run agents apply --workspace-root <path> --repo-root <path>`
- `bun run agents validate`

Legacy scripts:
- ensure `.gitignore` contains `/docs/`, `AGENT_NOTES*.md`, `.agentsmd`
- create repo `AGENTS.md` and `AGENT_NOTES.md` if missing
- keep `AGENTS.md` tracked and untrack already-tracked `AGENT_NOTES*.md`/`.agentsmd` files without deleting local copies

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

Deterministic validation (macOS/Linux):

```bash
bash ./scripts/validate_setup_consistency.sh
```

Deterministic validation (Windows):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_setup_consistency.ps1
```

## File Map

- `setup_instructions.md`: main setup profile for macOS/Linux
- `setup_instructions_ubuntu.md`: Ubuntu-specific profile
- `setup_instructions_win.md`: Windows-specific profile
- `cli.ts`: Bun CLI for deterministic cross-platform setup
- `package.json`: Bun scripts and CLI entry
- `scripts/apply_repo_agent_policy.sh`: Unix bootstrap automation
- `scripts/apply_repo_agent_policy.ps1`: Windows bootstrap automation
- `scripts/validate_setup_consistency.sh`: Unix setup consistency checks
- `scripts/validate_setup_consistency.ps1`: Windows setup consistency checks
- `templates/global/`: canonical global AGENTS/notes templates
- `templates/repo/`: canonical repo AGENTS/notes templates

## Operational Notes

- This repository is intended as a canonical reference for consumers.
- Consumer environments should pull updates read-only (daily), not auto-push.
- For deterministic updates, change `templates/` first, then Bun CLI/scripts/docs, then run `bun run agents validate` before push.
- Codex GitHub review behavior reference: https://developers.openai.com/codex/integrations/github/

## Updates

- 2026-02-10 | Added copy-paste-first setup guidance and runtime profile recommendations | Why: make onboarding deterministic across agent harnesses | Commit: `5259ef9`
- 2026-02-10 | Added idempotent bootstrap automation scripts (`.sh` + `.ps1`) and fast-path docs | Why: reduce setup drift, steps, and token usage | Commit: `1932bb0`
- 2026-02-10 | Added behavioral adaptation loop and token-efficiency protocol to setup docs | Why: improve iterative alignment and context efficiency | Commit: `8053028`
- 2026-02-10 | Hardened setup docs and local ignore defaults (`AGENT*.md`, `.agentsmd`) | Why: keep local agent memory private and standardized | Commit: `16754e9`
- 2026-02-10 | Added Bun-first cross-platform CLI (`cli.ts`) and terminal-first workflow (`setup` + `validate`) | Why: remove LLM/manual variability and make setup deterministic from terminal | Commit: `TBD`

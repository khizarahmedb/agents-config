# agents-config

This project is a portable AGENTS configuration system for setting up AI coding agents consistently across repositories.

The setup profile is designed so a user can copy and paste one markdown file into an AI agent and have the full config applied end-to-end.

Canonical term mapping:
- `the brain` = this maintained config system:
  - local: `/Users/khizar/Documents/GitHub/agents-config`
  - remote: `https://github.com/khizarahmedb/agents-config`

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

The project includes idempotent bootstrap scripts for faster setup in new repositories.

Files:
- `scripts/apply_repo_agent_policy.sh` (macOS/Linux)
- `scripts/apply_repo_agent_policy.ps1` (Windows PowerShell)
- `scripts/validate_setup_consistency.sh` (macOS/Linux validation)
- `scripts/validate_setup_consistency.ps1` (Windows validation)

These scripts:
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

## Obsidian-First Retrieval (Primary Path)

Obsidian-first retrieval is the default operating path for this repository.

Legacy markdown-only retrieval flow is deprecated.

Requirements:
- Obsidian CLI available in your environment (see `help.obsidian.md/cli`)
- Vault root set to your workspace root (for example `/Users/<username>/Documents/GitHub`)

Fast workflow:
1. Refresh incremental index (`obsidian_index_refresh.sh`).
2. Query ranked context (`obsidian_fast_context.sh`) with `--engine hybrid`.
3. Use `--mode paths` to minimize tokens, then load only selected files.

Files:
- `scripts/obsidian_index_refresh.sh`: builds/updates incremental SQLite FTS index
- `scripts/obsidian_fast_context.sh`: hybrid query engine (`auto|hybrid|base|fts|rg`)
- `scripts/benchmark_obsidian_fast_context.sh`: repeatable p50/p95 benchmark runner
- `obsidian/agents-config-index.base`: Base views optimized for this repository
- `obsidian/agents-config-flow.canvas`: visual map of retrieval flow
- `obsidian/obsidian-cli-playbook.md`: quickstart, troubleshooting, and benchmark cookbook

Examples:

```bash
bash ./scripts/obsidian_index_refresh.sh \
  --vault /Users/<username>/Documents/GitHub
```

```bash
bash ./scripts/obsidian_fast_context.sh \
  --vault /Users/<username>/Documents/GitHub \
  --query "last_config_sync_date" \
  --engine hybrid \
  --refresh auto \
  --mode paths
```

## File Map

- `setup_instructions.md`: main setup profile for macOS/Linux
- `setup_instructions_ubuntu.md`: Ubuntu-specific profile
- `setup_instructions_win.md`: Windows-specific profile
- `scripts/apply_repo_agent_policy.sh`: Unix bootstrap automation
- `scripts/apply_repo_agent_policy.ps1`: Windows bootstrap automation
- `scripts/validate_setup_consistency.sh`: Unix setup consistency checks
- `scripts/validate_setup_consistency.ps1`: Windows setup consistency checks
- `scripts/obsidian_index_refresh.sh`: incremental SQLite index builder for hybrid retrieval
- `scripts/obsidian_fast_context.sh`: Obsidian CLI retrieval helper for low-token lookups
- `scripts/benchmark_obsidian_fast_context.sh`: repeatable latency benchmark for retrieval pipeline
- `obsidian/agents-config-index.base`: Obsidian Base for high-signal file views
- `obsidian/agents-config-flow.canvas`: JSON Canvas map of retrieval flow
- `obsidian/obsidian-cli-playbook.md`: Obsidian CLI usage notes for this repo
- `templates/global/`: canonical global AGENTS/notes templates
- `templates/repo/`: canonical repo AGENTS/notes templates

## Operational Notes

- This repository is intended as a canonical reference for consumers.
- Consumer environments should pull updates read-only (daily), not auto-push.
- For deterministic updates, change `templates/` first, then setup docs/scripts, then run validation scripts before push.
- Codex GitHub review behavior reference: https://developers.openai.com/codex/integrations/github/

## Updates

- 2026-02-13 | Promoted Obsidian-first retrieval to primary path; deprecated markdown-only retrieval; added hybrid scripts (`obsidian_index_refresh.sh`, `obsidian_fast_context.sh`, `benchmark_obsidian_fast_context.sh`) and playbook | Why: fastest startup, deterministic lookup, and lower token usage for repeated setup operations | Commit: `pending`
- 2026-02-10 | Added copy-paste-first setup guidance and runtime profile recommendations | Why: make onboarding deterministic across agent harnesses | Commit: `5259ef9`
- 2026-02-10 | Added idempotent bootstrap automation scripts (`.sh` + `.ps1`) and fast-path docs | Why: reduce setup drift, steps, and token usage | Commit: `1932bb0`
- 2026-02-10 | Added behavioral adaptation loop and token-efficiency protocol to setup docs | Why: improve iterative alignment and context efficiency | Commit: `8053028`
- 2026-02-10 | Hardened setup docs and local ignore defaults (`AGENT*.md`, `.agentsmd`) | Why: keep local agent memory private and standardized | Commit: `16754e9`

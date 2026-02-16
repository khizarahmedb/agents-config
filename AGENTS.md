# Repo Agent Instructions

1. At the start of every conversation in this repository, read `AGENT_NOTES.md` before proposing or writing changes.
2. This repository is a read-only reference for consumers; do not instruct agents to auto-update or auto-push this repo.
3. On the first conversation of each new local date, pull latest changes from `https://github.com/khizarahmedb/agents-config` before applying setup guidance.
4. Record daily refresh using `last_config_sync_date` in the global notes file used by the local environment.
5. If `AGENTS.override.md` and `AGENTS.md` both exist in a directory, `AGENTS.override.md` takes precedence.
6. Prefer nearest-local instructions over broader instructions.
7. Keep instruction payloads compact; for large documentation, use index + retrieval instead of full inline docs.
8. If `skills.md` exists in a target repository, review it and use applicable workflows.
9. When repo-level notes are insufficient, consult `/Users/khizar/Documents/GitHub/AGENT_NOTES_GLOBAL.md`.
10. Do not copy global notes into local notes unless explicitly requested; reference them instead.
11. Only the owner updates canonical remote instructions; all other agents consume and follow them.

## Review guidelines

Use these for GitHub PR reviews (for example with `@codex review`):
- Prioritize correctness, security, and regression risk over style-only feedback.
- Keep each finding actionable with concrete impact and minimal noise.
- Require tests (or explicit risk notes) for behavior changes.
- Keep comments concise and line-specific.

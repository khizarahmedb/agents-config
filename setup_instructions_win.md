# Universal AGENTS Config Setup (Windows)

This file is intentionally dual-use:
- It is documentation for humans.
- It is a direct instruction payload for an AI agent.

If an AI agent receives this full file, it should execute it as an implementation runbook, not as background reading.

## 1) Agent Operating Contract

If you are the agent executing this setup, you MUST do all of the following:

1. Treat this as the source of truth for setup behavior.
2. Implement exactly this configuration model.
3. Preserve existing repo-specific AGENTS instructions when they already exist.
4. Use global instructions only as fallback when repo-level instructions exist.
5. Keep `AGENTS.md` and `AGENT_NOTES*.md` local/untracked by default.
6. Use read-only daily sync from the canonical instructions repo.
7. Never auto-push updates to the canonical instructions repo.
8. Update notes with dated, concise, behavioral entries.
9. Prefer compact docs indexes and retrieval-led reasoning.
10. Report every file created/changed at the end.

## 2) Inputs and Constants

Set these values first:

- `WORKSPACE_ROOT`: directory containing many repos.
  - Windows example: `C:\Users\<username>\Documents\GitHub`
- `CANONICAL_CONFIG_REPO_URL`: `https://github.com/khizarahmedb/agents-config`
- `LOCAL_CONFIG_REPO_PATH`: `<WORKSPACE_ROOT>\agents-config`
- `GLOBAL_AGENTS_PATH`: `<WORKSPACE_ROOT>\AGENTS.md`
- `GLOBAL_NOTES_PATH`: `<WORKSPACE_ROOT>\AGENT_NOTES_GLOBAL.md`
- `TARGET_REPO`: repository currently being configured

## 3) Required End State

After setup:

1. Global files exist:
   - `<WORKSPACE_ROOT>\AGENTS.md`
   - `<WORKSPACE_ROOT>\AGENT_NOTES_GLOBAL.md`
2. Each repo has deterministic bootstrap behavior:
   - If `<repo>\AGENTS.md` exists, use it.
   - If missing, create `<repo>\AGENTS.md` and `<repo>\AGENT_NOTES.md`.
3. Git ignore defaults are enforced per repo:
   - `/docs/`
   - `AGENT*.md`
   - `.agentsmd`
4. Tracked agent markdown files are untracked by default unless user explicitly asks otherwise.
5. Daily read-only sync from local clone of `agents-config` occurs once per new date.
6. Global notes store `last_config_sync_date` and iterative process fixes.
7. Cross-tool instruction discovery points to the same canonical global instruction source where supported.

## 4) Daily Sync Routine (Run at Start of Conversation)

Run this logic once per new local date:

1. Get local date in `YYYY-MM-DD`:

```powershell
(Get-Date).ToString("yyyy-MM-dd")
```

2. Read `last_config_sync_date` from `<WORKSPACE_ROOT>\AGENT_NOTES_GLOBAL.md`.
3. If date changed:
   - Pull latest canonical reference locally:

```powershell
git -C <LOCAL_CONFIG_REPO_PATH> pull --ff-only
```

4. Update `last_config_sync_date` in global notes.
5. Treat `agents-config` as read-only reference unless the owner explicitly asks to modify it.

## 5) Create / Update Global Files

### 5.1 `<WORKSPACE_ROOT>\AGENTS.md`

If missing, create using this template. If present, patch to match behavior below.

```md
# Global Agent Instructions (Workspace)

## Scope
These instructions apply to repositories under `<WORKSPACE_ROOT>`.

## Canonical Paths
- Global instructions: `<WORKSPACE_ROOT>/AGENTS.md`
- Global notes: `<WORKSPACE_ROOT>/AGENT_NOTES_GLOBAL.md`
- Repo instructions: `<repo_root>/AGENTS.md`
- Repo notes: `<repo_root>/AGENT_NOTES.md`
- Optional repo capability index: `<repo_root>/skills.md`
- Canonical reference repo (read-only for consumers): `https://github.com/khizarahmedb/agents-config`

## Precedence
1. Explicit user request in current conversation.
2. Nearest `AGENTS.override.md`.
3. Nearest `AGENTS.md`.
4. Parent directory AGENTS files up to repo root.
5. Tool-home global instructions (for example `~/.codex/AGENTS.md`) when supported.
6. Workspace-global fallback guidance.

If repo-local `AGENTS.md` exists, treat it as primary and this file as fallback.

## Bootstrap Behavior
1. Determine repo root.
2. If `<repo_root>/AGENTS.md` exists, follow it.
3. If missing, create:
   - `<repo_root>/AGENTS.md`
   - `<repo_root>/AGENT_NOTES.md`
   - `<repo_root>/skills.md` (only when reusable workflows are needed)
4. Continue using repo-local instructions.

## Default Git Ignore + Untracking Policy (All Repos)
1. Ensure `.gitignore` includes:
   - `/docs/`
   - `AGENT*.md`
   - `.agentsmd`
2. Untrack any already-tracked agent markdown files without deleting local copies.
3. Do not push agent markdown files unless user explicitly requests tracking.
4. Keep this policy as default across repos unless user explicitly changes it.

## Daily Canonical Reference Sync
1. On first conversation of a new local date, run:
   - `git -C <WORKSPACE_ROOT>/agents-config pull --ff-only`
2. Update `last_config_sync_date` in `<WORKSPACE_ROOT>/AGENT_NOTES_GLOBAL.md`.
3. Treat `agents-config` as read-only unless owner explicitly asks for updates.

## Docs Strategy
- Keep instruction payload compact.
- Use docs index + retrieval over embedding full docs.
- Prefer retrieval-led reasoning over pre-training-led reasoning for framework/version-sensitive tasks.

## Notes Policy
- Store shared behavior in global notes.
- Store repo-specific behavior in repo notes.
- Reference global notes from repo notes; do not copy/paste global notes into every repo.
- Never store secrets in notes.

## Iterative Improvement Rule
When the user calls out a process miss:
1. Apply the fix in the current task.
2. Add a dated global note so the miss is not repeated.
```

### 5.2 `<WORKSPACE_ROOT>\AGENT_NOTES_GLOBAL.md`

If missing, create using this starter. If present, keep existing notes and ensure required keys exist.

```md
# Global Agent Notes

- YYYY-MM-DD: If a repo lacks `AGENTS.md`, bootstrap `AGENTS.md` + `AGENT_NOTES.md` before major edits. Rationale: enforce stable repo-specific behavior.
- YYYY-MM-DD: Keep notes concise, behavioral, and free of secrets. Rationale: persistent memory must stay safe.
- YYYY-MM-DD: Prefer nearest-local instructions over broader scope; use `AGENTS.override.md` precedence where supported. Rationale: deterministic layering.
- YYYY-MM-DD: Default policy is to gitignore and untrack `AGENT*.md` files unless user explicitly asks to track them. Rationale: local memory should remain local.
- YYYY-MM-DD: For framework/version-sensitive work, use compact docs index + retrieval-led reasoning. Rationale: lower context bloat and improve correctness.
- YYYY-MM-DD: When user flags a repeated miss, codify it as a dated global note immediately. Rationale: iterative self-correction.
- YYYY-MM-DD: `last_config_sync_date: YYYY-MM-DD`. Rationale: once-per-day read-only canonical sync tracking.
```

## 6) Per-Repository Bootstrap Algorithm

Run these steps for each target repo.

1. Set `REPO_ROOT` to current repo root.
2. If `REPO_ROOT\AGENTS.md` exists:
   - Do not overwrite blindly.
   - Keep it primary.
   - Ensure `REPO_ROOT\AGENT_NOTES.md` exists.
3. If `REPO_ROOT\AGENTS.md` is missing:
   - Create `REPO_ROOT\AGENTS.md` from template below.
   - Create `REPO_ROOT\AGENT_NOTES.md` from template below.
4. If repo has reusable workflows, create/update `REPO_ROOT\skills.md`.
5. Update `REPO_ROOT\.gitignore` with local agent patterns.
6. Untrack already-tracked agent markdown files.

### 6.1 Repo `AGENTS.md` template

```md
# Repo Agent Instructions

1. At conversation start, read `AGENT_NOTES.md` before proposing or writing changes.
2. If `skills.md` exists, use relevant skills/workflows.
3. Prefer retrieval-led reasoning over pre-training-led reasoning for framework/version-sensitive tasks.
4. Explore project structure first, then retrieve only the minimum docs needed.
5. Keep AGENTS compact; for large docs use index pointers to retrievable files.
6. Append stable repo preferences to `AGENT_NOTES.md` with date and rationale.
7. Never store secrets in notes.
8. If repo notes are insufficient, consult `<WORKSPACE_ROOT>/AGENT_NOTES_GLOBAL.md`.
9. Reference global notes; do not duplicate them in this file.
```

### 6.2 Repo `AGENT_NOTES.md` template

```md
# Agent Notes

- YYYY-MM-DD: <repo-specific preference>. Rationale: <why it should persist>.
- Reference: Shared/global preferences live in `<WORKSPACE_ROOT>/AGENT_NOTES_GLOBAL.md`.
```

### 6.3 Optional repo `skills.md` template

```md
# Skills Index

- <skill-name>: <when to use>
- <skill-name>: <when to use>
```

## 7) Git Ignore + Untracking Commands (Windows PowerShell)

In each repo, ensure `.gitignore` has these exact lines (add if missing):

```gitignore
/docs/
AGENT*.md
.agentsmd
```

Then untrack matching files if already tracked:

```powershell
$tracked = git ls-files -- 'AGENT*.md' '.agentsmd'
if ($tracked) {
  $tracked | ForEach-Object { git rm --cached --ignore-unmatch -- $_ }
}
```

Important:
- This keeps local files on disk.
- Do not commit agent markdown files unless explicitly requested by the user.

## 8) Cross-Tool Global Compatibility

Goal: one canonical global instruction source under `<WORKSPACE_ROOT>\AGENTS.md`.

Recommended links/copies:
- Codex: `%USERPROFILE%\.codex\AGENTS.md`
- Claude Code: `%USERPROFILE%\.claude\CLAUDE.md`
- Gemini CLI: `%USERPROFILE%\.gemini\GEMINI.md` or configure `contextFileName` to include `AGENTS.md`
- Copilot CLI / coding agent: keep repository-level support for `AGENTS.md` and `.github/...instructions...` formats

Gemini example (`%USERPROFILE%\.gemini\settings.json`):

```json
{
  "contextFileName": ["AGENTS.md", "GEMINI.md"]
}
```

### Optional Codex Advanced Discovery Tuning

If your repos use alternate instruction filenames, add them in `%USERPROFILE%\\.codex\\config.toml`:

```toml
project_doc_fallback_filenames = ["TEAM_GUIDE.md", ".agents.md"]
project_doc_max_bytes = 65536
```

Notes:
- `project_doc_fallback_filenames` lets Codex treat alternate files as instruction sources.
- `project_doc_max_bytes` raises the combined AGENTS read budget beyond the 32 KiB default.

## 9) QA Checklist (Must Pass)

1. Global files exist and are non-empty.
2. Daily sync logic is documented and operational.
3. Repo bootstrap behavior is deterministic (create-if-missing, preserve-if-present).
4. `.gitignore` includes `/docs/`, `AGENT*.md`, `.agentsmd`.
5. Tracked agent markdown files are untracked by default.
6. Repo notes reference global notes instead of duplicating them.
7. Instructions enforce read-only consumption of canonical remote config unless owner explicitly asks for edits.
8. Instructions enforce compact docs index + retrieval-led reasoning.

## 10) Final Output Format (for the executing AI)

At completion, report:

1. Files created.
2. Files modified.
3. Gitignore/untracking actions performed.
4. Whether daily sync state was updated.
5. Any blockers.

## 11) Research-Based Improvements Embedded Here

This setup incorporates the following validated patterns:

- `AGENTS.md` as an open, tool-agnostic instruction standard with nearest-file precedence.
- Codex instruction-chain behavior (global + project hierarchy, fallback filenames, byte limits).
- Practical preference for compact docs index + retrieval-led reasoning.
- Explicit command-first, boundary-first instruction style for reliability.

## 12) Sources

- [AGENTS.md standard](https://agents.md/)
- [agentsmd/agents.md repository](https://github.com/agentsmd/agents.md)
- [OpenAI Codex guide: AGENTS.md](https://developers.openai.com/codex/guides/agents-md/)
- [OpenAI Codex config: project instructions discovery](https://developers.openai.com/codex/config-advanced/#project-instructions-discovery)
- [Vercel evals: AGENTS.md outperforms skills](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals)
- [Anthropic Claude Code memory hierarchy](https://code.claude.com/docs/en/memory)
- [GitHub changelog: Copilot coding agent supports AGENTS.md](https://github.blog/changelog/2025-08-28-copilot-coding-agent-now-supports-agents-md-custom-instructions/)
- [Gemini CLI context configuration](https://geminicli.com/docs/cli/configuration/)

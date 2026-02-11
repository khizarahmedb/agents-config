# Universal AGENTS Config Setup (macOS/Linux)

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
5. Keep `AGENTS.md` tracked for repository-level Codex review guidance, and keep `AGENT_NOTES*.md` local/untracked by default.
6. Use read-only daily sync from the canonical instructions repo.
7. Never auto-push updates to the canonical instructions repo.
8. Update notes with dated, concise, behavioral entries.
9. Prefer compact docs indexes and retrieval-led reasoning.
10. Report every file created/changed at the end.
11. When user feedback indicates a repeated process miss, update repo/global notes in the same turn without waiting for another reminder.

## 1.1) Required Local Clone (Deterministic)

Before any setup actions, ensure the canonical repo is cloned locally:

```bash
git clone https://github.com/khizarahmedb/agents-config.git <LOCAL_CONFIG_REPO_PATH>
```

If already cloned, do not re-clone; reuse `<LOCAL_CONFIG_REPO_PATH>`.

## 2) Inputs and Constants

Set these values first:

- `WORKSPACE_ROOT`: directory containing many repos.
  - Example: `/Users/<username>/Documents/GitHub`
- `CANONICAL_CONFIG_REPO_URL`: `https://github.com/khizarahmedb/agents-config`
- `LOCAL_CONFIG_REPO_PATH`: `<WORKSPACE_ROOT>/agents-config`
- `GLOBAL_TEMPLATE_DIR`: `<LOCAL_CONFIG_REPO_PATH>/templates/global`
- `REPO_TEMPLATE_DIR`: `<LOCAL_CONFIG_REPO_PATH>/templates/repo`
- `GLOBAL_AGENTS_PATH`: `<WORKSPACE_ROOT>/AGENTS.md`
- `GLOBAL_NOTES_PATH`: `<WORKSPACE_ROOT>/AGENT_NOTES_GLOBAL.md`
- `TARGET_REPO`: repository currently being configured
- `BUN_RUNTIME`: Bun (recommended `>=1.3`)

## 2.1) Fast Path (Token-Efficient Bootstrap)

Use the Bun CLI for deterministic, cross-platform setup:

```bash
bun run <LOCAL_CONFIG_REPO_PATH>/cli.ts setup \
  --workspace-root <WORKSPACE_ROOT> \
  --repo-root <TARGET_REPO>
```

This CLI renders files from canonical templates in `<LOCAL_CONFIG_REPO_PATH>/templates/`.

Fallback only when Bun is unavailable:
- `bash <LOCAL_CONFIG_REPO_PATH>/scripts/apply_repo_agent_policy.sh ...`

Then continue with daily sync + cross-tool mapping sections in this file.

## 3) Required End State

After setup:

1. Global files exist:
   - `<WORKSPACE_ROOT>/AGENTS.md`
   - `<WORKSPACE_ROOT>/AGENT_NOTES_GLOBAL.md`
2. Each repo has deterministic bootstrap behavior:
   - If `<repo>/AGENTS.md` exists, use it.
   - If missing, create `<repo>/AGENTS.md` and `<repo>/AGENT_NOTES.md`.
3. Git ignore defaults are enforced per repo:
   - `/docs/`
   - `AGENT_NOTES*.md`
   - `.agentsmd`
4. Tracked local note files (`AGENT_NOTES*.md`, `.agentsmd`) are untracked by default, while `AGENTS.md` remains tracked.
5. Daily read-only sync from local clone of `agents-config` occurs once per new date.
6. Global notes store `last_config_sync_date` and iterative process fixes.
7. Cross-tool instruction discovery points to the same canonical global instruction source where supported.
8. Bun CLI exists for cross-platform setup and is idempotent for repeated runs.
9. Canonical templates exist in `<LOCAL_CONFIG_REPO_PATH>/templates/global` and `<LOCAL_CONFIG_REPO_PATH>/templates/repo`.

## 4) Daily Sync Routine (Run at Start of Conversation)

Run this logic once per new local date:

1. Get local date in `YYYY-MM-DD`:

```bash
date +%F
```

2. Read `last_config_sync_date` from `<WORKSPACE_ROOT>/AGENT_NOTES_GLOBAL.md`.
3. If date changed:
   - Pull latest canonical reference locally:

```bash
git -C <LOCAL_CONFIG_REPO_PATH> pull --ff-only
```

4. Update `last_config_sync_date` in global notes.
5. Treat `agents-config` as read-only reference unless the owner explicitly asks to modify it.

## 4.1) Behavioral Adaptation Loop (Required)

For each conversation, run this loop:

1. Detect user signal types:
   - Correction (`this is wrong`, `you missed X`)
   - Repetition (`I should not have to remind you`)
   - Preference (`be concise`, `be more detailed`, `do X first`)
   - Priority/urgency (`now`, `first`, `blocker`)
2. Convert stable signals into durable rules:
   - Repo-specific rule -> append to `<repo_root>/AGENT_NOTES.md`
   - Cross-repo rule -> append to `<WORKSPACE_ROOT>/AGENT_NOTES_GLOBAL.md`
3. Apply the rule immediately in the same turn.
4. In completion summary, confirm which rule was added or updated.

This implements an explicit observe -> codify -> apply -> verify loop.

## 4.2) Token Efficiency Protocol (Required)

Default behavior:

1. Keep routine progress updates to 1-2 sentences.
2. Prefer concise outputs by default; expand only when user requests detail.
3. Use retrieval-on-demand:
   - Read indexes first.
   - Load only files required for the active task.
4. Prefer fewer tools and fewer steps when equivalent quality is possible.
5. Summarize command output instead of pasting large raw logs.
6. Avoid redundant restatement of known context.

Escalate to verbose mode only for:
- Safety-critical tasks
- Architecture decisions with tradeoffs
- Explicit user request for full detail

## 5) Create / Update Global Files

Canonical source of truth:
- `<LOCAL_CONFIG_REPO_PATH>/templates/global/AGENTS.md.template`
- `<LOCAL_CONFIG_REPO_PATH>/templates/global/AGENT_NOTES_GLOBAL.md.template`

When policy changes, update template files first, then keep this document in sync.

### 5.1 `<WORKSPACE_ROOT>/AGENTS.md`

If missing, render from `<LOCAL_CONFIG_REPO_PATH>/templates/global/AGENTS.md.template` and replace placeholders (`{{WORKSPACE_ROOT}}`, `{{DATE}}`). If present, patch to match behavior below.

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
   - `AGENT_NOTES*.md`
   - `.agentsmd`
2. Keep `AGENTS.md` tracked so Codex can apply repository review guidance.
3. Untrack already-tracked local notes (`AGENT_NOTES*.md`, `.agentsmd`) without deleting local copies.
4. Keep this policy as default across repos unless user explicitly changes it.

## Daily Canonical Reference Sync
1. On first conversation of a new local date, run:
   - `git -C <WORKSPACE_ROOT>/agents-config pull --ff-only`
2. Update `last_config_sync_date` in `<WORKSPACE_ROOT>/AGENT_NOTES_GLOBAL.md`.
3. Treat `agents-config` as read-only unless owner explicitly asks for updates.

## Automatic Global Config Maintenance
1. At conversation start, review:
   - `<WORKSPACE_ROOT>/AGENTS.md`
   - `<WORKSPACE_ROOT>/AGENT_NOTES_GLOBAL.md`
2. If a stable behavior/process preference is identified, update both files in the same turn.
3. Keep these state keys in global notes:
   - `last_config_sync_date`
   - `last_global_config_review_date`
   - `last_global_config_review_repo`
4. Refresh `last_global_config_review_date` and `last_global_config_review_repo` at each conversation start.
5. If drift or a stable new preference is detected mid-conversation, update both global files in the same turn.

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

### 5.2 `<WORKSPACE_ROOT>/AGENT_NOTES_GLOBAL.md`

If missing, render from `<LOCAL_CONFIG_REPO_PATH>/templates/global/AGENT_NOTES_GLOBAL.md.template` and replace placeholders (`{{WORKSPACE_ROOT}}`, `{{DATE}}`). If present, keep existing notes and ensure required keys exist.

```md
# Global Agent Notes

## Auto-Maintenance State
- `last_config_sync_date: YYYY-MM-DD`
- `last_global_config_review_date: YYYY-MM-DD`
- `last_global_config_review_repo: <workspace/repo-path>`
- `last_global_config_review_trigger: conversation_start|mid_conversation_update`

- YYYY-MM-DD: If a repo lacks `AGENTS.md`, bootstrap `AGENTS.md` + `AGENT_NOTES.md` before major edits. Rationale: enforce stable repo-specific behavior.
- YYYY-MM-DD: Keep notes concise, behavioral, and free of secrets. Rationale: persistent memory must stay safe.
- YYYY-MM-DD: Prefer nearest-local instructions over broader scope; use `AGENTS.override.md` precedence where supported. Rationale: deterministic layering.
- YYYY-MM-DD: Default policy is to keep `AGENTS.md` tracked and gitignore/untrack only `AGENT_NOTES*.md` and `.agentsmd`. Rationale: support Codex review guidance while keeping local memory local.
- YYYY-MM-DD: For framework/version-sensitive work, use compact docs index + retrieval-led reasoning. Rationale: lower context bloat and improve correctness.
- YYYY-MM-DD: When user flags a repeated miss, codify it as a dated global note immediately. Rationale: iterative self-correction.
- YYYY-MM-DD: At each conversation start, review both global files and refresh review-state keys. Rationale: prevent policy drift and stale state.
- YYYY-MM-DD: If drift/new stable preference is detected mid-conversation, update both global files in the same turn. Rationale: immediate correction.
- YYYY-MM-DD: `last_config_sync_date: YYYY-MM-DD`. Rationale: once-per-day read-only canonical sync tracking.
```

## 6) Per-Repository Bootstrap Algorithm

Run these steps for each target repo.

1. Set `REPO_ROOT` to current repo root.
2. If `REPO_ROOT/AGENTS.md` exists:
   - Do not overwrite blindly.
   - Keep it primary.
   - Ensure `REPO_ROOT/AGENT_NOTES.md` exists.
3. If `REPO_ROOT/AGENTS.md` is missing:
   - Create `REPO_ROOT/AGENTS.md` from template below.
   - Create `REPO_ROOT/AGENT_NOTES.md` from template below.
4. If repo has reusable workflows, create/update `REPO_ROOT/skills.md`.
5. Update `REPO_ROOT/.gitignore` with local agent patterns.
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

## Review guidelines

Use these for GitHub PR reviews (for example with `@codex review`):
- Prioritize correctness, security, and regression risk over style-only feedback.
- Keep findings actionable with concrete impact and line-specific context.
- Call out missing tests for behavior changes.
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

## 7) Git Ignore + Untracking Commands (macOS/Linux)

Preferred automation-first command:

```bash
bun run <LOCAL_CONFIG_REPO_PATH>/cli.ts apply \
  --workspace-root <WORKSPACE_ROOT> \
  --repo-root <REPO_ROOT>
```

Fallback command (if Bun is unavailable):

```bash
bash <LOCAL_CONFIG_REPO_PATH>/scripts/apply_repo_agent_policy.sh \
  --workspace-root <WORKSPACE_ROOT> \
  --repo-root <REPO_ROOT>
```

Manual mode (if automation is unavailable):

In each repo, ensure `.gitignore` has these exact lines (add if missing):

```gitignore
/docs/
AGENT_NOTES*.md
.agentsmd
```

Then untrack matching files if already tracked:

```bash
git ls-files -z -- 'AGENT_NOTES*.md' '**/AGENT_NOTES*.md' '.agentsmd' '**/.agentsmd' | xargs -0 git rm --cached --ignore-unmatch 2>/dev/null || true
```

Important:
- This keeps local files on disk.
- Keep `AGENTS.md` committed so Codex can use repo review guidance.
- Keep `AGENT_NOTES*.md` local unless explicitly requested otherwise.

## 8) Cross-Tool Global Compatibility

Goal: one canonical global instruction source under `<WORKSPACE_ROOT>/AGENTS.md`.

Recommended links/copies:
- Codex: `~/.codex/AGENTS.md`
- Claude Code: `~/.claude/CLAUDE.md`
- Gemini CLI: `~/.gemini/GEMINI.md` or configure `contextFileName` to include `AGENTS.md`
- Copilot CLI / coding agent: keep repository-level support for `AGENTS.md` and `.github/...instructions...` formats

Gemini example (`~/.gemini/settings.json`):

```json
{
  "contextFileName": ["AGENTS.md", "GEMINI.md"]
}
```

### Optional Codex Advanced Discovery Tuning

If your repos use alternate instruction filenames, add them in `~/.codex/config.toml`:

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
4. `.gitignore` includes `/docs/`, `AGENT_NOTES*.md`, `.agentsmd`.
5. Tracked local note files (`AGENT_NOTES*.md`, `.agentsmd`) are untracked by default while `AGENTS.md` remains tracked.
6. Repo notes reference global notes instead of duplicating them.
7. Instructions enforce read-only consumption of canonical remote config unless owner explicitly asks for edits.
8. Instructions enforce compact docs index + retrieval-led reasoning.
9. Behavioral adaptation loop is implemented and notes are updated when recurring user feedback appears.
10. Token efficiency protocol is followed (concise by default, retrieval-on-demand).
11. Bun CLI can be run repeatedly without duplicating entries or breaking tracked files.
12. Template files in `<LOCAL_CONFIG_REPO_PATH>/templates/` exist and match intended policy.
13. `bun run <LOCAL_CONFIG_REPO_PATH>/cli.ts validate` passes.

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
- Behavioral adaptation through explicit memory loops improves future interactions.
- Simpler toolchains can reduce steps/tokens and improve reliability when documentation quality is high.
- Idempotent bootstrap automation reduces repetitive edits and lowers operator/agent variance.
- Explicit command-first, boundary-first instruction style for reliability.

## 12) Sources

- [AGENTS.md standard](https://agents.md/)
- [agentsmd/agents.md repository](https://github.com/agentsmd/agents.md)
- [OpenAI Codex guide: AGENTS.md](https://developers.openai.com/codex/guides/agents-md/)
- [OpenAI Codex GitHub integration](https://developers.openai.com/codex/integrations/github/)
- [OpenAI Codex config: project instructions discovery](https://developers.openai.com/codex/config-advanced/#project-instructions-discovery)
- [Bun LLM full docs](https://bun.sh/llms-full.txt)
- [Bun README](https://github.com/oven-sh/bun/blob/main/README.md)
- [Bun CLAUDE.md](https://github.com/oven-sh/bun/blob/main/CLAUDE.md)
- [Vercel evals: AGENTS.md outperforms skills](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals)
- [Vercel: We removed 80% of our agent's tools](https://vercel.com/blog/we-removed-80-percent-of-our-agents-tools)
- [Anthropic Claude Code memory hierarchy](https://code.claude.com/docs/en/memory)
- [GitHub changelog: Copilot coding agent supports AGENTS.md](https://github.blog/changelog/2025-08-28-copilot-coding-agent-now-supports-agents-md-custom-instructions/)
- [Gemini CLI context configuration](https://geminicli.com/docs/cli/configuration/)
- [Apple ML: Feedback effect in IA interaction](https://machinelearning.apple.com/research/feedback-effect)
- [Self-Refine (arXiv)](https://arxiv.org/abs/2303.17651)
- [Reflexion (arXiv)](https://arxiv.org/abs/2303.11366)
- [Personalized LM from Personalized Human Feedback (arXiv)](https://arxiv.org/abs/2402.05133)

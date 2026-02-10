# Setup Instructions: Portable AGENTS/Notes Standard

## Purpose
Use this file to bootstrap the same agent-instruction system across any machine and any repository workspace.

This standard defines:
- One canonical global `AGENTS.md`
- One canonical global notes file
- Per-repo `AGENTS.md` + `AGENT_NOTES.md`
- Deterministic precedence and bootstrap behavior
- Cross-tool compatibility mappings

This document is intentionally **not** specific to clasp or Apps Script.

## What this setup creates

### Canonical files
- Global instruction file: `<WORKSPACE_ROOT>/AGENTS.md`
- Global notes file: `<WORKSPACE_ROOT>/AGENT_NOTES_GLOBAL.md`
- Repo instruction file: `<repo_root>/AGENTS.md`
- Repo notes file: `<repo_root>/AGENT_NOTES.md`

### Precedence
1. Explicit user request in current conversation
2. Repo-local `AGENTS.md`
3. Global `AGENTS.md`

## Step 1: Choose workspace root
Pick a directory that contains multiple repositories.

Example used in this project:
- `/Users/khizar/Documents/GitHub`

In the rest of this doc, this is `<WORKSPACE_ROOT>`.

## Step 2: Create global instruction files
Create `<WORKSPACE_ROOT>/AGENTS.md` with:

```md
# Global Agent Instructions (Workspace)

## Scope
These instructions apply to repositories under `<WORKSPACE_ROOT>`.

## Standard
- Canonical global instruction file: `<WORKSPACE_ROOT>/AGENTS.md`
- Canonical global notes file: `<WORKSPACE_ROOT>/AGENT_NOTES_GLOBAL.md`
- Canonical repo instruction file: `<repo_root>/AGENTS.md`
- Canonical repo notes file: `<repo_root>/AGENT_NOTES.md`
- Precedence order: explicit user request > repo-local instructions > global instructions

## Bootstrap Behavior
1. Determine repository root.
2. If `<repo_root>/AGENTS.md` exists, follow it and treat global file as fallback only.
3. If `<repo_root>/AGENTS.md` does not exist, create:
   - `<repo_root>/AGENTS.md`
   - `<repo_root>/AGENT_NOTES.md`
4. Continue by following repo-local `AGENTS.md`.

## Local File Templates (when missing)
Create `<repo_root>/AGENTS.md` with:

1. At the start of every conversation in this repository, read `AGENT_NOTES.md` before proposing or writing changes.
2. Use `AGENT_NOTES.md` as preference memory for communication style, delivery format, and reporting conventions.
3. When a new stable preference appears, append it to `AGENT_NOTES.md` with a date and short rationale.
4. Keep notes concise and behavioral; do not store secrets, passwords, API tokens, or personal data.
5. If a note conflicts with an explicit user request in the current conversation, follow the current explicit request and then update notes accordingly.
6. If multiple tasks are provided, prioritize the oldest requested task first and then newer tasks; if the user explicitly marks a task as urgent, complete that urgent task first and then automatically continue the remaining tasks in original order.
7. When repo-level notes are insufficient, consult `<WORKSPACE_ROOT>/AGENT_NOTES_GLOBAL.md`.
8. Do not copy global notes into local notes unless explicitly requested; reference them instead.

Create `<repo_root>/AGENT_NOTES.md` with:

# Agent Notes

- YYYY-MM-DD: <repo-specific preference>. Rationale: <why it should persist>.
- Reference: Shared/global preferences live in `<WORKSPACE_ROOT>/AGENT_NOTES_GLOBAL.md`.

## Global Notes Policy
- Global user preferences belong in `<WORKSPACE_ROOT>/AGENT_NOTES_GLOBAL.md`.
- Repo notes should contain only repository-specific behavior/preferences.
- Prefer references to global notes over duplication.
```

Create `<WORKSPACE_ROOT>/AGENT_NOTES_GLOBAL.md` with:

```md
# Global Agent Notes

- YYYY-MM-DD: If a repo lacks `AGENTS.md`, bootstrap `AGENTS.md` + `AGENT_NOTES.md` before major edits. Rationale: enforce stable repo-specific behavior.
- YYYY-MM-DD: Keep notes concise, behavioral, and free of secrets. Rationale: notes are persistent memory and should remain safe.
- YYYY-MM-DD: Prefer README/build/test checks early when modernizing repos. Rationale: reduce incorrect assumptions.
- YYYY-MM-DD: For multi-task requests, execute oldest requested task first unless user marks urgency. Rationale: deterministic priority order.
```

## Step 3: Per-repo behavior
For each repository:
- If this is a newly created repository/directory, create `AGENTS.md` and `AGENT_NOTES.md` before adding other project artifacts.
- If `AGENTS.md` exists, follow it.
- If missing, create:
  - `AGENTS.md`
  - `AGENT_NOTES.md`
- Keep repo notes repo-specific.
- Reference global notes when needed.

## Step 4: Git ignore policy
In each repo where you want local/ephemeral agent artifacts untracked, add:

```gitignore
# Local docs
/docs/

# Local agent guidance
AGENT*.md
```

Notes:
- `AGENT*.md` ignores `AGENTS.md`, `AGENT_NOTES.md`, and similar local agent markdown files.
- If you want repo `AGENTS.md` tracked, do not use this pattern.

## Step 5: Cross-tool global compatibility (machine level)
Map tool-specific global files to `<WORKSPACE_ROOT>/AGENTS.md`.

Recommended links:
- `~/.codex/AGENTS.md -> <WORKSPACE_ROOT>/AGENTS.md`
- `~/.claude/CLAUDE.md -> <WORKSPACE_ROOT>/AGENTS.md`
- `~/.gemini/AGENTS.md -> <WORKSPACE_ROOT>/AGENTS.md`
- `~/.gemini/GEMINI.md -> <WORKSPACE_ROOT>/AGENTS.md`
- `~/.copilot/copilot-instructions.md -> <WORKSPACE_ROOT>/AGENTS.md`

Gemini settings (`~/.gemini/settings.json`):

```json
{
  "context": {
    "fileName": ["AGENTS.md", "GEMINI.md"]
  }
}
```

## Step 6: Bootstrap script (optional)
Create and run this script once per machine (replace `<WORKSPACE_ROOT>`):

```bash
#!/usr/bin/env bash
set -euo pipefail

CANONICAL="<WORKSPACE_ROOT>/AGENTS.md"

link_or_preserve() {
  local target="$1"
  local link_path="$2"

  mkdir -p "$(dirname "$link_path")"

  if [[ -L "$link_path" ]]; then
    ln -sfn "$target" "$link_path"
    echo "updated symlink: $link_path -> $target"
    return
  fi

  if [[ -e "$link_path" ]]; then
    if [[ ! -s "$link_path" ]]; then
      rm -f "$link_path"
      ln -s "$target" "$link_path"
      echo "replaced empty file: $link_path -> $target"
    else
      echo "kept existing non-empty file: $link_path"
    fi
    return
  fi

  ln -s "$target" "$link_path"
  echo "created symlink: $link_path -> $target"
}

link_or_preserve "$CANONICAL" "$HOME/.codex/AGENTS.md"
link_or_preserve "$CANONICAL" "$HOME/.claude/CLAUDE.md"
link_or_preserve "$CANONICAL" "$HOME/.gemini/AGENTS.md"
link_or_preserve "$CANONICAL" "$HOME/.gemini/GEMINI.md"
link_or_preserve "$CANONICAL" "$HOME/.copilot/copilot-instructions.md"

if [[ ! -e "$HOME/.gemini/settings.json" ]]; then
  cat > "$HOME/.gemini/settings.json" <<'JSON'
{
  "context": {
    "fileName": ["AGENTS.md", "GEMINI.md"]
  }
}
JSON
  echo "created settings: $HOME/.gemini/settings.json"
else
  echo "kept existing settings: $HOME/.gemini/settings.json"
fi
```

## Step 7: Verification checklist
After setup, verify:

1. Global files exist:
   - `<WORKSPACE_ROOT>/AGENTS.md`
   - `<WORKSPACE_ROOT>/AGENT_NOTES_GLOBAL.md`
2. In a target repo:
   - `AGENTS.md` exists (or was bootstrapped)
   - `AGENT_NOTES.md` exists
3. Machine mappings:
   - `~/.codex/AGENTS.md`
   - `~/.claude/CLAUDE.md`
   - `~/.gemini/AGENTS.md`
   - `~/.copilot/copilot-instructions.md`
4. Gemini fileName includes `AGENTS.md`.

## Step 8: Documentation sync rule
When you update any instruction or notes behavior (global or repo-level), also:

1. Update this documentation repo files:
   - `setup_instructions.md`
   - `setup_instructions_win.md`
   - `setup_instructions_ubuntu.md`
2. Commit the changes.
3. Push to `main` in `https://github.com/khizarahmedb/agents-config` in the same turn when feasible.

## Operational rules for any AI using this system
- Always check repo-local `AGENTS.md` first.
- Read repo `AGENT_NOTES.md` before proposing major work.
- Append stable behavioral preferences with date + rationale.
- Never store secrets in notes.
- Keep notes concise.
- Use global notes as reference, not copy-paste duplication.

## Handoff Prompt (paste to another AI)
Use this exact prompt to instruct another AI to reproduce the setup:

```text
Implement the AGENTS standard in this machine/workspace.

Requirements:
1) Create canonical global files at <WORKSPACE_ROOT>:
   - AGENTS.md
   - AGENT_NOTES_GLOBAL.md
2) Ensure per-repo bootstrap behavior:
   - If repo AGENTS.md exists, follow it
   - If missing, create AGENTS.md + AGENT_NOTES.md
3) Use precedence:
   explicit user request > repo AGENTS.md > global AGENTS.md
4) Add repo .gitignore rules where requested:
   /docs/
   AGENT*.md
5) Configure cross-tool global compatibility by wiring these paths to <WORKSPACE_ROOT>/AGENTS.md:
   ~/.codex/AGENTS.md
   ~/.claude/CLAUDE.md
   ~/.gemini/AGENTS.md
   ~/.gemini/GEMINI.md
   ~/.copilot/copilot-instructions.md
6) Ensure ~/.gemini/settings.json includes:
   {"context":{"fileName":["AGENTS.md","GEMINI.md"]}}
7) Keep notes concise, dated, behavioral, no secrets.
8) Do not include clasp-specific instructions.
9) If instructions/notes are changed, sync all setup docs (`setup_instructions.md`, `setup_instructions_win.md`, `setup_instructions_ubuntu.md`) and push `main` to https://github.com/khizarahmedb/agents-config in the same turn when feasible.

Return a verification summary with created/updated files and final precedence behavior.
```

## Notes
- This standard is intentionally portable and minimal.
- If a tool has native rule systems, those can coexist; this standard still uses `AGENTS.md` as canonical shared policy.

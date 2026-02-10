# Setup Instructions (Windows): Portable AGENTS + Notes Standard

## Purpose
Use this file to bootstrap a portable instruction system for AI coding agents across Windows repositories and tools.

This setup is intentionally generic and not tied to Apps Script or clasp.

## Core Principles
- Use `AGENTS.md` as the canonical instruction file format.
- Keep global and repo instructions separate.
- Keep `agents-config` as a read-only reference for consumers.
- Refresh remote guidance once per day, not every turn.
- Keep context compact: use docs index + retrieval, not full docs in prompt context.
- Use `skills.md` as a repo-local capability index when needed.

## Canonical Files
- Global instruction file: `<WORKSPACE_ROOT>\AGENTS.md`
- Global notes file: `<WORKSPACE_ROOT>\AGENT_NOTES_GLOBAL.md`
- Repo instruction file: `<repo_root>\AGENTS.md`
- Repo notes file: `<repo_root>\AGENT_NOTES.md`
- Optional repo skills index: `<repo_root>\skills.md`

## Instruction Precedence
1. Explicit user request in current conversation.
2. Nearest `AGENTS.override.md` to working directory.
3. Nearest `AGENTS.md` to working directory.
4. Parent-directory `AGENTS.override.md`/`AGENTS.md` up to repo root.
5. Global tool-home file (`%USERPROFILE%\.codex\AGENTS.override.md` then `%USERPROFILE%\.codex\AGENTS.md`, when supported).
6. Workspace-global fallback guidance.

If a tool does not support `AGENTS.override.md`, use: explicit user request > repo `AGENTS.md` > global `AGENTS.md`.

## Step 1: Choose Workspace Root
Pick a directory that contains multiple repositories.

Recommended Windows example:
- `C:\Users\<USERNAME>\Documents\GitHub`

In this document, that path is `<WORKSPACE_ROOT>`.

## Step 2: Daily Remote Reference Refresh (Read-Only)
At the start of each conversation:

1. Read local date:
   - `(Get-Date).ToString("yyyy-MM-dd")`
2. Read `last_config_sync_date` from `<WORKSPACE_ROOT>\AGENT_NOTES_GLOBAL.md`.
3. If date changed, refresh local clone of canonical reference:
   - `git -C <LOCAL_AGENTS_CONFIG_PATH> pull --ff-only`
4. Update `last_config_sync_date` in `<WORKSPACE_ROOT>\AGENT_NOTES_GLOBAL.md`.
5. Do not push updates to `https://github.com/khizarahmedb/agents-config` unless explicitly requested by the owner.

## Step 3: Create Global Files
Create `<WORKSPACE_ROOT>\AGENTS.md` with:

```md
# Global Agent Instructions (Workspace)

## Scope
These instructions apply to repositories under `<WORKSPACE_ROOT>`.

## Standard
- Canonical global instruction file: `<WORKSPACE_ROOT>/AGENTS.md`
- Canonical global notes file: `<WORKSPACE_ROOT>/AGENT_NOTES_GLOBAL.md`
- Canonical repo instruction file: `<repo_root>/AGENTS.md`
- Canonical repo notes file: `<repo_root>/AGENT_NOTES.md`
- Optional repo skills index: `<repo_root>/skills.md`

## Precedence
1. Explicit user request in current conversation.
2. Nearest `AGENTS.override.md`.
3. Nearest `AGENTS.md`.
4. Parent AGENTS files up to repo root.
5. Global AGENTS in tool home.

## Bootstrap
1. Determine repo root.
2. If `<repo_root>/AGENTS.md` exists, follow it.
3. If missing, create `<repo_root>/AGENTS.md` and `<repo_root>/AGENT_NOTES.md`.
4. If repository has reusable workflows, create `<repo_root>/skills.md`.

## Working Style
- Prefer retrieval-led reasoning over pre-training-led reasoning for framework/version-sensitive tasks.
- Explore project structure first, then retrieve only the docs needed.
- Keep instructions compact; prefer doc indexes pointing to retrievable files.
```

Create `<WORKSPACE_ROOT>\AGENT_NOTES_GLOBAL.md` with:

```md
# Global Agent Notes

- YYYY-MM-DD: If a repo lacks `AGENTS.md`, bootstrap `AGENTS.md` + `AGENT_NOTES.md` before major edits. Rationale: enforce stable repo-specific behavior.
- YYYY-MM-DD: Keep notes concise, behavioral, and free of secrets. Rationale: notes are persistent memory and should remain safe.
- YYYY-MM-DD: For multi-task requests, execute oldest requested task first unless user marks urgency. Rationale: deterministic priority order.
- YYYY-MM-DD: Prefer nearest-local `AGENTS.override.md`/`AGENTS.md` over broader rules. Rationale: deterministic instruction layering.
- YYYY-MM-DD: Use compact docs index + retrieval for framework docs. Rationale: lower context bloat with high reliability.
- YYYY-MM-DD: `last_config_sync_date: YYYY-MM-DD`. Rationale: track once-per-day reference refresh.
```

## Step 4: Per-Repo Bootstrap
For each repository:

1. If this is a newly created repository/directory, create `AGENTS.md` and `AGENT_NOTES.md` before adding other artifacts.
2. If `AGENTS.md` exists, follow it.
3. If `AGENTS.md` does not exist, create:
   - `AGENTS.md`
   - `AGENT_NOTES.md`
4. If repo has reusable workflows/skills, create `skills.md`.
5. Keep repo notes repo-specific.
6. Reference global notes instead of copying them.

Recommended repo `AGENTS.md` starter:

```md
# Repo Agent Instructions

1. Read `AGENT_NOTES.md` before proposing or writing changes.
2. If `skills.md` exists, use relevant skills/workflows.
3. Prefer retrieval-led reasoning for framework/version-sensitive tasks.
4. Explore project structure first, then retrieve docs as needed.
5. Keep instructions compact and behavioral.
6. Append stable repo preferences to `AGENT_NOTES.md` with date + rationale.
7. Never store secrets in notes.
8. If repo notes are insufficient, consult global notes.
```

Recommended repo `AGENT_NOTES.md` starter:

```md
# Agent Notes

- YYYY-MM-DD: <repo-specific preference>. Rationale: <why it should persist>.
- Reference: Shared/global preferences live in `<WORKSPACE_ROOT>\AGENT_NOTES_GLOBAL.md`.
```

Recommended repo `skills.md` starter:

```md
# Skills Index

- <skill-name>: <when to use>
- <skill-name>: <when to use>
```

## Step 5: Compact Docs Index Pattern
For framework-heavy projects, do not paste full docs into `AGENTS.md`.

Do this instead:
1. Store retrievable docs in repo files/folders (example: `.next-docs/`).
2. Add a compact index in `AGENTS.md` that maps topics to paths.
3. Instruct agent to retrieve docs on demand.

Example compact index line:

```text
[Docs Index]|root: ./.next-docs|IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning|routing:{defining-routes.mdx,parallel-routes.mdx}|cache:{use-cache.mdx,cache-tag.mdx}
```

Practical recommendations:
- Compress aggressively.
- Prefer index + retrieval over full inline docs.
- Use evals for APIs not likely in model training data.
- Structure docs for fast file-level retrieval.

## Step 6: Git Ignore Policy
In each repo where local/ephemeral artifacts should be untracked, add:

```gitignore
# Local docs
/docs/

# Local agent guidance
AGENT*.md
```

Notes:
- `AGENT*.md` ignores `AGENTS.md`, `AGENT_NOTES.md`, and similar files.
- If you want repo `AGENTS.md` tracked, do not use this pattern.

## Step 7: Cross-Tool Global Compatibility
Map tool-specific global files to `<WORKSPACE_ROOT>\AGENTS.md`.

Recommended links:
- `%USERPROFILE%\.codex\AGENTS.md -> <WORKSPACE_ROOT>\AGENTS.md`
- `%USERPROFILE%\.claude\CLAUDE.md -> <WORKSPACE_ROOT>\AGENTS.md`
- `%USERPROFILE%\.gemini\AGENTS.md -> <WORKSPACE_ROOT>\AGENTS.md`
- `%USERPROFILE%\.gemini\GEMINI.md -> <WORKSPACE_ROOT>\AGENTS.md`
- `%USERPROFILE%\.copilot\copilot-instructions.md -> <WORKSPACE_ROOT>\AGENTS.md`

Gemini settings (`%USERPROFILE%\.gemini\settings.json`):

```json
{
  "context": {
    "fileName": ["AGENTS.md", "GEMINI.md"]
  }
}
```

## Step 8: Bootstrap Script (PowerShell, Optional)
Create and run once per machine (replace `<WORKSPACE_ROOT>`):

```powershell
$Canonical = "<WORKSPACE_ROOT>\\AGENTS.md"

function Link-OrPreserve {
  param(
    [string]$Target,
    [string]$LinkPath
  )

  $Parent = Split-Path -Parent $LinkPath
  if (-not (Test-Path $Parent)) {
    New-Item -ItemType Directory -Path $Parent -Force | Out-Null
  }

  if (Test-Path $LinkPath) {
    $Item = Get-Item -LiteralPath $LinkPath -Force
    $IsReparse = (($Item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)

    if ($IsReparse) {
      Remove-Item -LiteralPath $LinkPath -Force
      try {
        New-Item -ItemType SymbolicLink -Path $LinkPath -Target $Target -Force | Out-Null
        Write-Host "updated symlink: $LinkPath -> $Target"
      } catch {
        Copy-Item -LiteralPath $Target -Destination $LinkPath -Force
        Write-Host "symlink failed, copied file: $LinkPath"
      }
      return
    }

    if ($Item.Length -eq 0) {
      Remove-Item -LiteralPath $LinkPath -Force
      try {
        New-Item -ItemType SymbolicLink -Path $LinkPath -Target $Target -Force | Out-Null
        Write-Host "replaced empty file with symlink: $LinkPath -> $Target"
      } catch {
        Copy-Item -LiteralPath $Target -Destination $LinkPath -Force
        Write-Host "replaced empty file by copy: $LinkPath"
      }
    } else {
      Write-Host "kept existing non-empty file: $LinkPath"
    }
    return
  }

  try {
    New-Item -ItemType SymbolicLink -Path $LinkPath -Target $Target -Force | Out-Null
    Write-Host "created symlink: $LinkPath -> $Target"
  } catch {
    Copy-Item -LiteralPath $Target -Destination $LinkPath -Force
    Write-Host "symlink failed, created copy: $LinkPath"
  }
}

Link-OrPreserve -Target $Canonical -LinkPath "$env:USERPROFILE\\.codex\\AGENTS.md"
Link-OrPreserve -Target $Canonical -LinkPath "$env:USERPROFILE\\.claude\\CLAUDE.md"
Link-OrPreserve -Target $Canonical -LinkPath "$env:USERPROFILE\\.gemini\\AGENTS.md"
Link-OrPreserve -Target $Canonical -LinkPath "$env:USERPROFILE\\.gemini\\GEMINI.md"
Link-OrPreserve -Target $Canonical -LinkPath "$env:USERPROFILE\\.copilot\\copilot-instructions.md"

$GeminiSettings = "$env:USERPROFILE\\.gemini\\settings.json"
if (-not (Test-Path $GeminiSettings)) {
  $SettingsDir = Split-Path -Parent $GeminiSettings
  if (-not (Test-Path $SettingsDir)) {
    New-Item -ItemType Directory -Path $SettingsDir -Force | Out-Null
  }

  @"
{
  "context": {
    "fileName": ["AGENTS.md", "GEMINI.md"]
  }
}
"@ | Set-Content -LiteralPath $GeminiSettings -Encoding UTF8

  Write-Host "created settings: $GeminiSettings"
} else {
  Write-Host "kept existing settings: $GeminiSettings"
}
```

Notes:
- Symlink creation on Windows may require Developer Mode or elevated rights.
- Script falls back to copying if symlink creation fails.

## Step 9: Verification Checklist
After setup, verify:

1. Global files exist:
   - `<WORKSPACE_ROOT>\AGENTS.md`
   - `<WORKSPACE_ROOT>\AGENT_NOTES_GLOBAL.md`
2. In a target repo:
   - `AGENTS.md` exists (or was bootstrapped)
   - `AGENT_NOTES.md` exists
3. If needed, `skills.md` exists with repo workflows.
4. Machine mappings exist:
   - `%USERPROFILE%\.codex\AGENTS.md`
   - `%USERPROFILE%\.claude\CLAUDE.md`
   - `%USERPROFILE%\.gemini\AGENTS.md`
   - `%USERPROFILE%\.copilot\copilot-instructions.md`
5. `%USERPROFILE%\.gemini\settings.json` includes `AGENTS.md`.
6. On a new day, daily refresh pulls remote reference and updates `last_config_sync_date`.

## Handoff Prompt (Paste to Another AI)

```text
Implement the AGENTS standard in this machine/workspace.

Requirements:
1) Create canonical global files at <WORKSPACE_ROOT>:
   - AGENTS.md
   - AGENT_NOTES_GLOBAL.md
2) Ensure per-repo bootstrap behavior:
   - If repo AGENTS.md exists, follow it
   - If missing, create AGENTS.md + AGENT_NOTES.md
   - Create skills.md when reusable workflows are needed
3) Use precedence:
   explicit user request > nearest AGENTS.override.md > nearest AGENTS.md > parent AGENTS files > global AGENTS
4) Add repo .gitignore rules where requested:
   /docs/
   AGENT*.md
5) Configure cross-tool global compatibility by wiring these paths to <WORKSPACE_ROOT>\AGENTS.md:
   %USERPROFILE%\.codex\AGENTS.md
   %USERPROFILE%\.claude\CLAUDE.md
   %USERPROFILE%\.gemini\AGENTS.md
   %USERPROFILE%\.gemini\GEMINI.md
   %USERPROFILE%\.copilot\copilot-instructions.md
6) Ensure %USERPROFILE%\.gemini\settings.json includes:
   {"context":{"fileName":["AGENTS.md","GEMINI.md"]}}
7) Keep notes concise, dated, behavioral, no secrets.
8) Do not include clasp-specific instructions.
9) Use compact docs index + retrieval pattern for framework docs.
10) On first conversation of each new local date, pull local clone of https://github.com/khizarahmedb/agents-config with `git pull --ff-only` and update `last_config_sync_date`.
11) Treat that remote repository as read-only reference. Never mention auto-updating or auto-pushing it.

Return a verification summary with created/updated files and final precedence behavior.
```

## Notes
- This standard is intentionally portable and minimal.
- If a tool has native rule systems, those can coexist with `AGENTS.md`.
- Consumers read remote `agents-config`; owner-controlled updates happen separately.

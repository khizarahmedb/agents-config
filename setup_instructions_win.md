# Setup Instructions (Windows): Portable AGENTS/Notes Standard

## Purpose
Use this file to bootstrap the same agent-instruction system across Windows machines and repository workspaces.

This standard defines:
- One canonical global `AGENTS.md`
- One canonical global notes file
- Per-repo `AGENTS.md` + `AGENT_NOTES.md`
- Deterministic precedence and bootstrap behavior
- Cross-tool compatibility mappings

This document is intentionally not clasp-specific.

## What this setup creates

### Canonical files
- Global instruction file: `<WORKSPACE_ROOT>\AGENTS.md`
- Global notes file: `<WORKSPACE_ROOT>\AGENT_NOTES_GLOBAL.md`
- Repo instruction file: `<repo_root>\AGENTS.md`
- Repo notes file: `<repo_root>\AGENT_NOTES.md`

### Precedence
1. Explicit user request in current conversation
2. Repo-local `AGENTS.md`
3. Global `AGENTS.md`

## Step 1: Choose workspace root
Pick a directory containing multiple repositories.

Recommended example on Windows:
- `C:\Users\<USERNAME>\Documents\GitHub`

In this doc, this is `<WORKSPACE_ROOT>`.

## Step 2: Create global instruction files
Create `<WORKSPACE_ROOT>\AGENTS.md` with:

```md
# Global Agent Instructions (Workspace)

## Scope
These instructions apply to repositories under `<WORKSPACE_ROOT>`.

## Standard
- Canonical global instruction file: `<WORKSPACE_ROOT>\AGENTS.md`
- Canonical global notes file: `<WORKSPACE_ROOT>\AGENT_NOTES_GLOBAL.md`
- Canonical repo instruction file: `<repo_root>\AGENTS.md`
- Canonical repo notes file: `<repo_root>\AGENT_NOTES.md`
- Precedence order: explicit user request > repo-local instructions > global instructions

## Bootstrap Behavior
1. Determine repository root.
2. If `<repo_root>\AGENTS.md` exists, follow it and treat global file as fallback only.
3. If `<repo_root>\AGENTS.md` does not exist, create:
   - `<repo_root>\AGENTS.md`
   - `<repo_root>\AGENT_NOTES.md`
4. Continue by following repo-local `AGENTS.md`.

## Local File Templates (when missing)
Create `<repo_root>\AGENTS.md` with:

1. At the start of every conversation in this repository, read `AGENT_NOTES.md` before proposing or writing changes.
2. Use `AGENT_NOTES.md` as preference memory for communication style, delivery format, and reporting conventions.
3. When a new stable preference appears, append it to `AGENT_NOTES.md` with a date and short rationale.
4. Keep notes concise and behavioral; do not store secrets, passwords, API tokens, or personal data.
5. If a note conflicts with an explicit user request in the current conversation, follow the current explicit request and then update notes accordingly.
6. If multiple tasks are provided, prioritize the oldest requested task first and then newer tasks; if the user explicitly marks a task as urgent, complete that urgent task first and then automatically continue the remaining tasks in original order.
7. When repo-level notes are insufficient, consult `<WORKSPACE_ROOT>\AGENT_NOTES_GLOBAL.md`.
8. Do not copy global notes into local notes unless explicitly requested; reference them instead.

Create `<repo_root>\AGENT_NOTES.md` with:

# Agent Notes

- YYYY-MM-DD: <repo-specific preference>. Rationale: <why it should persist>.
- Reference: Shared/global preferences live in `<WORKSPACE_ROOT>\AGENT_NOTES_GLOBAL.md`.

## Global Notes Policy
- Global user preferences belong in `<WORKSPACE_ROOT>\AGENT_NOTES_GLOBAL.md`.
- Repo notes should contain only repository-specific behavior/preferences.
- Prefer references to global notes over duplication.
```

Create `<WORKSPACE_ROOT>\AGENT_NOTES_GLOBAL.md` with:

```md
# Global Agent Notes

- YYYY-MM-DD: If a repo lacks `AGENTS.md`, bootstrap `AGENTS.md` + `AGENT_NOTES.md` before major edits. Rationale: enforce stable repo-specific behavior.
- YYYY-MM-DD: Keep notes concise, behavioral, and free of secrets. Rationale: notes are persistent memory and should remain safe.
- YYYY-MM-DD: Prefer README/build/test checks early when modernizing repos. Rationale: reduce incorrect assumptions.
- YYYY-MM-DD: For multi-task requests, execute oldest requested task first unless user marks urgency. Rationale: deterministic priority order.
```

## Step 3: Per-repo behavior
For each repository:
- If `AGENTS.md` exists, follow it.
- If missing, create:
  - `AGENTS.md`
  - `AGENT_NOTES.md`
- Keep repo notes repo-specific.
- Reference global notes when needed.

## Step 4: Git ignore policy
In each repo where local/ephemeral agent artifacts should be untracked, add:

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

## Step 6: Bootstrap script (PowerShell, optional)
Create and run this once per machine (replace `<WORKSPACE_ROOT>`):

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
- Script falls back to copying the canonical file if symlink creation fails.

## Step 7: Verification checklist
After setup, verify:

1. Global files exist:
   - `<WORKSPACE_ROOT>\AGENTS.md`
   - `<WORKSPACE_ROOT>\AGENT_NOTES_GLOBAL.md`
2. In a target repo:
   - `AGENTS.md` exists (or was bootstrapped)
   - `AGENT_NOTES.md` exists
3. Machine mappings/files:
   - `%USERPROFILE%\.codex\AGENTS.md`
   - `%USERPROFILE%\.claude\CLAUDE.md`
   - `%USERPROFILE%\.gemini\AGENTS.md`
   - `%USERPROFILE%\.copilot\copilot-instructions.md`
4. `%USERPROFILE%\.gemini\settings.json` includes `AGENTS.md`.

## Operational rules for any AI using this system
- Always check repo-local `AGENTS.md` first.
- Read repo `AGENT_NOTES.md` before proposing major work.
- Append stable behavioral preferences with date + rationale.
- Never store secrets in notes.
- Keep notes concise.
- Use global notes as reference, not copy-paste duplication.

## Handoff prompt (paste to another AI)

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
5) Configure cross-tool global compatibility by wiring these paths to <WORKSPACE_ROOT>\\AGENTS.md:
   %USERPROFILE%\\.codex\\AGENTS.md
   %USERPROFILE%\\.claude\\CLAUDE.md
   %USERPROFILE%\\.gemini\\AGENTS.md
   %USERPROFILE%\\.gemini\\GEMINI.md
   %USERPROFILE%\\.copilot\\copilot-instructions.md
6) Ensure %USERPROFILE%\\.gemini\\settings.json includes:
   {"context":{"fileName":["AGENTS.md","GEMINI.md"]}}
7) Keep notes concise, dated, behavioral, no secrets.
8) Do not include clasp-specific instructions.

Return a verification summary with created/updated files and final precedence behavior.
```

## Notes
- This standard is intentionally portable and minimal.
- If a tool has native rule systems, those can coexist; this standard still uses `AGENTS.md` as canonical shared policy.

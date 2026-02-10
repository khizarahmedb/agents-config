param(
  [Parameter(Mandatory = $true)]
  [string]$WorkspaceRoot,

  [Parameter(Mandatory = $true)]
  [string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $RepoRoot)) {
  New-Item -ItemType Directory -Path $RepoRoot -Force | Out-Null
}

$gitignore = Join-Path $RepoRoot ".gitignore"
if (-not (Test-Path -LiteralPath $gitignore)) {
  New-Item -ItemType File -Path $gitignore -Force | Out-Null
}

$requiredLines = @(
  "/docs/",
  "AGENT*.md",
  ".agentsmd"
)

$current = @()
if (Test-Path -LiteralPath $gitignore) {
  $current = Get-Content -LiteralPath $gitignore
}

foreach ($line in $requiredLines) {
  if ($current -notcontains $line) {
    Add-Content -LiteralPath $gitignore -Value $line
  }
}

$agentsPath = Join-Path $RepoRoot "AGENTS.md"
if (-not (Test-Path -LiteralPath $agentsPath)) {
@"
# Repo Agent Instructions

1. At conversation start, read AGENT_NOTES.md before proposing or writing changes.
2. If skills.md exists, use relevant skills/workflows.
3. Prefer retrieval-led reasoning over pre-training-led reasoning for framework/version-sensitive tasks.
4. Keep instructions compact and fetch detailed docs on demand.
5. Append stable repo preferences to AGENT_NOTES.md with date and rationale.
6. Never store secrets in notes.
7. If repo notes are insufficient, consult $WorkspaceRoot/AGENT_NOTES_GLOBAL.md.
8. Reference global notes instead of duplicating them in this repo.
"@ | Set-Content -LiteralPath $agentsPath -Encoding UTF8
}

$notesPath = Join-Path $RepoRoot "AGENT_NOTES.md"
if (-not (Test-Path -LiteralPath $notesPath)) {
@"
# Agent Notes

- $(Get-Date -Format "yyyy-MM-dd"): Repository bootstrapped with standard local AGENTS policy. Rationale: ensure deterministic agent behavior from first task.
- Reference: Shared/global preferences live in $WorkspaceRoot/AGENT_NOTES_GLOBAL.md.
"@ | Set-Content -LiteralPath $notesPath -Encoding UTF8
}

$insideGit = $false
try {
  $null = git -C $RepoRoot rev-parse --is-inside-work-tree 2>$null
  if ($LASTEXITCODE -eq 0) {
    $insideGit = $true
  }
} catch {
  $insideGit = $false
}

if ($insideGit) {
  $tracked = git -C $RepoRoot ls-files -- 'AGENT*.md' '.agentsmd'
  foreach ($file in $tracked) {
    git -C $RepoRoot rm --cached --ignore-unmatch -- "$file" | Out-Null
  }
}

Write-Host "Applied policy to: $RepoRoot"
Write-Host "- ensured .gitignore: /docs/, AGENT*.md, .agentsmd"
Write-Host "- ensured AGENTS.md and AGENT_NOTES.md exist"
Write-Host "- untracked AGENT*.md/.agentsmd where previously tracked"

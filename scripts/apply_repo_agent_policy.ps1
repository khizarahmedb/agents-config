param(
  [Parameter(Mandatory = $true)]
  [string]$WorkspaceRoot,

  [Parameter(Mandatory = $true)]
  [string]$RepoRoot,

  [switch]$WithGrounded
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoAgentsTemplate = Join-Path $scriptDir "..\templates\repo\AGENTS.md.template"
$repoNotesTemplate = Join-Path $scriptDir "..\templates\repo\AGENT_NOTES.md.template"

foreach ($template in @($repoAgentsTemplate, $repoNotesTemplate)) {
  if (-not (Test-Path -LiteralPath $template)) {
    throw "Missing required template: $template"
  }
}

function Render-Template {
  param(
    [Parameter(Mandatory = $true)]
    [string]$TemplatePath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath
  )

  $content = Get-Content -LiteralPath $TemplatePath -Raw
  $content = $content.Replace("{{WORKSPACE_ROOT}}", $WorkspaceRoot)
  $content = $content.Replace("{{DATE}}", (Get-Date -Format "yyyy-MM-dd"))
  Set-Content -LiteralPath $OutputPath -Encoding UTF8 -Value $content
}

if (-not (Test-Path -LiteralPath $RepoRoot)) {
  New-Item -ItemType Directory -Path $RepoRoot -Force | Out-Null
}

$gitignore = Join-Path $RepoRoot ".gitignore"
if (-not (Test-Path -LiteralPath $gitignore)) {
  New-Item -ItemType File -Path $gitignore -Force | Out-Null
}

$requiredLines = @(
  "/docs/",
  "AGENT_NOTES*.md",
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
  Render-Template -TemplatePath $repoAgentsTemplate -OutputPath $agentsPath
}

$notesPath = Join-Path $RepoRoot "AGENT_NOTES.md"
if (-not (Test-Path -LiteralPath $notesPath)) {
  Render-Template -TemplatePath $repoNotesTemplate -OutputPath $notesPath
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
  $tracked = git -C $RepoRoot ls-files -- 'AGENT_NOTES*.md' '**/AGENT_NOTES*.md' '.agentsmd' '**/.agentsmd'
  foreach ($file in $tracked) {
    git -C $RepoRoot rm --cached --ignore-unmatch -- "$file" | Out-Null
  }
}

Write-Host "Applied policy to: $RepoRoot"
Write-Host "- ensured .gitignore: /docs/, AGENT_NOTES*.md, .agentsmd"
Write-Host "- ensured AGENTS.md and AGENT_NOTES.md exist"
Write-Host "- untracked AGENT_NOTES*.md/.agentsmd where previously tracked"

if ($WithGrounded) {
  $grounded = Get-Command grounded -ErrorAction SilentlyContinue
  if ($null -ne $grounded) {
    grounded init --path "$RepoRoot" *> $null
    grounded install --scope repo --path "$RepoRoot" --agents all *> $null
    Write-Host "- grounded repo checks installed (or already present)"
  } else {
    Write-Host "- grounded command not found; skipped grounded repo install"
  }
}

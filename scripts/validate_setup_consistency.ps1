Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ".."
$root = (Resolve-Path -LiteralPath $root).Path

$requiredFiles = @(
  "setup_instructions.md",
  "setup_instructions_ubuntu.md",
  "setup_instructions_win.md",
  "scripts\apply_repo_agent_policy.sh",
  "scripts\apply_repo_agent_policy.ps1",
  "templates\global\AGENTS.md.template",
  "templates\global\AGENT_NOTES_GLOBAL.md.template",
  "templates\repo\AGENTS.md.template",
  "templates\repo\AGENT_NOTES.md.template",
  "README.md"
)

foreach ($rel in $requiredFiles) {
  $full = Join-Path $root $rel
  if (-not (Test-Path -LiteralPath $full)) {
    throw "Missing required file: $full"
  }
}

$requiredTokens = @(
  "AGENT_NOTES*.md",
  ".agentsmd",
  "/docs/",
  "last_config_sync_date",
  "last_global_config_review_date",
  "last_global_config_review_repo",
  "read-only",
  "Review guidelines"
)
$docs = @(
  (Join-Path $root "setup_instructions.md"),
  (Join-Path $root "setup_instructions_ubuntu.md"),
  (Join-Path $root "setup_instructions_win.md")
)

foreach ($doc in $docs) {
  $content = Get-Content -LiteralPath $doc -Raw
  foreach ($token in $requiredTokens) {
    if ($content -notlike "*$token*") {
      throw "Missing token '$token' in $doc"
    }
  }
}

$winDoc = Get-Content -LiteralPath (Join-Path $root "setup_instructions_win.md") -Raw
if ($winDoc -match "<[^>]+>/") {
  throw "Windows setup doc contains Unix-style placeholder separators."
}

$tmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("agents-config-validate-" + [System.Guid]::NewGuid().ToString("N"))
$workspace = Join-Path $tmpRoot "workspace"
$repo = Join-Path $workspace "sample-repo"
New-Item -ItemType Directory -Path $repo -Force | Out-Null

& (Join-Path $root "scripts\apply_repo_agent_policy.ps1") -WorkspaceRoot $workspace -RepoRoot $repo | Out-Null
& (Join-Path $root "scripts\apply_repo_agent_policy.ps1") -WorkspaceRoot $workspace -RepoRoot $repo | Out-Null

$gitignore = Get-Content -LiteralPath (Join-Path $repo ".gitignore")
if (($gitignore | Where-Object { $_ -eq "/docs/" }).Count -ne 1) {
  throw "Non-idempotent /docs/ entry in generated .gitignore"
}
if (($gitignore | Where-Object { $_ -eq "AGENT_NOTES*.md" }).Count -ne 1) {
  throw "Non-idempotent AGENT_NOTES*.md entry in generated .gitignore"
}
if (($gitignore | Where-Object { $_ -eq ".agentsmd" }).Count -ne 1) {
  throw "Non-idempotent .agentsmd entry in generated .gitignore"
}

$agents = Get-Content -LiteralPath (Join-Path $repo "AGENTS.md") -Raw
$notes = Get-Content -LiteralPath (Join-Path $repo "AGENT_NOTES.md") -Raw
$expectedGlobal = "$workspace/AGENT_NOTES_GLOBAL.md"

if ($agents -notlike "*$expectedGlobal*") {
  throw "Generated repo AGENTS.md does not interpolate workspace path."
}
if ($notes -notlike "*$expectedGlobal*") {
  throw "Generated repo AGENT_NOTES.md does not interpolate workspace path."
}

# Verify recursive untracking removes nested AGENT_NOTES*.md but preserves AGENTS.md.
$nestedDir = Join-Path $repo "sub"
New-Item -ItemType Directory -Path $nestedDir -Force | Out-Null
Set-Content -LiteralPath (Join-Path $nestedDir "AGENT_NOTES_EXTRA.md") -Value "nested note"

git -C $repo init -q | Out-Null
git -C $repo config user.email "validate@example.com" | Out-Null
git -C $repo config user.name "validate" | Out-Null
git -C $repo add -f AGENTS.md AGENT_NOTES.md sub/AGENT_NOTES_EXTRA.md | Out-Null
git -C $repo commit -qm "seed tracked notes" | Out-Null

& (Join-Path $root "scripts\apply_repo_agent_policy.ps1") -WorkspaceRoot $workspace -RepoRoot $repo | Out-Null

git -C $repo ls-files --error-unmatch AGENT_NOTES.md *> $null
if ($LASTEXITCODE -eq 0) {
  throw "AGENT_NOTES.md should be untracked after policy application"
}
git -C $repo ls-files --error-unmatch sub/AGENT_NOTES_EXTRA.md *> $null
if ($LASTEXITCODE -eq 0) {
  throw "Nested AGENT_NOTES file should be untracked after policy application"
}
git -C $repo ls-files --error-unmatch AGENTS.md *> $null
if ($LASTEXITCODE -ne 0) {
  throw "AGENTS.md should remain tracked for Codex review guidance"
}

Write-Output "setup consistency checks passed"

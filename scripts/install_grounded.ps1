param(
  [ValidateSet("repo", "global")]
  [string]$Scope = "global",

  [string]$RepoRoot = "",

  [string]$Agents = "all",

  [switch]$WithGlobalGitTemplate
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$groundedRepo = "git+https://github.com/flow-grammer/grounded.git"

$pipx = Get-Command pipx -ErrorAction SilentlyContinue
if ($null -eq $pipx) {
  throw "pipx is required. Install pipx first."
}

pipx install --force $groundedRepo

if ($Scope -eq "global") {
  $args = @("install", "--scope", "global", "--agents", $Agents)
  if ($WithGlobalGitTemplate) {
    $args += "--global-git-template"
  }
  grounded @args
  exit 0
}

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  throw "-RepoRoot is required when -Scope repo"
}

grounded install --scope repo --path $RepoRoot --agents $Agents

# install.ps1 — gh-review Claude Code plugin installer (Windows/PowerShell)
# Usage:
#   .\install.ps1              # install to $env:USERPROFILE\.claude\
#   .\install.ps1 -DryRun      # preview without writing
#   .\install.ps1 -Uninstall   # remove installed files

param(
  [switch]$DryRun,
  [switch]$Uninstall,
  [string]$Target = ""
)

$ClaudeDir = if ($Target) { $Target } else { Join-Path $env:USERPROFILE ".claude" }
$ScriptDir = $PSScriptRoot

function Write-Ok   { param($msg) Write-Host "  v $msg" -ForegroundColor Green }
function Write-Skip { param($msg) Write-Host "  - $msg (up to date)" -ForegroundColor DarkGray }
function Write-Warn { param($msg) Write-Host "  ! $msg" -ForegroundColor Yellow }

$SkillSrc = Join-Path $ScriptDir "skills\gh-review"
$SkillDst = Join-Path $ClaudeDir "skills\gh-review"

Write-Host ""
$version = (Get-Content (Join-Path $ScriptDir "package.json") | Select-String '"version"' | Select-Object -First 1) -replace '.*"version":\s*"([^"]+)".*','$1'
Write-Host "  gh-review — Claude Code plugin v$version"
Write-Host "  Target: $ClaudeDir"
if ($DryRun) { Write-Host "  Mode: DRY RUN (no files modified)" }
Write-Host ""

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
  Write-Warn "'claude' CLI not found. Install Claude Code first: https://claude.ai/code"
}
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  Write-Warn "'gh' CLI not found. Install from https://cli.github.com/"
}

if ($Uninstall) {
  if (Test-Path $SkillDst) {
    if (-not $DryRun) { Remove-Item -Recurse -Force $SkillDst }
    Write-Ok "Removed $SkillDst"
  } else { Write-Skip "skills/gh-review (not found)" }
  Write-Host ""; Write-Host "  Uninstall complete."; Write-Host ""
  exit 0
}

$changed = 0
$skillMdDst = Join-Path $SkillDst "SKILL.md"
$skillMdSrc = Join-Path $SkillSrc "SKILL.md"

if ((Test-Path $skillMdDst) -and ((Get-FileHash $skillMdSrc).Hash -eq (Get-FileHash $skillMdDst).Hash)) {
  Write-Skip "skills/gh-review"
} else {
  if (-not $DryRun) { New-Item -ItemType Directory -Force $SkillDst | Out-Null; Copy-Item -Recurse -Force "$SkillSrc\*" $SkillDst }
  Write-Ok "skills/gh-review → $SkillDst"
  $changed++
}

Write-Host ""
if ($DryRun) { Write-Host "  [dry-run] $changed file(s) would be modified." }
else {
  Write-Host "  Done! $changed file(s) installed."
  Write-Host ""
  Write-Host "  Quick start:"
  Write-Host "    /gh-review                 # review pending drafts or scan GitHub"
  Write-Host "    /gh-review --mode=cron     # non-interactive scan"
}
Write-Host ""

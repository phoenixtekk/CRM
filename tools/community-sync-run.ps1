<#
  community-sync-run.ps1 — daily driver for the Workplace community glue (Phase E).

  Runs tools/community-sync.py, which (1) mirrors Discourse "Tips & Tricks" into the Wiki.js KB under
  Workplace/tips/<slug>, and (2) writes community demand signals to library/_index/community-signals.json
  for the /generate-solution factory. Read-only against Discourse; publishes only tips + the signal file.

  Credentials load from ~/.claude/.discourse.env (Discourse API) and ~/.claude/.wikijs.env (via the
  publish tool). Registered as Windows Scheduled Task 'PhoenixtekkCommunitySync' (daily).

  On-demand:  pwsh -File tools\community-sync-run.ps1
#>
$ErrorActionPreference = 'Stop'
$repo = 'G:\VisualStudioCode\CRM'
Set-Location $repo

$logDir = Join-Path $repo 'library\_index'
$log    = Join-Path $logDir 'community-sync-last-run.log'
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

"[$([DateTime]::Now)] community-sync run start" | Tee-Object -FilePath $log

$py = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $py) { $py = (Get-Command py -ErrorAction SilentlyContinue).Source }
if (-not $py) { "[$([DateTime]::Now)] python not found — aborting" | Tee-Object -FilePath $log -Append; exit 1 }

& $py 'tools\community-sync.py' 2>&1 | Tee-Object -FilePath $log -Append
$code = $LASTEXITCODE
"[$([DateTime]::Now)] community-sync exit=$code" | Tee-Object -FilePath $log -Append
exit $code

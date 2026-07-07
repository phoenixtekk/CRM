<#
.SYNOPSIS
  Resolve the records/retention scope and check module/connection/plan health (read-only).
.DESCRIPTION
  Confirms the required modules are present, tests Security & Compliance PowerShell and PnP
  connectivity, resolves the in-scope sites and their document libraries, and surfaces plan/cloud
  hints (compliance-licensing and Government-cloud endpoints must be verified in-tenant). A pre-flight
  helper run before configuration. Makes no changes.
.EXAMPLE
  .\Resolve-SpoRecordsScope.ps1 -Sites @("https://contoso.sharepoint.com/sites/RecordsPilot")
  # (PowerShell 5.1+/7+; PnP.PowerShell + ExchangeOnlineManagement)
.NOTES
  Expected results: a health summary (modules, connections, resolved sites/libraries) and plan/cloud
  verification reminders. Read-only; exits nonzero if a required module is missing.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$Sites
)

$ErrorActionPreference = 'Continue'
$problems = 0

# --- 1. Module health ---
foreach ($m in @('PnP.PowerShell', 'ExchangeOnlineManagement')) {
    $mod = Get-Module -ListAvailable -Name $m | Select-Object -First 1
    if ($mod) { Write-Host "  module OK: $m $($mod.Version)" -ForegroundColor Green }
    else { Write-Warning "  module MISSING: $m  (Install-Module $m -Scope CurrentUser)"; $problems++ }
}

# --- 2. Connection health (best-effort; assumes Connect-* already run) ---
try {
    $tags = Get-ComplianceTag -ErrorAction Stop
    Write-Host "  Security & Compliance PowerShell: connected ($($tags.Count) labels visible)" -ForegroundColor Green
}
catch {
    Write-Warning "  Security & Compliance PowerShell not connected - run Connect-IPPSSession. $_"
    $problems++
}

# --- 3. Scope resolution (PnP, read-only) ---
$resolved = New-Object System.Collections.Generic.List[object]
foreach ($site in $Sites) {
    try {
        Connect-PnPOnline -Url $site -Interactive
        $libs = Get-PnPList | Where-Object { $_.BaseTemplate -eq 101 -and -not $_.Hidden }
        Write-Host "  site OK: $site  ($($libs.Count) document libraries)" -ForegroundColor Green
        foreach ($l in $libs) {
            $resolved.Add([pscustomobject]@{ Site = $site; Library = $l.Title; Items = $l.ItemCount })
        }
    }
    catch {
        Write-Warning "  site UNREACHABLE: $site  $_"
        $problems++
    }
}

# --- 4. Plan / cloud reminders (cannot be auto-determined reliably) ---
Write-Host ""
Write-Host "VERIFY IN YOUR TENANT:" -ForegroundColor Cyan
Write-Host "  - Compliance licensing for records mgmt / auto-apply / adaptive scopes / disposition review." -ForegroundColor Cyan
Write-Host "  - Government cloud endpoints (e.g. *.office365.us) if not Commercial - portal paths differ." -ForegroundColor Cyan

Write-Host ""
if ($resolved.Count -gt 0) { $resolved | Format-Table -AutoSize }
if ($problems -gt 0) {
    Write-Warning "Scope/health check found $problems problem(s). Resolve before configuring."
    exit 1
}
Write-Host "Scope/health check passed." -ForegroundColor Green

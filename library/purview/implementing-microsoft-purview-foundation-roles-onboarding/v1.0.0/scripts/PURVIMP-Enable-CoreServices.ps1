<#
.SYNOPSIS
    PURVIMP-Enable-CoreServices.ps1 — core-services enablement checker/enabler for the unified audit log + Content/Activity Explorer roles (read-only by default; -Commit to enable audit).
.DESCRIPTION
    PURPOSE
        Reports the state of the Purview core data services the whole foundation depends on: the unified
        audit log (ingestion enabled?) and the Content Explorer / Activity Explorer visibility role
        groups (exist? have members?). SAFE BY DEFAULT — read-only; pass -Commit to enable the unified
        audit log (Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true), a one-time action.
        Writes the export "Purview Core Services - Enablement".
    HOW TO RUN
        # Check only (no changes):
        powershell -ExecutionPolicy Bypass -File .\PURVIMP-Enable-CoreServices.ps1
        # Enable the unified audit log (one-time; requires the appropriate admin):
        powershell -ExecutionPolicy Bypass -File .\PURVIMP-Enable-CoreServices.ps1 -Commit
        PowerShell 5.1+/7+. Requires ExchangeOnlineManagement (Connect-ExchangeOnline / Connect-IPPSSession).
    EXPECTED RESULTS
        Console + CSV showing UnifiedAuditLogIngestionEnabled and the viewer-role posture. PASS = audit
        reports True (allow up to ~24h after enabling for results) and the Content Explorer viewer role
        groups have the intended members. Audit history cannot be back-filled — enable early.
.NOTES
    Purview — Implementing Microsoft Purview: Foundation, Roles & Onboarding. Read-only unless -Commit.
    Assign the viewer role groups with PURVIMP-Set-RoleGroups.ps1. No secrets in code.
#>
[CmdletBinding()]
param(
    [switch]$Commit,
    [string]$CsvPath,
    [string]$ReportName = 'Purview Core Services - Enablement'
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop

Write-Host ("=== {0} ===" -f $ReportName) -ForegroundColor Cyan

# --- Unified audit log status (Exchange Online) ---
Connect-ExchangeOnline -ShowBanner:$false
$cfg = Get-AdminAuditLogConfig -ErrorAction SilentlyContinue
$auditOn = $false
if ($cfg -and ($cfg.PSObject.Properties.Name -contains 'UnifiedAuditLogIngestionEnabled')) {
    $auditOn = [bool]$cfg.UnifiedAuditLogIngestionEnabled
}
Write-Host ("Unified audit log ingestion enabled: {0}" -f $auditOn) -ForegroundColor $(if ($auditOn) {'Green'} else {'Yellow'})

if (-not $auditOn) {
    if ($Commit) {
        Write-Host "  -Commit set: enabling the unified audit log (one-time)..." -ForegroundColor Cyan
        try {
            Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true -ErrorAction Stop
            Write-Host "  [ENABLED] Unified audit log ingestion turned on. Results can take up to ~24 hours to appear." -ForegroundColor Green
            $auditOn = $true
        } catch {
            Write-Host ("  [ERROR] {0}" -f $_.Exception.Message) -ForegroundColor Red
        }
    } else {
        Write-Host "  [ACTION NEEDED] Audit is OFF. Re-run with -Commit to enable it (audit history cannot be back-filled)." -ForegroundColor Yellow
    }
}

# --- Content / Activity Explorer visibility role groups (S&C PowerShell) ---
Connect-IPPSSession -ShowBanner:$false
$viewerGroups = @('Content Explorer Content Viewer','Content Explorer List Viewer')
$viewerRows = foreach ($vg in $viewerGroups) {
    $rg = Get-RoleGroup -Identity $vg -ErrorAction SilentlyContinue
    if ($rg) {
        $m = @(Get-RoleGroupMember -Identity $vg -ErrorAction SilentlyContinue)
        [pscustomobject]@{ RoleGroup = $vg; Exists = $true; MemberCount = $m.Count }
    } else {
        [pscustomobject]@{ RoleGroup = $vg; Exists = $false; MemberCount = 0 }
    }
}
Write-Host '--- Content/Activity Explorer visibility roles ---' -ForegroundColor Cyan
$viewerRows | Format-Table -AutoSize
$viewerRows | Where-Object { -not $_.Exists -or $_.MemberCount -eq 0 } | ForEach-Object {
    Write-Host ("  [ACTION NEEDED] '{0}' has no members — assign reviewers with PURVIMP-Set-RoleGroups.ps1 so Content/Activity Explorer is visible." -f $_.RoleGroup) -ForegroundColor Yellow
}

$summary = [pscustomobject]@{
    UnifiedAuditLogEnabled = $auditOn
    ContentViewerExists    = ($viewerRows | Where-Object RoleGroup -eq 'Content Explorer Content Viewer').Exists
    ContentViewerMembers   = ($viewerRows | Where-Object RoleGroup -eq 'Content Explorer Content Viewer').MemberCount
    ListViewerExists       = ($viewerRows | Where-Object RoleGroup -eq 'Content Explorer List Viewer').Exists
    ListViewerMembers      = ($viewerRows | Where-Object RoleGroup -eq 'Content Explorer List Viewer').MemberCount
    CapturedUtc            = (Get-Date).ToUniversalTime().ToString('u')
}
if ($CsvPath) {
    $summary | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved '{0}' to {1}" -f $ReportName, $CsvPath) -ForegroundColor Green
}

Disconnect-ExchangeOnline -Confirm:$false | Out-Null
Write-Host 'Core-services check complete.' -ForegroundColor Green

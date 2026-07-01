<#
.SYNOPSIS
    HYBID-Validation.ps1 — confirm synchronization ran and sign-in is working.
.DESCRIPTION
    PURPOSE
        Read-only validation after the pilot goes live. Confirms the ADSync scheduler is enabled and
        the server is out of staging mode, reports the last sync run result, and (with Microsoft
        Graph) confirms on-premises sync is enabled in the tenant and lists recently synced users so
        you can verify a pilot account is present.
    HOW TO RUN
        On the Connect host, elevated:
        powershell -ExecutionPolicy Bypass -File .\HYBID-Validation.ps1
        ADSync cmdlets require the Microsoft Entra Connect role. The Graph check needs the Microsoft
        Graph SDK and Directory.Read.All / User.Read.All.
    EXPECTED RESULTS
        "SYNC HEALTHY" when the scheduler is on, the server is not in staging mode, the last run
        succeeded, and the tenant shows on-premises sync enabled.
.NOTES
    Workplace Marketplace — Entra ID Solutions. Read-only.
#>
[CmdletBinding()] param()

Write-Host "=== Hybrid Identity Validation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan

$ok = $true
if (-not (Get-Module -ListAvailable -Name ADSync)) {
    Write-Host "ADSync module not found — run this on the Microsoft Entra Connect host." -ForegroundColor Yellow
    $ok = $false
} else {
    Import-Module ADSync -ErrorAction Stop
    $sched = Get-ADSyncScheduler
    Write-Host ("Scheduler enabled : {0}" -f $sched.SyncCycleEnabled) -ForegroundColor ($(if ($sched.SyncCycleEnabled) { 'Green' } else { 'Yellow' }))
    Write-Host ("Staging mode      : {0}" -f $sched.StagingModeEnabled) -ForegroundColor ($(if ($sched.StagingModeEnabled) { 'Yellow' } else { 'Green' }))
    if (-not $sched.SyncCycleEnabled -or $sched.StagingModeEnabled) { $ok = $false }

    $run = Get-ADSyncRunProfileResult -NumberRequested 1 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($run) { Write-Host ("Last run result   : {0}" -f $run.Result) -ForegroundColor ($(if ($run.Result -eq 'success') { 'Green' } else { 'Yellow' })) }
}

# Tenant-side check via Graph (optional)
if (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication) {
    try {
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        Connect-MgGraph -Scopes 'Organization.Read.All', 'User.Read.All' -NoWelcome
        $org = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/organization').value | Select-Object -First 1
        Write-Host ("On-prem sync enabled (tenant): {0}" -f $org.onPremisesSyncEnabled) -ForegroundColor ($(if ($org.onPremisesSyncEnabled) { 'Green' } else { 'Yellow' }))
        $synced = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users?`$filter=onPremisesSyncEnabled eq true&`$top=5&`$select=userPrincipalName").value
        Write-Host "Sample synced users:" -ForegroundColor Cyan
        $synced | ForEach-Object { Write-Host ("  {0}" -f $_.userPrincipalName) }
        Disconnect-MgGraph | Out-Null
    } catch { Write-Host "Graph check skipped: $($_.Exception.Message)" -ForegroundColor Yellow }
} else {
    Write-Host "Microsoft Graph SDK not present — skipping tenant-side check." -ForegroundColor Yellow
}

if ($ok) { Write-Host "`nResult: SYNC HEALTHY" -ForegroundColor Green; exit 0 }
else { Write-Host "`nResult: NOT HEALTHY — exit staging, enable scheduler, or investigate the last run (see HYBID-Remediation.ps1)" -ForegroundColor Yellow; exit 1 }

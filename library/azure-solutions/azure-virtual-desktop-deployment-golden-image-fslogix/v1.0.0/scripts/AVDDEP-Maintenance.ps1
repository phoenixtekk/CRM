<#
.SYNOPSIS
    AVDDEP-Maintenance.ps1 — Safe drain-and-patch workflow: preview (default) or apply drain mode on session hosts ahead of an image-version replacement.
.DESCRIPTION
    PURPOSE
        Supports the patch-by-replacement workflow (03-implementation Step 10). By DEFAULT it runs in
        preview (-WhatIf) mode: it lists which hosts WOULD be drained and their active session counts,
        and changes NOTHING. Only with the explicit -Apply switch does it set AllowNewSession=$false
        (drain mode) so existing sessions finish while no new sessions land — after which you deploy
        replacement hosts from the new gallery image version and remove the drained hosts.
    HOW TO RUN
        # 1) PREVIEW (default, read-only) — always do this first:
        powershell -ExecutionPolicy Bypass -File .\AVDDEP-Maintenance.ps1 `
            -ResourceGroupName 'AVD - Resource Group - Core' -HostPoolName 'AVD - Host Pool - Pilot'
        # 2) APPLY drain (change-controlled; run in a maintenance window with rollback ready):
        powershell -ExecutionPolicy Bypass -File .\AVDDEP-Maintenance.ps1 `
            -ResourceGroupName 'AVD - Resource Group - Core' -HostPoolName 'AVD - Host Pool - Pilot' `
            -HostNames 'avdsh-pilot-0','avdsh-pilot-1' -Apply
        # To lift drain again, add -Undrain (with -Apply).
        Requires Az.Accounts, Az.DesktopVirtualization. Rollback: re-run with -Undrain -Apply, or
        redeploy the prior gallery image version via AVDDEP-SessionHosts.bicep.
    EXPECTED RESULTS
        Preview: a table of hosts, current AllowNewSession state, and active session counts — no change.
        Apply: drain mode set (or lifted with -Undrain) on the named hosts, with confirmation output.
.NOTES
    Azure Solutions — Azure Virtual Desktop (deployment/image/FSLogix/scaling).
    Change action GATED behind -Apply; defaults to a safe read-only preview.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$HostPoolName,
    [string[]]$HostNames = @(),          # empty in preview = show all hosts
    [switch]$Undrain,                    # lift drain instead of setting it
    [switch]$Apply                       # required to make any change; otherwise preview only
)

foreach ($m in 'Az.Accounts','Az.DesktopVirtualization') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module $m -Scope CurrentUser -Force -AllowClobber }
    Import-Module $m -ErrorAction Stop
}
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }

$targetAllowNewSession = [bool]$Undrain   # drain => $false ; undrain => $true
$actionWord = if ($Undrain) { 'UNDRAIN (allow new sessions)' } else { 'DRAIN (block new sessions)' }

Write-Host "`n=== AVD maintenance — $actionWord ===" -ForegroundColor Cyan
Write-Host ("Host pool: {0}" -f $HostPoolName)
if (-not $Apply) {
    Write-Host "MODE: PREVIEW (no changes). Re-run with -Apply to make changes." -ForegroundColor Yellow
} else {
    Write-Host "MODE: APPLY — this is a change-controlled action. Ensure you are in a maintenance window with rollback ready." -ForegroundColor Red
}

$allHosts = @(Get-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -ErrorAction Stop)
if (-not $allHosts) { Write-Host "No session hosts found." -ForegroundColor Yellow; return }

# Resolve targets: named hosts if provided, else all (preview shows all)
$targets = if ($HostNames.Count -gt 0) {
    $allHosts | Where-Object { $n = (($_.Name -split '/')[-1]); $HostNames | Where-Object { $n -like "$_*" } }
} else { $allHosts }

Write-Host "`nTargets:" -ForegroundColor Cyan
$targets | ForEach-Object {
    $n = ($_.Name -split '/')[-1]
    Write-Host ("  {0}  status: {1}  AllowNewSession: {2}  activeSessions: {3}" -f $n, $_.Status, $_.AllowNewSession, $_.Session)
}

if (-not $Apply) {
    Write-Host "`nPreview only — nothing changed. Add -Apply (and -HostNames) to set drain mode." -ForegroundColor Green
    return
}

foreach ($h in $targets) {
    $shortName = ($h.Name -split '/')[-1]
    if ($PSCmdlet.ShouldProcess($shortName, "Set AllowNewSession=$targetAllowNewSession")) {
        Update-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName `
            -Name $shortName -AllowNewSession:$targetAllowNewSession | Out-Null
        Write-Host ("  {0} → AllowNewSession set to {1}" -f $shortName, $targetAllowNewSession) -ForegroundColor Green
    }
}

Write-Host "`nDone. If draining: let active sessions finish, deploy replacement hosts from the new image version (AVDDEP-SessionHosts.bicep), then remove the drained hosts. Rollback: -Undrain -Apply, or redeploy the prior image version." -ForegroundColor Green

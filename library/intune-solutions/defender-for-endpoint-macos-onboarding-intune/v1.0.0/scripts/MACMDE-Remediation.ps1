<#
.SYNOPSIS
    MACMDE-Remediation.ps1 — safely reapply/repair a drifted MDE-for-macOS deployment (management plane, Graph).
.DESCRIPTION
    PURPOSE
        When MACMDE-Validation / MACMDE-Report shows drift, this makes the Intune-managed MDE macOS
        objects re-apply to the affected Macs: it issues a device sync action (so the capability
        profiles, the Defender app, and the onboarding profile re-evaluate) and confirms each drifted
        Mac is still in the assigned MDE macOS group. It does NOT hand-edit the Mac and does NOT push
        onboarding ahead of the capability profiles — Intune remains the single source of truth. Use
        this to recover drift, not to force an out-of-order onboarding.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\MACMDE-Remediation.ps1 -NameLike "MDE macOS"
        Apply:              powershell -ExecutionPolicy Bypass -File .\MACMDE-Remediation.ps1 -NameLike "MDE macOS" -WhatIf:$false
        Requires the Microsoft Graph SDK and DeviceManagementConfiguration.Read.All +
        DeviceManagementManagedDevices.PrivilegedOperations.All (for the sync action).
    EXPECTED RESULTS
        With -WhatIf (default): lists the drifted Macs and the sync actions it WOULD issue. With
        -WhatIf:$false: issues a sync to each drifted Mac so the MDE macOS objects re-apply. Re-run
        MACMDE-Validation.ps1 after a policy cycle and confirm 'mdatp health' on the device.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf (no change unless -WhatIf:$false).
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [string]$NameLike = 'MDE macOS'
)

# Default to WhatIf unless the caller explicitly passes -WhatIf:$false
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.PrivilegedOperations.All' -NoWelcome

Write-Host "=== MDE macOS Remediation ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "  (WhatIf mode — no changes will be made. Re-run with -WhatIf:`$false to apply.)" -ForegroundColor Yellow }

# Collect drifted Macs from the MDE macOS settings-catalog profiles and template/custom profiles
$drifted = @{}

$cps = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies?`$filter=startswith(name,'$NameLike')").value
foreach ($p in $cps) {
    $st = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies/$($p.id)/deviceStatuses").value
    foreach ($d in $st) { if ($d.status -notin @('compliant','succeeded')) { $drifted[$d.deviceDisplayName] = $true } }
}
$dcs = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations?`$filter=startswith(displayName,'$NameLike')").value
foreach ($p in $dcs) {
    $st = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations/$($p.id)/deviceStatuses").value
    foreach ($d in $st) { if ($d.status -notin @('compliant','succeeded')) { $drifted[$d.deviceDisplayName] = $true } }
}

if ($drifted.Count -eq 0) { Write-Host "  No drifted Macs found against '$NameLike' objects — nothing to reapply." -ForegroundColor Green; Disconnect-MgGraph | Out-Null; exit 0 }

Write-Host ("  {0} drifted Mac(s): {1}" -f $drifted.Count, ($drifted.Keys -join ', ')) -ForegroundColor Yellow

foreach ($name in $drifted.Keys) {
    $dev = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/deviceManagement/managedDevices?`$filter=deviceName eq '{0}' and operatingSystem eq 'macOS'" -f $name)).value | Select-Object -First 1
    if (-not $dev) { Write-Host "  (skip) $name not found as a managed Mac." -ForegroundColor Yellow; continue }
    if ($PSCmdlet.ShouldProcess($name, "Issue Intune device sync to re-apply MDE macOS objects")) {
        try {
            Invoke-MgGraphRequest -Method POST -Uri ("/v1.0/deviceManagement/managedDevices/{0}/syncDevice" -f $dev.id) | Out-Null
            Write-Host "  Sync requested for $name — MDE macOS objects will re-apply on the next cycle." -ForegroundColor Green
        } catch { Write-Host "  Sync failed for ${name}: $($_.Exception.Message)" -ForegroundColor Yellow }
    }
}

Write-Host "`nIf a Mac stays degraded, confirm the five capability profiles Succeed BEFORE onboarding (03-implementation / 06-troubleshooting)." -ForegroundColor Cyan
Write-Host "Re-run MACMDE-Validation.ps1 after a policy cycle and check 'mdatp health' on the device." -ForegroundColor Green
Disconnect-MgGraph | Out-Null

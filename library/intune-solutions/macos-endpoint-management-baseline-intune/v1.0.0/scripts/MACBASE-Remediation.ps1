<#
.SYNOPSIS
    MACBASE-Remediation.ps1 — safely reapply/repair a drifted macOS baseline (management plane, Graph).
.DESCRIPTION
    PURPOSE
        When MACBASE-Validation / MACBASE-Report shows drift, this makes the Intune-managed macOS
        baseline objects re-apply to the affected Macs: it issues a device sync action (so the
        configuration policies, custom profiles, and compliance policy re-evaluate) to each drifted
        Mac. It does NOT hand-edit settings on the Mac — Intune remains the single source of truth. It
        is safe by default: it previews unless you pass -WhatIf:$false.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\MACBASE-Remediation.ps1 -PolicyNameLike "macOS Baseline"
        Apply:              powershell -ExecutionPolicy Bypass -File .\MACBASE-Remediation.ps1 -PolicyNameLike "macOS Baseline" -WhatIf:$false
        Requires the Microsoft Graph SDK and DeviceManagementConfiguration.Read.All +
        DeviceManagementManagedDevices.PrivilegedOperations.All (for the sync action).
    EXPECTED RESULTS
        With -WhatIf (default): lists the drifted Macs and the sync actions it WOULD issue, no change.
        With -WhatIf:$false: issues a sync to each drifted Mac so the baseline objects re-apply.
        Re-run MACBASE-Validation.ps1 after a policy cycle to confirm the drift cleared.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf (no change unless -WhatIf:$false).
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [string]$PolicyNameLike = 'macOS Baseline'
)

# Default to WhatIf unless the caller explicitly passes -WhatIf:$false
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.PrivilegedOperations.All' -NoWelcome

Write-Host "=== macOS Baseline Remediation ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "  (WhatIf mode — no changes will be made. Re-run with -WhatIf:`$false to apply.)" -ForegroundColor Yellow }

# Collect drifted Macs from the baseline settings-catalog policy device statuses
$drifted = @{}
$cps = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies?`$filter=startswith(name,'$PolicyNameLike')").value
foreach ($p in $cps) {
    $st = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies/$($p.id)/deviceStatuses").value
    foreach ($d in $st) { if ($d.status -notin @('compliant','succeeded','success')) { $drifted[$d.deviceDisplayName] = $true } }
}

if ($drifted.Count -eq 0) { Write-Host "  No drifted Macs found against '$PolicyNameLike' policies — nothing to reapply." -ForegroundColor Green; Disconnect-MgGraph | Out-Null; exit 0 }

Write-Host ("  {0} drifted Mac(s): {1}" -f $drifted.Count, ($drifted.Keys -join ', ')) -ForegroundColor Yellow

foreach ($name in $drifted.Keys) {
    $dev = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/deviceManagement/managedDevices?`$filter=deviceName eq '{0}' and operatingSystem eq 'macOS'" -f $name)).value | Select-Object -First 1
    if (-not $dev) { Write-Host "  (skip) $name not found as a managed Mac." -ForegroundColor Yellow; continue }
    if ($PSCmdlet.ShouldProcess($name, "Issue Intune device sync to re-apply macOS baseline objects")) {
        try {
            Invoke-MgGraphRequest -Method POST -Uri ("/v1.0/deviceManagement/managedDevices/{0}/syncDevice" -f $dev.id) | Out-Null
            Write-Host "  Sync requested for $name — baseline objects will re-apply on the next cycle." -ForegroundColor Green
        } catch { Write-Host "  Sync failed for ${name}: $($_.Exception.Message)" -ForegroundColor Yellow }
    }
}

Write-Host "`nIf a Mac keeps drifting, resolve the conflicting profile or the second authority setting the same payload (see Troubleshooting)." -ForegroundColor Cyan
Write-Host "Re-run MACBASE-Validation.ps1 after a policy cycle to confirm the drift cleared." -ForegroundColor Green
Disconnect-MgGraph | Out-Null

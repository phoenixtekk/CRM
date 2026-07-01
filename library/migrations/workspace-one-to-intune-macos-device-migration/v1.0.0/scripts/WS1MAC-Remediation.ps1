<#
.SYNOPSIS
    WS1MAC-Remediation.ps1 — safely re-apply parity to stuck migrated Macs (Intune, Graph).
.DESCRIPTION
    PURPOSE
        When WS1MAC-Validation / WS1MAC-Report shows a migrated Mac that enrolled but whose parity
        objects did not fully apply (or drifted), this issues a device sync action so the Intune
        settings-catalog policies, custom profiles, and shell scripts re-evaluate and re-apply, and
        confirms the Mac is still in its assigned migration ring group. It does NOT hand-edit settings
        on the Mac — Intune stays the single source of truth; on-device enforcement remains in the
        Apple .mobileconfig/shell controls. It does NOT reassign devices in Apple Business Manager or
        touch Workspace ONE; those are done in their consoles (deferred to vendor docs).
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\WS1MAC-Remediation.ps1 -ParityNameLike "WS1MAC Parity"
        Apply:              powershell -ExecutionPolicy Bypass -File .\WS1MAC-Remediation.ps1 -ParityNameLike "WS1MAC Parity" -WhatIf:$false
        Requires the Microsoft Graph PowerShell SDK and DeviceManagementConfiguration.Read.All +
        DeviceManagementManagedDevices.PrivilegedOperations.All (for the sync action).
    EXPECTED RESULTS
        With -WhatIf (default): lists the drifted/stuck Macs and the sync actions it WOULD issue. With
        -WhatIf:$false: issues a sync to each so the parity objects re-apply. Re-run
        WS1MAC-Validation.ps1 after a policy cycle.
.NOTES
    Migrations — Workspace ONE to Intune macOS. Defaults to -WhatIf (no change unless -WhatIf:$false). ABM/WS1 actions deferred to vendor consoles.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [string]$ParityNameLike = 'WS1MAC Parity'
)

# Default to WhatIf unless the caller explicitly passes -WhatIf:$false
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.PrivilegedOperations.All' -NoWelcome

Write-Host "=== WS1->Intune macOS Remediation ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "  (WhatIf mode — no changes will be made. Re-run with -WhatIf:`$false to apply.)" -ForegroundColor Yellow }

# Collect drifted/stuck Macs from the WS1MAC parity settings-catalog device statuses
$drifted = @{}
$cps = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies?`$filter=startswith(name,'$ParityNameLike')").value
foreach ($p in $cps) {
    $st = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies/$($p.id)/deviceStatuses").value
    foreach ($d in $st) { if ($d.status -notin @('compliant','succeeded')) { $drifted[$d.deviceDisplayName] = $true } }
}

if ($drifted.Count -eq 0) { Write-Host "  No drifted/stuck Macs found against '$ParityNameLike' objects — nothing to reapply." -ForegroundColor Green; Disconnect-MgGraph | Out-Null; exit 0 }

Write-Host ("  {0} drifted/stuck Mac(s): {1}" -f $drifted.Count, ($drifted.Keys -join ', ')) -ForegroundColor Yellow

foreach ($name in $drifted.Keys) {
    $dev = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/deviceManagement/managedDevices?`$filter=deviceName eq '{0}' and operatingSystem eq 'macOS'" -f $name)).value | Select-Object -First 1
    if (-not $dev) { Write-Host "  (skip) $name not found as a managed Mac." -ForegroundColor Yellow; continue }
    if ($PSCmdlet.ShouldProcess($name, "Issue Intune device sync to re-apply WS1MAC parity objects")) {
        try {
            Invoke-MgGraphRequest -Method POST -Uri ("/v1.0/deviceManagement/managedDevices/{0}/syncDevice" -f $dev.id) | Out-Null
            Write-Host "  Sync requested for $name — WS1MAC parity objects will re-apply on the next cycle." -ForegroundColor Green
        } catch { Write-Host "  Sync failed for ${name}: $($_.Exception.Message)" -ForegroundColor Yellow }
    }
}

Write-Host "`nIf a Mac keeps drifting, resolve the conflicting profile or add a re-enforcement schedule to the shell-script parity (see Troubleshooting C/D)." -ForegroundColor Cyan
Write-Host "If a Mac never enrolled, fix it in ABM/Workspace ONE (reassign MDM server / release source) — those are vendor-console actions." -ForegroundColor DarkGray
Write-Host "Re-run WS1MAC-Validation.ps1 after a policy cycle to confirm parity re-applied." -ForegroundColor Green
Disconnect-MgGraph | Out-Null

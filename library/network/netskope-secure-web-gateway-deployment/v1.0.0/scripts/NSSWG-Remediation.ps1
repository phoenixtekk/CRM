<#
.SYNOPSIS
    NSSWG-Remediation.ps1 — safely fix mis-steered / non-compliant devices (default -WhatIf).
.DESCRIPTION
    PURPOSE
        For a device that should be steered but is not, this re-adds it to a steering-scope Entra
        group and requests an Intune/MDM sync so the client app, certificate, and steering config
        re-apply. SAFE BY DEFAULT: runs in -WhatIf mode and only reports intended actions unless you
        pass -Apply. Inline proxy affects live traffic — review the plan before applying.
    HOW TO RUN
        Preview (default): powershell -ExecutionPolicy Bypass -File .\NSSWG-Remediation.ps1 -DeviceId <entraDeviceId>
        Apply:             powershell -ExecutionPolicy Bypass -File .\NSSWG-Remediation.ps1 -DeviceId <entraDeviceId> -Apply
        On-device sync only: run elevated with -LocalSync on the affected device.
    EXPECTED RESULTS
        With no -Apply: a printed plan (what would change). With -Apply: the device is added to the
        target steering group and a sync is requested. Re-run NSSWG-Validation.ps1 afterward.
.NOTES
    Workplace Marketplace — Network Solutions. Mutating actions are gated behind -Apply.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$DeviceId,
    [string]$TargetGroup = 'Web Steering - Broad - Stage 2',
    [switch]$Apply,
    [switch]$LocalSync
)

# Default to preview unless -Apply is explicitly passed.
if (-not $Apply) { $WhatIfPreference = $true }

Write-Host "=== Netskope SWG Remediation (Apply=$($Apply.IsPresent)) ===" -ForegroundColor Cyan

if ($LocalSync) {
    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Request Intune/MDM sync so steering config re-applies')) {
        Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
        Write-Host "  MDM sync requested on $($env:COMPUTERNAME)." -ForegroundColor Green
    }
    Write-Host "Re-run NSSWG-Validation.ps1 after a policy cycle." -ForegroundColor Green
    return
}

if (-not $DeviceId) { Write-Host "Provide -DeviceId (Entra device object id) or use -LocalSync on the device." -ForegroundColor Yellow; return }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','DeviceManagementManagedDevices.PrivilegedOperations.All' -NoWelcome

# Resolve the target steering group
$enc = [uri]::EscapeDataString($TargetGroup)
$grp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$enc'").value | Select-Object -First 1
if (-not $grp) { Write-Host "Target group '$TargetGroup' not found — create it with NSSWG-Set-ScopeTargeting.ps1." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

if ($PSCmdlet.ShouldProcess("device $DeviceId", "add to steering group '$TargetGroup'")) {
    $body = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$DeviceId" }
    try {
        Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$($grp.id)/members/`$ref" -Body ($body | ConvertTo-Json)
        Write-Host "  Added device $DeviceId to '$TargetGroup'." -ForegroundColor Green
    } catch {
        Write-Host ("  Add failed (may already be a member): {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
}

# Request an Intune sync for the device (best-effort; requires the managed device id, not the Entra id, on some tenants)
if ($PSCmdlet.ShouldProcess("device $DeviceId", "request Intune sync")) {
    try {
        Invoke-MgGraphRequest -Method POST -Uri "/v1.0/deviceManagement/managedDevices/$DeviceId/syncDevice"
        Write-Host "  Intune sync requested." -ForegroundColor Green
    } catch {
        Write-Host ("  Sync request skipped (use the managedDevice id if needed): {0}" -f $_.Exception.Message) -ForegroundColor DarkGray
    }
}

Disconnect-MgGraph | Out-Null
Write-Host "`nRe-run NSSWG-Validation.ps1 on the device after a policy cycle." -ForegroundColor Cyan

<#
.SYNOPSIS
    MACFV-Remediation.ps1 — safely re-apply the FileVault policy to unencrypted/unescrowed Macs (management plane, Graph).
.DESCRIPTION
    PURPOSE
        When MACFV-Validation / MACFV-Report shows a Mac that is not encrypted, or is encrypted but
        has NO escrowed personal recovery key, this issues an Intune device sync so the assigned
        FileVault disk-encryption policy re-evaluates and Intune escrows (or rotates to) a fresh
        personal recovery key. It does NOT change FileVault on the Mac directly and does NOT decrypt
        anything — Intune stays the single source of truth. On-device enablement still requires a
        SecureToken-enabled user (see Troubleshooting A/C).
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\MACFV-Remediation.ps1
        Apply:              powershell -ExecutionPolicy Bypass -File .\MACFV-Remediation.ps1 -WhatIf:$false
        Target one Mac:     powershell -ExecutionPolicy Bypass -File .\MACFV-Remediation.ps1 -DeviceName "MAC-001" -WhatIf:$false
        Requires the Microsoft Graph SDK and DeviceManagementManagedDevices.Read.All +
        DeviceManagementManagedDevices.PrivilegedOperations.All (for the sync action + key read).
    EXPECTED RESULTS
        With -WhatIf (default): lists the at-risk Macs and the sync actions it WOULD issue. With
        -WhatIf:$false: issues a sync to each so the FileVault policy re-applies. Re-run
        MACFV-Validation.ps1 after a policy cycle.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf (no change unless -WhatIf:$false). Read-only against Graph otherwise.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [string]$DeviceName,
    [switch]$WhatIf = $true
)

# Default to WhatIf unless the caller explicitly passes -WhatIf:$false
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }
elseif ($WhatIf) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementManagedDevices.PrivilegedOperations.All' -NoWelcome

Write-Host "=== FileVault Remediation ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "  (WhatIf mode — no changes will be made. Re-run with -WhatIf:`$false to apply.)" -ForegroundColor Yellow }

function Get-FvKey([string]$id) { try { $k = Invoke-MgGraphRequest -Method GET -Uri ("/beta/deviceManagement/managedDevices/{0}/getFileVaultKey" -f $id); return $k.value } catch { return $null } }

# Build the candidate list: not encrypted OR encrypted-without-escrow
$filter = "operatingSystem eq 'macOS'"
if ($DeviceName) { $filter += (" and deviceName eq '{0}'" -f $DeviceName) }
$macs = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/deviceManagement/managedDevices?`$filter={0}&`$select=id,deviceName,isEncrypted" -f $filter)).value

$atRisk = foreach ($m in $macs) {
    $hasKey = [bool](Get-FvKey $m.id)
    if (-not $m.isEncrypted -or -not $hasKey) {
        $reason = if (-not $m.isEncrypted) { 'not encrypted' } else { 'encrypted but not escrowed' }
        [pscustomobject]@{ Id=$m.id; Device=$m.deviceName; Reason=$reason }
    }
}

if (-not $atRisk) { Write-Host "  No at-risk Macs found (all encrypted + escrowed) — nothing to reapply." -ForegroundColor Green; Disconnect-MgGraph | Out-Null; exit 0 }

Write-Host ("  {0} at-risk Mac(s):" -f ($atRisk | Measure-Object).Count) -ForegroundColor Yellow
$atRisk | ForEach-Object { Write-Host ("    - {0} ({1})" -f $_.Device, $_.Reason) -ForegroundColor Yellow }

foreach ($m in $atRisk) {
    if ($PSCmdlet.ShouldProcess($m.Device, "Issue Intune device sync to re-apply the FileVault policy")) {
        try {
            Invoke-MgGraphRequest -Method POST -Uri ("/v1.0/deviceManagement/managedDevices/{0}/syncDevice" -f $m.Id) | Out-Null
            Write-Host ("  Sync requested for {0} — FileVault policy will re-apply on the next cycle." -f $m.Device) -ForegroundColor Green
        } catch { Write-Host ("  Sync failed for {0}: {1}" -f $m.Device, $_.Exception.Message) -ForegroundColor Yellow }
    }
}

Write-Host "`nIf a Mac stays 'not encrypted' after sync, it likely has no SecureToken user (Troubleshooting A/C)." -ForegroundColor Cyan
Write-Host "Re-run MACFV-Validation.ps1 after a policy cycle to confirm encryption + escrow." -ForegroundColor Green
Disconnect-MgGraph | Out-Null

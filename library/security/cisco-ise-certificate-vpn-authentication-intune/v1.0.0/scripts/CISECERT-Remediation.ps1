<#
.SYNOPSIS
    CISECERT-Remediation.ps1 — safely re-trigger failed VPN certificate issuance (default -WhatIf).
.DESCRIPTION
    PURPOSE
        For devices whose Cisco VPN SCEP/PKCS certificate profile shows Error/Pending, performs the
        safe, reversible remediation that resolves the common causes: triggers a device sync/check-in
        so the certificate profile re-evaluates and re-requests issuance. It does NOT delete
        certificates, unassign profiles, or touch any CA. By default it only REPORTS what it would do
        (-WhatIf); pass -Apply to act.
    HOW TO RUN
        Report only (default):  powershell -ExecutionPolicy Bypass -File .\CISECERT-Remediation.ps1 -CertProfileMatch "Cisco VPN"
        Apply:                  powershell -ExecutionPolicy Bypass -File .\CISECERT-Remediation.ps1 -CertProfileMatch "Cisco VPN" -Apply
        Requires the Microsoft Graph PowerShell SDK and consent to:
        DeviceManagementConfiguration.Read.All, DeviceManagementManagedDevices.Read.All,
        DeviceManagementManagedDevices.PrivilegedOperations.All (to send a sync action).
    EXPECTED RESULTS
        A list of devices in Error/Pending on the matched Cisco VPN cert profiles; with -Apply, a sync
        action is issued to each so issuance re-evaluates at next check-in. Re-run CISECERT-Report.ps1
        after a sync cycle to confirm the move to Succeeded.
.NOTES
    White-label — the repeatable way. Safe by default (-WhatIf). Connector/CA repair is out of scope; Cisco ISE internals deferred to vendor docs.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [string]$CertProfileMatch = 'Cisco VPN',
    [switch]$Apply
)

# Default posture is -WhatIf unless -Apply is explicitly passed.
if (-not $Apply -and -not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = @('DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.PrivilegedOperations.All','DeviceManagementManagedDevices.Read.All')
Connect-MgGraph -Scopes $scopes -NoWelcome

$cfgs = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/deviceConfigurations').value
$certProfiles = $cfgs | Where-Object { $_.'@odata.type' -match 'scepCertificate|pkcsCertificate' -and $_.displayName -like "*$CertProfileMatch*" }
if (-not $certProfiles) { Write-Host "No Cisco VPN cert profiles match '$CertProfileMatch'." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

$targets = @{}
foreach ($p in $certProfiles) {
    $statuses = @()
    try { $statuses = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations/$($p.id)/deviceStatuses").value } catch { }
    foreach ($s in ($statuses | Where-Object { $_.status -in @('error','nonCompliant','pending','unknown') })) {
        if ($s.deviceId) { $targets[$s.deviceId] = $s.deviceDisplayName }
    }
}

Write-Host ("`n{0} device(s) in Error/Pending on Cisco VPN cert profiles." -f $targets.Count) -ForegroundColor Cyan
if ($targets.Count -eq 0) { Disconnect-MgGraph | Out-Null; return }

foreach ($kv in $targets.GetEnumerator()) {
    $deviceId = $kv.Key; $name = $kv.Value
    if ($PSCmdlet.ShouldProcess("$name ($deviceId)", "Send Intune sync to re-evaluate certificate issuance")) {
        try {
            Invoke-MgGraphRequest -Method POST -Uri "/beta/deviceManagement/managedDevices/$deviceId/syncDevice" | Out-Null
            Write-Host ("  SYNC sent: {0}" -f $name) -ForegroundColor Green
        } catch {
            Write-Host ("  Sync failed for {0}: {1}" -f $name, $_.Exception.Message) -ForegroundColor Red
        }
    }
}

Write-Host "`nRe-run CISECERT-Report.ps1 after a check-in cycle to confirm Succeeded. Persistent failures →" -ForegroundColor Yellow
Write-Host "Troubleshooting A (no cert) — check connector/CA health; those repairs are deferred to vendor docs." -ForegroundColor Yellow
Disconnect-MgGraph | Out-Null

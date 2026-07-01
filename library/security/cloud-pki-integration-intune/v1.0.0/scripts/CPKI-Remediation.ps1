<#
.SYNOPSIS
    CPKI-Remediation.ps1 — safe remediation of failed certificate issuance (default -WhatIf).
.DESCRIPTION
    PURPOSE
        For devices whose cloud PKI SCEP/PKCS profile shows Error/Pending, performs the safe, reversible
        remediations that resolve the common causes: trigger a device sync/check-in so the certificate
        profile re-evaluates and re-requests issuance. It does NOT delete certificates, unassign
        profiles, or touch the cloud PKI CA. By default it only REPORTS what it would do (-WhatIf);
        pass -Apply to act.
    HOW TO RUN
        Report only (default):  powershell -ExecutionPolicy Bypass -File .\CPKI-Remediation.ps1 `
                                    -CloudPkiProfileMatch "Cloud PKI"
        Apply:                  ... .\CPKI-Remediation.ps1 -CloudPkiProfileMatch "Cloud PKI" -Apply
        Requires the Microsoft Graph SDK and: DeviceManagementConfiguration.Read.All,
        DeviceManagementManagedDevices.PrivilegedOperations.All (to send a sync action).
    EXPECTED RESULTS
        A list of devices in Error/Pending on the matched cloud PKI cert profiles; with -Apply, a sync
        action is issued to each so issuance re-evaluates at next check-in. Re-run CPKI-Report.ps1 after
        a sync cycle to confirm the move to Succeeded.
.NOTES
    White-label — the repeatable way. Safe by default (-WhatIf). Connector repair and cloud-PKI CA/
    template fixes are out of scope and deferred to the vendor's documentation (see Troubleshooting A/C).
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [string]$CloudPkiProfileMatch = 'Cloud PKI',
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
$certProfiles = $cfgs | Where-Object { $_.'@odata.type' -match 'scepCertificate|pkcsCertificate' -and $_.displayName -like "*$CloudPkiProfileMatch*" }
if (-not $certProfiles) { Write-Host "No cloud PKI cert profiles match '$CloudPkiProfileMatch'." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

$targets = @{}
foreach ($p in $certProfiles) {
    $statuses = @()
    try { $statuses = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations/$($p.id)/deviceStatuses").value } catch { }
    foreach ($s in ($statuses | Where-Object { $_.status -in @('error','nonCompliant','pending','unknown') })) {
        if ($s.deviceId) { $targets[$s.deviceId] = $s.deviceDisplayName }
    }
}

Write-Host ("`n{0} device(s) in Error/Pending on cloud PKI cert profiles." -f $targets.Count) -ForegroundColor Cyan
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

Write-Host "`nRe-run CPKI-Report.ps1 after a check-in cycle to confirm Succeeded." -ForegroundColor Yellow
Disconnect-MgGraph | Out-Null

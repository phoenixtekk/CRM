<#
.SYNOPSIS
    CISECERT-Report.ps1 — VPN certificate deployment + expiry coverage across the fleet (Graph).
.DESCRIPTION
    PURPOSE
        Builds a fleet-wide picture of certificate coverage to drive the pilot and expansion gates:
        for each managed device it reports the SCEP/PKCS certificate profile deployment state
        (Succeeded / Error / Pending) for the Cisco VPN certificate profiles, so coverage and laggards
        are visible before you expand. Read-only against Microsoft Graph.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CISECERT-Report.ps1 -CertProfileMatch "Cisco VPN" -CsvPath .\cisecert-coverage.csv
        Requires the Microsoft Graph PowerShell SDK and consent to:
        DeviceManagementConfiguration.Read.All, DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        A per-profile deployment-state summary (how many devices Succeeded / Error / Pending) for the
        matched Cisco VPN cert profiles, with an optional CSV export. Exact per-device certificate
        expiry (NotAfter) lives on the device — run CISECERT-Validation.ps1 there for precise dates.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. Cisco ISE internals deferred to vendor docs.
#>
[CmdletBinding()]
param(
    [string]$CertProfileMatch = 'Cisco VPN',
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome

$cfgs = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/deviceConfigurations').value
$certProfiles = $cfgs | Where-Object {
    $_.'@odata.type' -match 'scepCertificate|pkcsCertificate' -and $_.displayName -like "*$CertProfileMatch*"
}

function Report-Profile($certProfile) {
    $statuses = @()
    try {
        $statuses = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations/$($certProfile.id)/deviceStatuses").value
    } catch { }
    $succeeded = ($statuses | Where-Object { $_.status -eq 'compliant' -or $_.status -eq 'succeeded' }).Count
    $errors    = ($statuses | Where-Object { $_.status -eq 'error' -or $_.status -eq 'nonCompliant' }).Count
    $pending   = ($statuses | Where-Object { $_.status -eq 'pending' -or $_.status -eq 'unknown' }).Count
    Write-Host ("  {0}: Succeeded={1}  Error={2}  Pending={3}  Total={4}" -f `
        $certProfile.displayName, $succeeded, $errors, $pending, $statuses.Count)
    foreach ($s in $statuses) {
        [pscustomobject]@{
            Profile      = $certProfile.displayName
            Device       = $s.deviceDisplayName
            UserName     = $s.userName
            Status       = $s.status
            LastReported = $s.lastReportedDateTime
        }
    }
}

$rows = @()
Write-Host "`n=== Cisco VPN certificate profiles — coverage ===" -ForegroundColor Cyan
if (-not $certProfiles) { Write-Host "  No SCEP/PKCS profiles matching '$CertProfileMatch'." -ForegroundColor Yellow }
foreach ($p in $certProfiles) { $rows += Report-Profile $p }

if ($CsvPath -and $rows.Count) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`nExported {0} rows to {1}" -f $rows.Count, $CsvPath) -ForegroundColor Green
}

Write-Host "`nExpansion gate: expected Succeeded count with no unresolved Error/Pending." -ForegroundColor Yellow
Write-Host "For exact per-device certificate expiry (NotAfter), run CISECERT-Validation.ps1 on the device." -ForegroundColor Yellow
Disconnect-MgGraph | Out-Null

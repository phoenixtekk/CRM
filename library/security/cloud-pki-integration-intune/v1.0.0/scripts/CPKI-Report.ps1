<#
.SYNOPSIS
    CPKI-Report.ps1 — certificate coverage + expiry across managed devices (Graph).
.DESCRIPTION
    PURPOSE
        Builds a fleet-wide picture of certificate coverage to drive the migration and expansion
        gates: for each managed device it reports the SCEP/PKCS certificate profile deployment state
        (Succeeded / Error / Pending) and surfaces which devices are still depending on a legacy CA
        vs the cloud PKI, plus upcoming expiries to chase. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CPKI-Report.ps1 `
            -CloudPkiProfileMatch "Cloud PKI" [-LegacyProfileMatch "Legacy"] [-CsvPath .\cpki-coverage.csv]
        Requires the Microsoft Graph SDK and: DeviceManagementConfiguration.Read.All,
        DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        A per-profile deployment-state summary (how many devices Succeeded / Error / Pending) for the
        cloud PKI cert profiles (and legacy, if matched), so coverage and laggards are visible. Optional
        CSV export. Device-internal certificate expiry dates live on the device — use CPKI-Validation.ps1
        per device for exact NotAfter; cloud-PKI PRODUCT issuance APIs are deferred to vendor docs.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$CloudPkiProfileMatch = 'Cloud PKI',
    [string]$LegacyProfileMatch,
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome

$cfgs = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/deviceConfigurations').value
$certProfiles = $cfgs | Where-Object { $_.'@odata.type' -match 'scepCertificate|pkcsCertificate' }

function Report-Profile($profile,$label) {
    $statuses = @()
    try {
        $statuses = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations/$($profile.id)/deviceStatuses").value
    } catch { }
    $succeeded = ($statuses | Where-Object { $_.status -eq 'compliant' -or $_.status -eq 'succeeded' }).Count
    $errors    = ($statuses | Where-Object { $_.status -eq 'error' -or $_.status -eq 'nonCompliant' }).Count
    $pending   = ($statuses | Where-Object { $_.status -eq 'pending' -or $_.status -eq 'unknown' }).Count
    Write-Host ("  [{0}] {1}: Succeeded={2}  Error={3}  Pending={4}  Total={5}" -f `
        $label, $profile.displayName, $succeeded, $errors, $pending, $statuses.Count)
    foreach ($s in $statuses) {
        [pscustomobject]@{
            ProfileLabel = $label
            Profile      = $profile.displayName
            Device       = $s.deviceDisplayName
            UserName     = $s.userName
            Status       = $s.status
            LastReported = $s.lastReportedDateTime
        }
    }
}

$rows = @()
Write-Host "`n=== Cloud PKI certificate profiles — coverage ===" -ForegroundColor Cyan
$cloud = $certProfiles | Where-Object { $_.displayName -like "*$CloudPkiProfileMatch*" }
if (-not $cloud) { Write-Host "  None matching '$CloudPkiProfileMatch'." -ForegroundColor Yellow }
foreach ($p in $cloud) { $rows += Report-Profile $p 'CLOUD' }

if ($LegacyProfileMatch) {
    Write-Host "`n=== Legacy CA certificate profiles — remaining dependency ===" -ForegroundColor Cyan
    $legacy = $certProfiles | Where-Object { $_.displayName -like "*$LegacyProfileMatch*" }
    if (-not $legacy) { Write-Host "  None matching '$LegacyProfileMatch' — legacy may already be retired." -ForegroundColor Green }
    foreach ($p in $legacy) { $rows += Report-Profile $p 'LEGACY' }
}

if ($CsvPath -and $rows.Count) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`nExported {0} rows to {1}" -f $rows.Count, $CsvPath) -ForegroundColor Green
}

Write-Host "`nFor exact per-device certificate expiry (NotAfter), run CPKI-Validation.ps1 on the device." -ForegroundColor Yellow
Disconnect-MgGraph | Out-Null

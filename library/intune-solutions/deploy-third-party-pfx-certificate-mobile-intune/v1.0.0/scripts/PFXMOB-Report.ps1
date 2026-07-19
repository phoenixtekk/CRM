<#
.SYNOPSIS
    PFXMOB-Report.ps1 — fleet-wide certificate-deployment status for the iOS app-certificate profiles.
    READ-ONLY.
.DESCRIPTION
    PURPOSE
        Produces a per-device deployment summary across the certificate profiles used by this
        solution (the trusted chain profile and the delivery profile), so you can see at a glance
        which devices have the certificate delivered and which are pending/failed.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PFXMOB-Report.ps1
        Optional:  -ProfileNames @('Trusted Root - Org CA - iOS','PFX Imported - iOS App Cert - Pilot')
        Optional:  -CsvPath .\pfx-report.csv   (also writes a CSV)
    EXPECTED RESULTS
        A table of device | profile | state, plus a per-state count. No changes are made.
.NOTES
    Intune Solutions. Read-only. Documented Graph endpoints
    (deviceConfigurations + deviceStatuses).
#>
[CmdletBinding()] param(
    [string[]] $ProfileNames = @(
        'Trusted Root - Org CA - iOS',
        'PFX Imported - iOS App Cert - Pilot',
        'PFX Imported - iOS App Cert - Broad',
        'Custom PKCS12 - iOS App Cert - Pilot',
        'Custom PKCS12 - iOS App Cert - Broad'),
    [string] $CsvPath
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' -NoWelcome

Write-Host "`n=== Third-Party PFX to Mobile — Fleet Report ===" -ForegroundColor Cyan

$allProfiles = (Invoke-MgGraphRequest -Method GET `
    -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations').value
$targets = $allProfiles | Where-Object { $ProfileNames -contains $_.displayName }
if (-not $targets) { Write-Host "None of the named profiles were found. Check -ProfileNames." -ForegroundColor Yellow; return }

$rows = foreach ($p in $targets) {
    $statuses = (Invoke-MgGraphRequest -Method GET `
        -Uri "https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations/$($p.id)/deviceStatuses").value
    foreach ($s in $statuses) {
        [pscustomobject]@{
            Device  = $s.deviceDisplayName
            Profile = $p.displayName
            State   = $s.status
            Updated = $s.lastReportedDateTime
        }
    }
}

if (-not $rows) { Write-Host "No device status reported yet for these profiles." -ForegroundColor Yellow; return }
$rows | Sort-Object Device, Profile | Format-Table -AutoSize

Write-Host "`nState summary:" -ForegroundColor Cyan
$rows | Group-Object State | ForEach-Object { Write-Host ("  {0,-12} {1}" -f $_.Name, $_.Count) }

if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host "`nCSV written: $CsvPath" -ForegroundColor Green }
Disconnect-MgGraph | Out-Null

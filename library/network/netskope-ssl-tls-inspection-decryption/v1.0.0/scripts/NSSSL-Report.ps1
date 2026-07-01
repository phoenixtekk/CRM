<#
.SYNOPSIS
    NSSSL-Report.ps1 — fleet certificate-trust deployment + decryption-readiness inventory (Graph).
.DESCRIPTION
    PURPOSE
        Reports, across managed Windows devices in Intune, the deployment state of the trusted
        inspection-certificate profile and basic device readiness (last sync), so you can confirm
        certificate trust precedes decryption and chase laggards before they hit a decrypt policy.
        Netskope decryption-policy coverage is in the Netskope console (deferred).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\NSSSL-Report.ps1 -ProfileNameMatch 'Netskope Inspection Root' -CsvPath C:\Temp\nsssl.csv
        Requires Microsoft Graph SDK and DeviceManagementConfiguration.Read.All +
        DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        Per-device deployment state (Succeeded/Error/Pending) for the matching trusted-cert profile(s)
        and a breakdown of how many devices have trust deployed; optional per-device CSV.
.NOTES
    Workplace Marketplace — Network Solutions. Read-only against Graph.
#>
[CmdletBinding()] param(
    [string]$ProfileNameMatch = 'Netskope Inspection Root',
    [string]$CsvPath
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome

# Find the trusted-certificate configuration profile(s) by name
$cfgs = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/deviceConfigurations').value
$profiles = $cfgs | Where-Object { $_.displayName -match $ProfileNameMatch }
if (-not $profiles) { Write-Host ("No configuration profile matches '{0}'." -f $ProfileNameMatch) -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

$rows = @()
foreach ($p in $profiles) {
    Write-Host ("=== Profile: {0} ===" -f $p.displayName) -ForegroundColor Cyan
    $st = (Invoke-MgGraphRequest -Method GET -Uri ("/beta/deviceManagement/deviceConfigurations/{0}/deviceStatuses" -f $p.id)).value
    foreach ($d in $st) {
        $rows += [pscustomobject]@{ Profile=$p.displayName; Device=$d.deviceDisplayName; State=$d.status; LastReport=$d.lastReportedDateTime }
    }
    $st | Group-Object status | Select-Object Count, @{n='State';e={$_.Name}} | Format-Table -AutoSize
}
Write-Host ("Total device status rows: {0}" -f $rows.Count) -ForegroundColor Cyan
if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }
Write-Host "Note: Netskope decryption-policy coverage is reported in the Netskope console (deferred)." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null

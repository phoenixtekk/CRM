<#
.SYNOPSIS
    WAPG-Report.ps1 — read-only deployment report for GCC High Autopilot provisioning.
.DESCRIPTION
    PURPOSE
        Connects to Microsoft Graph US Gov and produces a human-readable and optional CSV
        report of Windows Autopilot device preparation outcomes on a GCC High / DoD tenant:
        devices in the WAPG-Autopilot-Devices group, their Entra-join/enrollment/compliance
        state, and a rollout summary. Read-only. Use it after piloting and during expansion to
        evidence results. Placeholders use hyphenated names such as your-tenant-id and
        your-output-folder.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WAPG-Report.ps1
        (Graph scopes; -Environment USGov)
        Optional: -CsvPath your-output-folder\WAPG-report.csv
        Scopes requested: Group.Read.All, Directory.Read.All,
        DeviceManagementManagedDevices.Read.All
    EXPECTED RESULTS
        A printed rollout summary (counts by state) and per-device table; a CSV if -CsvPath is
        given. PASS when the report renders against the USGov environment.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string]$TenantId,
    [ValidateSet('USGov','USGovDoD')]
    [string]$Environment = 'USGov',
    [string]$DeviceGroupName = 'WAPG-Autopilot-Devices',
    # Optional output path, e.g. your-output-folder\WAPG-report.csv
    [string]$CsvPath
)

$ErrorActionPreference = 'Stop'
$baseUri = 'https://graph.microsoft.us/beta'

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$connect = @{ Environment = $Environment; Scopes = @(
    'Group.Read.All','Directory.Read.All','DeviceManagementManagedDevices.Read.All') }
if ($TenantId) { $connect['TenantId'] = $TenantId }
Connect-MgGraph @connect | Out-Null
$ctx = Get-MgContext
Write-Host ("Connected. Environment = {0} | Tenant = {1}" -f $ctx.Environment, $ctx.TenantId) -ForegroundColor Cyan
if ($ctx.Environment -notmatch 'USGov') { Write-Warning "Not a US Gov cloud — verify the tenant (this solution targets GCC High/DoD)." }

# Resolve device group
$esc = [uri]::EscapeDataString($DeviceGroupName)
$dg = (Invoke-MgGraphRequest -Method GET -Uri "$baseUri/groups?`$filter=displayName eq '$esc'&`$select=id,displayName").value | Select-Object -First 1
if (-not $dg) { Write-Warning "Device group '$DeviceGroupName' not found. Run WAPG-Validation.ps1."; return }

# Enumerate device members
$members = @()
$uri = "$baseUri/groups/$($dg.id)/members/microsoft.graph.device?`$select=deviceId,displayName,operatingSystem,trustType,approximateLastSignInDateTime"
do {
    $page = Invoke-MgGraphRequest -Method GET -Uri $uri
    $members += $page.value
    $uri = $page.'@odata.nextLink'
} while ($uri)

# Correlate to managed devices for enrollment/compliance
$report = foreach ($d in $members) {
    $md = $null
    if ($d.deviceId) {
        try {
            $md = (Invoke-MgGraphRequest -Method GET -Uri "$baseUri/deviceManagement/managedDevices?`$filter=azureADDeviceId eq '$($d.deviceId)'&`$select=deviceName,complianceState,enrolledDateTime,managementAgent,operatingSystem,osVersion").value | Select-Object -First 1
        } catch { }
    }
    [pscustomobject]@{
        DeviceName    = $d.displayName
        OS            = $d.operatingSystem
        JoinType      = $d.trustType          # AzureAd = Entra joined
        Enrolled      = [bool]$md
        Compliance    = if ($md) { $md.complianceState } else { 'not-enrolled' }
        OSVersion     = if ($md) { $md.osVersion } else { '' }
        EnrolledDate  = if ($md) { $md.enrolledDateTime } else { '' }
        LastSignIn    = $d.approximateLastSignInDateTime
    }
}

Write-Host "`n== WAPG Rollout Report — group '$DeviceGroupName' ==" -ForegroundColor Green
Write-Host ("Devices in group: {0}" -f @($report).Count)
Write-Host "`n-- Summary --" -ForegroundColor Yellow
Write-Host ("  Entra joined (trustType=AzureAd): {0}" -f @($report | Where-Object JoinType -eq 'AzureAd').Count)
Write-Host ("  Enrolled in Intune:               {0}" -f @($report | Where-Object Enrolled).Count)
Write-Host ("  Compliant:                        {0}" -f @($report | Where-Object Compliance -eq 'compliant').Count)
Write-Host ("  Non-compliant:                    {0}" -f @($report | Where-Object { $_.Compliance -notin @('compliant','not-enrolled') }).Count)
Write-Host ("  Not enrolled:                     {0}" -f @($report | Where-Object { -not $_.Enrolled }).Count)

Write-Host "`n-- Devices --" -ForegroundColor Yellow
$report | Format-Table -AutoSize | Out-String | Write-Host

if ($CsvPath) {
    $report | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("CSV written: {0}" -f $CsvPath) -ForegroundColor Cyan
}

Write-Host "`n== Report complete (nothing was changed). ==" -ForegroundColor Green
Write-Host "Note: near-real-time OOBE app/script status also lives in intune.microsoft.us > Devices > Windows > Enrollment > Windows Autopilot device preparation > Monitor." -ForegroundColor DarkCyan

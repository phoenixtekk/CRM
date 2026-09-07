<#
.SYNOPSIS
    Export the Jamf Pro inventory (computers, mobile devices, PreStage enrollments, configuration
    profiles, smart groups) to CSV — the migration mapping worksheet.

.DESCRIPTION
    Phase 1. Authenticates to the Jamf Pro API with an API client (OAuth client-credentials), pulls the
    inventory that must be translated into Intune, and writes CSVs you complete with the Intune
    equivalent for each item.

.HOW TO RUN
    Create a Jamf Pro API client (Settings > API Roles and Clients) with read privileges, then:
        .\JAMFMIG-Export-JamfInventory.ps1 -JamfUrl "https://yourorg.jamfcloud.com" `
            -ClientId <api-client-id> -ClientSecret <api-client-secret> -OutputPath C:\Temp

.EXPECTED RESULT
    Jamf-Computers-<stamp>.csv, Jamf-MobileDevices-<stamp>.csv, Jamf-Prestages-<stamp>.csv,
    Jamf-Profiles-<stamp>.csv — one row per item with an empty 'IntuneEquivalent' column to fill in.

.NOTES
    Migrations — read-only against the Jamf Pro API. No Intune/Graph calls here.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$JamfUrl,
    [Parameter(Mandatory=$true)][string]$ClientId,
    [Parameter(Mandatory=$true)][string]$ClientSecret,
    [string]$OutputPath = "."
)
$ErrorActionPreference = 'Stop'
$JamfUrl = $JamfUrl.TrimEnd('/')
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

# --- OAuth client-credentials token ---
$tok = Invoke-RestMethod -Method Post -Uri "$JamfUrl/api/oauth/token" `
    -ContentType 'application/x-www-form-urlencoded' `
    -Body @{ client_id = $ClientId; client_secret = $ClientSecret; grant_type = 'client_credentials' }
$hdr = @{ Authorization = "Bearer $($tok.access_token)"; Accept = 'application/json' }

function Get-JamfPaged([string]$path, [string]$node = 'results') {
    $items = @(); $page = 0
    do {
        $resp = Invoke-RestMethod -Method Get -Uri "$JamfUrl$path?page=$page&page-size=200" -Headers $hdr
        $batch = if ($node) { $resp.$node } else { $resp }
        if ($batch) { $items += $batch }
        $page++
    } while ($batch -and $batch.Count -eq 200)
    return $items
}

# --- Computers (macOS) ---
Write-Host "Exporting computers..." -ForegroundColor Cyan
$computers = Get-JamfPaged '/api/v1/computers-inventory' 'results'
$computers | ForEach-Object {
    [pscustomobject]@{ Type='Computer'; Name=$_.general.name; Serial=$_.hardware.serialNumber
        OS=$_.operatingSystem.version; Supervised=$_.general.supervised; IntuneEquivalent='' }
} | Export-Csv (Join-Path $OutputPath "Jamf-Computers-$stamp.csv") -NoTypeInformation -Encoding UTF8

# --- Mobile devices (iOS/iPadOS) ---
Write-Host "Exporting mobile devices..." -ForegroundColor Cyan
$mobiles = Get-JamfPaged '/api/v2/mobile-devices' 'results'
$mobiles | ForEach-Object {
    [pscustomobject]@{ Type='Mobile'; Name=$_.name; Serial=$_.serialNumber; OS=$_.osVersion
        Supervised=$_.supervised; IntuneEquivalent='' }
} | Export-Csv (Join-Path $OutputPath "Jamf-MobileDevices-$stamp.csv") -NoTypeInformation -Encoding UTF8

# --- PreStage enrollments ---
Write-Host "Exporting PreStage enrollments..." -ForegroundColor Cyan
$prestagesC = Get-JamfPaged '/api/v3/computer-prestages' 'results'
$prestagesM = Get-JamfPaged '/api/v2/mobile-device-prestages' 'results'
($prestagesC + $prestagesM) | ForEach-Object {
    [pscustomobject]@{ Type='PreStage'; Name=$_.displayName; IntuneEquivalent='ADE profile' }
} | Export-Csv (Join-Path $OutputPath "Jamf-Prestages-$stamp.csv") -NoTypeInformation -Encoding UTF8

# --- Configuration profiles (classic API) ---
Write-Host "Exporting configuration profiles..." -ForegroundColor Cyan
try {
    $macProf = (Invoke-RestMethod -Method Get -Uri "$JamfUrl/JSSResource/osxconfigurationprofiles" -Headers $hdr).os_x_configuration_profiles
    $iosProf = (Invoke-RestMethod -Method Get -Uri "$JamfUrl/JSSResource/mobiledeviceconfigurationprofiles" -Headers $hdr).configuration_profiles
    ($macProf + $iosProf) | ForEach-Object {
        [pscustomobject]@{ Type='Profile'; Name=$_.name; IntuneEquivalent='' }
    } | Export-Csv (Join-Path $OutputPath "Jamf-Profiles-$stamp.csv") -NoTypeInformation -Encoding UTF8
} catch { Write-Warning "Config profile export (classic API) failed: $($_.Exception.Message)" }

Write-Host "`nExported to $OutputPath. Fill in the IntuneEquivalent column, then build the target in Phase 2." -ForegroundColor Green
Write-Host "Computers: $($computers.Count)  Mobile: $($mobiles.Count)" -ForegroundColor Green

<#
.SYNOPSIS
    MACMDE-Report.ps1 — fleet MDE-for-macOS posture + drift via Microsoft Graph (profiles, app, onboarding).
.DESCRIPTION
    PURPOSE
        Reports, across the Mac fleet, how each device evaluates against the MDE-for-macOS object set
        in Intune — the five capability profiles (System Extensions, Full Disk Access, Network Filter,
        Background Services, Notifications), the Microsoft Defender app install state, and the
        onboarding profile — by reading each object's device statuses. Summarizes succeeded vs drifted
        (error/conflict/failed/notApplicable) per object so you can spot Macs onboarded without their
        capability profiles. Read-only against Graph.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MACMDE-Report.ps1 -NameLike "MDE macOS" -CsvPath C:\Temp\macmde-posture.csv
        Requires the Microsoft Graph SDK and DeviceManagementConfiguration.Read.All,
        DeviceManagementApps.Read.All.
    EXPECTED RESULTS
        A per-object breakdown of device states (succeeded/error/conflict/failed/etc.) and an optional
        per-device CSV showing which Macs have drifted. PASS when capability profiles succeed and no
        Mac is onboarded ahead of its profiles.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param(
    [string]$NameLike = 'MDE macOS',
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementApps.Read.All' -NoWelcome

$rows = @()

# Settings-catalog policies (configurationPolicies) — MDE macOS capability profiles
$cps = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies?`$filter=startswith(name,'$NameLike')").value
foreach ($p in $cps) {
    $st = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies/$($p.id)/deviceStatuses").value
    foreach ($d in $st) { $rows += [pscustomobject]@{ Object=$p.name; Type='SettingsCatalog'; Device=$d.deviceDisplayName; State=$d.status } }
}

# Template/custom profiles (deviceConfigurations) — extensions/PPPC/network/notifications/onboarding
$dcs = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations?`$filter=startswith(displayName,'$NameLike')").value
foreach ($p in $dcs) {
    $st = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations/$($p.id)/deviceStatuses").value
    $isOnboard = $p.displayName -match 'Onboard'
    foreach ($d in $st) { $rows += [pscustomobject]@{ Object=$p.displayName; Type=$(if($isOnboard){'Onboarding'}else{'Profile'}); Device=$d.deviceDisplayName; State=$d.status } }
}

# Microsoft Defender (macOS) app install status
$apps = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.macOSMicrosoftDefenderApp')").value
foreach ($a in $apps) {
    try {
        $st = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceAppManagement/mobileApps/$($a.id)/deviceStatuses").value
        foreach ($d in $st) { $rows += [pscustomobject]@{ Object=$a.displayName; Type='App'; Device=$d.deviceName; State=$d.installState } }
    } catch { }
}

Write-Host "=== MDE macOS posture by object ===" -ForegroundColor Cyan
if (-not $rows) { Write-Host "No MDE macOS objects/states found (check -NameLike)." -ForegroundColor Yellow }
$rows | Group-Object Object | ForEach-Object {
    Write-Host ("`nObject: {0}" -f $_.Name) -ForegroundColor Cyan
    $_.Group | Group-Object State | Sort-Object Name | Select-Object Count, @{n='State';e={$_.Name}} | Format-Table -AutoSize
}

# Order-safety cross-check: Macs onboarded but with a drifted capability profile
$onboardedDevices = ($rows | Where-Object { $_.Type -eq 'Onboarding' -and $_.State -in @('compliant','succeeded') }).Device | Select-Object -Unique
$capDrift = $rows | Where-Object { $_.Type -in @('SettingsCatalog','Profile') -and $_.State -notin @('compliant','succeeded') -and $_.Device -in $onboardedDevices }
if ($capDrift) {
    Write-Host "`n*** ORDER WARNING: these onboarded Macs have a capability profile NOT healthy (possible silently degraded agent):" -ForegroundColor Red
    $capDrift | Select-Object Device, Object, State -Unique | Format-Table -AutoSize
}

$drift = $rows | Where-Object { $_.State -notin @('compliant','succeeded','installed','success') }
Write-Host ("`nDrifted/errored device-object states: {0} of {1}" -f ($drift | Measure-Object).Count, ($rows | Measure-Object).Count) -ForegroundColor ($(if($drift){'Yellow'}else{'Green'}))
if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }

Disconnect-MgGraph | Out-Null

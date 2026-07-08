<#
.SYNOPSIS
    ANDROIDDX-EnrollmentReadiness.ps1 — read-only per-tenant/per-device Android enrollment readiness assessment.
.DESCRIPTION
    PURPOSE
        Builds the 'Enrollment Readiness - Android - Assessed' artifact. Reads the managed Google Play
        binding state, the Android platform enrollment restriction, any device-owner enrollment
        profiles, and recently-enrolled Android devices, then prints a readiness table with a PASS/WARN
        flag per check so you can tell before troubleshooting whether the tenant is even positioned to
        enroll. Read-only — it queries Microsoft Graph and changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ANDROIDDX-EnrollmentReadiness.ps1 -Days 14 -CsvPath C:\Temp\android-readiness.csv
        Requires the Microsoft Graph PowerShell SDK and the read scopes DeviceManagementServiceConfig.Read.All,
        DeviceManagementConfiguration.Read.All, DeviceManagementManagedDevices.Read.All. See ANDROIDDX-BindingHealth.ps1.
    EXPECTED RESULTS
        PASS on every check = tenant is positioned to enroll (binding bound, sync recent, Android
        enrollment allowed, at least one enrollment path configured). Any WARN points at the node in
        the Diagnostic Playbook to open next. Endpoint reachability is device-side — run
        ANDROIDDX-EndpointReachability.ps1 from the device network as well.
.NOTES
    Android. Read-only against Microsoft Graph (beta resources noted inline).
    AMAPI transition is evolving — verify resource shapes against current Microsoft Graph documentation.
#>
[CmdletBinding()] param(
    [int]$Days = 14,
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.Read.All','DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome

$results = New-Object System.Collections.Generic.List[object]
function Add-Check([string]$Check,[string]$Status,[string]$Detail){ $results.Add([pscustomobject]@{ Check=$Check; Status=$Status; Detail=$Detail }) }

Write-Host "=== Android Enterprise enrollment readiness ===" -ForegroundColor Cyan

# 1) Managed Google Play binding (beta resource; verify shape against current Graph docs)
try {
    $bind = Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/androidManagedStoreAccountEnterpriseSettings"
    $bound = ($bind.bindStatus -eq 'bound')
    Add-Check 'Managed Google Play binding' ($(if($bound){'PASS'}else{'WARN'})) ("bindStatus={0}; owner={1}" -f $bind.bindStatus,$bind.ownerUserPrincipalName)
    if ($bind.lastAppSyncDateTime) {
        $ageH = [math]::Round(((Get-Date).ToUniversalTime() - ([datetime]$bind.lastAppSyncDateTime).ToUniversalTime()).TotalHours,1)
        $syncOk = ($bind.lastAppSyncStatus -eq 'success' -and $ageH -lt 48)
        Add-Check 'Managed Play app sync' ($(if($syncOk){'PASS'}else{'WARN'})) ("lastStatus={0}; ageHours={1}" -f $bind.lastAppSyncStatus,$ageH)
    } else { Add-Check 'Managed Play app sync' 'WARN' 'No lastAppSyncDateTime — binding may be new or unhealthy' }
} catch { Add-Check 'Managed Google Play binding' 'WARN' ("Could not read binding settings: {0}" -f $_.Exception.Message) }

# 2) Android platform enrollment restriction — is Android Enterprise personally/corporate owned allowed?
try {
    $encfg = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceEnrollmentConfigurations?`$top=100").value
    $platform = $encfg | Where-Object { $_.'@odata.type' -like '*deviceEnrollmentPlatformRestriction*' -or $_.'@odata.type' -like '*PlatformRestrictionsConfiguration*' }
    if ($platform) { Add-Check 'Android enrollment restriction' 'PASS' ("{0} platform-restriction policy(ies) present — confirm androidForWork/android platformBlocked=false in Intune" -f @($platform).Count) }
    else { Add-Check 'Android enrollment restriction' 'WARN' 'No platform restriction policy read — verify Android Enterprise is not blocked (Intune > Devices > Enrollment > Enrollment restrictions)' }
} catch { Add-Check 'Android enrollment restriction' 'WARN' ("Could not read enrollment configurations: {0}" -f $_.Exception.Message) }

# 3) Device-owner enrollment profiles (fully managed / dedicated / corp-owned WP token paths)
try {
    $profiles = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/androidDeviceOwnerEnrollmentProfiles?`$top=100").value
    Add-Check 'Device-owner enrollment profiles' ($(if($profiles.Count -gt 0){'PASS'}else{'WARN'})) ("{0} profile(s) — needed for fully managed / dedicated (COSU) / corp-owned work profile; not needed for BYOD work profile" -f @($profiles).Count)
} catch { Add-Check 'Device-owner enrollment profiles' 'WARN' 'Could not read device-owner profiles (only needed for corporate-owned paths)' }

# 4) Recent Android enrollments as a positive signal
try {
    $since = (Get-Date).ToUniversalTime().AddDays(-$Days).ToString('yyyy-MM-ddTHH:mm:ssZ')
    $dev = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/managedDevices?`$filter=operatingSystem eq 'Android' and enrolledDateTime ge $since&`$select=deviceName,enrolledDateTime,managementAgent,ownerType&`$top=200").value
    Add-Check 'Recent Android enrollments' ($(if($dev.Count -gt 0){'PASS'}else{'WARN'})) ("{0} Android device(s) enrolled in last {1}d — zero when you expect enrollments is itself a symptom" -f @($dev).Count,$Days)
} catch { Add-Check 'Recent Android enrollments' 'WARN' ("Could not read managed devices: {0}" -f $_.Exception.Message) }

$results | Format-Table -AutoSize
$warns = @($results | Where-Object { $_.Status -ne 'PASS' }).Count
Write-Host ("`nChecks: {0}  PASS: {1}  WARN: {2}" -f $results.Count, ($results.Count-$warns), $warns) -ForegroundColor $(if($warns){'Yellow'}else{'Green'})
if ($CsvPath) { $results | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath (record as 'Enrollment Readiness - Android - Assessed')." -ForegroundColor Green }
Disconnect-MgGraph | Out-Null

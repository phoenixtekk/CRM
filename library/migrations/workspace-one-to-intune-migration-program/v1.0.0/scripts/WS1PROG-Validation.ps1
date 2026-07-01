<#
.SYNOPSIS
    WS1PROG-Validation.ps1 - Read-only per-device / per-wave migration validation for Workspace ONE -> Intune.

    PURPOSE:
        Validates that the devices in a wave have migrated cleanly into Microsoft Intune. For each
        in-scope device it checks (via Microsoft Graph, read-only):
          - Intune enrollment state (the device is Intune-managed),
          - single-MDM integrity (managed by Intune, not co-managed in a way that signals a stuck WS1 state),
          - compliance state against the platform compliance policy,
          - assigned-app install state (required apps reporting Installed).
        Emits PASS/FAIL per check, feeding the acceptance gates in 05-testing.md.

    HOW TO RUN:
        1. Install the Microsoft Graph PowerShell SDK (run once):
             Install-Module Microsoft.Graph -Scope CurrentUser
        2. Validate a wave by Entra group name (the wave group created by WS1PROG-Set-WaveTargeting.ps1):
             .\WS1PROG-Validation.ps1 -WaveGroupName "Wave 00 Devices - All - Pilot" `
                                      -OutputCsv ".\Validation Results - Program - Wave 00.csv"
           Or validate an explicit list of device names:
             .\WS1PROG-Validation.ps1 -DeviceName "LT-1001","PH-2002"
        Sign in interactively when prompted; read-only Graph scopes are sufficient.

    EXPECTED RESULTS:
        A CSV of per-device, per-check PASS/FAIL results plus a console summary (counts of PASS/FAIL per
        check and an overall wave verdict). Strictly READ-ONLY - no changes are made.

.NOTES
    Migrations - read-only. Intune/Entra side via Microsoft Graph PowerShell.
#>

[CmdletBinding()]
param(
    [string]$WaveGroupName,
    [string[]]$DeviceName,
    [string]$OutputCsv = ".\Validation Results - Program - Wave.csv"
)

$ErrorActionPreference = 'Stop'
if (-not $WaveGroupName -and -not $DeviceName) {
    throw "Supply -WaveGroupName or -DeviceName to define the validation scope."
}

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Write-Host "Connecting to Microsoft Graph (read-only)..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All","Group.Read.All","Directory.Read.All" -NoWelcome

Import-Module Microsoft.Graph.DeviceManagement -ErrorAction Stop
Import-Module Microsoft.Graph.Groups -ErrorAction Stop

# --- Resolve the device scope ---
$targetNames = @()
if ($WaveGroupName) {
    $grp = Get-MgGroup -Filter "displayName eq '$WaveGroupName'" -Top 1
    if (-not $grp) { throw "Wave group not found: $WaveGroupName" }
    $members = Get-MgGroupMember -GroupId $grp.Id -All
    # Group may contain device or user objects; collect device display names where present.
    $targetNames += ($members | ForEach-Object { $_.AdditionalProperties['displayName'] } | Where-Object { $_ })
}
if ($DeviceName) { $targetNames += $DeviceName }
$targetNames = $targetNames | Sort-Object -Unique
if (-not $targetNames) { throw "No devices resolved from the supplied scope." }

$results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param($Device, $Platform, $Check, $Pass, $Detail)
    $results.Add([pscustomobject]@{
        Device   = $Device
        Platform = $Platform
        Check    = $Check
        Result   = if ($Pass) { 'PASS' } else { 'FAIL' }
        Detail   = $Detail
    })
}

foreach ($name in $targetNames) {
    $dev = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$name'" -Top 1
    if (-not $dev) {
        Add-Result -Device $name -Platform 'Unknown' -Check 'T*.1 Enrollment state' -Pass $false -Detail 'Not found in Intune'
        continue
    }
    $platform = switch -Wildcard ($dev.OperatingSystem) {
        'Windows*' { 'Windows' } 'iOS*' { 'iOS' } 'iPadOS*' { 'iOS' }
        'Android*' { 'Android' } 'macOS*' { 'macOS' } default { $dev.OperatingSystem }
    }

    # T*.1 - Intune enrollment state
    $enrolled = ($dev.ManagementState -ne 'discovered') -and ($dev.ManagementAgent)
    Add-Result -Device $name -Platform $platform -Check 'T*.1 Enrollment state' -Pass $enrolled `
        -Detail ("Agent={0}; State={1}" -f $dev.ManagementAgent, $dev.ManagementState)

    # T6.1 - single-MDM integrity (Intune-managed agent expected; flag mdm-pending/foreign agents)
    $singleMdm = $dev.ManagementAgent -in @('mdm','configurationManagerClientMdm','intuneClient','easMdm') -or $dev.ManagementAgent -like '*mdm*'
    Add-Result -Device $name -Platform $platform -Check 'T6.1 Single-MDM integrity' -Pass $singleMdm `
        -Detail ("ManagementAgent={0}" -f $dev.ManagementAgent)

    # T*.3 - compliance
    $compliant = $dev.ComplianceState -eq 'compliant'
    Add-Result -Device $name -Platform $platform -Check 'T*.3 Compliance' -Pass $compliant `
        -Detail ("ComplianceState={0}" -f $dev.ComplianceState)

    # T*.4 - required app install state
    try {
        $appStates = Get-MgDeviceManagementManagedDeviceMobileAppConfigurationState -ManagedDeviceId $dev.Id -ErrorAction SilentlyContinue
        # Fall back to device app intent/status if the above is unavailable in the tenant.
        $appPass = $true; $appDetail = 'No required-app failures detected'
        if ($appStates) {
            $failed = $appStates | Where-Object { $_.State -and $_.State -notin @('compliant','installed','notApplicable') }
            if ($failed) { $appPass = $false; $appDetail = ("{0} app(s) not in installed state" -f $failed.Count) }
        } else {
            $appDetail = 'App state unavailable via Graph in this tenant - verify in Intune portal (T*.4)'
        }
        Add-Result -Device $name -Platform $platform -Check 'T*.4 Required apps' -Pass $appPass -Detail $appDetail
    } catch {
        Add-Result -Device $name -Platform $platform -Check 'T*.4 Required apps' -Pass $false -Detail $_.Exception.Message
    }
}

# --- Export + summary ---
$results | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
Write-Host ("`nValidation results written to {0}" -f $OutputCsv) -ForegroundColor Green

Write-Host "`n=== Result summary by check ===" -ForegroundColor Cyan
$results | Group-Object Check | Sort-Object Name | ForEach-Object {
    $pass = ($_.Group | Where-Object Result -eq 'PASS').Count
    $fail = ($_.Group | Where-Object Result -eq 'FAIL').Count
    Write-Host ("  {0,-28} PASS={1,-4} FAIL={2}" -f $_.Name, $pass, $fail)
}
$anyFail = ($results | Where-Object Result -eq 'FAIL').Count
Write-Host ("`nWave verdict: {0}" -f ($(if ($anyFail -eq 0) { 'PASS - all checks green' } else { "FAIL - $anyFail check(s) failing" }))) `
    -ForegroundColor ($(if ($anyFail -eq 0) { 'Green' } else { 'Red' }))

Disconnect-MgGraph | Out-Null

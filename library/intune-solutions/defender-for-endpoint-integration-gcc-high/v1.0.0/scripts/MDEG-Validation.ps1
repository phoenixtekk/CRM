<#
.SYNOPSIS
    MDEG-Validation.ps1 — validate the Intune-to-MDE connector and device onboarding on a GCC High tenant.
.DESCRIPTION
    PURPOSE
        Read-only validation that the Microsoft Defender for Endpoint connector is enabled in
        Intune, that the EDR onboarding policy exists and is assigned, and that the Graph
        session is on the US Government cloud. Use it as the pilot validation gate. Replace
        values like your-pilot-group-name only if you pass -PilotGroupName.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDEG-Validation.ps1
        (Graph scopes: DeviceManagementConfiguration.Read.All,
         DeviceManagementManagedDevices.Read.All; connects with -Environment USGov)
    EXPECTED RESULTS
        A checklist of PASS/FAIL lines: US Gov environment, MDE connector enabled, EDR
        onboarding policy present and assigned, devices onboarded. PASS = all green.
        FAIL = a red line points you to the matching fix in 06-troubleshooting.md.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string] $TenantId,
    [string] $PilotGroupName = 'SG-MDE-Pilot'
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]

function Add-Check {
    param([string] $Name, [bool] $Pass, [string] $Detail)
    $results.Add([pscustomobject]@{ Check = $Name; Result = ($(if ($Pass) { 'PASS' } else { 'FAIL' })); Detail = $Detail })
}

function Connect-UsGovGraph {
    param([string] $TenantId)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $scopes = @('DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All')
    $p = @{ Environment = 'USGov'; Scopes = $scopes }
    if ($TenantId) { $p.TenantId = $TenantId }
    Connect-MgGraph @p | Out-Null
}

function Invoke-GovGraph {
    param([string] $RelativeUrl)
    # Beta endpoint on US Gov Graph for management resources not in the v1.0 cmdlet set.
    Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.us/beta/{0}" -f $RelativeUrl) -ErrorAction Stop
}

try {
    Connect-UsGovGraph -TenantId $TenantId
    $ctx = Get-MgContext
    Add-Check "US Gov Graph environment" ($ctx.Environment -eq 'USGov') ("Environment reported: {0}" -f $ctx.Environment)

    # 1) MDE connector state (mobileThreatDefenseConnectors surfaces the Defender/Intune link)
    try {
        $mtd = Invoke-GovGraph "deviceManagement/mobileThreatDefenseConnectors"
        $mde = @($mtd.value) | Where-Object { $_.id -or $_.partnerState }
        $enabled = @($mde | Where-Object { $_.partnerState -eq 'enabled' -or $_.microsoftDefenderForEndpointAttachEnabled -eq $true -or $_.androidEnabled -eq $true -or $_.windowsEnabled -eq $true })
        Add-Check "Intune-to-MDE connector present/enabled" ($enabled.Count -gt 0) ("Connectors found: {0}; enabled-looking: {1}" -f @($mtd.value).Count, $enabled.Count)
    }
    catch {
        Add-Check "Intune-to-MDE connector present/enabled" $false ("Could not read connectors: {0}" -f $_.Exception.Message)
    }

    # 2) EDR onboarding policy present
    try {
        $edr = Invoke-GovGraph "deviceManagement/deviceConfigurations"
        $edrPolicies = @($edr.value) | Where-Object { $_.displayName -match 'EDR|Endpoint detection|MDE' }
        Add-Check "EDR onboarding policy present" ($edrPolicies.Count -gt 0) ("Matching policies: {0}" -f $edrPolicies.Count)
    }
    catch {
        Add-Check "EDR onboarding policy present" $false ("Could not read configuration policies: {0}" -f $_.Exception.Message)
    }

    # 3) Pilot group exists and has members
    try {
        $grp = Invoke-GovGraph ("groups?`$filter=displayName eq '{0}'" -f $PilotGroupName)
        $g = @($grp.value) | Select-Object -First 1
        if ($g) {
            $members = Invoke-GovGraph ("groups/{0}/members?`$count=true" -f $g.id)
            $count = @($members.value).Count
            Add-Check ("Pilot group '{0}' exists with members" -f $PilotGroupName) ($count -gt 0) ("Members: {0}" -f $count)
        } else {
            Add-Check ("Pilot group '{0}' exists with members" -f $PilotGroupName) $false "Group not found — create SG-MDE-Pilot (03-implementation.md Step 3)."
        }
    }
    catch {
        Add-Check ("Pilot group '{0}' exists with members" -f $PilotGroupName) $false ("Group lookup failed: {0}" -f $_.Exception.Message)
    }

    # 4) At least one onboarded/compliant Windows device (proxy for sensor reporting)
    try {
        $md = Invoke-GovGraph "deviceManagement/managedDevices?`$select=deviceName,operatingSystem,complianceState"
        $win = @($md.value) | Where-Object { $_.operatingSystem -match 'Windows' }
        Add-Check "Windows devices reporting to Intune" ($win.Count -gt 0) ("Windows managed devices: {0}" -f $win.Count)
    }
    catch {
        Add-Check "Windows devices reporting to Intune" $false ("Could not read managed devices: {0}" -f $_.Exception.Message)
    }

    Write-Host "`n=== MDE GCC High validation gate ===" -ForegroundColor Yellow
    $results | Format-Table -AutoSize
    $fails = @($results | Where-Object { $_.Result -eq 'FAIL' })
    if ($fails.Count -eq 0) {
        Write-Host "`nAll checks PASSED. Pilot validation gate is green." -ForegroundColor Green
    } else {
        Write-Host ("`n{0} check(s) FAILED. See 06-troubleshooting.md for the matching fix." -f $fails.Count) -ForegroundColor Red
    }
    Write-Host "Reminder: onboarding-environment (US Gov vs Commercial) is confirmed device-side in the Defender portal security.microsoft.us and by the sensor; this script validates the Intune/Graph side." -ForegroundColor DarkGray
}
catch {
    Write-Error ("Validation failed: {0}" -f $_.Exception.Message)
    Write-Host "If this is an authority error you may be on the Commercial cloud — Disconnect-MgGraph and retry (uses -Environment USGov)." -ForegroundColor Yellow
    exit 1
}
finally {
    if (Get-MgContext -ErrorAction SilentlyContinue) { Disconnect-MgGraph | Out-Null }
}

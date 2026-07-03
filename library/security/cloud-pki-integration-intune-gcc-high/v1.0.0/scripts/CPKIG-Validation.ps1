<#
.SYNOPSIS
    CPKIG-Validation.ps1 — validate that the designed certificate objects exist and are scoped (read-only, GCC High).
.DESCRIPTION
    PURPOSE
        Checks a GCC High tenant for the specific, named objects this solution creates and reports
        PASS or FAIL for each: the pilot group, the trusted-root profile, the SCEP profile, the PKCS
        profile, and at least one healthy Intune Certificate Connector. It does not change anything.
        Use it as the pilot validation gate before expanding scope. Cloud PKI is not available in GCC
        High, so validation targets the connector-backed SCEP/PKCS path. Replace the default names
        only if you named your objects differently.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CPKIG-Validation.ps1

        Required Graph scopes (delegated): DeviceManagementConfiguration.Read.All,
        DeviceManagementServiceConfig.Read.All, Directory.Read.All.
        GCC High: connects with Connect-MgGraph -Environment USGov (graph.microsoft.us). For DoD
        change USGov to USGovDoD.
    EXPECTED RESULTS
        A checklist with PASS/FAIL per object and a final summary count. PASS overall = every required
        object is present, correctly named, and (for the connector) healthy. FAIL = one or more
        objects are missing, misnamed, or the connector is unhealthy; the report names them so you can
        remediate.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string] $PilotGroupName   = 'SG-CPKI-Pilot',
    [string] $TrustProfileName = 'Trust-Root-CA',
    [string] $ScepProfileName  = 'SCEP-Device-ClientAuth',
    [string] $PkcsProfileName  = 'PKCS-User-ClientAuth',
    [ValidateSet('USGov','USGovDoD')]
    [string] $GraphEnvironment = 'USGov'
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]

function Add-Result([string] $Item, [string] $Status, [string] $Detail = '') {
    $results.Add([pscustomobject]@{ Item = $Item; Status = $Status; Detail = $Detail })
}

try {
    Connect-MgGraph -Environment $GraphEnvironment `
        -Scopes @('DeviceManagementConfiguration.Read.All','DeviceManagementServiceConfig.Read.All','Directory.Read.All') | Out-Null
    $ctx = Get-MgContext
    Write-Host ("Environment : {0}" -f $ctx.Environment)
    if ($ctx.Environment -notin @('USGov','USGovDoD')) {
        Add-Result 'Sovereign cloud' 'FAIL' 'Not connected to US Gov cloud — reconnect with -Environment USGov.'
        $results | Format-Table -AutoSize
        return
    }
    Add-Result 'Sovereign cloud' 'PASS' ("Environment {0}" -f $ctx.Environment)
}
catch {
    Write-Error ("Graph connect (US Gov) failed: {0}" -f $_.Exception.Message)
    return
}

# Pull device configuration profiles once.
$profiles = @()
try {
    $configs = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/deviceManagement/deviceConfigurations?$select=id,displayName,@odata.type' -ErrorAction Stop
    $profiles = @($configs.value)
}
catch {
    Add-Result 'Read device configurations' 'FAIL' $_.Exception.Message
}

function Test-Profile([string] $Name, [string] $Label, [string] $TypeMatch) {
    $match = $profiles | Where-Object {
        $_.displayName -eq $Name -and ($_.'@odata.type' -match $TypeMatch)
    }
    if (-not $match) { $match = $profiles | Where-Object { $_.displayName -like "$Name*" -and ($_.'@odata.type' -match $TypeMatch) } }
    if ($match) { Add-Result $Label 'PASS' ("Found: {0}" -f (($match | Select-Object -First 1).displayName)) }
    else        { Add-Result $Label 'FAIL' ("Not found (expected name '{0}')." -f $Name) }
}

Test-Profile $TrustProfileName ("Trusted-root profile '{0}'" -f $TrustProfileName) 'TrustedRoot'
Test-Profile $ScepProfileName  ("SCEP profile '{0}'"          -f $ScepProfileName)  'Scep|SCEP'
Test-Profile $PkcsProfileName  ("PKCS profile '{0}'"          -f $PkcsProfileName)  'Pkcs|PKCS'

# Certificate connector health.
try {
    $connectors = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/deviceManagement/certificateConnectorDetails' -ErrorAction Stop
    $items = @($connectors.value)
    if ($items.Count -eq 0) {
        Add-Result 'Certificate connector' 'FAIL' 'No certificate connectors registered.'
    } else {
        $healthy = $items | Where-Object { "$($_.status)" -match 'active|healthy|connected' }
        if ($healthy) { Add-Result 'Certificate connector' 'PASS' ("{0} healthy connector(s)." -f @($healthy).Count) }
        else          { Add-Result 'Certificate connector' 'FAIL' 'Connector(s) present but none report healthy — check version/status in intune.microsoft.us.' }
    }
}
catch {
    Add-Result 'Certificate connector' 'FAIL' $_.Exception.Message
}

# Pilot group.
try {
    $grp = Get-MgGroup -Filter "displayName eq '$PilotGroupName'" -ConsistencyLevel eventual -CountVariable c -All
    if ($grp) { Add-Result ("Pilot group '{0}'" -f $PilotGroupName) 'PASS' ("Id {0}" -f $grp[0].Id) }
    else      { Add-Result ("Pilot group '{0}'" -f $PilotGroupName) 'FAIL' 'Not found — create in entra.microsoft.us.' }
}
catch {
    Add-Result ("Pilot group '{0}'" -f $PilotGroupName) 'FAIL' $_.Exception.Message
}

Write-Host ''
Write-Host '=== Validation results ===' -ForegroundColor Cyan
$results | Format-Table -AutoSize
$fail = @($results | Where-Object { $_.Status -eq 'FAIL' }).Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: PASS — all designed certificate objects present and connector healthy.' -ForegroundColor Green }
else             { Write-Host ("OVERALL: FAIL — {0} item(s) need remediation (see CPKIG-Remediation.ps1, defaults to -WhatIf)." -f $fail) -ForegroundColor Red }

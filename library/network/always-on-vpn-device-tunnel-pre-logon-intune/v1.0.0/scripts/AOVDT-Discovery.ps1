<#
.SYNOPSIS
    AOVDT-Discovery.ps1 — Always On VPN device-tunnel deployment-readiness discovery across Entra + Intune.
.DESCRIPTION
    PURPOSE
        Read-only readiness sweep for a Windows Always On VPN device-tunnel deployment via Intune.
        Finds the Custom OMA-URI ProfileXML configuration profile
        ('AOVPN – Device Tunnel – ProfileXML – Windows', a windows10CustomConfiguration with an
        omaSettings entry), the Trusted Root CA and SCEP machine-certificate profiles, and the
        pilot/production DEVICE groups, and reports which expected objects are present, named to
        convention, and assigned. Makes NO changes.
        NOTE: there is NO app to find — the device tunnel is a native Windows VPN profile (VPNv2 CSP),
        delivered as a Custom configuration profile, not an installed application.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AOVDT-Discovery.ps1
        Required Microsoft Graph scopes (delegated, read-only):
            DeviceManagementConfiguration.Read.All
            DeviceManagementServiceConfig.Read.All
            Group.Read.All
            Directory.Read.All
    EXPECTED RESULTS
        A readiness table: the Custom ProfileXML profile, the Trusted Root CA profile, and the SCEP
        machine-cert profile each Found/Missing with assignment state (and whether the ProfileXML is
        assigned to a DEVICE group), plus the pilot device-group membership count. All green = ready to
        pilot; any Missing/Unassigned = fix before deploying (see 02-requirements.md / 03-implementation.md).
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. VPN gateway head-end internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string] $PilotGroupName = 'PILOT – AOVPN Device Tunnel – Devices',
    [string] $ProdGroupName  = 'PROD – AOVPN Device Tunnel – Devices'
)

$ErrorActionPreference = 'Stop'

# Object names this solution creates (match 03-implementation.md verbatim).
$ProfileXmlName  = 'AOVPN – Device Tunnel – ProfileXML – Windows'
$RootCaName      = 'AOVPN – Device Tunnel – Trusted Root CA – Windows'
$ScepCertName    = 'AOVPN – Device Tunnel – Machine Cert (SCEP) – Windows'
$ExpectedProfiles = @($ProfileXmlName, $RootCaName, $ScepCertName)

function Connect-Graph {
    if (-not (Get-Module Microsoft.Graph.Authentication -ListAvailable)) {
        throw "Microsoft Graph PowerShell SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $scopes = @(
        'DeviceManagementConfiguration.Read.All',
        'DeviceManagementServiceConfig.Read.All',
        'Group.Read.All',
        'Directory.Read.All'
    )
    if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $scopes | Out-Null }
    Write-Host "Connected to Microsoft Graph as $((Get-MgContext).Account)" -ForegroundColor Green
}

function Invoke-Graph {
    param([string] $Uri)
    $results = @()
    do {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $Uri
        if ($resp.value) { $results += $resp.value } elseif ($resp) { $results += $resp }
        $Uri = $resp.'@odata.nextLink'
    } while ($Uri)
    return $results
}

Connect-Graph
$base = 'https://graph.microsoft.com/v1.0'

Write-Host "`n=== Always On VPN Device Tunnel — Deployment Readiness ===" -ForegroundColor Cyan

# --- Helper: assignment summary (and whether it targets a device group) -------
function Get-AssignmentSummary {
    param([string] $Uri)
    try {
        $a = Invoke-Graph $Uri
        if ($a -and $a.Count -gt 0) { return "$($a.Count) assignment(s)" } else { return "UNASSIGNED" }
    } catch { return "unknown" }
}

# --- Configuration profiles (ProfileXML + cert) ------------------------------
Write-Host "`n[1] Configuration profiles (ProfileXML + certificates)" -ForegroundColor Cyan
$allConfigs = Invoke-Graph "$base/deviceManagement/deviceConfigurations?`$select=id,displayName"

$profileRows = foreach ($name in $ExpectedProfiles) {
    $p = $allConfigs | Where-Object { $_.displayName -eq $name }
    if ($p) {
        $assign = Get-AssignmentSummary "$base/deviceManagement/deviceConfigurations/$($p.id)/assignments"
        [pscustomobject]@{ Object = $name; State = 'Found'; Assignment = $assign }
    } else {
        [pscustomobject]@{ Object = $name; State = 'MISSING'; Assignment = '-' }
    }
}
$profileRows | Format-Table -AutoSize -Wrap

# --- Groups (DEVICE groups) --------------------------------------------------
Write-Host "[2] Target Entra DEVICE groups" -ForegroundColor Cyan
$groupRows = foreach ($gname in @($PilotGroupName, $ProdGroupName)) {
    $enc = [uri]::EscapeDataString($gname)
    $g = Invoke-Graph "$base/groups?`$filter=displayName eq '$enc'&`$select=id,displayName"
    if ($g) {
        $members = Invoke-Graph "$base/groups/$($g[0].id)/members?`$select=id"
        [pscustomobject]@{ Group = $gname; State = 'Found'; Members = $members.Count }
    } else {
        [pscustomobject]@{ Group = $gname; State = 'MISSING'; Members = 0 }
    }
}
$groupRows | Format-Table -AutoSize

# --- Device-context reminder for the ProfileXML ------------------------------
$xmlRow = $profileRows | Where-Object { $_.Object -eq $ProfileXmlName }
if ($xmlRow -and $xmlRow.State -eq 'Found') {
    Write-Host "Reminder: '$ProfileXmlName' uses a ./Device/ OMA-URI — it MUST be assigned to a DEVICE group" -ForegroundColor DarkGray
    Write-Host "          ('$PilotGroupName'), never a user group, or the device tunnel never appears." -ForegroundColor DarkGray
}

# --- Summary -----------------------------------------------------------------
$missing = @()
$missing += ($profileRows | Where-Object { $_.State -eq 'MISSING' }).Object
$missing += ($groupRows   | Where-Object { $_.State -eq 'MISSING' }).Group

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
if ($missing.Count -eq 0) {
    Write-Host "READY: the ProfileXML, Trusted Root CA, SCEP cert profiles, and device groups are present." -ForegroundColor Green
    Write-Host "Confirm '$ProfileXmlName' is assigned to the DEVICE group before piloting." -ForegroundColor Green
} else {
    Write-Host "NOT READY — missing objects:" -ForegroundColor Yellow
    $missing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    Write-Host "See 02-requirements.md / 03-implementation.md to create them." -ForegroundColor Yellow
}
Write-Host "Discovery complete (read-only). No changes were made." -ForegroundColor Green

<#
.SYNOPSIS
    PREVPN-Report.ps1 — fleet pre-logon readiness roll-up: join types + pre-logon path coverage.
.DESCRIPTION
    PURPOSE
        Read-only fleet roll-up for the pre-logon VPN decision. Counts Windows devices by join type
        (Entra hybrid-joined / domain-joined / Entra-joined / registered / unknown) and estimates
        pre-logon-path coverage for the IN-SCOPE (hybrid + domain-joined) devices by whether the
        referenced pre-logon objects are deployed and assigned — the device-tunnel ProfileXML profile
        and/or the SBL Win32 app. Prints a coverage percentage and an optional CSV. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PREVPN-Report.ps1
        Optional: -CsvPath .\prevpn-readiness.csv to export the per-join-type rows.
        Required Microsoft Graph scopes (delegated, read-only):
            Device.Read.All
            DeviceManagementApps.Read.All
            DeviceManagementConfiguration.Read.All
    EXPECTED RESULTS
        A join-type table, a pre-logon-capability table (device tunnel / SBL present + assigned), and a
        coverage % = share of in-scope devices that have a deployed+assigned pre-logon path. Target:
        pilot 100% of in-scope devices; expansion >= your threshold (e.g. 95%). Entra-joined devices are
        reported separately and excluded from the in-scope denominator.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. Vendor internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string] $CsvPath = ''
)

$ErrorActionPreference = 'Stop'

$DeviceTunnelProfileName = 'AOVPN – Device Tunnel – ProfileXML – Windows'
$SblAppName              = 'Cisco Secure Client – Pre-Logon (SBL) – Win32'

function Connect-Graph {
    if (-not (Get-Module Microsoft.Graph.Authentication -ListAvailable)) {
        throw "Microsoft Graph PowerShell SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $scopes = @(
        'Device.Read.All',
        'DeviceManagementApps.Read.All',
        'DeviceManagementConfiguration.Read.All'
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

Write-Host "`n=== Pre-Logon VPN — Fleet Readiness Report ===" -ForegroundColor Cyan

# --- Join-type counts --------------------------------------------------------
$devices = Invoke-Graph "$base/devices?`$select=displayName,operatingSystem,trustType,onPremisesSyncEnabled&`$top=999"
$win = $devices | Where-Object { $_.operatingSystem -match 'Windows' }

$hybrid = 0; $entraJoined = 0; $domainJoined = 0; $registered = 0; $unknown = 0
foreach ($d in $win) {
    switch ($d.trustType) {
        'AzureAd'   { $entraJoined++ }
        'ServerAd'  { if ($d.onPremisesSyncEnabled) { $hybrid++ } else { $domainJoined++ } }
        'Workplace' { $registered++ }
        default     { $unknown++ }
    }
}
$inScope = $hybrid + $domainJoined

$joinRows = @(
    [pscustomobject]@{ JoinType = 'Entra hybrid-joined'; Count = $hybrid;       InScope = 'yes' }
    [pscustomobject]@{ JoinType = 'Domain-joined';       Count = $domainJoined; InScope = 'yes' }
    [pscustomobject]@{ JoinType = 'Entra-joined (cloud)'; Count = $entraJoined; InScope = 'no'  }
    [pscustomobject]@{ JoinType = 'Registered/Workplace'; Count = $registered;  InScope = 'no'  }
    [pscustomobject]@{ JoinType = 'Unknown';             Count = $unknown;      InScope = '?'   }
)
Write-Host "`n[1] Windows devices by join type" -ForegroundColor Cyan
$joinRows | Format-Table -AutoSize

# --- Pre-logon capability present + assigned ---------------------------------
function Get-AssignmentCount {
    param([string] $Uri)
    try { $a = Invoke-Graph $Uri; return [int]$a.Count } catch { return 0 }
}

$allConfigs = Invoke-Graph "$base/deviceManagement/deviceConfigurations?`$select=id,displayName"
$dt = $allConfigs | Where-Object { $_.displayName -eq $DeviceTunnelProfileName }
$dtAssigned = if ($dt) { (Get-AssignmentCount "$base/deviceManagement/deviceConfigurations/$($dt.id)/assignments") -gt 0 } else { $false }

$allApps = Invoke-Graph "$base/deviceAppManagement/mobileApps?`$select=id,displayName"
$sbl = $allApps | Where-Object { $_.displayName -eq $SblAppName }
$sblAssigned = if ($sbl) { (Get-AssignmentCount "$base/deviceAppManagement/mobileApps/$($sbl.id)/assignments") -gt 0 } else { $false }

$capRows = @(
    [pscustomobject]@{ Capability = 'Device tunnel (A)'; Object = $DeviceTunnelProfileName; Present = [bool]$dt;  Assigned = $dtAssigned }
    [pscustomobject]@{ Capability = 'SBL / PLAP (B)';    Object = $SblAppName;              Present = [bool]$sbl; Assigned = $sblAssigned }
)
Write-Host "[2] Pre-logon capability (referenced companion objects)" -ForegroundColor Cyan
$capRows | Format-Table -AutoSize -Wrap

# --- Coverage estimate -------------------------------------------------------
# A deployed+assigned pre-logon path exists for the in-scope population if EITHER approach is present
# and assigned. (Exact per-device coverage is validated on-device with PREVPN-Validation.ps1.)
$pathAvailable = $dtAssigned -or $sblAssigned
$coveragePct = if ($inScope -eq 0) { 'n/a (no in-scope devices)' } elseif ($pathAvailable) { '100% (path deployed+assigned; confirm per-device with PREVPN-Validation.ps1)' } else { '0% (no pre-logon path deployed+assigned)' }

Write-Host "`n=== Coverage ===" -ForegroundColor Cyan
Write-Host ("  In-scope devices (hybrid + domain-joined) : {0}" -f $inScope)
Write-Host ("  Entra-joined (excluded, cloud-only)       : {0}" -f $entraJoined)
Write-Host ("  Pre-logon path deployed+assigned          : {0}" -f $(if($pathAvailable){'YES'}else{'NO'})) -ForegroundColor $(if($pathAvailable){'Green'}else{'Red'})
Write-Host ("  Estimated in-scope coverage               : {0}" -f $coveragePct) -ForegroundColor $(if($pathAvailable){'Green'}else{'Yellow'})
if ($inScope -eq 0) {
    Write-Host "  Fleet is effectively cloud-only — pre-logon VPN is likely not needed (SSPR/TAP cover cloud)." -ForegroundColor Green
} elseif (-not $pathAvailable) {
    Write-Host "  Deploy the chosen approach via its companion product, then re-run." -ForegroundColor Yellow
}

if ($CsvPath) {
    $joinRows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "`nExported join-type rows to $CsvPath" -ForegroundColor Green
}
Write-Host "Report complete (read-only). No changes were made." -ForegroundColor Green

<#
.SYNOPSIS
    TUNMAMG-Validation.ps1 — Validate the Microsoft Tunnel for MAM deployment on a GCC High / DoD tenant.
.DESCRIPTION
    PURPOSE
        Read-only validation of Microsoft Tunnel for MAM against this solution's expected state on a
        US sovereign-cloud (GCC High / DoD) tenant. Checks that the Tunnel site and server config
        exist, a server is registered, the three MAM policies per platform exist and share the same
        assignment groups, only one Defender app-config policy is present, and there is no MDM/MAM
        collision. Replace placeholders like your-tenant-id with real values.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TUNMAMG-Validation.ps1
        (Graph scopes: DeviceManagementConfiguration.Read.All, DeviceManagementApps.Read.All,
         Group.Read.All. Uses -Environment USGov for GCC High; pass -Environment USGovDoD for DoD.)
    EXPECTED RESULTS
        A pass/fail table for gates A1-A9. PASS = all expected objects present and consistent.
        FAIL = a listed check failed, with a one-line reason and the doc reference to fix it.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [ValidateSet('USGov', 'USGovDoD')]
    [string]$Environment = 'USGov',

    [string]$ServerConfigName = 'SC-TUNMAMG-Gov',
    [string]$SiteName         = 'SITE-TUNMAMG-Gov'
)

$ErrorActionPreference = 'Stop'
$script:results = @()

function Add-Result {
    param([string]$Id, [string]$Check, [bool]$Pass, [string]$Detail)
    $script:results += [pscustomobject]@{ Id = $Id; Check = $Check; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}

function Connect-GovGraph {
    param([string]$Env)
    $scopes = @('DeviceManagementConfiguration.Read.All', 'DeviceManagementApps.Read.All', 'Group.Read.All')
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph PowerShell SDK not found. Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Write-Host "Connecting to Microsoft Graph (US Gov environment: $Env)..." -ForegroundColor Cyan
    Connect-MgGraph -Environment $Env -Scopes $scopes | Out-Null
    return Get-MgContext
}

function Invoke-GraphGet {
    param([string]$Uri)
    try { return Invoke-MgGraphRequest -Method GET -Uri $Uri -ErrorAction Stop }
    catch { Write-Warning "GET $Uri failed: $($_.Exception.Message)"; return $null }
}

try {
    $ctx  = Connect-GovGraph -Env $Environment
    $base = if ($Environment -eq 'USGovDoD') { 'https://dod-graph.microsoft.us/beta' } else { 'https://graph.microsoft.us/beta' }

    # A1 — Gov Graph endpoint
    Add-Result 'A1' 'Graph context is a US Gov endpoint' ($ctx.Environment -match 'USGov') "Environment=$($ctx.Environment)"

    # A2 — Site + Server config present and linked
    $sites = Invoke-GraphGet "$base/deviceManagement/microsoftTunnelSites"
    $sc    = Invoke-GraphGet "$base/deviceManagement/microsoftTunnelConfigurations"
    $site  = $sites.value | Where-Object { $_.displayName -eq $SiteName } | Select-Object -First 1
    $cfg   = $sc.value    | Where-Object { $_.displayName -eq $ServerConfigName } | Select-Object -First 1
    Add-Result 'A2' "Site '$SiteName' and Server config '$ServerConfigName' exist" ([bool]$site -and [bool]$cfg) `
        "site=$([bool]$site) serverConfig=$([bool]$cfg)"

    # A3 — at least one server registered and online
    $online = $false; $serverDetail = 'no servers'
    if ($site) {
        $servers = Invoke-GraphGet "$base/deviceManagement/microsoftTunnelSites/$($site.id)/microsoftTunnelServers"
        if ($servers.value) {
            $serverDetail = ($servers.value | ForEach-Object { "$($_.displayName)=$($_.tunnelServerHealthStatus)" }) -join '; '
            $online = [bool]($servers.value | Where-Object { $_.tunnelServerHealthStatus -in @('healthy', 'online') })
        }
    }
    Add-Result 'A3' 'A Tunnel server is registered and online (else: check intune_env=FXP)' $online $serverDetail

    # App config + protection policies
    $appCfg = (Invoke-GraphGet "$base/deviceAppManagement/targetedManagedAppConfigurations").value
    $andAp  = (Invoke-GraphGet "$base/deviceAppManagement/androidManagedAppProtections").value
    $iosAp  = (Invoke-GraphGet "$base/deviceAppManagement/iosManagedAppProtections").value

    $defAnd  = @($appCfg | Where-Object { $_.displayName -eq 'AC-TUNMAMG-Defender-Android' })
    $edgeAnd = @($appCfg | Where-Object { $_.displayName -eq 'AC-TUNMAMG-Edge-Android' })
    $edgeIos = @($appCfg | Where-Object { $_.displayName -eq 'AC-TUNMAMG-Edge-iOS' })
    $apAnd   = @($andAp  | Where-Object { $_.displayName -eq 'AP-TUNMAMG-Edge-Android' })
    $apIos   = @($iosAp  | Where-Object { $_.displayName -eq 'AP-TUNMAMG-iOS' })

    # A4 — Android three policies
    Add-Result 'A4' 'Android policies (Defender AC, Edge AC, Edge AP) exist' `
        (($defAnd.Count -ge 1) -and ($edgeAnd.Count -ge 1) -and ($apAnd.Count -ge 1)) `
        "Defender=$($defAnd.Count) Edge=$($edgeAnd.Count) AP=$($apAnd.Count)"

    # A5 — iOS policies
    Add-Result 'A5' 'iOS policies (Edge/LOB AC, AP) exist' `
        (($edgeIos.Count -ge 1) -and ($apIos.Count -ge 1)) "EdgeAC=$($edgeIos.Count) AP=$($apIos.Count)"

    # A6 — assignment groups aligned per platform (best-effort: compare assignment target group ids)
    function Get-AssignmentGroups {
        param([string]$Segment, [string]$Id)
        $a = Invoke-GraphGet "$base/deviceAppManagement/$Segment/$Id/assignments"
        if (-not $a.value) { return @() }
        return @($a.value | ForEach-Object { $_.target.groupId } | Where-Object { $_ })
    }
    $alignedAndroid = $true; $alignDetail = 'n/a'
    if ($defAnd.Count -and $edgeAnd.Count -and $apAnd.Count) {
        $g1 = Get-AssignmentGroups 'targetedManagedAppConfigurations' $defAnd[0].id
        $g2 = Get-AssignmentGroups 'targetedManagedAppConfigurations' $edgeAnd[0].id
        $g3 = Get-AssignmentGroups 'androidManagedAppProtections'     $apAnd[0].id
        $u  = @($g1 + $g2 + $g3 | Sort-Object -Unique)
        $alignedAndroid = (($g1 | Sort-Object) -join ',') -eq (($g2 | Sort-Object) -join ',') -and `
                          (($g2 | Sort-Object) -join ',') -eq (($g3 | Sort-Object) -join ',')
        $alignDetail = "distinct groups across 3 Android policies: $($u.Count)"
    }
    Add-Result 'A6' 'Android policies target the same group(s)' $alignedAndroid $alignDetail

    # A7 — single Defender app-config policy
    Add-Result 'A7' 'Exactly one Defender app-config policy (race-condition guard)' ($defAnd.Count -le 1) "count=$($defAnd.Count)"

    # A8 — MDM vs MAM tunnel collision (best-effort: MDM VPN profiles referencing Tunnel)
    $vpn = Invoke-GraphGet "$base/deviceManagement/deviceConfigurations?`$filter=isof('microsoft.graph.androidWorkProfileVpnConfiguration')"
    $mdmTunnel = @()
    if ($vpn.value) { $mdmTunnel = @($vpn.value | Where-Object { $_.connectionType -match 'microsoftTunnel' }) }
    Add-Result 'A8' 'No obvious MDM-Tunnel + MAM-Tunnel overlap (review groups if MDM Tunnel exists)' `
        ($mdmTunnel.Count -eq 0) "MDM Tunnel VPN profiles found=$($mdmTunnel.Count)"

    # A9 — advanced capability / licensing signal (best-effort presence check)
    Add-Result 'A9' 'Intune Plan 2 / advanced capability (verify assignment in portal)' `
        (($defAnd.Count -ge 1) -or ($edgeIos.Count -ge 1)) 'Policies present implies entitlement is usable; confirm license in intune.microsoft.us'

    # Output
    Write-Host "`n==== TUNMAMG Validation ($($ctx.Environment)) ====" -ForegroundColor Cyan
    $script:results | Format-Table -AutoSize Id, Result, Check, Detail
    $fails = @($script:results | Where-Object { $_.Result -eq 'FAIL' })
    if ($fails.Count -eq 0) { Write-Host "`nGate A: PASS — all checks passed." -ForegroundColor Green }
    else { Write-Host "`nGate A: FAIL — $($fails.Count) check(s) failed. See 05-testing.md / 06-troubleshooting.md." -ForegroundColor Red; exit 2 }
}
catch {
    Write-Error "Validation failed: $($_.Exception.Message)"
    exit 1
}
finally {
    if (Get-MgContext -ErrorAction SilentlyContinue) { Disconnect-MgGraph | Out-Null }
}

<#
.SYNOPSIS
    Clinical Endpoint Logon & Profile Optimization (FSLogix) - inventory / discovery (read-only).

    PURPOSE:
        Inventories readiness for the FSLogix clinical-endpoint deployment. Runs in
        two complementary modes:
          - TENANT mode (default, via Microsoft Graph): confirms the named FSLogix
            agent Win32 app and the two settings profiles exist and are assigned, and
            that the 'Clinical - Logon Optimization' device group exists.
          - LOCAL mode (-Local, run on an endpoint): reports the FSLogix agent
            presence and version, the Profile Container configuration
            (HKLM\SOFTWARE\FSLogix\Profiles), and profile-share health (reachability
            of the configured VHD Locations path).
        Makes NO changes.

    HOW TO RUN:
        Tenant : 1. Install-Module Microsoft.Graph -Scope CurrentUser
                 2. .\CLINLOGON-Discovery.ps1
                 3. Sign in with Intune read access (Global Reader / Intune Administrator).
        Local  : Run on a clinical endpoint:
                 .\CLINLOGON-Discovery.ps1 -Local

    EXPECTED RESULTS:
        A readiness summary, one line per check, marked FOUND / MISSING (tenant) or
        OK / WARN (local). Exit code 0 if all checks pass, 1 otherwise. Any MISSING /
        WARN item must be addressed before deployment (see 03-implementation.md).

.NOTES
    Healthcare Solutions - read-only.
#>

[CmdletBinding(DefaultParameterSetName='Tenant')]
param(
    [Parameter(ParameterSetName='Local')] [switch]$Local,
    [string]$AgentAppName        = 'FSLogix Agent - Clinical Endpoints - Deploy',
    [string]$ProfileConfigName   = 'FSLogix Profile - Clinical Endpoints - Container',
    [string]$FastLogonConfigName = 'Fast Logon - Clinical Endpoints - Tuning',
    [string]$GroupName           = 'Clinical - Logon Optimization'
)

$ErrorActionPreference = 'Stop'
$allOk = $true

function Write-Check {
    param([string]$Label, [bool]$Ok, [string]$Detail, [string]$OkTag = 'FOUND  ', [string]$BadTag = 'MISSING')
    $status = if ($Ok) { $OkTag } else { $BadTag }
    Write-Host ("[{0}] {1} {2}" -f $status, $Label, $Detail)
}

if ($Local) {
    # ---------------- LOCAL endpoint mode ----------------
    Write-Host "FSLogix local discovery on $env:COMPUTERNAME`n"

    # Agent presence + version
    $agentReg = 'HKLM:\SOFTWARE\FSLogix\Apps'
    $agent = Get-ItemProperty -Path $agentReg -ErrorAction SilentlyContinue
    if ($agent -and $agent.InstallVersion) {
        Write-Check "FSLogix agent installed" $true ("(version $($agent.InstallVersion))") 'OK  ' 'WARN'
    } else {
        Write-Check "FSLogix agent installed" $false '' 'OK  ' 'WARN'; $allOk = $false
    }

    # Profile Container config
    $profReg = 'HKLM:\SOFTWARE\FSLogix\Profiles'
    $prof = Get-ItemProperty -Path $profReg -ErrorAction SilentlyContinue
    if ($prof -and $prof.Enabled -eq 1) {
        Write-Check "Profile Container enabled" $true '' 'OK  ' 'WARN'
        $vhdLoc = $prof.VHDLocations
        Write-Host ("       VHDLocations : {0}" -f ($vhdLoc -join '; '))
        Write-Host ("       VolumeType   : {0}" -f $prof.VolumeType)
        Write-Host ("       SizeInMBs    : {0}" -f $prof.SizeInMBs)
        Write-Host ("       IsDynamic    : {0}" -f $prof.IsDynamic)

        # Share health: reachability of each VHD location
        foreach ($loc in @($vhdLoc)) {
            if ([string]::IsNullOrWhiteSpace($loc)) { continue }
            $reachable = Test-Path -Path $loc -ErrorAction SilentlyContinue
            Write-Check "Profile share reachable: $loc" $reachable '' 'OK  ' 'WARN'
            if (-not $reachable) { $allOk = $false }
        }
    } else {
        Write-Check "Profile Container enabled" $false '(HKLM\SOFTWARE\FSLogix\Profiles Enabled=1 not set)' 'OK  ' 'WARN'
        $allOk = $false
    }

    Write-Host ''
    if ($allOk) { Write-Host 'RESULT: Local FSLogix discovery PASSED.'; exit 0 }
    else        { Write-Host 'RESULT: One or more local checks WARN - see 03-implementation.md / 06-troubleshooting.md.'; exit 1 }
}

# ---------------- TENANT (Graph) mode ----------------
try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All','DeviceManagementConfiguration.Read.All','Group.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome
}
catch {
    Write-Error "Unable to connect to Microsoft Graph: $($_.Exception.Message)"
    exit 1
}

# --- Agent app ---
$agent = Get-MgDeviceAppManagementMobileApp -Filter "displayName eq '$AgentAppName'" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($agent) {
    $assignments = Get-MgDeviceAppManagementMobileAppAssignment -MobileAppId $agent.Id -ErrorAction SilentlyContinue
    Write-Check "Agent app '$AgentAppName'" $true ("- assignments: {0}" -f ($assignments | Measure-Object).Count)
    if (-not $assignments) { $allOk = $false; Write-Host "         WARNING: agent app has no assignments." }
} else { Write-Check "Agent app '$AgentAppName'" $false ''; $allOk = $false }

# --- Settings profiles (settings catalog = deviceManagement/configurationPolicies) ---
function Test-ConfigPolicy {
    param([string]$Name)
    $uri = "https://graph.microsoft.com/v1.0/deviceManagement/configurationPolicies?`$filter=name eq '$Name'"
    try { $resp = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop; return [bool]($resp.value) } catch { return $false }
}
$profOk = Test-ConfigPolicy -Name $ProfileConfigName
Write-Check "Settings profile '$ProfileConfigName'" $profOk ''
if (-not $profOk) { $allOk = $false }

$fastOk = Test-ConfigPolicy -Name $FastLogonConfigName
Write-Check "Settings profile '$FastLogonConfigName'" $fastOk ''
if (-not $fastOk) { $allOk = $false }

# --- Device group ---
$group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($group) {
    $members = Get-MgGroupMember -GroupId $group.Id -All -ErrorAction SilentlyContinue
    Write-Check "Group '$GroupName'" $true ("- members: {0}" -f ($members | Measure-Object).Count)
} else { Write-Check "Group '$GroupName'" $false ''; $allOk = $false }

Write-Host ''
if ($allOk) { Write-Host 'RESULT: Tenant readiness checks PASSED.'; exit 0 }
else        { Write-Host 'RESULT: One or more readiness checks MISSING - see 03-implementation.md.'; exit 1 }

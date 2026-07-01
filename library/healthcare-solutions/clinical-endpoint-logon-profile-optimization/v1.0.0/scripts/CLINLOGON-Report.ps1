<#
.SYNOPSIS
    Clinical Endpoint Logon & Profile Optimization (FSLogix) - logon-time + profile-size
    report to CSV (read-only).

    PURPOSE:
        Produces a report for the clinical-endpoint deployment. Two modes:
          - SHARE mode (default): given the profile share path, reports each per-user
            FSLogix container folder, its VHD(X) size (profile bloat tracking), and
            last-write time. Exports to CSV.
          - FLEET mode (-Fleet, via Microsoft Graph): for every device in
            'Clinical - Logon Optimization', reports the FSLogix agent app install
            state and group coverage. Exports to CSV.
        Optionally includes a local logon-time sample when run on an endpoint
        (-IncludeLocalLogon). Makes NO changes.

    HOW TO RUN:
        Share : .\CLINLOGON-Report.ps1 -SharePath "\\fileserver\ClinicalProfiles$" -OutCsv "C:\Temp\fslogix-sizes.csv"
        Fleet : 1. Install-Module Microsoft.Graph -Scope CurrentUser
                2. .\CLINLOGON-Report.ps1 -Fleet -OutCsv "C:\Temp\fslogix-coverage.csv"
                3. Sign in with Intune read access.

    EXPECTED RESULTS:
        A CSV at the path given (default in the working directory). Share mode: one
        row per container (UserFolder, SizeMB, LastWriteTime). Fleet mode: one row
        per device (DeviceName, AgentInstallState, InGroup). A summary prints to console.

.NOTES
    Healthcare Solutions - read-only.
#>

[CmdletBinding(DefaultParameterSetName='Share')]
param(
    [Parameter(ParameterSetName='Share', Mandatory)] [string]$SharePath,
    [Parameter(ParameterSetName='Fleet', Mandatory)] [switch]$Fleet,
    [switch]$IncludeLocalLogon,
    [string]$GroupName    = 'Clinical - Logon Optimization',
    [string]$AgentAppName = 'FSLogix Agent - Clinical Endpoints - Deploy',
    [string]$OutCsv       = (".\CLINLOGON-Report-{0}.csv" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
)

$ErrorActionPreference = 'Stop'

if ($Fleet) {
    # ---------------- FLEET (Graph) mode ----------------
    try {
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All','Group.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome
    }
    catch { Write-Error "Unable to connect to Microsoft Graph: $($_.Exception.Message)"; exit 1 }

    # agent install-state map (beta deviceStatuses)
    $agentMap = @{}
    $app = Get-MgDeviceAppManagementMobileApp -Filter "displayName eq '$AgentAppName'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($app) {
        $uri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($app.Id)/deviceStatuses"
        do {
            try { $resp = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop } catch { break }
            foreach ($d in $resp.value) { if ($d.deviceName) { $agentMap[$d.deviceName] = $d.installState } }
            $uri = $resp.'@odata.nextLink'
        } while ($uri)
    }

    $group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $group) { Write-Error "Group '$GroupName' not found."; exit 1 }
    $members = Get-MgGroupMember -GroupId $group.Id -All -ErrorAction SilentlyContinue

    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($m in $members) {
        $name = $m.AdditionalProperties['displayName']; if (-not $name) { $name = $m.Id }
        $rows.Add([pscustomobject]@{
            DeviceName        = $name
            AgentInstallState = if ($agentMap.ContainsKey($name)) { $agentMap[$name] } else { 'unknown' }
            InGroup           = $true
        })
    }
    $rows | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8
    $agentOk = ($rows | Where-Object { $_.AgentInstallState -eq 'installed' }).Count
    Write-Host ("Devices in group : {0}" -f $rows.Count)
    Write-Host ("Agent installed  : {0}/{1}" -f $agentOk, $rows.Count)
    Write-Host ("CSV written      : {0}" -f (Resolve-Path $OutCsv))
    exit 0
}

# ---------------- SHARE mode (container sizes) ----------------
if (-not (Test-Path $SharePath)) { Write-Error "Share path '$SharePath' not reachable."; exit 1 }

$rows = New-Object System.Collections.Generic.List[object]
Get-ChildItem -Path $SharePath -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $folder = $_
    $vhd = Get-ChildItem -Path $folder.FullName -Recurse -Include '*.vhdx','*.vhd' -ErrorAction SilentlyContinue |
           Sort-Object Length -Descending | Select-Object -First 1
    $sizeMb = if ($vhd) { [math]::Round($vhd.Length / 1MB, 0) } else { 0 }
    $rows.Add([pscustomobject]@{
        UserFolder    = $folder.Name
        SizeMB        = $sizeMb
        LastWriteTime = if ($vhd) { $vhd.LastWriteTime } else { $folder.LastWriteTime }
        VhdFile       = if ($vhd) { $vhd.Name } else { '(none found)' }
    })
}

if ($IncludeLocalLogon) {
    try {
        $evt = Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-User Profile Service/Operational'; Id=1,2 } -MaxEvents 50 -ErrorAction SilentlyContinue | Sort-Object TimeCreated
        $start = ($evt | Where-Object Id -eq 1 | Select-Object -Last 1).TimeCreated
        $end   = ($evt | Where-Object Id -eq 2 | Select-Object -Last 1).TimeCreated
        if ($start -and $end -and $end -gt $start) {
            Write-Host ("Local logon sample on {0}: {1}s" -f $env:COMPUTERNAME, [math]::Round(($end-$start).TotalSeconds,1))
        }
    } catch { }
}

$rows | Sort-Object SizeMB -Descending | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8
$total = $rows.Count
$avg   = if ($total) { [math]::Round((($rows | Measure-Object SizeMB -Average).Average),0) } else { 0 }
$max   = if ($total) { ($rows | Measure-Object SizeMB -Maximum).Maximum } else { 0 }
Write-Host ("Containers found : {0}" -f $total)
Write-Host ("Avg size (MB)    : {0}" -f $avg)
Write-Host ("Max size (MB)    : {0}" -f $max)
Write-Host ("CSV written      : {0}" -f (Resolve-Path $OutCsv))

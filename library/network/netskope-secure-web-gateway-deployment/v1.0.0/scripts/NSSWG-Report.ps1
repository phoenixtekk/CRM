<#
.SYNOPSIS
    NSSWG-Report.ps1 — steering-scope coverage and (optional) web-activity report.
.DESCRIPTION
    PURPOSE
        Reports SWG coverage: the steering-scope Entra groups and their member counts (Microsoft
        Graph), plus the client-app assignment targets. Optionally pulls per-category web activity
        from the Netskope REST API to confirm traffic is flowing through the gateway. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\NSSWG-Report.ps1 -CsvPath C:\Temp\nsswg.csv
        Microsoft side uses Microsoft Graph (read scopes below); sign in when prompted.
        Optional Netskope activity: set NSSWG_NETSKOPE_BASEURL and NSSWG_NETSKOPE_TOKEN, and pass
        -NetskopeActivityPath '<exact read-only REST path for your tenant/version>'.
    EXPECTED RESULTS
        Steering-group coverage (members per group), client-app assignment targets, an optional CSV,
        and (if configured) a per-category web-activity summary from the Netskope tenant.
.NOTES
    Workplace Marketplace — Network Solutions. Read-only.
    The Netskope REST path is tenant/version specific and is NOT invented here — supply it yourself
    via -NetskopeActivityPath per Netskope's API documentation. Secrets come from the environment.
#>
[CmdletBinding()] param(
    [string]$PilotGroup = 'Web Steering - Pilot - Stage 1',
    [string]$BroadGroup = 'Web Steering - Broad - Stage 2',
    [string]$ClientAppName = 'SWG Client Deployment - Managed Devices - Production',
    [string]$CsvPath,
    [string]$NetskopeActivityPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.Read.All','DeviceManagementApps.Read.All' -NoWelcome

function Get-GroupInfo($name) {
    $enc = [uri]::EscapeDataString($name)
    $g = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$enc'").value | Select-Object -First 1
    if (-not $g) { return [pscustomobject]@{ Group=$name; Exists=$false; Members=0 } }
    $count = 0; $uri = "/v1.0/groups/$($g.id)/members?`$select=id"
    do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $count += $r.value.Count; $uri = $r.'@odata.nextLink' } while ($uri)
    return [pscustomobject]@{ Group=$name; Exists=$true; Members=$count }
}

$rows = @((Get-GroupInfo $PilotGroup), (Get-GroupInfo $BroadGroup))
Write-Host "=== SWG steering-scope coverage ===" -ForegroundColor Cyan
$rows | Format-Table -AutoSize
if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }

# Client-app assignment targets
$app = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.win32LobApp')").value | Where-Object { $_.displayName -eq $ClientAppName } | Select-Object -First 1
if ($app) {
    $asg = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileApps/$($app.id)/assignments").value
    Write-Host ("Client app '{0}' assignment targets: {1}" -f $ClientAppName, (($asg | ForEach-Object { $_.target.'@odata.type' }) -join ', ')) -ForegroundColor Cyan
} else {
    Write-Host ("Client app '{0}' not found." -f $ClientAppName) -ForegroundColor Yellow
}

# --- Optional: per-category web activity from the Netskope tenant (generic REST) ---
$nsBase = $env:NSSWG_NETSKOPE_BASEURL
$nsToken = $env:NSSWG_NETSKOPE_TOKEN
if ($nsBase -and $nsToken -and $NetskopeActivityPath) {
    try {
        $uri = "{0}/{1}" -f $nsBase.TrimEnd('/'), $NetskopeActivityPath.TrimStart('/')
        # NOTE: $NetskopeActivityPath is supplied by you per Netskope's API docs — not invented here.
        $data = Invoke-RestMethod -Method GET -Uri $uri -Headers @{ 'Netskope-Api-Token' = $nsToken } -TimeoutSec 30 -ErrorAction Stop
        Write-Host "=== Netskope web activity (tenant) ===" -ForegroundColor Cyan
        $data | Format-List
    } catch {
        Write-Host ("Netskope activity query failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
} else {
    Write-Host "Netskope web activity : skipped (set env vars and pass -NetskopeActivityPath to enable)" -ForegroundColor DarkGray
}

Disconnect-MgGraph | Out-Null

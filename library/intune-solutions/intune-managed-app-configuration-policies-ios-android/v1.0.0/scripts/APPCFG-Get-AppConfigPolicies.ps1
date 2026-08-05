<#
.SYNOPSIS
    APPCFG-Get-AppConfigPolicies.ps1 — export App Configuration Policies + assignments (read-only, Graph).
.DESCRIPTION
    PURPOSE
        Inventories every App Configuration Policy in the tenant — both channels: managed-device
        policies (mobileAppConfigurations, iOS plist / Android managed configurations) and managed-app
        policies (targetedManagedAppConfigurations, MAM / App SDK) — with each policy's platform,
        targeted app(s), and group assignments. Use it to baseline your app-config posture and to keep
        an exported copy in source control. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\APPCFG-Get-AppConfigPolicies.ps1 -CsvPath C:\Temp\appcfg.csv
        powershell -ExecutionPolicy Bypass -File .\APPCFG-Get-AppConfigPolicies.ps1 -Environment USGov
        Requires the Microsoft Graph SDK and DeviceManagementApps.Read.All.
    EXPECTED RESULTS
        One row per policy (Channel / Name / Platform / TargetedApps / Assignments), plus optional CSV.
        PASS = every intended app-config policy appears with the expected platform and assignment.
.NOTES
    Intune Solutions — read-only. Cloud-aware (Commercial / USGov). No credentials stored.
.EXAMPLE
    .\APPCFG-Get-AppConfigPolicies.ps1 -CsvPath C:\Temp\appcfg.csv
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [ValidateSet('Global', 'USGov', 'USGovDoD')]
    [string]$Environment = 'Global'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All' -Environment $Environment -NoWelcome

function Get-GraphAll($uri) {
    $items = @()
    do {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $uri
        if ($resp.value) { $items += $resp.value } else { $items += $resp }
        $uri = $resp.'@odata.nextLink'
    } while ($uri)
    return $items
}

$rows = @()

# ---- Channel 1: managed-device app configuration (iOS plist / Android managed configs) ----
$mdConfigs = Get-GraphAll "/v1.0/deviceAppManagement/mobileAppConfigurations?`$expand=assignments"
foreach ($c in $mdConfigs) {
    $apps = ''
    if ($c.targetedMobileApps) { $apps = ($c.targetedMobileApps -join ';') }
    $assign = ''
    if ($c.assignments) { $assign = (($c.assignments | ForEach-Object { $_.target.groupId }) -join ';') }
    $rows += [pscustomobject]@{
        Channel      = 'ManagedDevice'
        Name         = $c.displayName
        Platform     = ($c.'@odata.type' -replace '#microsoft.graph.', '')
        TargetedApps = $apps
        Assignments  = $assign
    }
}

# ---- Channel 2: managed-app configuration (MAM / App SDK) ----
$mamConfigs = Get-GraphAll "/v1.0/deviceAppManagement/targetedManagedAppConfigurations?`$expand=assignments"
foreach ($c in $mamConfigs) {
    $assign = ''
    if ($c.assignments) { $assign = (($c.assignments | ForEach-Object { $_.target.groupId }) -join ';') }
    $rows += [pscustomobject]@{
        Channel      = 'ManagedApp(MAM)'
        Name         = $c.displayName
        Platform     = $c.appGroupType
        TargetedApps = '(see policy apps)'
        Assignments  = $assign
    }
}

if (-not $rows) {
    Write-Host "No App Configuration Policies found in this tenant." -ForegroundColor Yellow
} else {
    $rows | Sort-Object Channel, Name | Format-Table -AutoSize
    $unassigned = ($rows | Where-Object { -not $_.Assignments }).Count
    Write-Host ("`nPolicies: {0} | Unassigned: {1}" -f $rows.Count, $unassigned) -ForegroundColor Cyan
    if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" -ForegroundColor Green }
}
Disconnect-MgGraph | Out-Null

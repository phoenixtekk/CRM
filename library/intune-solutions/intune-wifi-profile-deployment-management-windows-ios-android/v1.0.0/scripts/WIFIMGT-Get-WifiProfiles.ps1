<#
.SYNOPSIS
    WIFIMGT-Get-WifiProfiles.ps1 — export existing Intune Wi-Fi configuration profiles + assignments (read-only, cloud-aware).
.DESCRIPTION
    PURPOSE
        Lists every Wi-Fi device-configuration profile in the tenant across Windows, iOS/iPadOS, and
        Android Enterprise (template-based, identified by @odata.type) plus any Settings Catalog
        policies whose name suggests Wi-Fi, and shows each profile's assigned groups. Use it to
        inventory what exists before authoring new profiles (and to spot same-SSID duplicates).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WIFIMGT-Get-WifiProfiles.ps1
        Sovereign cloud:  .\WIFIMGT-Get-WifiProfiles.ps1 -Environment USGov      (or USGovDoD)
        Export to CSV:    .\WIFIMGT-Get-WifiProfiles.ps1 -OutputCsv .\wifi-profiles.csv
        Required Graph scopes: DeviceManagementConfiguration.Read.All
    EXPECTED RESULTS
        A table of Wi-Fi profiles (name, platform/type, assigned groups). Read-only — nothing changes.
.NOTES
    White-label — Intune Solutions. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [ValidateSet('Global','USGov','USGovDoD')]
    [string] $Environment = 'Global',
    [string] $OutputCsv
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    throw "Microsoft.Graph SDK not installed. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment $Environment -Scopes 'DeviceManagementConfiguration.Read.All' -NoWelcome
Write-Host "Connected to Graph ($Environment) tenant: $((Get-MgContext).TenantId)" -ForegroundColor Cyan

function Get-All($uri) {
    $out = @(); $next = $uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $out += $resp.value } elseif ($resp) { $out += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $out
}

# Cache group id -> displayName for readable assignment output
$groupNames = @{}
function Resolve-Group($id) {
    if (-not $id) { return $null }
    if ($groupNames.ContainsKey($id)) { return $groupNames[$id] }
    try {
        $g = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$id`?`$select=displayName"
        $groupNames[$id] = $g.displayName
    } catch { $groupNames[$id] = $id }
    return $groupNames[$id]
}

$rows = New-Object System.Collections.Generic.List[object]

# Template-based Wi-Fi profiles live under deviceConfigurations; match by @odata.type
Write-Host "`n=== Template Wi-Fi profiles ===" -ForegroundColor Yellow
$dc = Get-All "/beta/deviceManagement/deviceConfigurations?`$select=id,displayName,@odata.type"
foreach ($p in $dc) {
    $t = [string]$p.'@odata.type'
    if ($t -match '(?i)wifi|wireless') {
        $asg = Get-All "/beta/deviceManagement/deviceConfigurations/$($p.id)/assignments"
        $groups = @()
        foreach ($a in $asg) { $g = Resolve-Group $a.target.groupId; if ($g) { $groups += $g } }
        $rows.Add([pscustomobject]@{
            Name = $p.displayName; Type = ($t -replace '#microsoft.graph.',''); Source='Template'
            Groups = if ($groups) { $groups -join '; ' } else { 'UNASSIGNED' }
        })
    }
}

# Settings Catalog policies whose name hints Wi-Fi
Write-Host "=== Settings Catalog (name-matched) ===" -ForegroundColor Yellow
try {
    $cp = Get-All "/beta/deviceManagement/configurationPolicies?`$select=id,name"
    foreach ($sc in $cp) {
        if ($sc.name -match '(?i)wi-?fi|wireless|802\.?1x') {
            $asg = Get-All "/beta/deviceManagement/configurationPolicies/$($sc.id)/assignments"
            $groups = @()
            foreach ($a in $asg) { $g = Resolve-Group $a.target.groupId; if ($g) { $groups += $g } }
            $rows.Add([pscustomobject]@{
                Name = $sc.name; Type='configurationPolicy'; Source='SettingsCatalog'
                Groups = if ($groups) { $groups -join '; ' } else { 'UNASSIGNED' }
            })
        }
    }
} catch { Write-Verbose "configurationPolicies not readable: $($_.Exception.Message)" }

if ($rows.Count -eq 0) { Write-Host "  No Wi-Fi profiles found." -ForegroundColor DarkYellow }
else { $rows | Format-Table -AutoSize }

Write-Host ("`n{0} Wi-Fi profile(s) found." -f $rows.Count) -ForegroundColor Green
if ($OutputCsv) { $rows | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8; Write-Host "Written to $OutputCsv" -ForegroundColor Cyan }

Disconnect-MgGraph | Out-Null

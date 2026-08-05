<#
.SYNOPSIS
    APPOPS-Discovery.ps1 — inventory the application estate and expose governance gaps.
.DESCRIPTION
    PURPOSE
        Read-only. Builds the "before" picture for the application management operating
        model. For every application in Intune it reports the assignment count, whether it
        targets All Users / All Devices (a governance red flag), its scope tags, and whether
        a governance owner block has been stamped into its Notes field. This is the baseline
        the Application Register is seeded from and the scorecard is measured against.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\APPOPS-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\APPOPS-Discovery.ps1 -CsvPath .\AppEstate-Baseline.csv
        Government tenant:  add  -GraphEnvironment USGov
        Required Graph scopes: DeviceManagementApps.Read.All, DeviceManagementRBAC.Read.All, Group.Read.All
    EXPECTED RESULTS
        A table (and optional CSV) of every application with: AssignmentCount, TargetsAllUsers,
        TargetsAllDevices, ScopeTags, GovernedOwner. Pass = every production application has an
        assignment, no All Users/All Devices targeting, a non-default scope tag, and a governed
        owner. Fail = any blank owner, zero assignment, or All Users/All Devices targeting —
        these are your ungoverned / orphaned applications to remediate.
.NOTES
    Intune Solutions — read-only. Uses the Microsoft Graph PowerShell SDK.
#>

[CmdletBinding()]
param(
    [string] $AppNameLike,
    [string] $CsvPath,
    [ValidateSet('Global','USGov')]
    [string] $GraphEnvironment = 'Global'
)

$ErrorActionPreference = 'Stop'

function Connect-Graph {
    param([string] $Environment)
    $scopes = @('DeviceManagementApps.Read.All','DeviceManagementRBAC.Read.All','Group.Read.All')
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft Graph SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if (-not (Get-MgContext)) {
        if ($Environment -eq 'USGov') {
            Connect-MgGraph -Scopes $scopes -Environment USGov | Out-Null
        } else {
            Connect-MgGraph -Scopes $scopes | Out-Null
        }
    }
}

function Get-GraphBase {
    param([string] $Environment)
    if ($Environment -eq 'USGov') { return 'https://graph.microsoft.us/beta' }
    return 'https://graph.microsoft.com/beta'
}

function Invoke-GraphGet {
    param([Parameter(Mandatory)][string] $Uri)
    $items = @()
    $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $items += $resp.value } elseif ($resp) { $items += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $items
}

Connect-Graph -Environment $GraphEnvironment
$base = Get-GraphBase -Environment $GraphEnvironment

Write-Host "Reading applications from Intune..." -ForegroundColor Cyan
$apps = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps?`$top=100"

if ($AppNameLike) {
    $apps = $apps | Where-Object { $_.displayName -like "*$AppNameLike*" }
}

$results = foreach ($app in $apps) {
    $id   = $app.id
    $name = $app.displayName
    $type = ($app.'@odata.type' -replace '#microsoft.graph.','')
    $notes = [string]$app.notes
    $scopeTagIds = @($app.roleScopeTagIds)

    $assignments = @()
    $targetsAllUsers = $false
    $targetsAllDevices = $false
    try {
        $assignments = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps/$id/assignments"
        foreach ($a in $assignments) {
            $tt = [string]$a.target.'@odata.type'
            if ($tt -match 'allLicensedUsersAssignmentTarget') { $targetsAllUsers = $true }
            if ($tt -match 'allDevicesAssignmentTarget')       { $targetsAllDevices = $true }
        }
    } catch { }

    # A governed application carries a "Owner:" line in its Notes, stamped by APPOPS-Remediation.ps1
    $governedOwner = ''
    if ($notes -match '(?im)^\s*Owner:\s*(.+)$') { $governedOwner = $Matches[1].Trim() }

    # Resolve scope tag ids to a readable "Default"/tag-id summary
    $scopeTagSummary = if ($scopeTagIds.Count -eq 0 -or ($scopeTagIds.Count -eq 1 -and $scopeTagIds[0] -eq '0')) {
        'Default'
    } else {
        ($scopeTagIds -join ',')
    }

    [pscustomobject]@{
        AppName           = $name
        AppType           = $type
        AppId             = $id
        AssignmentCount   = $assignments.Count
        TargetsAllUsers   = $targetsAllUsers
        TargetsAllDevices = $targetsAllDevices
        ScopeTags         = $scopeTagSummary
        GovernedOwner     = $governedOwner
    }
}

$results = $results | Sort-Object AppName
$results | Format-Table -AutoSize AppName, AppType, AssignmentCount, TargetsAllUsers, TargetsAllDevices, ScopeTags, GovernedOwner

# Governance gap summary
$total       = $results.Count
$orphaned    = ($results | Where-Object { $_.AssignmentCount -eq 0 }).Count
$broadTarget = ($results | Where-Object { $_.TargetsAllUsers -or $_.TargetsAllDevices }).Count
$noOwner     = ($results | Where-Object { [string]::IsNullOrWhiteSpace($_.GovernedOwner) }).Count
$noScopeTag  = ($results | Where-Object { $_.ScopeTags -eq 'Default' }).Count

Write-Host ""
Write-Host "===== Governance baseline =====" -ForegroundColor Cyan
Write-Host ("Total applications        : {0}" -f $total)
Write-Host ("Orphaned (no assignment)  : {0}" -f $orphaned) -ForegroundColor $(if($orphaned){'Yellow'}else{'Green'})
Write-Host ("All Users/All Devices     : {0}" -f $broadTarget) -ForegroundColor $(if($broadTarget){'Yellow'}else{'Green'})
Write-Host ("No governed owner         : {0}" -f $noOwner) -ForegroundColor $(if($noOwner){'Yellow'}else{'Green'})
Write-Host ("No scope tag (Default)    : {0}" -f $noScopeTag) -ForegroundColor $(if($noScopeTag){'Yellow'}else{'Green'})

if ($CsvPath) {
    $results | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Saved baseline to {0}" -f $CsvPath) -ForegroundColor Green
}

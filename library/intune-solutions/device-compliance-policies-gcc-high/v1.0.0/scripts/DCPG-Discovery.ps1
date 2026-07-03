<#
.SYNOPSIS
    DCPG-Discovery.ps1 — inventory device compliance policies, assignments, and actions on a GCC High tenant.
.DESCRIPTION
    PURPOSE
        Read-only discovery of Intune device compliance policies in a US Government
        (GCC High) tenant. Lists each policy, its assignments (which groups it targets),
        and its noncompliance actions, so you can baseline the tenant before you build
        and detect drift afterward. Connects to US Gov Microsoft Graph only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DCPG-Discovery.ps1
        (Graph scopes: DeviceManagementConfiguration.Read.All, Group.Read.All; -Environment USGov)
        For DoD tenants, pass -Environment USGovDoD.
    EXPECTED RESULTS
        A table of compliance policies with platform, assignment target group names, and
        the count of noncompliance actions. Optionally writes a CSV. Makes NO changes.
        PASS if the connected environment reports USGov (or USGovDoD) and policies list.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [ValidateSet('USGov', 'USGovDoD')]
    [string]$Environment = 'USGov',

    [string]$CsvPath
)

$ErrorActionPreference = 'Stop'

function Connect-GovGraph {
    param([string]$Env)
    $scopes = @('DeviceManagementConfiguration.Read.All', 'Group.Read.All')
    Write-Host "Connecting to Microsoft Graph (Environment: $Env)..." -ForegroundColor Cyan
    Connect-MgGraph -Environment $Env -Scopes $scopes | Out-Null
    $ctx = Get-MgContext
    if (-not $ctx) { throw 'Failed to establish a Microsoft Graph context.' }
    if ($ctx.Environment -ne $Env) {
        throw "Connected environment is '$($ctx.Environment)', expected '$Env'. Reconnect with -Environment $Env."
    }
    Write-Host "Connected. Environment: $($ctx.Environment)  Account: $($ctx.Account)" -ForegroundColor Green
    return $ctx
}

# Resolve a group id to its display name (best effort, read-only).
$script:GroupNameCache = @{}
function Get-GroupName {
    param([string]$GroupId)
    if ([string]::IsNullOrWhiteSpace($GroupId)) { return '(unknown)' }
    if ($script:GroupNameCache.ContainsKey($GroupId)) { return $script:GroupNameCache[$GroupId] }
    try {
        $g = Get-MgGroup -GroupId $GroupId -Property 'displayName' -ErrorAction Stop
        $name = $g.DisplayName
    } catch {
        $name = "(group $GroupId)"
    }
    $script:GroupNameCache[$GroupId] = $name
    return $name
}

# Describe an assignment target in plain language.
function Get-AssignmentTargetLabel {
    param($Target)
    if (-not $Target) { return '(none)' }
    switch ($Target.AdditionalProperties.'@odata.type') {
        '#microsoft.graph.allDevicesAssignmentTarget' { return 'All devices' }
        '#microsoft.graph.allLicensedUsersAssignmentTarget' { return 'All users' }
        '#microsoft.graph.groupAssignmentTarget' { return "Group: $(Get-GroupName $Target.AdditionalProperties.groupId)" }
        '#microsoft.graph.exclusionGroupAssignmentTarget' { return "Exclude group: $(Get-GroupName $Target.AdditionalProperties.groupId)" }
        default { return $Target.AdditionalProperties.'@odata.type' }
    }
}

try {
    Connect-GovGraph -Env $Environment | Out-Null

    Write-Host "`nRetrieving device compliance policies..." -ForegroundColor Cyan
    $policies = Get-MgDeviceManagementDeviceCompliancePolicy -All -ExpandProperty 'assignments' -ErrorAction Stop

    if (-not $policies -or $policies.Count -eq 0) {
        Write-Host "No device compliance policies found in this ($Environment) tenant." -ForegroundColor Yellow
        return
    }

    $rows = foreach ($p in $policies) {
        $platform = ($p.AdditionalProperties.'@odata.type' -replace '#microsoft.graph.', '' -replace 'CompliancePolicy', '')
        $targets = @()
        foreach ($a in $p.Assignments) { $targets += Get-AssignmentTargetLabel $a.Target }
        $actionCount = 0
        if ($p.AdditionalProperties.ContainsKey('scheduledActionsForRule')) {
            foreach ($rule in $p.AdditionalProperties.scheduledActionsForRule) {
                if ($rule.scheduledActionConfigurations) { $actionCount += $rule.scheduledActionConfigurations.Count }
            }
        }

        [pscustomobject]@{
            Name            = $p.DisplayName
            Platform        = $platform
            Id              = $p.Id
            AssignedTargets = if ($targets) { ($targets -join '; ') } else { '(unassigned)' }
            NoncomplyActions = $actionCount
            LastModified    = $p.LastModifiedDateTime
        }
    }

    Write-Host "`n=== Device Compliance Policies ($Environment) ===`n" -ForegroundColor Green
    $rows | Sort-Object Name | Format-Table Name, Platform, AssignedTargets, NoncomplyActions, LastModified -AutoSize -Wrap

    Write-Host "Total policies: $($rows.Count)" -ForegroundColor Cyan

    if ($CsvPath) {
        $rows | Sort-Object Name | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
        Write-Host "CSV written to: $CsvPath" -ForegroundColor Green
    }
}
finally {
    if (Get-MgContext) { Disconnect-MgGraph | Out-Null; Write-Host "`nDisconnected from Microsoft Graph." -ForegroundColor DarkGray }
}

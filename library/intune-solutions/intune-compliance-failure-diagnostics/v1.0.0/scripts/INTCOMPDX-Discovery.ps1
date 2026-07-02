<#
.SYNOPSIS
    INTCOMPDX-Discovery.ps1 — enumerate Intune compliance policies, their settings, grace, assignments, and device compliance state (read-only).
.DESCRIPTION
    PURPOSE
        Builds the compliance map for diagnosis: every compliance policy, the grace
        configuration (Actions for noncompliance), assignments, and where devices stand.
        Optionally scope to one policy or one device by name. Read-only against Microsoft
        Graph. Replace the sample values such as your-policy-name / your-device-name.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\INTCOMPDX-Discovery.ps1

        Required Graph scopes:
            DeviceManagementConfiguration.Read.All
            DeviceManagementManagedDevices.Read.All
    EXPECTED RESULTS
        A table of compliance policies with grace and assignments, and (if a device is
        named) that device's compliance state per policy. No changes are made — pass = the
        map returns; fail = an authorization error means missing scopes/role.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding()]
param(
    [string]$PolicyName,
    [string]$DeviceName,
    [string]$OutputCsv
)

$ErrorActionPreference = 'Stop'

function Connect-Graph {
    $scopes = @(
        'DeviceManagementConfiguration.Read.All',
        'DeviceManagementManagedDevices.Read.All'
    )
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft Graph PowerShell SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = Get-MgContext
    if (-not $ctx -or -not ($scopes | Where-Object { $ctx.Scopes -contains $_ })) {
        Connect-MgGraph -Scopes $scopes | Out-Null
    }
    Write-Host "Connected to tenant: $((Get-MgContext).TenantId)" -ForegroundColor Green
}

function Invoke-GraphGetAll {
    param([Parameter(Mandatory)][string]$Uri)
    $results = @()
    $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $results += $resp.value } else { $results += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $results
}

Connect-Graph

Write-Host "`n=== Compliance policies ===" -ForegroundColor Cyan
$policies = Invoke-GraphGetAll -Uri "https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies"
if ($PolicyName) { $policies = $policies | Where-Object { $_.displayName -eq $PolicyName } }

$policyRows = foreach ($p in $policies) {
    # Grace / scheduled actions (Actions for noncompliance)
    $actions = Invoke-GraphGetAll -Uri ("https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies/{0}/scheduledActionsForRule?`$expand=scheduledActionConfigurations" -f $p.id)
    $graceDays = ($actions.scheduledActionConfigurations |
        Where-Object { $_.actionType -eq 'block' } |
        Select-Object -ExpandProperty gracePeriodHours -ErrorAction SilentlyContinue |
        Sort-Object -Descending | Select-Object -First 1)
    $graceText = if ($null -ne $graceDays) { "{0} hours" -f $graceDays } else { "Immediately (0)" }

    $assignments = Invoke-GraphGetAll -Uri ("https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies/{0}/assignments" -f $p.id)
    $assignText = if ($assignments) { ($assignments.target.groupId -join '; ') } else { '(none)' }

    [pscustomobject]@{
        PolicyName   = $p.displayName
        PolicyId     = $p.id
        Type         = $p.'@odata.type' -replace '#microsoft.graph.', ''
        Grace        = $graceText
        Assignments  = $assignText
    }
}
$policyRows | Format-Table -AutoSize

if ($DeviceName) {
    Write-Host "`n=== Device compliance state: $DeviceName ===" -ForegroundColor Cyan
    $devs = Invoke-GraphGetAll -Uri ("https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=deviceName eq '{0}'" -f $DeviceName)
    if (-not $devs) { Write-Warning "No managed device named '$DeviceName' found." }
    foreach ($d in $devs) {
        [pscustomobject]@{
            DeviceName      = $d.deviceName
            ComplianceState = $d.complianceState
            OS              = "$($d.operatingSystem) $($d.osVersion)"
            LastSync        = $d.lastSyncDateTime
            UserPrincipal   = $d.userPrincipalName
        } | Format-List
    }
}

if ($OutputCsv) {
    $policyRows | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
    Write-Host "`nSaved policy map to $OutputCsv" -ForegroundColor Green
}

Write-Host "`nDiscovery complete (read-only)." -ForegroundColor Green

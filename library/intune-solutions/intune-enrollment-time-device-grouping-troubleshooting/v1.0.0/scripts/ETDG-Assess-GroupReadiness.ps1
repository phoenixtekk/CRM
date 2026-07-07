<#
.SYNOPSIS
    ETDG-Assess-GroupReadiness.ps1 — report whether a target group meets the Enrollment-Time Grouping spec and is owned by the Intune Provisioning Client (read-only).
.DESCRIPTION
    Reports a device group's Type, MembershipType (Assigned vs Dynamic), onPremisesSyncEnabled,
    mailEnabled, isAssignableToRole, and member count, and whether the Intune Provisioning Client
    service principal (AppId f1346770-5b25-470b-88bd-d5744ab7952c) is an OWNER — giving a PASS/FAIL
    per prerequisite R1-R7. Read-only against Microsoft Graph; makes no changes.
.EXAMPLE
    .\ETDG-Assess-GroupReadiness.ps1 -GroupName "Autopilot - Devices - Pilot"
    (PowerShell 5.1+/7+, Microsoft.Graph SDK; connect with Connect-MgGraph)
.NOTES
    Expected results: a per-prerequisite PASS/FAIL table. Pass = every row PASS (group is ready to
    wire to an enrollment policy). Fail = any row FAIL maps to a fix in 02-requirements.
    White-label. Read-only.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$GroupName,
    [string]$ProvisioningClientAppId = 'f1346770-5b25-470b-88bd-d5744ab7952c'
)

$ErrorActionPreference = 'Stop'

function Connect-EtdgGraph {
    param([string[]]$Scopes = @('Group.Read.All'))
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph PowerShell SDK not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = Get-MgContext
    if (-not $ctx -or ($Scopes | Where-Object { $ctx.Scopes -notcontains $_ })) {
        Connect-MgGraph -Scopes $Scopes | Out-Null
    }
    Write-Host "Connected to tenant: $((Get-MgContext).TenantId)" -ForegroundColor Green
}

function Invoke-GraphGetAll {
    param([Parameter(Mandatory)][string]$Uri)
    $results = @(); $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($null -ne $resp.value) { $results += $resp.value } else { $results += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $results
}

Connect-EtdgGraph

$escaped = $GroupName -replace "'", "''"
$grp = Invoke-GraphGetAll -Uri ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $escaped)
if (-not $grp) { throw "Group '$GroupName' not found. Verify the exact display name." }
if ($grp.Count -gt 1) { Write-Warning "Multiple groups named '$GroupName' found; assessing the first (id $($grp[0].id))." }
$g = $grp[0]

# Owner check — match the service principal by AppId, not display name.
$owners     = Invoke-GraphGetAll -Uri "https://graph.microsoft.com/v1.0/groups/$($g.id)/owners"
$ownerSp    = $owners | Where-Object { $_.appId -eq $ProvisioningClientAppId }
$ownerFound = [bool]$ownerSp

# Member count.
$members    = Invoke-GraphGetAll -Uri "https://graph.microsoft.com/v1.0/groups/$($g.id)/members?`$select=id"
$memberCount = @($members).Count

$isSecurity   = [bool]$g.securityEnabled -and -not ($g.groupTypes -contains 'Unified')
$isAssigned   = [string]::IsNullOrEmpty($g.membershipRule)
$isCloudOnly  = -not $g.onPremisesSyncEnabled
$notMail      = -not $g.mailEnabled
$notRoleAsgn  = -not $g.isAssignableToRole

function Row($id, $label, $ok, $detail) {
    [pscustomobject]@{
        Req    = $id
        Check  = $label
        Result = $(if ($ok) { 'PASS' } else { 'FAIL' })
        Detail = $detail
    }
}

$rows = @(
    Row 'R1' 'Security group'                 $isSecurity  ("securityEnabled=$($g.securityEnabled); groupTypes=[$($g.groupTypes -join ',')]")
    Row 'R2' 'Assigned membership (not Dynamic)' $isAssigned ($(if ($isAssigned) { 'membershipRule empty' } else { "Dynamic: $($g.membershipRule)" }))
    Row 'R3' 'Cloud-only (not AD-synced)'      $isCloudOnly ("onPremisesSyncEnabled=$($g.onPremisesSyncEnabled)")
    Row 'R4' 'Not mail-enabled'               $notMail     ("mailEnabled=$($g.mailEnabled)")
    Row 'R5' 'Not role-assignable'            $notRoleAsgn ("isAssignableToRole=$($g.isAssignableToRole)")
    Row 'R6' 'Empty (best practice)'          ($memberCount -eq 0) ("memberCount=$memberCount")
    Row 'R7' 'Intune Provisioning Client is Owner' $ownerFound ($(if ($ownerFound) { "owner appId=$ProvisioningClientAppId ($($ownerSp.displayName))" } else { 'no owner with that AppId' }))
)

Write-Host "`n=== Group readiness: $GroupName (id $($g.id)) ===" -ForegroundColor Cyan
$rows | Format-Table -AutoSize

$fails = $rows | Where-Object { $_.Result -eq 'FAIL' -and $_.Req -ne 'R6' }
if ($fails) {
    Write-Host "RESULT: NOT READY — resolve the FAIL rows above (see 02-requirements) before saving the enrollment policy." -ForegroundColor Red
} else {
    Write-Host "RESULT: READY — group meets the spec and is owned by the Provisioning Client. (R6 empty is advisory.)" -ForegroundColor Green
}

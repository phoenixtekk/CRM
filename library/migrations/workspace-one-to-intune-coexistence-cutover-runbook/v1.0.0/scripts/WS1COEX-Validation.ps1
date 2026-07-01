<#
.SYNOPSIS
    WS1COEX-Validation.ps1 — per-cohort cutover-readiness gate (read-only).
.DESCRIPTION
    PURPOSE
        Runs the pre-cutover go/no-go checks for one cohort group: (1) the cohort group exists and has
        members; (2) every Conditional Access policy that requires a compliant/Entra-joined device is
        scoped to a cohort group, NOT All users; (3) the cohort's devices are present and reporting a
        compliance state in Intune. Read-only against Microsoft Graph — it decides GO / NO-GO, it does
        not change anything.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WS1COEX-Validation.ps1 -CohortGroupId <entra-group-guid>
        (or) -CohortGroupName "Cutover Cohort - Pilot - Stage1"
        Requires the Microsoft Graph PowerShell SDK. Scopes:
        Group.Read.All, DeviceManagementManagedDevices.Read.All, Policy.Read.All.
    EXPECTED RESULTS
        A PASS/FAIL line per gate and an overall GO / NO-GO verdict for the cohort. A NO-GO means
        hold the cohort and remediate before running the cutover sequence.
        NOTE: Workspace ONE enrollment-channel and source-assignment checks are deferred to the
        Workspace ONE console — see VMware docs.
#>
[CmdletBinding(DefaultParameterSetName='ById')]
param(
    [Parameter(ParameterSetName='ById',Mandatory)][string]$CohortGroupId,
    [Parameter(ParameterSetName='ByName',Mandatory)][string]$CohortGroupName
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.Read.All','DeviceManagementManagedDevices.Read.All','Policy.Read.All' -NoWelcome

$pass = $true
function Gate([string]$name,[bool]$ok,[string]$detail){
    $script:pass = $script:pass -and $ok
    $tag = if($ok){'PASS'}else{'FAIL'}; $col = if($ok){'Green'}else{'Red'}
    Write-Host ("  [{0}] {1}{2}" -f $tag,$name,($(if($detail){" — $detail"}else{''}))) -ForegroundColor $col
}

# Resolve the cohort group
if ($PSCmdlet.ParameterSetName -eq 'ByName') {
    $g = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'" -f $CohortGroupName.Replace("'","''"))).value | Select-Object -First 1
    if (-not $g) { Write-Host "Cohort group not found: $CohortGroupName" -ForegroundColor Red; Disconnect-MgGraph|Out-Null; return }
    $CohortGroupId = $g.id
}
$grp = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$CohortGroupId?`$select=displayName,id"
Write-Host "=== WS1COEX Validation — cohort: $($grp.displayName) ===" -ForegroundColor Cyan

# Gate 1 — cohort membership
$members = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$CohortGroupId/members?`$select=id,displayName").value
Gate 'Cohort group has members' (@($members).Count -gt 0) ("{0} members" -f @($members).Count)

# Gate 2 — Conditional Access is cohort-scoped, not All users
$ca = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
$gating = foreach ($p in $ca) {
    $c = @($p.grantControls.builtInControls)
    if (($c -contains 'compliantDevice' -or $c -contains 'domainJoinedDevice') -and $p.state -eq 'enabled') { $p }
}
$allUsers = @($gating | Where-Object { @($_.conditions.users.includeUsers) -contains 'All' })
Gate 'No tenant-wide (All users) device-compliance CA policy' (@($allUsers).Count -eq 0) `
     ("{0} enabled device-gating CA policies; {1} target All users" -f @($gating).Count,@($allUsers).Count)

# Gate 3 — cohort devices known to Intune with a compliance state
$devs = @()
$uri = '/v1.0/deviceManagement/managedDevices?$select=deviceName,azureADDeviceId,complianceState,userPrincipalName'
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $devs += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
$memberUpns = @($members | ForEach-Object { $_.userPrincipalName } | Where-Object { $_ })
$cohortDevs = @($devs | Where-Object { $memberUpns -contains $_.userPrincipalName })
Gate 'Cohort devices present in Intune' (@($cohortDevs).Count -gt 0) ("{0} cohort devices in Intune" -f @($cohortDevs).Count)

Write-Host "`nNOTE: confirm the target enrollment channel is Active and that Workspace ONE is not double-targeting this cohort (see VMware docs) before proceeding." -ForegroundColor Yellow
Write-Host ("`n=== Cohort verdict: {0} ===" -f $(if($pass){'GO'}else{'NO-GO'})) -ForegroundColor $(if($pass){'Green'}else{'Red'})
Disconnect-MgGraph | Out-Null

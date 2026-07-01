<#
.SYNOPSIS
    AZSEC-Set-ScopeTargeting.ps1 — resolve and confirm the management-group / subscription scope
    used by every step of the baseline & governance rollout.
.DESCRIPTION
    PURPOSE
        Scope helper for the "Azure Security Baseline & Governance" solution. Resolves a target scope
        from either a management-group id or a subscription id, prints the resource-manager scope
        string that policy/RBAC assignments use, and lists the subscriptions that fall under it (for a
        management group, its child subscriptions; for a subscription, itself). Read-only — it
        confirms WHERE guardrails and roles will apply before you assign them. Use the printed scope
        string as the -Scope input to the other AZSEC scripts and the portal assignments.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AZSEC-Set-ScopeTargeting.ps1 -ManagementGroupId '<mg id>'
        powershell -ExecutionPolicy Bypass -File .\AZSEC-Set-ScopeTargeting.ps1 -SubscriptionId '<sub id>'
        Requires Az.Accounts, Az.Resources (management-group listing uses Get-AzManagementGroup from
        Az.Resources). Run Connect-AzAccount first, or the script will prompt.
    EXPECTED RESULTS
        The resolved scope string (e.g. '/providers/Microsoft.Management/managementGroups/<id>' or
        '/subscriptions/<id>') and the list of subscriptions in scope — the confirmed target you
        reuse verbatim in every assignment, script, and test.
.NOTES
    Workplace Marketplace — Azure Solutions. Read-only. The repeatable way.
    Object naming convention: <Purpose> - <Scope> - <Stage>, e.g.
    'Governance Scope - Pilot MG - Prod'. Reuse the resolved scope verbatim.
#>
[CmdletBinding()]
param(
    [string]$ManagementGroupId,
    [string]$SubscriptionId
)

foreach ($m in 'Az.Accounts','Az.Resources') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Az -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.Resources -ErrorAction Stop

if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }

if (-not $ManagementGroupId -and -not $SubscriptionId) {
    Write-Host "Provide -ManagementGroupId or -SubscriptionId to resolve the target scope." -ForegroundColor Red
    return
}

Write-Host "`n=== Azure Security Baseline & Governance — scope targeting ===" -ForegroundColor Cyan

if ($ManagementGroupId) {
    $scope = "/providers/Microsoft.Management/managementGroups/$ManagementGroupId"
    Write-Host ("Resolved scope: {0}" -f $scope) -ForegroundColor Green
    Write-Host "Subscriptions in scope (child subscriptions of the management group):" -ForegroundColor Cyan
    try {
        $mg = Get-AzManagementGroup -GroupId $ManagementGroupId -Expand -Recurse -ErrorAction Stop
        $subs = @()
        function Get-ChildSubs($node) {
            foreach ($child in $node.Children) {
                if ($child.Type -match 'subscriptions') { $script:subs += $child }
                elseif ($child.Children) { Get-ChildSubs $child }
            }
        }
        Get-ChildSubs $mg
        if ($subs) { $subs | ForEach-Object { Write-Host ("   {0}  ({1})" -f $_.DisplayName, $_.Name) } }
        else { Write-Host "   (no child subscriptions found)" -ForegroundColor Yellow }
    } catch { Write-Host ("   Could not enumerate the management group: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}
else {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    $scope = "/subscriptions/$SubscriptionId"
    Write-Host ("Resolved scope: {0}" -f $scope) -ForegroundColor Green
    try {
        $sub = Get-AzSubscription -SubscriptionId $SubscriptionId -ErrorAction Stop
        Write-Host ("Subscription in scope: {0}  ({1})" -f $sub.Name, $sub.Id)
    } catch { Write-Host ("   Could not read subscription: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}

Write-Host "`nUse the resolved scope string as -Scope for the other AZSEC scripts and portal assignments." -ForegroundColor Cyan
Write-Host "Scope targeting complete (read-only)." -ForegroundColor Green

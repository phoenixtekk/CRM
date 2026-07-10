<#
.SYNOPSIS
    ENTPIMG-Report.ps1 — activation/audit and access-review report for privileged roles.
.DESCRIPTION
    PURPOSE
        Read-only reporting for PIM governance evidence. By default it reports recent role ACTIVATIONS
        (who activated which role, when, the justification, and the approver if any) from the
        role-assignment schedule requests — an audit trail for compliance. With -AccessReviews it
        instead reports the status of privileged-role access reviews (name, schedule, whether
        auto-apply is on). Use it monthly.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTPIMG-Report.ps1
        Optional: -Days 30            look back window for activations (default 30)
        Optional: -AccessReviews      report access-review status instead of activations
        Optional: -CsvPath .\entpim-activations.csv   export a flat CSV
        Consents to RoleManagement.Read.All, AccessReview.Read.All, Directory.Read.All (read-only).
        GCC High / US Gov: Connect-MgGraph uses -Environment USGov (login.microsoftonline.us / graph.microsoft.us).
        For DoD (IL5) use -Environment USGovDoD (dod-graph.microsoft.us). *Verify the correct cloud for your tenant.*
    EXPECTED RESULTS
        A list of privileged activations with actor, role, justification, approval, and time — or, with
        -AccessReviews, the active review definitions. No changes are made.
.NOTES
    White-label — Entra ID Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [int]$Days = 30,
    [switch]$AccessReviews,
    [string]$CsvPath
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = if ($AccessReviews) { @('AccessReview.Read.All','Directory.Read.All') } else { @('RoleManagement.Read.All','Directory.Read.All') }
# US Government cloud (GCC High). For DoD (IL5) use -Environment USGovDoD (dod-graph.microsoft.us).
Connect-MgGraph -Environment USGov -Scopes $scopes -NoWelcome

$roleDefs = @{}
Get-MgRoleManagementDirectoryRoleDefinition -All | ForEach-Object { $roleDefs[$_.Id] = $_.DisplayName }
$principalCache = @{}
function Resolve-Principal($id) {
    if (-not $id) { return '' }
    if ($principalCache.ContainsKey($id)) { return $principalCache[$id] }
    $obj = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/directoryObjects/$id" -ErrorAction SilentlyContinue
    $name = if ($obj) { $obj.userPrincipalName ?? $obj.displayName ?? $id } else { $id }
    $principalCache[$id] = $name; return $name
}

$rows = @()
if ($AccessReviews) {
    Write-Host "`n=== Privileged-Role Access Reviews — $(Get-Date -Format s) ===" -ForegroundColor Cyan
    $defs = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/identityGovernance/accessReviews/definitions" -ErrorAction SilentlyContinue
    foreach ($d in $defs.value) {
        Write-Host ("• {0,-45} status={1}" -f $d.displayName, $d.status)
        Write-Host ("    recurrence: {0}   autoApply: {1}" -f $d.settings.recurrence.pattern.type, $d.settings.autoApplyDecisionsEnabled)
        $rows += [pscustomobject]@{ Name=$d.displayName; Status=$d.status; AutoApply=$d.settings.autoApplyDecisionsEnabled }
    }
    if (-not $defs.value) { Write-Host "No access-review definitions found. Create 'Privileged Role Access Review - Tenant - Quarterly' (Implementation Step 7)." -ForegroundColor Yellow }
}
else {
    Write-Host "`n=== Privileged Role Activations (last $Days days) — $(Get-Date -Format s) ===" -ForegroundColor Cyan
    $since = (Get-Date).ToUniversalTime().AddDays(-$Days).ToString('o')
    $reqs = Get-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -All -ErrorAction SilentlyContinue |
            Where-Object { $_.Action -match 'selfActivate|adminAssign' -and $_.CreatedDateTime -ge $since }
    Write-Host ("Requests in window: {0}`n" -f @($reqs).Count)
    foreach ($r in $reqs) {
        $roleName = $roleDefs[$r.RoleDefinitionId]
        $actor    = Resolve-Principal $r.PrincipalId
        Write-Host ("• {0}  {1,-30} {2}" -f $r.CreatedDateTime, $roleName, $actor) -ForegroundColor White
        Write-Host ("    action: {0}   justification: {1}" -f $r.Action, ($r.Justification ?? '<none>'))
        $rows += [pscustomobject]@{
            When=$r.CreatedDateTime; Role=$roleName; Actor=$actor; Action=$r.Action; Justification=$r.Justification
        }
    }
    if (-not $reqs) { Write-Host "No activations in the window (or none audited yet)." -ForegroundColor Yellow }
}

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`nExported {0} rows to {1}" -f $rows.Count, $CsvPath) -ForegroundColor Green
}
Disconnect-MgGraph | Out-Null

<#
.SYNOPSIS
    IGAG-Report.ps1 — GCC High standing-privilege and governance-coverage report (Microsoft Graph US Gov).
.DESCRIPTION
    PURPOSE
        Summarizes privileged access posture on a US Government (GCC High/DoD) tenant: per-role standing
        (active) vs eligible assignment counts, which roles are onboarded to PIM, how many access
        reviews are configured, and how many access packages are published — so you can see governance
        coverage and residual standing admin. Read-only. Use -Environment USGovDoD on the DoD cloud.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IGAG-Report.ps1 -CsvPath C:\Temp\igag.csv
        Connects to US Gov Graph (-Environment USGov). Read-only scopes:
        RoleManagement.Read.Directory, AccessReview.Read.All, EntitlementManagement.Read.All.
    EXPECTED RESULTS
        A per-role standing-vs-eligible table, governance coverage totals, and an optional CSV. Pass =
        table renders from graph.microsoft.us; fail = a connection error means -Environment was omitted.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding()] param(
    [string]$CsvPath,
    [ValidateSet('USGov','USGovDoD')][string]$Environment = 'USGov'
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment $Environment -Scopes 'RoleManagement.Read.Directory','AccessReview.Read.All','EntitlementManagement.Read.All' -NoWelcome

$defs  = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/roleManagement/directory/roleDefinitions').value)
$name  = @{}; $defs | ForEach-Object { $name[$_.id] = $_.displayName }
$elig  = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/roleManagement/directory/roleEligibilityScheduleInstances').value)
$activ = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/roleManagement/directory/roleAssignmentScheduleInstances').value)

$roleIds = @($elig.roleDefinitionId + $activ.roleDefinitionId | Sort-Object -Unique)
$rows = foreach ($rid in $roleIds) {
    [pscustomobject]@{
        Role     = $name[$rid]
        Active   = @($activ | Where-Object { $_.roleDefinitionId -eq $rid }).Count
        Eligible = @($elig  | Where-Object { $_.roleDefinitionId -eq $rid }).Count
    }
}
Write-Host "=== Privileged roles: standing (Active) vs Eligible — GCC High (env: $Environment) ===" -ForegroundColor Cyan
$rows | Sort-Object Active -Descending | Format-Table -AutoSize

$reviews = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identityGovernance/accessReviews/definitions').value)
$pkgs    = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identityGovernance/entitlementManagement/accessPackages').value)
Write-Host ("Total active (standing) assignments : {0}" -f ($rows | Measure-Object Active -Sum).Sum) -ForegroundColor Cyan
Write-Host ("Total eligible assignments          : {0}" -f ($rows | Measure-Object Eligible -Sum).Sum) -ForegroundColor Cyan
Write-Host ("Access reviews configured           : {0}" -f $reviews.Count) -ForegroundColor Cyan
Write-Host ("Access packages published           : {0}" -f $pkgs.Count) -ForegroundColor Cyan

if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }
Disconnect-MgGraph | Out-Null

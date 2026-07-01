<#
.SYNOPSIS
    IGA-Report.ps1 — standing-privilege and governance-coverage report (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Summarizes privileged access posture: per-role standing (active) vs eligible assignment counts,
        which roles are onboarded to PIM, how many access reviews are configured, and how many access
        packages are published — so you can see governance coverage and residual standing admin.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IGA-Report.ps1 -CsvPath C:\Temp\iga.csv
        Requires the Microsoft Graph PowerShell SDK. Read-only scopes:
        RoleManagement.Read.Directory, AccessReview.Read.All, EntitlementManagement.Read.All.
    EXPECTED RESULTS
        A per-role standing-vs-eligible table, governance coverage totals, and an optional CSV.
.NOTES
    Phoenixtekk Workplace Marketplace — Entra ID Solutions. Read-only against Graph.
#>
[CmdletBinding()] param([string]$CsvPath)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'RoleManagement.Read.Directory','AccessReview.Read.All','EntitlementManagement.Read.All' -NoWelcome

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
Write-Host "=== Privileged roles: standing (Active) vs Eligible ===" -ForegroundColor Cyan
$rows | Sort-Object Active -Descending | Format-Table -AutoSize

$reviews = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identityGovernance/accessReviews/definitions').value)
$pkgs    = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identityGovernance/entitlementManagement/accessPackages').value)
Write-Host ("Total active (standing) assignments : {0}" -f ($rows | Measure-Object Active -Sum).Sum) -ForegroundColor Cyan
Write-Host ("Total eligible assignments          : {0}" -f ($rows | Measure-Object Eligible -Sum).Sum) -ForegroundColor Cyan
Write-Host ("Access reviews configured           : {0}" -f $reviews.Count) -ForegroundColor Cyan
Write-Host ("Access packages published           : {0}" -f $pkgs.Count) -ForegroundColor Cyan

if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }
Disconnect-MgGraph | Out-Null

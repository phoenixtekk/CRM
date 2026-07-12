<#
.SYNOPSIS
    EKIDFUND-Report.ps1 — cohort progress + fundamentals snapshot for the enablement kit (read-only).
.DESCRIPTION
    PURPOSE
        A one-page, read-only report the instructor runs at the end of the kit: the cohort roster
        (members of Grp-EntraFund-Cohort), which lab sandbox objects exist, the Conditional Access lab
        policy state, MFA-registration coverage across the tenant (a fundamentals talking point), and
        the licensing tier. Optionally exports the rows to CSV for a training record. Read-only.
    HOW TO RUN
        pwsh -File .\EKIDFUND-Report.ps1
        pwsh -File .\EKIDFUND-Report.ps1 -OutputCsv .\ekidfund-cohort.csv
        Consents to read-only scopes (Directory.Read.All, Policy.Read.All, Reports.Read.All,
        AuditLog.Read.All). Government cloud: -Environment USGov.
    EXPECTED RESULTS
        A console summary + optional CSV. Nothing is modified.
.NOTES
    White-label — Entra ID Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string]$OutputCsv,
    [ValidateSet('Global','USGov','USGovDoD')][string]$Environment = 'Global'
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Directory.Read.All','Policy.Read.All','Reports.Read.All','AuditLog.Read.All' -Environment $Environment -NoWelcome

$rows = New-Object System.Collections.Generic.List[object]
function Add-Row($section,$item,$value){ $rows.Add([pscustomobject]@{ Section=$section; Item=$item; Value=$value }); Write-Host ("  {0,-40} {1}" -f $item, $value) }
function Get-GroupByName($n){ (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$n'").value | Select-Object -First 1 }

Write-Host "`n=== EKIDFUND Cohort & Fundamentals Report — $(Get-Date -Format s) ===" -ForegroundColor Cyan

# Cohort roster
Write-Host "`n-- Cohort --" -ForegroundColor Cyan
$cohort = Get-GroupByName 'Grp-EntraFund-Cohort'
if ($cohort) {
    $members = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups/{0}/members?`$select=displayName,userPrincipalName" -f $cohort.id)).value
    Add-Row 'Cohort' 'Grp-EntraFund-Cohort members' $members.Count
    foreach ($m in $members) { Write-Host ("     • {0} <{1}>" -f $m.displayName, $m.userPrincipalName) -ForegroundColor DarkGray }
} else { Add-Row 'Cohort' 'Grp-EntraFund-Cohort' 'NOT FOUND (create it — Step 0.2)' }

# Sandbox objects
Write-Host "`n-- Lab sandbox --" -ForegroundColor Cyan
foreach ($g in 'Grp-EntraFund-LabTeam-Pilot','Grp-EntraFund-DynamicDept-Pilot') {
    Add-Row 'Sandbox' $g $(if (Get-GroupByName $g) { 'present' } else { 'missing' })
}
$app = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/applications?`$filter=displayName eq 'App-EntraFund-LabApp-Pilot'").value | Select-Object -First 1
Add-Row 'Sandbox' 'App-EntraFund-LabApp-Pilot' $(if ($app) { 'present' } else { 'missing' })
$lu = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users?`$filter=startswith(displayName,'Lab-EntraFund')&`$count=true" -Headers @{ ConsistencyLevel='eventual' }).'@odata.count'
Add-Row 'Sandbox' 'Lab-EntraFund-* users' $lu

# CA lab policy state
Write-Host "`n-- Conditional Access lab --" -ForegroundColor Cyan
try {
    $lab = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value |
            Where-Object { $_.displayName -eq 'CAFund-RequireMFA-LabTeam-ReportOnly' } | Select-Object -First 1
    if ($lab) {
        $state = if ($lab.state -eq 'enabledForReportingButNotEnforced') { 'report-only (correct)' } else { "$($lab.state) — should be report-only!" }
        Add-Row 'CA-Lab' 'CAFund-RequireMFA-LabTeam-ReportOnly' $state
    } else { Add-Row 'CA-Lab' 'CAFund-RequireMFA-LabTeam-ReportOnly' 'not built (N/A if no P1)' }
} catch { Add-Row 'CA-Lab' 'policy read' 'unavailable (needs P1 + Policy.Read.All)' }

# MFA registration coverage (fundamentals talking point)
Write-Host "`n-- MFA registration coverage (tenant-wide, teaching prop) --" -ForegroundColor Cyan
try {
    $reg = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/reports/authenticationMethods/userRegistrationDetails?$top=999').value
    $total = $reg.Count
    $mfaCapable = @($reg | Where-Object { $_.isMfaCapable }).Count
    $pct = if ($total -gt 0) { [math]::Round(100.0*$mfaCapable/$total,1) } else { 0 }
    Add-Row 'MFA' 'Users evaluated' $total
    Add-Row 'MFA' 'MFA-capable users' ("{0} ({1}%)" -f $mfaCapable, $pct)
} catch { Write-Host "  (MFA registration report unavailable — needs Reports.Read.All / P1+. Verify in Entra -> Authentication methods -> Activity.)" -ForegroundColor DarkGray }

# Licensing
$plans = ((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value).servicePlans.servicePlanName
Add-Row 'Licensing' 'Entra ID P1' ($plans -contains 'AAD_PREMIUM')
Add-Row 'Licensing' 'Entra ID P2' ($plans -contains 'AAD_PREMIUM_P2')

if ($OutputCsv) { $rows | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8; Write-Host "`nExported to $OutputCsv" -ForegroundColor Green }
Write-Host "`nRead-only report complete. Nothing was changed." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null

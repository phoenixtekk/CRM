<#
.SYNOPSIS
    EKMFACA-Report.ps1 — report-only CA impact + cohort progress for the enablement kit (read-only).
.DESCRIPTION
    PURPOSE
        The evidence report the instructor runs at the end of the kit. From recent sign-in logs it
        summarizes what the REPORT-ONLY lab policies (CALab001-003) WOULD have done — per policy: how
        many sign-ins they would have granted, would have required a control for, or would have blocked
        — so the cohort sees impact without anything being enforced. It also reports the cohort roster,
        which lab policies/groups exist, and tenant-wide MFA-registration coverage. Read-only.
    HOW TO RUN
        pwsh -File .\EKMFACA-Report.ps1
        pwsh -File .\EKMFACA-Report.ps1 -LookbackDays 7 -OutputCsv .\ekmfaca-cohort.csv
        Consents to read-only scopes (AuditLog.Read.All, Policy.Read.All, Directory.Read.All,
        Reports.Read.All). Government cloud: -Environment USGov.
    EXPECTED RESULTS
        A console summary + optional CSV. Nothing is modified.
.NOTES
    White-label — Entra ID Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [int]$LookbackDays = 7,
    [string]$OutputCsv,
    [ValidateSet('Global','USGov','USGovDoD')][string]$Environment = 'Global'
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'AuditLog.Read.All','Policy.Read.All','Directory.Read.All','Reports.Read.All' -Environment $Environment -NoWelcome

$rows = New-Object System.Collections.Generic.List[object]
function Add-Row($section,$item,$value){ $rows.Add([pscustomobject]@{ Section=$section; Item=$item; Value=$value }); Write-Host ("  {0,-46} {1}" -f $item, $value) }
function Get-GroupByName($n){ (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$n'").value | Select-Object -First 1 }

Write-Host "`n=== EKMFACA Report-Only Impact & Cohort Report — last $LookbackDays days — $(Get-Date -Format s) ===" -ForegroundColor Cyan

# --- Cohort roster ---
Write-Host "`n-- Cohort --" -ForegroundColor Cyan
$cohort = Get-GroupByName 'Grp-MfaCa-Cohort'
if ($cohort) {
    $members = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups/{0}/members?`$select=displayName,userPrincipalName" -f $cohort.id)).value
    Add-Row 'Cohort' 'Grp-MfaCa-Cohort members' $members.Count
    foreach ($m in $members) { Write-Host ("     • {0} <{1}>" -f $m.displayName, $m.userPrincipalName) -ForegroundColor DarkGray }
} else { Add-Row 'Cohort' 'Grp-MfaCa-Cohort' 'NOT FOUND (create it — Step 0.2)' }

# --- Lab policy states ---
Write-Host "`n-- Report-only lab policies --" -ForegroundColor Cyan
$labNames = @(
    'CALab001 Require MFA - Internals - ReportOnly',
    'CALab002 Require Phishing-Resistant MFA - Admins - ReportOnly',
    'CALab003 Block Legacy Authentication - AllUsers - ReportOnly'
)
$ca = @()
try { $ca = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value } catch {}
foreach ($name in $labNames) {
    $p = $ca | Where-Object { $_.displayName -eq $name } | Select-Object -First 1
    if ($p) {
        $state = if ($p.state -eq 'enabledForReportingButNotEnforced') { 'report-only (correct)' } else { "$($p.state) — should be report-only!" }
        Add-Row 'LabPolicies' ($name.Split(' ')[0]) $state
    } else { Add-Row 'LabPolicies' ($name.Split(' ')[0]) 'not built (N/A if no P1)' }
}

# --- Report-only impact from sign-in logs ---
Write-Host "`n-- What the report-only policies WOULD have done (from sign-in logs) --" -ForegroundColor Cyan
$since = (Get-Date).AddDays(-$LookbackDays).ToString('yyyy-MM-ddT00:00:00Z')
$agg = @{}   # policy -> @{ grant=0; require=0; block=0; notApplied=0 }
try {
    $uri = "/v1.0/auditLogs/signIns?`$filter=$([uri]::EscapeDataString("createdDateTime ge $since"))&`$top=500"
    do {
        $page = Invoke-MgGraphRequest -Method GET -Uri $uri
        foreach ($s in $page.value) {
            foreach ($pol in @($s.appliedConditionalAccessPolicies)) {
                if ($pol.displayName -notlike 'CALab*') { continue }
                if (-not $agg.ContainsKey($pol.displayName)) { $agg[$pol.displayName] = @{ grant=0; require=0; block=0; notApplied=0 } }
                switch -Wildcard ($pol.result) {
                    'reportOnlySuccess'    { $agg[$pol.displayName].grant++ }
                    'reportOnlyFailure'    { $agg[$pol.displayName].block++ }
                    'reportOnlyInterrupted'{ $agg[$pol.displayName].require++ }
                    'reportOnlyNotApplied' { $agg[$pol.displayName].notApplied++ }
                    default { }
                }
            }
        }
        $uri = $page.'@odata.nextLink'
    } while ($uri)
    if ($agg.Keys.Count -eq 0) { Write-Host "  no report-only results yet — have the persona test users sign in, or widen -LookbackDays." -ForegroundColor Yellow }
    foreach ($k in $agg.Keys) {
        $v = $agg[$k]
        Write-Host ("   {0}" -f $k) -ForegroundColor White
        Write-Host ("      would-grant={0}  would-require={1}  would-block={2}  not-applied={3}" -f $v.grant, $v.require, $v.block, $v.notApplied) -ForegroundColor DarkGray
        Add-Row 'ReportOnlyImpact' ("$($k.Split(' ')[0]) would-block") $v.block
        Add-Row 'ReportOnlyImpact' ("$($k.Split(' ')[0]) would-grant") $v.grant
    }
    Write-Host "  (Report-only = 'would have'. Nothing was enforced. This is the evidence you'd review before enforcing in ENTZTCA.)" -ForegroundColor DarkGray
} catch { Write-Host "  (could not read sign-in logs — needs AuditLog.Read.All and P1+)" -ForegroundColor DarkGray }

# --- MFA registration coverage ---
Write-Host "`n-- MFA registration coverage (tenant-wide) --" -ForegroundColor Cyan
try {
    $reg = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/reports/authenticationMethods/userRegistrationDetails?$top=999').value
    $total = $reg.Count; $mfa = @($reg | Where-Object { $_.isMfaCapable }).Count
    $pct = if ($total) { [math]::Round(100.0*$mfa/$total,1) } else { 0 }
    Add-Row 'MFA' 'MFA-capable users' ("{0}/{1} ({2}%)" -f $mfa, $total, $pct)
} catch { Write-Host "  (MFA registration report unavailable — needs Reports.Read.All / P1+)" -ForegroundColor DarkGray }

if ($OutputCsv) { $rows | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8; Write-Host "`nExported to $OutputCsv" -ForegroundColor Green }
Write-Host "`nRead-only report complete. Nothing was changed." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null

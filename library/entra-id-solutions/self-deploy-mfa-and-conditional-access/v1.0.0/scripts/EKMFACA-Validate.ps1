<#
.SYNOPSIS
    EKMFACA-Validate.ps1 — run the kit pass/fail gates and print the knowledge-check (read-only).
.DESCRIPTION
    PURPOSE
        Turns 05-testing.md into a checklist run: confirms the cohort/persona/exclusion groups exist,
        that the report-only lab policies CALab001/002/003 exist and are REPORT-ONLY, that break-glass
        is excluded from every one, and the licensing tier — then prints the knowledge-check
        Check-MfaCa-Pilot answer key for the instructor to score. Read-only.
    HOW TO RUN
        pwsh -File .\EKMFACA-Validate.ps1
        pwsh -File .\EKMFACA-Validate.ps1 -BreakGlassUpn bg1@contoso.onmicrosoft.com,bg2@contoso.onmicrosoft.com
        Consents to read-only scopes (Directory.Read.All, Policy.Read.All). Government cloud: -Environment USGov.
    EXPECTED RESULTS
        A list of PASS / FAIL / MANUAL gate lines and the knowledge-check answer key. Any FAIL =
        reinforce the mapped lab and re-check. Any lab policy NOT report-only is a hard FAIL (this kit
        never enforces). Nothing is modified.
.NOTES
    White-label — Entra ID Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string[]]$BreakGlassUpn,
    [ValidateSet('Global','USGov','USGovDoD')][string]$Environment = 'Global'
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Directory.Read.All','Policy.Read.All' -Environment $Environment -NoWelcome

$results = New-Object System.Collections.Generic.List[object]
function Add-Gate([string]$Gate,[string]$Status,[string]$Detail){
    $results.Add([pscustomobject]@{ Gate=$Gate; Status=$Status; Detail=$Detail })
    $c = switch ($Status) { 'PASS'{'Green'} 'FAIL'{'Red'} default{'Yellow'} }
    Write-Host ("[{0}] {1} — {2}" -f $Status, $Gate, $Detail) -ForegroundColor $c
}
function Get-GroupByName($n){ (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$n'").value | Select-Object -First 1 }
function Get-UserByUpn($u){  (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users?`$filter=userPrincipalName eq '$u'").value | Select-Object -First 1 }

Write-Host "`n=== EKMFACA validation — $(Get-Date -Format s) ===" -ForegroundColor Cyan

# Gate 2 — groups
foreach ($g in 'Grp-MfaCa-Cohort','Grp-MfaCa-Persona-Admins-Pilot','Grp-MfaCa-Persona-Internals-Pilot','Grp-MfaCa-Persona-Guests-Pilot') {
    if (Get-GroupByName $g) { Add-Gate "G2 group $g" 'PASS' 'present' } else { Add-Gate "G2 group $g" 'FAIL' 'create it (Step 0.2 / 1.1 or EKMFACA-LabPolicy.ps1)' }
}
$excl = Get-GroupByName 'Grp-MfaCa-Excl-BreakGlass'
if ($excl) {
    $exclMembers = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups/{0}/members/`$count" -f $excl.id) -Headers @{ ConsistencyLevel='eventual' })
    if ([int]$exclMembers -ge 2) { Add-Gate 'G2 break-glass exclusion group' 'PASS' ("Grp-MfaCa-Excl-BreakGlass has {0} member(s)" -f $exclMembers) }
    else { Add-Gate 'G2 break-glass exclusion group' 'FAIL' 'add your two break-glass accounts to Grp-MfaCa-Excl-BreakGlass (R4/G4)' }
} else { Add-Gate 'G2 break-glass exclusion group' 'FAIL' 'create Grp-MfaCa-Excl-BreakGlass (R4/G4)' }

# Licensing context
$plans = ((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value).servicePlans.servicePlanName
$hasP1 = $plans -contains 'AAD_PREMIUM'
Add-Gate 'Licensing P1 (for lab policies)' $(if($hasP1){'PASS'}else{'MANUAL'}) $(if($hasP1){'Entra ID P1 present'}else{'no P1 — Labs 2-6 are a read-only CA tour; mark policy gates N/A (R1)'})

# Gate 3/4 — lab policies report-only + break-glass excluded
$labNames = @(
    'CALab001 Require MFA - Internals - ReportOnly',
    'CALab002 Require Phishing-Resistant MFA - Admins - ReportOnly',
    'CALab003 Block Legacy Authentication - AllUsers - ReportOnly'
)
try {
    $ca = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
    $bgIds = @(); if ($BreakGlassUpn) { foreach ($bg in $BreakGlassUpn) { $o = Get-UserByUpn $bg; if ($o) { $bgIds += $o.id } } }
    foreach ($name in $labNames) {
        $p = $ca | Where-Object { $_.displayName -eq $name } | Select-Object -First 1
        if (-not $p) { Add-Gate "G3 $($name.Split(' ')[0])" $(if($hasP1){'FAIL'}else{'MANUAL'}) "$name not found (build in Lab 4, or N/A if no P1)"; continue }
        # report-only?
        if ($p.state -eq 'enabledForReportingButNotEnforced') { Add-Gate "G3 $($name.Split(' ')[0]) report-only" 'PASS' 'report-only' }
        else { Add-Gate "G3 $($name.Split(' ')[0]) report-only" 'FAIL' ("state = {0} — this kit NEVER enforces; set back to Report-only" -f $p.state) }
        # break-glass excluded?
        $exclG = @($p.conditions.users.excludeGroups); $exclU = @($p.conditions.users.excludeUsers)
        $viaGroup = $excl -and ($exclG -contains $excl.id)
        $viaUser  = $bgIds.Count -gt 0 -and (@($bgIds | Where-Object { $exclU -notcontains $_ }).Count -eq 0)
        if ($viaGroup) { Add-Gate "G4 $($name.Split(' ')[0]) break-glass" 'PASS' 'excludes Grp-MfaCa-Excl-BreakGlass' }
        elseif ($viaUser) { Add-Gate "G4 $($name.Split(' ')[0]) break-glass" 'PASS' 'break-glass excluded by user (prefer the group)' }
        elseif (($exclG.Count + $exclU.Count) -gt 0) { Add-Gate "G4 $($name.Split(' ')[0]) break-glass" 'MANUAL' 'has exclusions — confirm they cover break-glass (pass -BreakGlassUpn to auto-check)' }
        else { Add-Gate "G4 $($name.Split(' ')[0]) break-glass" 'FAIL' 'NO exclusions — add Grp-MfaCa-Excl-BreakGlass (R4/G4)' }
    }
} catch { Add-Gate 'G3 lab policies' 'MANUAL' 'could not read CA policies (needs P1 + Policy.Read.All) — verify in the portal' }

# --- Knowledge-check answer key ---
Write-Host ''
Write-Host '=== Knowledge-check (Check-MfaCa-Pilot) — concept answer key ===' -ForegroundColor Cyan
@(
  'Q1 MFA strength ........ SMS/voice (weak) < authenticator+number-match < FIDO2/passkey/WHfB/CBA (phishing-resistant).'
  'Q2 CA anatomy .......... assignments/conditions (who/what/where/risk) -> grant and/or session controls.'
  'Q3 Report-only ......... evaluated + logged but NOT enforced — the safe way to test a policy.'
  'Q4 What-If ............. simulates a sign-in; shows which policies would apply + controls fire, no real sign-in.'
  'Q5 Personas ............ admins (phish-resistant), internals (MFA+device), guests (MFA+app-enforced), service accts (scoped out).'
  'Q6 Break-glass ......... 2 cloud-only emergency accounts EXCLUDED from every CA policy (exclude the GROUP).'
  'Q7 reportOnlyFailure ... a "would have" result — the policy did NOT block; not an outage.'
  'Q8 Auth strength ....... a named grant requirement (e.g. Phishing-resistant MFA) bridging methods -> CA.'
  'Q9 Legacy auth ......... basic-auth clients cannot do MFA; observe here, block in ENTZTCA (migrate first).'
  'Q10 Licensing .......... CA needs P1; risk-based conditions + PIM need P2; verify your tenant.'
) | ForEach-Object { Write-Host ("  {0}" -f $_) }
Add-Gate 'G7 knowledge-check' 'MANUAL' 'instructor scores each learner against the key above; threshold is your call'

Write-Host ''
Write-Host '=== Validation summary ===' -ForegroundColor Cyan
$results | Format-Table -AutoSize
$fail = @($results | Where-Object Status -eq 'FAIL').Count
if ($fail -eq 0) { Write-Host 'No hard FAILs — resolve any MANUAL checks, then the cohort can design/test/troubleshoot MFA/CA safely.' -ForegroundColor Green }
else { Write-Host ("{0} FAIL gate(s) — reinforce the mapped lab and re-run. Any non-report-only lab policy MUST be reset." -f $fail) -ForegroundColor Red }
Disconnect-MgGraph | Out-Null

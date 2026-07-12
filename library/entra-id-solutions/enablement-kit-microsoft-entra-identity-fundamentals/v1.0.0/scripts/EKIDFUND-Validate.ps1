<#
.SYNOPSIS
    EKIDFUND-Validate.ps1 — run the kit pass/fail gates and print the knowledge-check (read-only).
.DESCRIPTION
    PURPOSE
        Turns 05-testing.md into a checklist run: confirms the cloud-only lab sandbox exists and is
        correctly named (Grp-EntraFund-LabTeam-Pilot, Grp-EntraFund-DynamicDept-Pilot,
        Lab-EntraFund-User1, App-EntraFund-LabApp-Pilot), that the Conditional Access lab policy
        CAFund-RequireMFA-LabTeam-ReportOnly exists in REPORT-ONLY with break-glass excluded, that the
        cohort group exists, and the detected licensing tier — then prints the knowledge-check
        Check-EntraFund-Pilot answer key for the instructor to score. Read-only.
    HOW TO RUN
        pwsh -File .\EKIDFUND-Validate.ps1
        pwsh -File .\EKIDFUND-Validate.ps1 -BreakGlassUpn bg1@contoso.onmicrosoft.com,bg2@contoso.onmicrosoft.com
        Consents to read-only scopes (Directory.Read.All, Policy.Read.All). Government cloud: -Environment USGov.
    EXPECTED RESULTS
        A list of PASS / FAIL / MANUAL gate lines and the knowledge-check answer key. Any FAIL =
        reinforce the mapped lab and re-check before declaring the cohort grounded. Nothing is modified.
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
function Get-AppByName($n){  (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/applications?`$filter=displayName eq '$n'").value | Select-Object -First 1 }

Write-Host "`n=== EKIDFUND validation — $(Get-Date -Format s) ===" -ForegroundColor Cyan

# Gate 2 — cohort
if (Get-GroupByName 'Grp-EntraFund-Cohort') { Add-Gate 'G2 cohort exists' 'PASS' 'Grp-EntraFund-Cohort found' }
else { Add-Gate 'G2 cohort exists' 'FAIL' 'create Grp-EntraFund-Cohort (Step 0.2)' }

# Gate 3 — sandbox objects present + cloud-only
$sandbox = @{
    'Grp-EntraFund-LabTeam-Pilot'    = { Get-GroupByName 'Grp-EntraFund-LabTeam-Pilot' }
    'Grp-EntraFund-DynamicDept-Pilot'= { Get-GroupByName 'Grp-EntraFund-DynamicDept-Pilot' }
    'App-EntraFund-LabApp-Pilot'     = { Get-AppByName  'App-EntraFund-LabApp-Pilot' }
}
foreach ($k in $sandbox.Keys) {
    if (& $sandbox[$k]) { Add-Gate "G3 sandbox $k" 'PASS' 'present' }
    else { Add-Gate "G3 sandbox $k" 'FAIL' 'create with EKIDFUND-LabSetup.ps1 -WhatIf:$false (or in the labs)' }
}
$u = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users?`$filter=startswith(displayName,'Lab-EntraFund')&`$select=userPrincipalName,onPremisesSyncEnabled").value | Select-Object -First 1
if ($u) {
    if ($u.onPremisesSyncEnabled) { Add-Gate 'G3 sandbox user cloud-only' 'FAIL' 'test user is SYNCED — use a cloud-only user (R3)' }
    else { Add-Gate 'G3 sandbox user cloud-only' 'PASS' ("{0} is cloud-only" -f $u.userPrincipalName) }
} else { Add-Gate 'G3 sandbox user' 'FAIL' 'no Lab-EntraFund-* user found — create it (Lab 2 / LabSetup)' }

# Licensing (context for Gate 5)
$plans = ((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value).servicePlans.servicePlanName
$hasP1 = $plans -contains 'AAD_PREMIUM'
Add-Gate 'Licensing P1 (for CA lab)' $(if($hasP1){'PASS'}else{'MANUAL'}) $(if($hasP1){'Entra ID P1 present'}else{'no P1 — Lab 6 is a read-only CA tour; mark the policy build N/A (R5)'})

# Gate 5/6 — CA lab policy report-only + break-glass excluded
try {
    $ca = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
    $lab = $ca | Where-Object { $_.displayName -eq 'CAFund-RequireMFA-LabTeam-ReportOnly' } | Select-Object -First 1
    if (-not $lab) {
        Add-Gate 'G5 CA lab policy' $(if($hasP1){'FAIL'}else{'MANUAL'}) 'CAFund-RequireMFA-LabTeam-ReportOnly not found (build it in Lab 6, or N/A if no P1)'
    } else {
        if ($lab.state -eq 'enabledForReportingButNotEnforced') { Add-Gate 'G5 CA lab report-only' 'PASS' 'policy state = report-only' }
        else { Add-Gate 'G5 CA lab report-only' 'FAIL' ("policy state = {0} — set it back to Report-only (it must never enforce)" -f $lab.state) }
        # break-glass exclusion
        $exclU = @($lab.conditions.users.excludeUsers); $exclG = @($lab.conditions.users.excludeGroups)
        if ($BreakGlassUpn) {
            $missing = @()
            foreach ($bg in $BreakGlassUpn) {
                $bgObj = Get-UserByUpn $bg
                if (-not $bgObj -or ($exclU -notcontains $bgObj.id -and -not ($exclG | ForEach-Object { $_ }))) { $missing += $bg }
            }
            if ($missing.Count -eq 0) { Add-Gate 'G6 break-glass excluded' 'PASS' 'break-glass excluded (directly or via group)' }
            else { Add-Gate 'G6 break-glass excluded' 'FAIL' ("not excluded: {0} — add to Users->Exclude (R4/G4)" -f ($missing -join ', ')) }
        } else {
            if (($exclU.Count + $exclG.Count) -gt 0) { Add-Gate 'G6 break-glass excluded' 'MANUAL' ("policy has {0} user + {1} group exclusion(s) — confirm they are your break-glass accounts" -f $exclU.Count, $exclG.Count) }
            else { Add-Gate 'G6 break-glass excluded' 'FAIL' 'policy has NO exclusions — add break-glass (R4/G4)' }
        }
    }
} catch { Add-Gate 'G5 CA lab policy' 'MANUAL' 'could not read CA policies (needs P1 + Policy.Read.All) — verify in the portal' }

# --- Knowledge-check answer key (instructor scores each learner) ---
Write-Host ''
Write-Host '=== Knowledge-check (Check-EntraFund-Pilot) — concept answer key ===' -ForegroundColor Cyan
@(
  'Q1 Tenant .............. an isolated Entra directory instance; has a tenant ID + initial/custom domains.'
  'Q2 User vs guest vs SP . member = staff; guest = external B2B (#EXT#); service principal = app/automation.'
  'Q3 Security vs M365 grp  security = access/policy targeting; M365 = also backs a mailbox/Team.'
  'Q4 Assigned vs dynamic . assigned = you add members; dynamic = a rule (e.g. department eq "Sales") adds them.'
  'Q5 Least privilege ..... use narrow roles (Helpdesk/User Admin/Security Reader); keep Global Admin tiny.'
  'Q6 Reg vs enterprise app registration = the app DEFINITION; enterprise app = the INSTANCE users sign in to.'
  'Q7 Sign-in flow ........ authenticate -> Conditional Access evaluates -> token issued.'
  'Q8 Report-only ......... a CA policy is evaluated + logged but NOT enforced (the safe way to learn CA).'
  'Q9 Break-glass ......... 2 cloud-only emergency accounts, EXCLUDED from CA policies.'
  'Q10 Licensing .......... CA needs P1; risk policies + PIM need P2; verify your tenant.'
) | ForEach-Object { Write-Host ("  {0}" -f $_) }
Add-Gate 'G7 knowledge-check' 'MANUAL' 'instructor scores each learner against the key above; threshold is your call'

Write-Host ''
Write-Host '=== Validation summary ===' -ForegroundColor Cyan
$results | Format-Table -AutoSize
$fail = @($results | Where-Object Status -eq 'FAIL').Count
if ($fail -eq 0) { Write-Host 'No hard FAILs — resolve any MANUAL checks, then the cohort is grounded.' -ForegroundColor Green }
else { Write-Host ("{0} FAIL gate(s) — reinforce the mapped lab and re-run." -f $fail) -ForegroundColor Red }
Disconnect-MgGraph | Out-Null

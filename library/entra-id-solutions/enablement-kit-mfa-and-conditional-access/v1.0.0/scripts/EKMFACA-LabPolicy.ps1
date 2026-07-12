<#
.SYNOPSIS
    EKMFACA-LabPolicy.ps1 — create the REPORT-ONLY CA lab policies (persona-scoped, break-glass excluded).
.DESCRIPTION
    PURPOSE
        Creates the lab persona/exclusion groups if absent, then the three report-only Conditional
        Access lab policies used by the kit:
            CALab001 Require MFA - Internals - ReportOnly
            CALab002 Require Phishing-Resistant MFA - Admins - ReportOnly
            CALab003 Block Legacy Authentication - AllUsers - ReportOnly
        EVERY policy is created in REPORT-ONLY (enabledForReportingButNotEnforced) and excludes the
        break-glass group Grp-MfaCa-Excl-BreakGlass — so nothing can ever be blocked. This script can
        NEVER create an enforced policy. Enforcing a real baseline is the ENTZTCA / Conditional Access
        Integration solutions, not this kit. Defaults to -WhatIf (preview); a plain run changes
        nothing. -Remove tears the lab policies down (preview by default too).
    HOW TO RUN
        Preview (default, no changes):
            pwsh -File .\EKMFACA-LabPolicy.ps1
        Create the report-only lab (after review):
            pwsh -File .\EKMFACA-LabPolicy.ps1 -WhatIf:$false
        Tear the lab policies down (preview, then apply):
            pwsh -File .\EKMFACA-LabPolicy.ps1 -Remove
            pwsh -File .\EKMFACA-LabPolicy.ps1 -Remove -WhatIf:$false
        Consents to Policy.ReadWrite.ConditionalAccess, Group.ReadWrite.All, Policy.Read.All,
        Directory.Read.All. Government cloud: -Environment USGov.
    EXPECTED RESULTS
        In preview: the groups/policies that WOULD be created (all report-only). When applied: the
        three report-only policies exist, persona-scoped, break-glass excluded. Fully reversible.
.NOTES
    White-label — Entra ID Solutions. Write action — preview (-WhatIf) by default. Creates REPORT-ONLY
    policies ONLY; never enforces. No credentials in code.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch]$Remove,
    [ValidateSet('Global','USGov','USGovDoD')][string]$Environment = 'Global'
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Policy.ReadWrite.ConditionalAccess','Group.ReadWrite.All','Policy.Read.All','Directory.Read.All' -Environment $Environment -NoWelcome

$RO = 'enabledForReportingButNotEnforced'
$policyNames = @(
    'CALab001 Require MFA - Internals - ReportOnly',
    'CALab002 Require Phishing-Resistant MFA - Admins - ReportOnly',
    'CALab003 Block Legacy Authentication - AllUsers - ReportOnly'
)

function Get-GroupByName($n){ (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$n'").value | Select-Object -First 1 }
function Ensure-Group($n,$nick){
    $g = Get-GroupByName $n
    if ($g) { Write-Host ("  group exists: {0}" -f $n) -ForegroundColor DarkGray; return $g.id }
    if ($PSCmdlet.ShouldProcess($n,'Create security group')) {
        $b = @{ displayName=$n; mailEnabled=$false; mailNickname=$nick; securityEnabled=$true }
        $r = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($b|ConvertTo-Json)
        Write-Host ("  CREATED group: {0}" -f $n) -ForegroundColor Green; return $r.id
    } else { Write-Host ("  [WhatIf] would create group: {0}" -f $n) -ForegroundColor Yellow; return $null }
}

$existing = @()
try { $existing = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value } catch {}

if ($Remove) {
    Write-Host "`n=== Remove MFA/CA report-only lab policies — $(Get-Date -Format s) ===" -ForegroundColor Cyan
    foreach ($name in $policyNames) {
        $p = $existing | Where-Object { $_.displayName -eq $name } | Select-Object -First 1
        if (-not $p) { Write-Host ("  not present: {0}" -f $name) -ForegroundColor DarkGray; continue }
        if ($PSCmdlet.ShouldProcess($name,'Delete report-only CA policy')) {
            Invoke-MgGraphRequest -Method DELETE -Uri ("/v1.0/identity/conditionalAccess/policies/{0}" -f $p.id) | Out-Null
            Write-Host ("  REMOVED: {0}" -f $name) -ForegroundColor Green
        } else { Write-Host ("  [WhatIf] would remove: {0}" -f $name) -ForegroundColor Yellow }
    }
    Write-Host "  (Persona/exclusion groups left in place — delete them by hand if the kit was one-off.)" -ForegroundColor DarkGray
    Disconnect-MgGraph | Out-Null; return
}

Write-Host "`n=== Create MFA/CA report-only lab policies — $(Get-Date -Format s) ===" -ForegroundColor Cyan

# P1 check
$plans = ((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value).servicePlans.servicePlanName
if ($plans -notcontains 'AAD_PREMIUM') { Write-Host "  NOTE: no Entra ID P1 detected — Conditional Access needs P1. Run Labs 2-6 as a read-only tour instead. Verify licensing." -ForegroundColor Yellow }

# Ensure groups
$gExcl      = Ensure-Group 'Grp-MfaCa-Excl-BreakGlass'        'grpMfaCaExclBG'
$gAdmins    = Ensure-Group 'Grp-MfaCa-Persona-Admins-Pilot'    'grpMfaCaAdmins'
$gInternals = Ensure-Group 'Grp-MfaCa-Persona-Internals-Pilot' 'grpMfaCaInternals'
$null       = Ensure-Group 'Grp-MfaCa-Persona-Guests-Pilot'    'grpMfaCaGuests'
Write-Host "  REMINDER: add your two break-glass accounts to Grp-MfaCa-Excl-BreakGlass (R4/G4)." -ForegroundColor Yellow

if (-not ($gExcl -and $gAdmins -and $gInternals)) {
    if ($WhatIfPreference) { Write-Host "`n[WhatIf] groups would be created above; re-run with -WhatIf:`$false to create groups + policies." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }
    Write-Host "Could not resolve required groups. Aborting policy creation." -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return
}

# Report-only policy definitions
$defs = @(
    @{ Name=$policyNames[0]; Include=@($gInternals); Grant=@{ operator='OR'; builtInControls=@('mfa') } },
    @{ Name=$policyNames[1]; Include=@($gAdmins);    Strength=$true },
    @{ Name=$policyNames[2]; IncludeAll=$true;       Grant=@{ operator='OR'; builtInControls=@('block') }; Legacy=$true }
)

foreach ($d in $defs) {
    if ($existing | Where-Object { $_.displayName -eq $d.Name }) { Write-Host ("  exists: {0}" -f $d.Name) -ForegroundColor DarkGray; continue }

    $users = @{ excludeGroups = @($gExcl) }
    if ($d.IncludeAll) { $users.includeUsers = @('All') } else { $users.includeGroups = $d.Include }

    $conditions = @{ users=$users; applications=@{ includeApplications=@('All') }; clientAppTypes=@('all') }
    if ($d.Legacy) { $conditions.clientAppTypes = @('exchangeActiveSync','other') }

    $grant = $null
    if ($d.Strength) { $grant = @{ operator='OR'; authenticationStrength=@{ id='00000000-0000-0000-0000-000000000004' } } }  # built-in phishing-resistant strength — VERIFY id in your tenant
    elseif ($d.Grant) { $grant = @{ operator=$d.Grant.operator; builtInControls=$d.Grant.builtInControls } }

    $policy = @{ displayName=$d.Name; state=$RO; conditions=$conditions; grantControls=$grant }

    if ($PSCmdlet.ShouldProcess($d.Name,'Create REPORT-ONLY CA policy')) {
        try {
            Invoke-MgGraphRequest -Method POST -Uri '/v1.0/identity/conditionalAccess/policies' -Body ($policy | ConvertTo-Json -Depth 8) | Out-Null
            Write-Host ("  CREATED (report-only): {0}" -f $d.Name) -ForegroundColor Green
        } catch { Write-Host ("  ERROR creating {0}: {1}" -f $d.Name, $_.Exception.Message) -ForegroundColor Red }
    } else { Write-Host ("  [WhatIf] would create (report-only): {0}" -f $d.Name) -ForegroundColor Yellow }
}

Write-Host "`nAll lab policies are REPORT-ONLY and exclude break-glass. Validate with What-If + EKMFACA-Report.ps1." -ForegroundColor Cyan
Write-Host "NOTE: verify the phishing-resistant authentication-strength id (CALab002) against your tenant before relying on it." -ForegroundColor DarkGray
Write-Host "This kit NEVER enforces. Enforcing a real baseline is the ENTZTCA / Conditional Access Integration solutions." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null

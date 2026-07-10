<#
.SYNOPSIS
    ENTZTCA-Set-Baseline.ps1 — create the numbered CA baseline in REPORT-ONLY with break-glass excluded.
.DESCRIPTION
    PURPOSE
        Creates the Zero Trust Conditional Access baseline policies (CA001-CA008) already scoped to the
        persona groups and with the break-glass exclusion group applied — every policy is created in
        REPORT-ONLY state (enabledForReportingButNotEnforced), never straight into enforcement.
        Defaults to -WhatIf, so a plain run only PREVIEWS the policies it would create and changes
        nothing. Enforcement is a deliberate, separate portal step done wave by wave after validation.
        Policies requiring Entra ID P2 (CA004 sign-in risk, CA005 user risk) are skipped automatically
        if the tenant is not P2, and CA003 device controls are noted as dependent on Intune/hybrid join.
    HOW TO RUN
        Preview (default, no changes):
            powershell -ExecutionPolicy Bypass -File .\ENTZTCA-Set-Baseline.ps1
        Apply after review (still report-only, not enforced):
            powershell -ExecutionPolicy Bypass -File .\ENTZTCA-Set-Baseline.ps1 -WhatIf:$false
        Consents to Policy.ReadWrite.ConditionalAccess, Policy.Read.All, Group.Read.All, Directory.Read.All.
    EXPECTED RESULTS
        In preview: the baseline policies that WOULD be created (all report-only). When applied: the
        policies exist in report-only with persona scope and break-glass excluded. Reversible — delete
        or leave in report-only; nothing is enforced by this script.
.NOTES
    White-label — Entra ID Solutions. Write action — preview (-WhatIf) by default. Creates report-only ONLY.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch]$IncludeRiskPolicies   # force-include CA004/CA005 even if P2 not auto-detected
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Policy.ReadWrite.ConditionalAccess','Policy.Read.All','Group.Read.All','Directory.Read.All' -NoWelcome

Write-Host "`n=== Create CA Baseline (report-only) — $(Get-Date -Format s) ===" -ForegroundColor Cyan

# Resolve required groups by name
function Get-GroupId($name) {
    $g = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$name'").value | Select-Object -First 1
    if (-not $g) { Write-Host ("  MISSING group '{0}' — run ENTZTCA-Set-ScopeTargeting.ps1 first." -f $name) -ForegroundColor Red }
    return $g.id
}
$gExcl      = Get-GroupId 'CA Exclusion - Break-Glass - Steady'
$gAdmins    = Get-GroupId 'CA Persona - Admins - Steady'
$gInternals = Get-GroupId 'CA Persona - Internals - Steady'
$gGuests    = Get-GroupId 'CA Persona - Externals-Guests - Steady'
if (-not ($gExcl -and $gAdmins -and $gInternals -and $gGuests)) {
    Write-Host "Create the persona/exclusion groups first (ENTZTCA-Set-ScopeTargeting.ps1). Aborting." -ForegroundColor Red
    Disconnect-MgGraph | Out-Null; return
}

# P2 detection
$plans = ((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value).servicePlans.servicePlanName
$hasP2 = ($plans -contains 'AAD_PREMIUM_P2') -or $IncludeRiskPolicies
Write-Host ("Entra ID P2 risk policies: {0}" -f ($(if($hasP2){'included'}else{'SKIPPED (no P2 detected)'}))) -ForegroundColor $(if($hasP2){'Green'}else{'Yellow'})

$RO = 'enabledForReportingButNotEnforced'
$excludeBlock = @{ excludeGroups = @($gExcl) }

# Baseline definitions
$defs = @(
    @{ Name='CA001 Require MFA - Internals - Report-Only'; Include=@($gInternals); Grant=@{ operator='OR'; builtInControls=@('mfa') } },
    @{ Name='CA002 Require Phishing-Resistant MFA - Admins - Report-Only'; Include=@($gAdmins); GrantStrength=$true },
    @{ Name='CA003 Require Compliant or Hybrid Device - Internals - Report-Only'; Include=@($gInternals); Grant=@{ operator='OR'; builtInControls=@('compliantDevice','domainJoinedDevice') }; Note='requires Intune compliance or hybrid join' },
    @{ Name='CA004 Sign-in Risk MFA - Internals - Report-Only'; Include=@($gInternals); Grant=@{ operator='OR'; builtInControls=@('mfa') }; SignInRisk=@('medium','high'); P2=$true },
    @{ Name='CA005 User Risk Password Change - Internals - Report-Only'; Include=@($gInternals); Grant=@{ operator='AND'; builtInControls=@('mfa','passwordChange') }; UserRisk=@('high'); P2=$true },
    @{ Name='CA006 App-Enforced Restrictions - Externals-Guests - Report-Only'; Include=@($gGuests); SessionAppEnforced=$true },
    @{ Name='CA007 Block Legacy Authentication - All Users - Report-Only'; IncludeAll=$true; Grant=@{ operator='OR'; builtInControls=@('block') }; LegacyClients=$true },
    @{ Name='CA008 Sign-in Frequency + No Persistent Browser - Admins - Report-Only'; Include=@($gAdmins); SessionAdmin=$true }
)

$existing = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value

foreach ($d in $defs) {
    if ($d.P2 -and -not $hasP2) { Write-Host ("  SKIP (needs P2): {0}" -f $d.Name) -ForegroundColor Yellow; continue }
    if ($existing | Where-Object { $_.displayName -eq $d.Name }) { Write-Host ("  exists: {0}" -f $d.Name) -ForegroundColor DarkGray; continue }

    # Build users condition
    $users = @{ excludeGroups = @($gExcl) }
    if ($d.IncludeAll) { $users.includeUsers = @('All') } else { $users.includeGroups = $d.Include }

    $conditions = @{
        users        = $users
        applications = @{ includeApplications = @('All') }
        clientAppTypes = @('all')
    }
    if ($d.LegacyClients) { $conditions.clientAppTypes = @('exchangeActiveSync','other') }
    if ($d.SignInRisk)    { $conditions.signInRiskLevels = $d.SignInRisk }
    if ($d.UserRisk)      { $conditions.userRiskLevels   = $d.UserRisk }

    $grantControls = $null
    if ($d.GrantStrength) {
        # phishing-resistant built-in authentication strength id (Microsoft built-in)
        $grantControls = @{ operator='OR'; authenticationStrength = @{ id='00000000-0000-0000-0000-000000000004' } }
    } elseif ($d.Grant) {
        $grantControls = @{ operator=$d.Grant.operator; builtInControls=$d.Grant.builtInControls }
    }

    $sessionControls = $null
    if ($d.SessionAppEnforced) { $sessionControls = @{ applicationEnforcedRestrictions = @{ isEnabled=$true } } }
    if ($d.SessionAdmin) {
        $sessionControls = @{
            signInFrequency        = @{ isEnabled=$true; type='hours'; value=4; authenticationType='primaryAndSecondaryAuthentication' }
            persistentBrowser      = @{ isEnabled=$true; mode='never' }
        }
    }

    $policy = @{ displayName=$d.Name; state=$RO; conditions=$conditions }
    if ($grantControls)   { $policy.grantControls   = $grantControls }
    if ($sessionControls) { $policy.sessionControls = $sessionControls }

    $note = if ($d.Note) { " ($($d.Note))" } else { '' }
    if ($PSCmdlet.ShouldProcess($d.Name, 'Create report-only CA policy')) {
        try {
            Invoke-MgGraphRequest -Method POST -Uri '/v1.0/identity/conditionalAccess/policies' -Body ($policy | ConvertTo-Json -Depth 8) | Out-Null
            Write-Host ("  CREATED (report-only): {0}{1}" -f $d.Name, $note) -ForegroundColor Green
        } catch {
            Write-Host ("  ERROR creating {0}: {1}" -f $d.Name, $_.Exception.Message) -ForegroundColor Red
        }
    } else {
        Write-Host ("  [WhatIf] would create (report-only): {0}{1}" -f $d.Name, $note) -ForegroundColor Yellow
    }
}

Write-Host "`nAll policies are REPORT-ONLY. Validate with ENTZTCA-Report.ps1 + What-If, then enforce wave by wave in the portal." -ForegroundColor Cyan
Write-Host "NOTE: verify the phishing-resistant authentication-strength id and CA003 device dependency in your tenant before enforcing." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null

<#
.SYNOPSIS
    PHIDLP-Config.ps1 — PHI DLP policy configuration helper that creates/updates a policy in SIMULATION mode (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Creates a new DLP compliance policy (and a matching content rule for one or more HIPAA-relevant
        sensitive information types) in SIMULATION mode, or updates an existing policy's rule, across the
        chosen locations (Exchange / SharePoint / OneDrive / Teams / Endpoint). Safe by default: with
        -WhatIf it only reports the intended change; it applies nothing unless -Commit is passed, and it
        NEVER creates or leaves a policy in enforce (Enable) mode — simulation only. Enforcement (and the
        encrypt/block action decision for PHI) is a deliberate, separate portal/change-control step.
        Optionally set -RequireAllTypes to require CO-OCCURRENCE of the supplied SITs (e.g. an identifier
        AND a clinical detector), which is the single biggest PHI false-positive reducer.
    HOW TO RUN
        # Preview a PHI email simulation policy requiring SSN + an ICD code together:
        powershell -File .\PHIDLP-Config.ps1 -PolicyName 'DLP - PHI Email - Simulation' `
            -Locations Exchange `
            -SensitiveTypes 'U.S. Social Security Number (SSN)','International Classification of Diseases (ICD-10-CM)' `
            -RequireAllTypes -MinCount 1 -Confidence Medium -WhatIf
        # Actually create it (still simulation mode):
        powershell -File .\PHIDLP-Config.ps1 -PolicyName 'DLP - PHI Email - Simulation' `
            -Locations Exchange `
            -SensitiveTypes 'U.S. Social Security Number (SSN)','International Classification of Diseases (ICD-10-CM)' `
            -RequireAllTypes -MinCount 1 -Confidence Medium -Commit
        Requires Security & Compliance PowerShell (Connect-IPPSSession).
    EXPECTED RESULTS
        -WhatIf: prints the New-DlpCompliancePolicy / New-DlpComplianceRule calls it WOULD run, with
        Mode=TestWithNotifications. -Commit: creates the policy in simulation and the rule, then prints
        the resulting Mode (a Test* value = PASS). Verify with PHIDLP-Validate.ps1 / PHIDLP-Discovery.ps1.
.NOTES
    Purview — HIPAA / PHI DLP Pack. Writes gated behind -Commit; simulation-only (never Enable). No credentials in code.
    Which data is PHI and the enforced action per category are compliance/privacy/legal determinations — deferred.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PolicyName,
    [ValidateSet('Exchange','SharePoint','OneDrive','Teams','Endpoint')]
    [string[]]$Locations = @('Exchange'),
    # Default set = HIPAA-relevant built-in SITs. Verify these names exist in your tenant (SIT library evolves).
    [string[]]$SensitiveTypes = @('U.S. Social Security Number (SSN)','International Classification of Diseases (ICD-10-CM)'),
    # Require ALL supplied SITs to co-occur (PHI = identifier + clinical detector). Off = ANY-of (a match on one).
    [switch]$RequireAllTypes,
    [int]$MinCount = 1,
    [ValidateSet('Low','Medium','High')][string]$Confidence = 'Medium',
    # Simulation flavour: with or without showing policy tips to users during the test.
    [ValidateSet('TestWithNotifications','TestWithoutNotifications')][string]$SimulationMode = 'TestWithNotifications',
    [string]$UserPrincipalName,
    [switch]$Commit
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

# Map confidence name -> minimum confidence level used by the content rule.
$confMap = @{ Low = 65; Medium = 75; High = 85 }
$minConfidence = $confMap[$Confidence]

# Build the location parameter splat (all scoped to "All" here; narrow with PHIDLP-ScopeHealth.ps1).
$locParams = @{}
foreach ($l in $Locations) {
    switch ($l) {
        'Exchange'   { $locParams['ExchangeLocation']   = 'All' }
        'SharePoint' { $locParams['SharePointLocation'] = 'All' }
        'OneDrive'   { $locParams['OneDriveLocation']   = 'All' }
        'Teams'      { $locParams['TeamsLocation']      = 'All' }
        'Endpoint'   { $locParams['EndpointDlpLocation']= 'All' }  # requires onboarded devices + licensing
    }
}

# Build the sensitive-information-type condition.
# ANY-of: a single group listing all SITs -> match on any one.
# ALL-of (co-occurrence): a separate group per SIT -> the rule requires each group to match.
$sitGroups = foreach ($t in $SensitiveTypes) {
    @{ Name = $t; minCount = $MinCount; minconfidence = $minConfidence }
}
if ($RequireAllTypes -and $SensitiveTypes.Count -gt 1) {
    # One condition entry per SIT; New-DlpComplianceRule AND-combines multiple -ContentContainsSensitiveInformation groups.
    $ruleContent = @( ,@($sitGroups[0]) )
    for ($i = 1; $i -lt $sitGroups.Count; $i++) { $ruleContent += ,@($sitGroups[$i]) }
} else {
    $ruleContent = @($sitGroups)   # single group = ANY-of
}

$coText = if ($RequireAllTypes -and $SensitiveTypes.Count -gt 1) { 'CO-OCCURRENCE (all required)' } else { 'ANY-of' }
Write-Host ("=== PHI DLP policy '{0}' — SIMULATION ({1}) ===" -f $PolicyName, $SimulationMode) -ForegroundColor Cyan
Write-Host ("Locations : {0}" -f ($Locations -join ', '))
Write-Host ("SITs      : {0}" -f ($SensitiveTypes -join ', '))
Write-Host ("Matching  : {0}  (minCount={1}, minConfidence={2})" -f $coText, $MinCount, $minConfidence)

$existing = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue

if (-not $Commit) {
    Write-Host '-- WhatIf: no changes made. Would run: --' -ForegroundColor Yellow
    if ($existing) {
        Write-Host ("Set-DlpComplianceRule for policy '{0}' (already exists, Mode={1})" -f $PolicyName, $existing.Mode)
    } else {
        Write-Host ("New-DlpCompliancePolicy -Name '{0}' -Mode {1} {2}" -f $PolicyName, $SimulationMode, (($locParams.GetEnumerator() | ForEach-Object { "-$($_.Key) $($_.Value)" }) -join ' '))
        Write-Host ("New-DlpComplianceRule -Name '{0} - Rule' -Policy '{0}' -ContentContainsSensitiveInformation <{1}: {2}>" -f $PolicyName, $coText, ($SensitiveTypes -join '; '))
    }
    Write-Host 'Re-run with -Commit to apply (policy will be created in SIMULATION, never enforce).' -ForegroundColor Yellow
    return
}

# --- Commit path (simulation only) ---
if (-not $existing) {
    New-DlpCompliancePolicy -Name $PolicyName -Mode $SimulationMode @locParams -ErrorAction Stop | Out-Null
    Write-Host ("Created policy '{0}' in {1}." -f $PolicyName, $SimulationMode) -ForegroundColor Green
} else {
    if ($existing.Mode -eq 'Enable') {
        Write-Host ("SAFETY: policy '{0}' is currently ENFORCING; this helper will not modify an enforcing policy. Adjust in the portal under change control." -f $PolicyName) -ForegroundColor Red
        return
    }
    Set-DlpCompliancePolicy -Identity $PolicyName -Mode $SimulationMode @locParams -ErrorAction Stop
    Write-Host ("Updated policy '{0}' (kept in {1})." -f $PolicyName, $SimulationMode) -ForegroundColor Green
}

$ruleName = "$PolicyName - Rule"
if (-not (Get-DlpComplianceRule -Identity $ruleName -ErrorAction SilentlyContinue)) {
    New-DlpComplianceRule -Name $ruleName -Policy $PolicyName `
        -ContentContainsSensitiveInformation $ruleContent -ErrorAction Stop | Out-Null
    Write-Host ("Created rule '{0}'." -f $ruleName) -ForegroundColor Green
} else {
    Set-DlpComplianceRule -Identity $ruleName -ContentContainsSensitiveInformation $ruleContent -ErrorAction Stop
    Write-Host ("Updated rule '{0}'." -f $ruleName) -ForegroundColor Green
}

$after = Get-DlpCompliancePolicy -Identity $PolicyName
if ($after.Mode -like 'Test*') {
    Write-Host ("PASS: '{0}' is in SIMULATION (Mode={1}). Let it dwell, then measure with PHIDLP-Report.ps1." -f $PolicyName, $after.Mode) -ForegroundColor Green
} else {
    Write-Host ("WARNING: unexpected Mode '{0}' — verify in the portal." -f $after.Mode) -ForegroundColor Yellow
}

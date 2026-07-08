<#
.SYNOPSIS
    DLPCMMC-Config.ps1 — CUI DLP policy helper that creates/updates a policy keyed on the CUI label + marking SIT in SIMULATION (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Creates a new DLP compliance policy (and a matching content rule) that detects CUI by the "CUI"
        SENSITIVITY LABEL (primary signal) and, optionally, a CUI marking keyword sensitive-information-type
        (backstop), across the chosen locations (Exchange / SharePoint / OneDrive / Teams / Endpoint), in
        SIMULATION mode. Safe by default: with -WhatIf it only reports the intended change; it applies
        nothing unless -Commit is passed, and it NEVER creates or leaves a policy in enforce (Enable) mode —
        simulation only. Enforcement is a deliberate, separate portal/change-control step.
    HOW TO RUN
        # Preview a CUI email simulation policy (label + marking backstop, external recipients):
        powershell -File .\DLPCMMC-Config.ps1 -PolicyName 'DLP - CUI Email - Simulation' `
            -Locations Exchange -SensitivityLabel 'CUI' `
            -MarkingSit 'CUI Banner Marking - Custom SIT - Classification' -WhatIf
        # Actually create it (still simulation mode):
        powershell -File .\DLPCMMC-Config.ps1 -PolicyName 'DLP - CUI Email - Simulation' `
            -Locations Exchange -SensitivityLabel 'CUI' `
            -MarkingSit 'CUI Banner Marking - Custom SIT - Classification' -Commit
        Requires Security & Compliance PowerShell (Connect-IPPSSession). Verify label-based DLP + Endpoint
        availability for your licensing/tenant (GCC High differs).
    EXPECTED RESULTS
        -WhatIf: prints the New-DlpCompliancePolicy / New-DlpComplianceRule calls it WOULD run, with
        Mode=TestWithNotifications and the label/marking condition. -Commit: creates the policy in
        simulation and the rule, then prints the resulting Mode (a Test* value = PASS). Verify with
        DLPCMMC-Discovery.ps1 / DLPCMMC-Validate.ps1.
.NOTES
    Purview — CMMC / CUI DLP Pack. Writes gated behind -Commit; simulation-only (never Enable). No credentials in code.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PolicyName,
    [ValidateSet('Exchange','SharePoint','OneDrive','Teams','Endpoint')]
    [string[]]$Locations = @('Exchange'),
    # Primary signal: the CUI sensitivity label (leave blank only if using the marking SIT alone).
    [string]$SensitivityLabel = 'CUI',
    # Backstop signal: the CUI marking keyword SIT (optional but recommended).
    [string]$MarkingSit,
    [int]$MinCount = 1,
    [ValidateSet('Low','Medium','High')][string]$Confidence = 'High',
    # Simulation flavour: with or without showing policy tips to users during the test.
    [ValidateSet('TestWithNotifications','TestWithoutNotifications')][string]$SimulationMode = 'TestWithNotifications',
    [string]$UserPrincipalName,
    [switch]$Commit
)

if (-not $SensitivityLabel -and -not $MarkingSit) {
    throw 'Provide at least one detection signal: -SensitivityLabel (recommended) and/or -MarkingSit.'
}

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

# Map confidence name -> minimum confidence level used by the marking-SIT condition.
$confMap = @{ Low = 65; Medium = 75; High = 85 }
$minConfidence = $confMap[$Confidence]

# Build the location parameter splat (scoped to "All" here; narrow to the CUI enclave with DLPCMMC-Set-Scope.ps1).
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

Write-Host ("=== CUI DLP policy '{0}' — SIMULATION ({1}) ===" -f $PolicyName, $SimulationMode) -ForegroundColor Cyan
Write-Host ("Locations : {0}" -f ($Locations -join ', '))
if ($SensitivityLabel) { Write-Host ("Label     : {0} (primary signal)" -f $SensitivityLabel) }
if ($MarkingSit)       { Write-Host ("MarkingSIT: {0} (backstop, minCount={1}, minConfidence={2})" -f $MarkingSit, $MinCount, $minConfidence) }

# Resolve the sensitivity label GUID for the rule condition, if a label is used.
$labelGuid = $null
if ($SensitivityLabel -and (Get-Command Get-Label -ErrorAction SilentlyContinue)) {
    $lbl = Get-Label -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq $SensitivityLabel -or $_.Name -eq $SensitivityLabel } | Select-Object -First 1
    if ($lbl) { $labelGuid = $lbl.Guid } else {
        Write-Host ("WARNING: sensitivity label '{0}' not found — confirm it is published (Req 2.1) before committing." -f $SensitivityLabel) -ForegroundColor Yellow
    }
}

# Build the marking-SIT condition (backstop), if supplied.
$sitConditions = $null
if ($MarkingSit) {
    $sitConditions = @( @{ Name = $MarkingSit; minCount = $MinCount; minconfidence = $minConfidence } )
}

$existing = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue

if (-not $Commit) {
    Write-Host '-- WhatIf: no changes made. Would run: --' -ForegroundColor Yellow
    if ($existing) {
        Write-Host ("Set-DlpComplianceRule for policy '{0}' (already exists, Mode={1})" -f $PolicyName, $existing.Mode)
    } else {
        Write-Host ("New-DlpCompliancePolicy -Name '{0}' -Mode {1} {2}" -f $PolicyName, $SimulationMode, (($locParams.GetEnumerator() | ForEach-Object { "-$($_.Key) $($_.Value)" }) -join ' '))
        $cond = @()
        if ($labelGuid)     { $cond += ("ContentContainsSensitivityLabel={0}" -f $SensitivityLabel) }
        if ($sitConditions) { $cond += ("ContentContainsSensitiveInformation<{0}>" -f $MarkingSit) }
        Write-Host ("New-DlpComplianceRule -Name '{0} - Rule' -Policy '{0}' -{1}" -f $PolicyName, ($cond -join ' -OR- '))
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

# Assemble the rule parameters: label condition (primary) and/or marking-SIT condition (backstop).
$ruleName = "$PolicyName - Rule"
$ruleParams = @{ Name = $ruleName; Policy = $PolicyName }
if ($labelGuid)     { $ruleParams['ContentContainsSensitivityLabel'] = @(@{ labels = @(@{ name = $SensitivityLabel; id = $labelGuid }) }) }
if ($sitConditions) { $ruleParams['ContentContainsSensitiveInformation'] = $sitConditions }

if (-not (Get-DlpComplianceRule -Identity $ruleName -ErrorAction SilentlyContinue)) {
    New-DlpComplianceRule @ruleParams -ErrorAction Stop | Out-Null
    Write-Host ("Created rule '{0}'." -f $ruleName) -ForegroundColor Green
} else {
    $setParams = @{ Identity = $ruleName }
    if ($ruleParams.ContainsKey('ContentContainsSensitivityLabel'))      { $setParams['ContentContainsSensitivityLabel'] = $ruleParams['ContentContainsSensitivityLabel'] }
    if ($ruleParams.ContainsKey('ContentContainsSensitiveInformation'))  { $setParams['ContentContainsSensitiveInformation'] = $ruleParams['ContentContainsSensitiveInformation'] }
    Set-DlpComplianceRule @setParams -ErrorAction Stop
    Write-Host ("Updated rule '{0}'." -f $ruleName) -ForegroundColor Green
}

$after = Get-DlpCompliancePolicy -Identity $PolicyName
if ($after.Mode -like 'Test*') {
    Write-Host ("PASS: '{0}' is in SIMULATION (Mode={1}). Let it dwell, then measure with DLPCMMC-Report.ps1." -f $PolicyName, $after.Mode) -ForegroundColor Green
} else {
    Write-Host ("WARNING: unexpected Mode '{0}' — verify in the portal." -f $after.Mode) -ForegroundColor Yellow
}

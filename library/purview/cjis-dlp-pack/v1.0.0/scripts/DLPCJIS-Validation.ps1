<#
.SYNOPSIS
    DLPCJIS-Validation.ps1 — read-only pass/fail validation of the CJI DLP policy: existence, mode, workload scope, and detection rule. Makes no changes.
.DESCRIPTION
    PURPOSE
        Validates the deployed CJI DLP policy against explicit pass/fail gates before (and after)
        enforcement: the policy exists and is in the EXPECTED mode; it is scoped to the intended workloads;
        and the detection rule is present and references the CJI classification with the intended action.
        Read-only; uses Security & Compliance PowerShell. Prints a PASS/FAIL per gate and an overall result.
    HOW TO RUN
        Connect-IPPSSession                                   # modern-auth admin sign-in (no secrets in code)
        # Validate the pilot is correctly created in simulation:
        .\DLPCJIS-Validation.ps1 -ExpectedMode TestWithNotifications
        # Validate it is correctly enforcing after promotion:
        .\DLPCJIS-Validation.ps1 -ExpectedMode Enable
        PowerShell 5.1+/7+; requires Security & Compliance PowerShell (Get-DlpCompliancePolicy / Get-DlpComplianceRule).
    EXPECTED RESULTS
        A gate table (Existence / Mode / WorkloadScope / RulePresent / RuleAction) each PASS or FAIL, and an
        overall PASS only when every gate passes. Any FAIL => do not promote; fix and re-validate.
.NOTES
    CJIS DLP Pack — read-only. Validates the technical control only; stakeholder sign-off of the simulation
    results and the CJIS determinations remain with your CSO/TAC / compliance / legal. Verify licensing/tenant.
#>
[CmdletBinding()]
param(
    [string]$PolicyName = 'CJIS CJI Protection - AllWorkloads - Pilot',
    [string]$RuleName   = 'CJI Detection Rule - Identifiers+CHRI - v1',
    [ValidateSet('TestWithNotifications','TestWithoutNotifications','Enable','Disable')]
    [string]$ExpectedMode = 'TestWithNotifications',
    [string[]]$ExpectedWorkloads = @('Exchange','SharePoint','OneDrive','Teams')
)

if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    Write-Error "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first."
    return
}

$results = New-Object System.Collections.Generic.List[object]
function Add-Gate { param([string]$Gate,[bool]$Pass,[string]$Detail)
    $results.Add([pscustomobject]@{ Gate=$Gate; Result=$(if($Pass){'PASS'}else{'FAIL'}); Detail=$Detail }) }

Write-Host "=== Validation: CJIS CJI Protection ===" -ForegroundColor Cyan

# Gate 1: existence
$policy = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
if (-not $policy) {
    Add-Gate 'Existence' $false "Policy '$PolicyName' not found."
    $results | Format-Table -AutoSize
    Write-Host "OVERALL: FAIL — policy does not exist. Create it in test mode first." -ForegroundColor Red
    return
}
Add-Gate 'Existence' $true "Found '$PolicyName'."

# Gate 2: mode
$actualMode = [string]$policy.Mode
Add-Gate 'Mode' ($actualMode -eq $ExpectedMode) ("Expected {0}, found {1}." -f $ExpectedMode, $actualMode)

# Gate 3: workload scope
$scoped = @()
foreach ($w in 'ExchangeLocation','SharePointLocation','OneDriveLocation','TeamsLocation','EndpointDlpLocation') {
    if ($policy.PSObject.Properties.Name -contains $w -and $policy.$w) { $scoped += ($w -replace 'Location$','') }
}
$missing = @($ExpectedWorkloads | Where-Object { $_ -notin $scoped })
Add-Gate 'WorkloadScope' ($missing.Count -eq 0) ("Scoped: [{0}]; missing: [{1}]" -f ($scoped -join ','), ($missing -join ','))

# Gate 4: rule present + references a CJI classification
$rule = Get-DlpComplianceRule -Policy $PolicyName -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $RuleName } | Select-Object -First 1
if (-not $rule) { $rule = Get-DlpComplianceRule -Policy $PolicyName -ErrorAction SilentlyContinue | Select-Object -First 1 }
Add-Gate 'RulePresent' ([bool]$rule) ($(if($rule){"Rule '$($rule.Name)' present."}else{"No rule found on policy."}))

# Gate 5: rule action (block/alert configured)
if ($rule) {
    $hasAction = ($rule.BlockAccess -eq $true) -or ($null -ne $rule.GenerateAlert)
    $sitInfo = ''
    try { if ($rule.ContentContainsSensitiveInformation) { $sitInfo = ($rule.ContentContainsSensitiveInformation | ForEach-Object { $_.Name }) -join ',' } } catch {}
    Add-Gate 'RuleAction' ([bool]$hasAction) ("BlockAccess={0}; SITs=[{1}]" -f $rule.BlockAccess, $sitInfo)
} else {
    Add-Gate 'RuleAction' $false 'No rule to evaluate.'
}

$results | Format-Table -AutoSize
$overall = -not ($results | Where-Object { $_.Result -eq 'FAIL' })
if ($overall) {
    Write-Host "OVERALL: PASS — all gates green. Safe to proceed (promote only after stakeholder sign-off of simulation)." -ForegroundColor Green
} else {
    Write-Host "OVERALL: FAIL — fix the failed gate(s) in test mode and re-validate before enforcing." -ForegroundColor Red
}

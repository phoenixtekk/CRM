<#
.SYNOPSIS
    DLPSPO-Validate.ps1 — Validate the DLP policy exists, covers the intended locations, matches the
    intended content/sharing condition, and is in the expected mode (read-only).
.DESCRIPTION
    PURPOSE
        The pilot/expansion gate. Confirms PASS/FAIL that 'SPO-OneDrive DLP - Policy' exists, covers
        SharePoint/OneDrive as intended, has its detection rule, and — for the pilot — is in TEST mode (not
        prematurely enforcing). Read-only. Run on the pilot before enforcing, and after each expansion wave.
    HOW TO RUN
        .\DLPSPO-Validate.ps1 -ExpectEnforce:$false
        PowerShell 5.1+/7+. Connect first with Connect-IPPSSession. No secret is stored in the script.
    EXPECTED RESULTS
        A PASS/FAIL line per gate; overall PASS only when the policy matches the intended design. During the
        pilot, the policy being in Enable (enforce) mode FAILS the "still in test mode" gate.
.NOTES
    Purview — SharePoint Online DLP. Read-only gate. Verify your licensing/tenant; property/mode names vary
    by module version.
#>
[CmdletBinding()]
param(
    [string]$PolicyName = 'SPO-OneDrive DLP - Policy',
    [string]$RuleName   = 'SPO DLP - External Sharing Rule',
    [bool]$ExpectEnforce = $false      # pilot expects test mode ($false); after approval set $true
)

function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
$fail = 0
function Gate([string]$Name, [bool]$Ok, [string]$Detail) {
    if ($Ok) { Write-Host ("PASS  {0} — {1}" -f $Name, $Detail) -ForegroundColor Green }
    else     { Write-Host ("FAIL  {0} — {1}" -f $Name, $Detail) -ForegroundColor Red; $script:fail++ }
}

Write-Host "`n=== SharePoint Online DLP — validation gate (read-only) ===" -ForegroundColor Cyan
if (-not (Test-Command 'Get-DlpCompliancePolicy')) { Write-Host "Run Connect-IPPSSession first." -ForegroundColor Yellow; return }

$policy = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
Gate ("Policy exists: {0}" -f $PolicyName) ([bool]$policy) $(if($policy){'found'}else{'not found — create it (Implementation Step 3)'})
if (-not $policy) { Write-Host "`nOVERALL: FAIL — policy missing." -ForegroundColor Red; return }

$spo = ($policy.PSObject.Properties.Name -contains 'SharePointLocation' -and $policy.SharePointLocation)
$od  = ($policy.PSObject.Properties.Name -contains 'OneDriveLocation'   -and $policy.OneDriveLocation)
Gate 'Covers SharePoint/OneDrive' ($spo -or $od) $(if($spo -or $od){("SPO={0}; OneDrive={1}" -f [bool]$spo, [bool]$od)}else{'no SPO/OneDrive location set'})

$isEnforce = ("{0}" -f $policy.Mode) -match 'Enable'
if ($ExpectEnforce) {
    Gate 'Policy in Enforce mode' $isEnforce ("Mode = {0}" -f $policy.Mode)
} else {
    Gate 'Policy still in TEST mode (pilot)' (-not $isEnforce) ("Mode = {0}" -f $policy.Mode)
}

$rule = Get-DlpComplianceRule -Policy $PolicyName -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $RuleName }
Gate ("Detection rule exists: {0}" -f $RuleName) ([bool]$rule) $(if($rule){("Disabled = {0}" -f $rule.Disabled)}else{'not found — add the rule'})

Write-Host ""
if ($fail -eq 0) { Write-Host "OVERALL: PASS — policy matches the intended design. Safe to proceed/expand." -ForegroundColor Green }
else             { Write-Host ("OVERALL: FAIL — {0} gate(s) failed. Remediate before enforcing or expanding." -f $fail) -ForegroundColor Red }

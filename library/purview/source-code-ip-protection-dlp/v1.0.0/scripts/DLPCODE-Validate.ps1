<#
.SYNOPSIS
    DLPCODE-Validate.ps1 — Validate the code/IP DLP policy exists, covers the intended channels, has its
    detection rule, and is in the expected mode (read-only).
.DESCRIPTION
    PURPOSE
        The pilot/expansion gate. Confirms PASS/FAIL that 'Source-Code & IP DLP - Policy' exists, covers the
        intended channels (Exchange/SharePoint/OneDrive/Teams/Endpoint), has its detection rule, and — for
        the pilot — is in TEST mode (not prematurely enforcing). Read-only. Run on the pilot before
        enforcing, and after each expansion wave.
    HOW TO RUN
        .\DLPCODE-Validate.ps1 -ExpectEnforce:$false -ExpectEndpoint:$true
        PowerShell 5.1+/7+. Connect first with Connect-IPPSSession. No secret is stored in the script.
    EXPECTED RESULTS
        A PASS/FAIL line per gate; overall PASS only when the policy matches the intended design. During the
        pilot, the policy being in Enable (enforce) mode FAILS the "still in test mode" gate.
.NOTES
    Purview — Source-Code & IP Protection DLP. Read-only gate. Verify your licensing/tenant; property/mode
    names vary by module version. Endpoint coverage requires E5 + onboarding.
#>
[CmdletBinding()]
param(
    [string]$PolicyName = 'Source-Code & IP DLP - Policy',
    [string]$RuleName   = 'Source-Code Detection Rule',
    [bool]$ExpectEnforce = $false,     # pilot expects test mode ($false); after approval set $true
    [bool]$ExpectEndpoint = $false     # set $true if Endpoint DLP is in scope (E5 + onboarding)
)

function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
$fail = 0
function Gate([string]$Name, [bool]$Ok, [string]$Detail) {
    if ($Ok) { Write-Host ("PASS  {0} — {1}" -f $Name, $Detail) -ForegroundColor Green }
    else     { Write-Host ("FAIL  {0} — {1}" -f $Name, $Detail) -ForegroundColor Red; $script:fail++ }
}

Write-Host "`n=== Source-Code & IP Protection DLP — validation gate (read-only) ===" -ForegroundColor Cyan
if (-not (Test-Command 'Get-DlpCompliancePolicy')) { Write-Host "Run Connect-IPPSSession first." -ForegroundColor Yellow; return }

$policy = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
Gate ("Policy exists: {0}" -f $PolicyName) ([bool]$policy) $(if($policy){'found'}else{'not found — create it (Implementation Step 3)'})
if (-not $policy) { Write-Host "`nOVERALL: FAIL — policy missing." -ForegroundColor Red; return }

$chanProps = @{ 'Exchange'='ExchangeLocation'; 'SharePoint'='SharePointLocation'; 'OneDrive'='OneDriveLocation'; 'Teams'='TeamsLocation' }
foreach ($k in $chanProps.Keys) {
    $prop = $chanProps[$k]
    $has = ($policy.PSObject.Properties.Name -contains $prop -and $policy.$prop)
    Gate ("Covers channel: {0}" -f $k) ([bool]$has) $(if($has){'in scope'}else{'not set — add the channel'})
}

$hasEp = ($policy.PSObject.Properties.Name -contains 'EndpointDlpLocation' -and $policy.EndpointDlpLocation)
if ($ExpectEndpoint) { Gate 'Covers channel: Endpoint' ([bool]$hasEp) $(if($hasEp){'in scope'}else{'not set — requires E5 + device onboarding'}) }
else { Write-Host ("INFO  Endpoint channel: {0} (set -ExpectEndpoint if in scope)" -f $(if($hasEp){'in scope'}else{'not in scope'})) -ForegroundColor DarkGray }

$isEnforce = ("{0}" -f $policy.Mode) -match 'Enable'
if ($ExpectEnforce) { Gate 'Policy in Enforce mode' $isEnforce ("Mode = {0}" -f $policy.Mode) }
else                { Gate 'Policy still in TEST mode (pilot)' (-not $isEnforce) ("Mode = {0}" -f $policy.Mode) }

$rule = Get-DlpComplianceRule -Policy $PolicyName -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $RuleName }
Gate ("Detection rule exists: {0}" -f $RuleName) ([bool]$rule) $(if($rule){("Disabled = {0}" -f $rule.Disabled)}else{'not found — add the rule'})

Write-Host "  INFO  Confirm the Source Code classifier + endpoint egress conditions on the rule in the portal (not fully readable here)." -ForegroundColor DarkGray

Write-Host ""
if ($fail -eq 0) { Write-Host "OVERALL: PASS — policy matches the intended design. Safe to proceed/expand." -ForegroundColor Green }
else             { Write-Host ("OVERALL: FAIL — {0} gate(s) failed. Remediate before enforcing or expanding." -f $fail) -ForegroundColor Red }

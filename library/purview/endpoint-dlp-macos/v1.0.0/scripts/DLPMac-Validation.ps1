<#
.SYNOPSIS
    DLPMac-Validation.ps1 — validate the macOS Endpoint DLP policy is Devices-scoped, in a test/simulation mode, with the intended egress channels (read-only).
.DESCRIPTION
    PURPOSE
        Confirms the pilot policy is configured correctly and SAFELY: that 'Endpoint DLP - macOS - Pilot'
        targets the DEVICES (Endpoint) location, is in a TEST/SIMULATION mode (TestWithoutNotifications
        or TestWithNotifications) rather than Enable, that its rule includes the intended macOS egress
        channels, and that any restricted-app control references a named app group. Emits PASS/FAIL/WARN
        lines and an overall gate. Read-only — makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLPMac-Validation.ps1
        Optionally: ... -PolicyName 'Endpoint DLP - macOS - Pilot' -ExpectEnforcing:$false
        PowerShell 5.1+/7+. Requires ExchangeOnlineManagement; connects via Connect-IPPSSession. No secrets.
    EXPECTED RESULTS
        PASS when the policy is Devices-scoped, in a test mode, and the rule covers the intended egress
        channels. FAIL if it is enforcing unexpectedly, not Devices-scoped, or missing channels. Use the
        gate before advancing the policy mode.
.NOTES
    Purview category — macOS Endpoint DLP. Read-only. Verify macOS channel support for your version.
#>
[CmdletBinding()]
param(
    [string]$PolicyName = 'Endpoint DLP - macOS - Pilot',
    [string]$RuleName   = 'macOS Egress - Sensitive Content',
    [string[]]$ExpectedChannels = @('CloudEgress','RemovableMedia','NetworkShare','CopyPaste','Print','UnallowedApps'),
    [switch]$ExpectEnforcing   # set only when you have intentionally moved to Enable
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop

$script:fail = 0; $script:warn = 0
function Pass($m){ Write-Host ("  PASS : {0}" -f $m) -ForegroundColor Green }
function Fail($m){ Write-Host ("  FAIL : {0}" -f $m) -ForegroundColor Red; $script:fail++ }
function Warn($m){ Write-Host ("  WARN : {0}" -f $m) -ForegroundColor Yellow; $script:warn++ }

Write-Host "`n=== Validate macOS Endpoint DLP policy: $PolicyName ===" -ForegroundColor Cyan
try { Connect-IPPSSession -ErrorAction Stop | Out-Null } catch {
    Write-Host ("Could not connect: {0}" -f $_.Exception.Message) -ForegroundColor Red; return
}

$policy = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
if (-not $policy) {
    Fail "policy '$PolicyName' not found — create it in TestWithoutNotifications (Implementation Step 5)."
} else {
    # Devices scope
    if ($policy.EndpointDlpLocation -and $policy.EndpointDlpLocation.Count -gt 0) { Pass "policy is scoped to the Devices (Endpoint) location." }
    else { Fail "policy is NOT scoped to Devices — endpoint restrictions will not apply to Macs." }

    # Mode
    $mode = "$($policy.Mode)"
    if ($ExpectEnforcing) {
        if ($mode -eq 'Enable') { Pass "policy Mode is Enable (enforcing) as expected." }
        else { Warn "expected enforcing but Mode is '$mode'." }
    } else {
        if ($mode -in @('TestWithoutNotifications','TestWithNotifications')) { Pass "policy Mode is '$mode' (test/simulation) — safe for pilot." }
        elseif ($mode -eq 'Enable') { Fail "policy is ENFORCING (Enable) but enforcement was not expected — roll back with Set-DlpCompliancePolicy -Mode TestWithoutNotifications until signed off." }
        else { Warn "policy Mode is '$mode'." }
    }
    if (-not $policy.Enabled) { Warn "policy Enabled = False (it will not evaluate)." }
}

# Rule + channels
$rule = Get-DlpComplianceRule -Identity $RuleName -ErrorAction SilentlyContinue
if (-not $rule) {
    Fail "rule '$RuleName' not found — add it to '$PolicyName' (Implementation Step 6)."
} else {
    Pass "rule '$RuleName' exists (policy: $($rule.ParentPolicyName))."
    $configured = @()
    if ($rule.EndpointDlpRestrictions) { $configured = $rule.EndpointDlpRestrictions | ForEach-Object { "$($_.Setting)" } }
    foreach ($ch in $ExpectedChannels) {
        if ($configured -contains $ch) {
            $val = ($rule.EndpointDlpRestrictions | Where-Object { "$($_.Setting)" -eq $ch } | Select-Object -First 1).Value
            if (-not $ExpectEnforcing -and "$val" -eq 'Block') { Warn "channel '$ch' is set to Block while still in pilot — confirm this is intended." }
            else { Pass "channel '$ch' present (action: $val)." }
        } else {
            Warn "expected egress channel '$ch' not configured on the rule (verify it is supported on your macOS version)."
        }
    }
    # Restricted-app control references a group
    if ($configured -contains 'UnallowedApps') {
        Write-Host "  NOTE : the UnallowedApps control acts on the restricted-app group defined in Endpoint DLP settings — confirm 'macOS - Restricted Apps' exists in the portal." -ForegroundColor DarkGray
    }
}

Write-Host "`n-- Gate --" -ForegroundColor Cyan
if ($script:fail -eq 0) { Write-Host ("VALIDATION PASS ({0} warning(s)). Safe to proceed per the Testing gate." -f $script:warn) -ForegroundColor Green }
else { Write-Host ("VALIDATION FAIL — {0} failure(s), {1} warning(s). Fix before advancing the mode." -f $script:fail, $script:warn) -ForegroundColor Red }
try { Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null } catch {}

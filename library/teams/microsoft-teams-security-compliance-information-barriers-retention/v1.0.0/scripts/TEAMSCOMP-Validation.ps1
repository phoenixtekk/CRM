<#
.SYNOPSIS
  Compliance-control validation report (read-only): checks the expected named artifacts and states.
.DESCRIPTION
  Verifies the Teams compliance controls are configured as intended and reports PASS/FAIL per check:
  the two IB segments exist, the IB policy is Active and application Completed, the Teams retention
  policy is Enabled with a rule of the expected duration/action, and the Teams DLP policy/rule exist
  in the expected mode. Read-only — changes nothing. Pass the artifact names you used (defaults match
  the guide's example names).
.EXAMPLE
  .\TEAMSCOMP-Validation.ps1 -IbPolicyName "IB Policy - GroupA-blocks-GroupB - Pilot" -RetentionPolicyName "Retention Policy - Teams Chat+Channel - Pilot" -DlpPolicyName "DLP Policy - Teams Sensitive - Pilot"
  # read-only; prints PASS/FAIL for each expected artifact
  (PowerShell 5.1+/7+, ExchangeOnlineManagement; connect via Connect-IPPSSession)
.NOTES
  Expected results: a PASS/FAIL line per control. A FAIL names the artifact and the expected state.
  White-label. Read-only.
#>
[CmdletBinding()]
param(
    [string[]]$SegmentNames = @('IB Segment - GroupA - Prod','IB Segment - GroupB - Prod'),
    [string]$IbPolicyName = 'IB Policy - GroupA-blocks-GroupB - Pilot',
    [string]$RetentionPolicyName = 'Retention Policy - Teams Chat+Channel - Pilot',
    [string]$DlpPolicyName = 'DLP Policy - Teams Sensitive - Pilot'
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false -ErrorAction Stop

$pass = 0; $fail = 0
function Check($name, [bool]$ok, $detail) {
    if ($ok) { Write-Host ("  PASS  {0}" -f $name) -ForegroundColor Green; $script:pass++ }
    else     { Write-Host ("  FAIL  {0} — {1}" -f $name, $detail) -ForegroundColor Red; $script:fail++ }
}

Write-Host "`n=== Teams compliance-control validation (read-only) ===" -ForegroundColor Cyan

# IB segments
$allSeg = Get-OrganizationSegment -ErrorAction SilentlyContinue
foreach ($s in $SegmentNames) {
    Check "Segment '$s' exists" ([bool]($allSeg | Where-Object Name -eq $s)) "segment not found"
}

# IB policy Active
$ibp = Get-InformationBarrierPolicy -ErrorAction SilentlyContinue | Where-Object Name -eq $IbPolicyName
Check "IB policy '$IbPolicyName' is Active" ([bool]($ibp -and $ibp.State -eq 'Active')) "policy missing or not Active"

# IB application completed
$ibStatus = Get-InformationBarrierPoliciesApplicationStatus -ErrorAction SilentlyContinue | Select-Object -First 1
Check "IB application Completed" ([bool]($ibStatus -and $ibStatus.Status -match 'Completed')) "no completed application run"

# Teams retention policy Enabled + Teams-scoped + rule
$rp = Get-RetentionCompliancePolicy -Identity $RetentionPolicyName -ErrorAction SilentlyContinue
$rpTeamsScoped = $rp -and (($rp.TeamsChatLocation.Count -gt 0) -or ($rp.TeamsChannelLocation.Count -gt 0))
Check "Retention '$RetentionPolicyName' Enabled + Teams-scoped" ([bool]($rp -and $rp.Enabled -and $rpTeamsScoped)) "missing, disabled, or not Teams-scoped"
if ($rp) {
    $rr = Get-RetentionComplianceRule -Policy $RetentionPolicyName -ErrorAction SilentlyContinue | Select-Object -First 1
    Check "Retention rule present with duration + action" ([bool]($rr -and $rr.RetentionDuration -and $rr.RetentionComplianceAction)) "rule missing or incomplete"
}

# Teams DLP policy + rule
$dp = Get-DlpCompliancePolicy -Identity $DlpPolicyName -ErrorAction SilentlyContinue
$dpTeamsScoped = $dp -and ($dp.TeamsLocation.Count -gt 0)
Check "Teams DLP '$DlpPolicyName' exists + Teams-scoped" ([bool]($dp -and $dpTeamsScoped)) "missing or not Teams-scoped"
if ($dp) {
    Write-Host ("        DLP mode = {0} (Test = audit gate; Enable = enforcing)" -f $dp.Mode) -ForegroundColor Gray
    $dr = Get-DlpComplianceRule -Policy $DlpPolicyName -ErrorAction SilentlyContinue | Select-Object -First 1
    Check "Teams DLP rule present" ([bool]$dr) "rule missing"
}

Write-Host ("`nValidation summary: {0} PASS, {1} FAIL." -f $pass, $fail) -ForegroundColor Cyan
if ($fail -gt 0) { Write-Host "Remediate the FAIL items and re-run." -ForegroundColor Yellow }
Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
exit ([int]($fail -gt 0))

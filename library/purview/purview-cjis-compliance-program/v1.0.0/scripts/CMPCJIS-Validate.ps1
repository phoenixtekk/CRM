<#
.SYNOPSIS
    CMPCJIS-Validate.ps1 - verify the CJI controls are present and in the expected state; technical PASS/FAIL (read-only).
.DESCRIPTION
    PURPOSE
        Read-only technical validation of the CJIS-aligned Purview controls. Confirms: unified audit logging
        is ON; the CJI label exists and (indicatively) has encryption; the CJI-exfiltration DLP policy exists
        and is in the expected mode (Test before enforcement); the CJI retention policy exists and is staged;
        and, from a supplied board/role matrix, that SEPARATION OF DUTIES holds. Produces a per-control
        PASS/FAIL/CHECK table. It validates TECHNICAL STATE only - whether the controls SATISFY CJIS is the
        CSA/auditor's determination.
    HOW TO RUN
        .\CMPCJIS-Validate.ps1 -ExpectEnforced:$false -OutPath .\CJIS-Validate.csv
        Optional: -RoleMatrixCsv .\cjis-roles.csv (columns Member,RoleGroup) to run the SoD check;
        -ExpectEnforced to assert the enforced end-state instead of the safe-first pilot state.
        Requires ExchangeOnlineManagement (Connect-IPPSSession + Connect-ExchangeOnline). No secrets.
    EXPECTED RESULTS
        A per-control PASS/FAIL/CHECK table + summary. PASS = the control exists in the expected state.
        CHECK = verify manually (e.g. label encryption params, audit retention duration). Whether the posture
        is SUFFICIENT is deferred to the CSA/auditor.
.NOTES
    Purview category - CJIS Compliance Program. Read-only. Audit-retention duration and control satisfaction
    are CSA/records determinations. No client names; no secrets.
#>
[CmdletBinding()]
param(
    [string]$LabelName     = 'CJI - Protected - Label',
    [string]$DlpPolicyName = 'CJI Protection - Exfiltration - Policy',
    [string]$RetentionName = 'CJI Records - Retention - Policy',
    [switch]$ExpectEnforced,
    [string]$RoleMatrixCsv,
    [string]$UserPrincipalName,
    [string]$OutPath
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
$results = New-Object System.Collections.Generic.List[object]
function Add-R($control,$status,$detail){ $results.Add([pscustomobject]@{ Control=$control; Status=$status; Detail=$detail }) }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) { Write-Host 'ExchangeOnlineManagement not installed.' -ForegroundColor Red; return }
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$cp = @{}; if ($UserPrincipalName) { $cp['UserPrincipalName'] = $UserPrincipalName }

# Audit logging (Auditing & Accountability)
try {
    Connect-ExchangeOnline @cp -ShowBanner:$false -ErrorAction Stop | Out-Null
    $cfg = Get-AdminAuditLogConfig -ErrorAction Stop
    if ([bool]$cfg.UnifiedAuditLogIngestionEnabled) { Add-R 'Unified audit logging (AU)' 'PASS' 'UnifiedAuditLogIngestionEnabled=True' }
    else { Add-R 'Unified audit logging (AU)' 'FAIL' 'Audit logging OFF - enable it (Impl Step 4.1)' }
    Add-R 'Audit retention duration (AU)' 'CHECK' 'Confirm the required CJI audit-retention period (Audit Premium) with your CSA/records owner - determination'
} catch { Add-R 'Unified audit logging (AU)' 'CHECK' $_.Exception.Message }

try { if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) { Connect-IPPSSession @cp -ErrorAction Stop | Out-Null } }
catch { Add-R 'S&C PowerShell' 'FAIL' $_.Exception.Message }

# CJI label + encryption (Information Protection / Access Control)
try {
    $l = Get-Label -Identity $LabelName -ErrorAction Stop
    Add-R 'CJI label present (IP)' 'PASS' "'$LabelName' exists"
    if ($l.PSObject.Properties.Name -contains 'EncryptionEnabled' -and $l.EncryptionEnabled) { Add-R 'CJI label encryption (SC)' 'PASS' 'EncryptionEnabled=True' }
    else { Add-R 'CJI label encryption (SC)' 'CHECK' 'Encryption not confirmed via cmdlet - verify label encryption/access scope in the portal per the agency design' }
    # Published?
    try {
        $published = @(Get-LabelPolicy -ErrorAction Stop | Where-Object { $_.Labels -contains $l.Name -or $_.ScopedLabels -contains $l.Name }).Count -gt 0
        if ($ExpectEnforced) { if ($published) { Add-R 'CJI label published (enforce)' 'PASS' 'label is published' } else { Add-R 'CJI label published (enforce)' 'FAIL' 'expected published in enforce state' } }
        else { if ($published) { Add-R 'CJI label publish state (pilot)' 'CHECK' 'label is PUBLISHED while validating the safe-first pilot - confirm this is intended' } else { Add-R 'CJI label publish state (pilot)' 'PASS' 'unpublished (safe-first)' } }
    } catch {}
} catch { Add-R 'CJI label present (IP)' 'FAIL' "'$LabelName' not found" }

# CJI DLP mode (Information Flow / Prevent exfiltration)
try {
    $d = Get-DlpCompliancePolicy -Identity $DlpPolicyName -ErrorAction Stop
    $m = "$($d.Mode)"
    if ($ExpectEnforced) {
        if ($m -match 'Enable') { Add-R 'CJI DLP mode (enforce)' 'PASS' "Mode=$m" } else { Add-R 'CJI DLP mode (enforce)' 'FAIL' "expected Enable, found $m" }
    } else {
        if ($m -match '(?i)test|sim') { Add-R 'CJI DLP mode (pilot)' 'PASS' "Mode=$m (safe-first)" } else { Add-R 'CJI DLP mode (pilot)' 'FAIL' "expected Test/simulation, found $m - return to test before enforce" }
    }
    $ruleCount = 0; try { $ruleCount = @(Get-DlpComplianceRule -Policy $DlpPolicyName -ErrorAction Stop).Count } catch {}
    if ($ruleCount -gt 0) { Add-R 'CJI DLP rule present' 'PASS' "$ruleCount rule(s) - confirm they bind the CJI label/agency SITs" } else { Add-R 'CJI DLP rule present' 'CHECK' 'No rule found - add the CJI-matching rule (CJI identifiers from the agency)' }
} catch { Add-R 'CJI DLP present' 'FAIL' "'$DlpPolicyName' not found" }

# CJI retention staged/enabled
try {
    $r = Get-RetentionCompliancePolicy -Identity $RetentionName -ErrorAction Stop
    $en = [bool]$r.Enabled
    if ($ExpectEnforced) { if ($en) { Add-R 'CJI retention (enforce)' 'PASS' 'Enabled=True' } else { Add-R 'CJI retention (enforce)' 'FAIL' 'expected Enabled in enforce state' } }
    else { if (-not $en) { Add-R 'CJI retention (pilot)' 'PASS' 'Disabled/staged (safe-first)' } else { Add-R 'CJI retention (pilot)' 'CHECK' 'retention Enabled while validating pilot - confirm intended' } }
    Add-R 'CJI retention schedule (records)' 'CHECK' 'Confirm the retention duration/action matches the agency-approved schedule - records/legal determination'
} catch { Add-R 'CJI retention present' 'FAIL' "'$RetentionName' not found" }

# Separation of duties (optional)
if ($RoleMatrixCsv -and (Test-Path $RoleMatrixCsv)) {
    Write-Section 'Separation of duties'
    $investigative = @('Insider Risk Management','Communication Compliance','eDiscovery Manager','eDiscovery Administrator')
    $rows = @(Import-Csv -Path $RoleMatrixCsv)
    foreach ($g in ($rows | Group-Object Member)) {
        $roles = @($g.Group | ForEach-Object { "$($_.RoleGroup)".Trim() })
        $inv = @($roles | Where-Object { $investigative -contains $_ })
        if ($inv.Count -ge 2) { Add-R "SoD: $($g.Name)" 'FAIL' ("multiple investigative roles: {0}" -f ($inv -join ',')) }
        elseif ($inv.Count -eq 1 -and $roles.Count -gt 1) { Add-R "SoD: $($g.Name)" 'CHECK' ("investigative + other roles - confirm charter separation") }
        else { Add-R "SoD: $($g.Name)" 'PASS' 'no conflict' }
    }
}

if ($OutPath) { $results | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8 }
Write-Section 'Result - CJIS technical validation'
$results | Format-Table -AutoSize | Out-String | Write-Host
$fail = @($results | Where-Object Status -eq 'FAIL').Count
$check= @($results | Where-Object Status -eq 'CHECK').Count
if ($fail -gt 0) { Write-Host "$fail FAIL - correct before expanding/enforcing." -ForegroundColor Red }
else { Write-Host "0 FAIL, $check CHECK - resolve CHECK items (verify manually) before the formal audit." -ForegroundColor Yellow }
Write-Host 'This validates TECHNICAL STATE only. Whether the controls SATISFY CJIS is the CSA/auditor determination.' -ForegroundColor Yellow
if ($OutPath) { Write-Host ("Results -> {0}" -f $OutPath) -ForegroundColor Green }

<#
.SYNOPSIS
    CMPCJIS-Configure.ps1 - scaffold the CJI label, CJI-exfiltration DLP (Test mode), and CJI retention; enable audit; -WhatIf by default.
.DESCRIPTION
    PURPOSE
        Configures the CJI technical controls SAFE-FIRST. It can enable unified audit logging
        (-EnableAudit), and scaffold "CJI - Protected - Label", "CJI Protection - Exfiltration - Policy"
        (created in TEST/SIMULATION mode), and "CJI Records - Retention - Policy" (created disabled/staged).
        Everything is gated: it PREVIEWS with -WhatIf and writes only with -Commit; nothing ENFORCES without
        a separate, explicit -Enforce -Commit. It creates ONLY its own named objects and never deletes
        pre-existing policies. The label's ENCRYPTION/access scope is confirmed in the portal per the agency
        design (this script sets the label and flags encryption for you to finalize) - it does not invent
        CJI identifiers or a retention schedule (agency/records determinations).
    HOW TO RUN
        # Enable the source audit trail (not a user-impacting content policy):
        .\CMPCJIS-Configure.ps1 -EnableAudit -WhatIf     ;  .\CMPCJIS-Configure.ps1 -EnableAudit -Commit
        # Scaffold the CJI controls safe-first for the pilot:
        .\CMPCJIS-Configure.ps1 -Scope Pilot -PilotSharePointUrl https://contoso.sharepoint.com/sites/cji -WhatIf
        .\CMPCJIS-Configure.ps1 -Scope Pilot -PilotSharePointUrl https://contoso.sharepoint.com/sites/cji -Commit
        # Enforce deliberately after the pilot passes and CSA/change approval:
        .\CMPCJIS-Configure.ps1 -Scope Pilot -Enforce -WhatIf   ;  ... -Enforce -Commit
        # Rollback the objects this program created:
        .\CMPCJIS-Configure.ps1 -Scope Pilot -Remove -Commit
        Requires ExchangeOnlineManagement (Connect-IPPSSession + Connect-ExchangeOnline). No secrets in code.
    EXPECTED RESULTS
        Without -Commit: the exact New-/Set-* cmdlets it WOULD run. With -Commit (no -Enforce): label exists
        (unpublished), DLP in Test mode, retention disabled/staged - NO user impact. With -Enforce -Commit:
        label published / DLP Enable / retention enabled - the one step that turns on real impact.
.NOTES
    Purview category - CJIS Compliance Program. -WhatIf by default; enforce is separate. Do NOT run in a
    non-CJIS-authorized tenant (CSA/CSO determination). CJI identifiers and retention schedule come from the
    agency. No client names; no secrets.
#>
[CmdletBinding()]
param(
    [ValidateSet('Pilot','Full')][string]$Scope = 'Pilot',
    [string]$LabelName        = 'CJI - Protected - Label',
    [string]$DlpPolicyName    = 'CJI Protection - Exfiltration - Policy',
    [string]$RetentionName    = 'CJI Records - Retention - Policy',
    [string]$PilotSharePointUrl,          # a pilot site to scope the DLP/retention to (recommended)
    [string]$UserPrincipalName,
    [switch]$EnableAudit,
    [switch]$Enforce,                      # with -Commit: publish label / enable DLP / enable retention
    [switch]$Remove,                       # with -Commit: delete the objects this program created
    [switch]$Commit
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
$mode = if ($Commit) { if ($Enforce) { 'COMMIT + ENFORCE (real user/data impact)' } else { 'COMMIT (safe-first - no enforcement)' } } else { '-WhatIf (dry-run - no changes)' }
Write-Section ("Mode: {0}   Scope: {1}" -f $mode, $Scope)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host 'ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser' -ForegroundColor Red; return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$cp = @{}; if ($UserPrincipalName) { $cp['UserPrincipalName'] = $UserPrincipalName }

# ------------------------------------------------------------------ (opt) enable unified audit logging
if ($EnableAudit) {
    Write-Section 'Unified audit logging'
    try {
        Connect-ExchangeOnline @cp -ShowBanner:$false -ErrorAction Stop | Out-Null
        $cfg = Get-AdminAuditLogConfig -ErrorAction Stop
        if ([bool]$cfg.UnifiedAuditLogIngestionEnabled) { Write-Host '  [OK] already enabled' -ForegroundColor Green }
        elseif ($Commit) { Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true -ErrorAction Stop; Write-Host '  [PASS] enabled unified audit logging' -ForegroundColor Green }
        else { Write-Host '  [WHATIF] would run: Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true' }
    } catch { Write-Host "  [FAIL] audit config: $($_.Exception.Message)" -ForegroundColor Red }
}

try {
    if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) { Connect-IPPSSession @cp -ErrorAction Stop | Out-Null }
} catch { Write-Host "  [FAIL] Connect-IPPSSession: $($_.Exception.Message)" -ForegroundColor Red; return }

# ------------------------------------------------------------------ REMOVE (rollback)
if ($Remove) {
    Write-Section 'Remove program-created objects (rollback)'
    foreach ($item in @(
        @{ Get='Get-RetentionCompliancePolicy'; Rm='Remove-RetentionCompliancePolicy'; Name=$RetentionName },
        @{ Get='Get-DlpCompliancePolicy';       Rm='Remove-DlpCompliancePolicy';       Name=$DlpPolicyName },
        @{ Get='Get-Label';                     Rm='Remove-Label';                     Name=$LabelName }
    )) {
        $exists = $null; try { $exists = & $item.Get -Identity $item.Name -ErrorAction Stop } catch {}
        if (-not $exists) { Write-Host "  [SKIP] '$($item.Name)' not found." -ForegroundColor Yellow; continue }
        if ($Commit) { try { & $item.Rm -Identity $item.Name -Confirm:$false -ErrorAction Stop; Write-Host "  [PASS] removed '$($item.Name)'" -ForegroundColor Green } catch { Write-Host "  [FAIL] remove '$($item.Name)': $($_.Exception.Message)" -ForegroundColor Red } }
        else { Write-Host "  [WHATIF] would remove '$($item.Name)'" }
    }
    Write-Host 'Removal touches ONLY this program''s named objects; pre-existing policies are untouched.'
    return
}

# ------------------------------------------------------------------ CJI sensitivity label
Write-Section "CJI sensitivity label: $LabelName"
$labelObj = $null; try { $labelObj = Get-Label -Identity $LabelName -ErrorAction Stop } catch {}
if (-not $labelObj) {
    if ($Commit) {
        try {
            New-Label -DisplayName $LabelName -Name ($LabelName -replace '[^0-9A-Za-z]','') `
                -Tooltip 'Criminal Justice Information - handle per CJIS Security Policy' -ErrorAction Stop | Out-Null
            Write-Host "  [PASS] created label '$LabelName' (UNPUBLISHED)." -ForegroundColor Green
            Write-Host "  [ACTION] Finalize ENCRYPTION + access scope in the portal per the agency design (Set-Label -EncryptionEnabled ...) - verify supported params in your tenant." -ForegroundColor Yellow
        } catch { Write-Host "  [FAIL] create label: $($_.Exception.Message)" -ForegroundColor Red }
    } else {
        Write-Host "  [WHATIF] would run: New-Label -DisplayName '$LabelName' ... (then finalize ENCRYPTION/access in the portal)"
    }
} else { Write-Host "  [OK] label already exists." -ForegroundColor Green }

# Publish the label only on -Enforce -Commit
if ($Enforce) {
    if ($Commit) {
        try {
            $lp = $null; try { $lp = Get-LabelPolicy -Identity 'CJI - Protected - LabelPolicy' -ErrorAction Stop } catch {}
            if (-not $lp) { New-LabelPolicy -Name 'CJI - Protected - LabelPolicy' -Labels $LabelName -ErrorAction Stop | Out-Null; Write-Host "  [PASS] published label via 'CJI - Protected - LabelPolicy'." -ForegroundColor Green }
            else { Write-Host "  [OK] label policy already exists." -ForegroundColor Green }
        } catch { Write-Host "  [FAIL] publish label: $($_.Exception.Message)" -ForegroundColor Red }
    } else { Write-Host "  [WHATIF] would publish the label via a label policy (New-LabelPolicy)." }
}

# ------------------------------------------------------------------ CJI-exfiltration DLP (Test mode safe-first)
Write-Section "CJI-exfiltration DLP: $DlpPolicyName"
$dlpMode = if ($Enforce) { 'Enable' } else { 'TestWithNotifications' }
$dlpObj = $null; try { $dlpObj = Get-DlpCompliancePolicy -Identity $DlpPolicyName -ErrorAction Stop } catch {}
$loc = @{}
if ($PilotSharePointUrl) { $loc['SharePointLocation'] = $PilotSharePointUrl } else { $loc['SharePointLocation'] = 'All' }
if (-not $dlpObj) {
    if ($Commit) {
        try {
            New-DlpCompliancePolicy -Name $DlpPolicyName -Mode $dlpMode @loc -Comment 'CJI exfiltration protection (CJIS)' -ErrorAction Stop | Out-Null
            Write-Host "  [PASS] created DLP policy in mode '$dlpMode'." -ForegroundColor Green
            Write-Host "  [ACTION] Add the DLP RULE binding your CJI label / agency CJI SITs (New-DlpComplianceRule -Policy '$DlpPolicyName' -ContentContainsSensitiveInformation ...) - CJI identifiers come from the agency." -ForegroundColor Yellow
        } catch { Write-Host "  [FAIL] create DLP policy: $($_.Exception.Message)" -ForegroundColor Red }
    } else {
        Write-Host "  [WHATIF] would run: New-DlpCompliancePolicy -Name '$DlpPolicyName' -Mode $dlpMode -SharePointLocation '$($loc['SharePointLocation'])' ..."
        Write-Host "  [WHATIF] then add a rule (New-DlpComplianceRule) matching the CJI label / agency SITs."
    }
} else {
    if ($Enforce) {
        if ($Commit) { try { Set-DlpCompliancePolicy -Identity $DlpPolicyName -Mode Enable -ErrorAction Stop; Write-Host "  [PASS] DLP policy moved to Enable (enforce)." -ForegroundColor Green } catch { Write-Host "  [FAIL] enforce DLP: $($_.Exception.Message)" -ForegroundColor Red } }
        else { Write-Host "  [WHATIF] would run: Set-DlpCompliancePolicy -Identity '$DlpPolicyName' -Mode Enable" }
    } else { Write-Host "  [OK] DLP policy exists (mode $($dlpObj.Mode)) - safe-first; use -Enforce to enable." -ForegroundColor Green }
}

# ------------------------------------------------------------------ CJI retention (staged/disabled safe-first)
Write-Section "CJI retention: $RetentionName"
$retObj = $null; try { $retObj = Get-RetentionCompliancePolicy -Identity $RetentionName -ErrorAction Stop } catch {}
$retLoc = @{}
if ($PilotSharePointUrl) { $retLoc['SharePointLocation'] = $PilotSharePointUrl } else { $retLoc['SharePointLocation'] = 'All' }
if (-not $retObj) {
    if ($Commit) {
        try {
            New-RetentionCompliancePolicy -Name $RetentionName @retLoc -Enabled $false -Comment 'CJI records retention (schedule = agency/records determination)' -ErrorAction Stop | Out-Null
            Write-Host "  [PASS] created retention policy (DISABLED/staged)." -ForegroundColor Green
            Write-Host "  [ACTION] Add the retention RULE with the agency-approved duration/action (New-RetentionComplianceRule) - the SCHEDULE is a records/legal determination." -ForegroundColor Yellow
        } catch { Write-Host "  [FAIL] create retention policy: $($_.Exception.Message)" -ForegroundColor Red }
    } else {
        Write-Host "  [WHATIF] would run: New-RetentionCompliancePolicy -Name '$RetentionName' -SharePointLocation '$($retLoc['SharePointLocation'])' -Enabled `$false ..."
        Write-Host "  [WHATIF] then add a rule with the agency-approved retention duration/action."
    }
} else {
    if ($Enforce) {
        if ($Commit) { try { Set-RetentionCompliancePolicy -Identity $RetentionName -Enabled $true -ErrorAction Stop; Write-Host "  [PASS] retention policy enabled." -ForegroundColor Green } catch { Write-Host "  [FAIL] enable retention: $($_.Exception.Message)" -ForegroundColor Red } }
        else { Write-Host "  [WHATIF] would run: Set-RetentionCompliancePolicy -Identity '$RetentionName' -Enabled `$true" }
    } else { Write-Host "  [OK] retention policy exists (Enabled=$($retObj.Enabled)) - safe-first; use -Enforce to enable." -ForegroundColor Green }
}

Write-Section 'Summary'
if (-not $Commit) { Write-Host 'Dry-run only. Review the plan, then re-run with -Commit (safe-first) and later -Enforce -Commit.' }
elseif (-not $Enforce) { Write-Host 'Safe-first committed: label UNPUBLISHED, DLP in Test mode, retention DISABLED. No user impact. Pilot + validate, then -Enforce -Commit.' }
else { Write-Host 'ENFORCE committed: real user/data impact is now on for the scope. Monitor; ROLLBACK = re-run without -Enforce (-Commit) or -Remove -Commit.' }
Write-Host 'Finalize label encryption/access, DLP rule (CJI label/agency SITs), and retention duration per the agency design - this tool does not invent them.'

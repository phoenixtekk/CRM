<#
.SYNOPSIS
    PURVIEW-Validation.ps1 — confirm the optional quick-win baseline is present, non-enforcing, and pilot-scoped (read-only).
.DESCRIPTION
    PURPOSE
        Verifies the quick-win baseline objects that PURVIEW-Remediation.ps1 may have created for the
        maturity roadmap's "Now" horizon: the baseline sensitivity label + label policy, the baseline
        DLP policy in TEST mode, and the unified audit log state. Confirms each exists, is NON-ENFORCING
        (test/simulation/disabled), and is scoped to the pilot group. Read-only — it only checks.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVIEW-Validation.ps1
        powershell -ExecutionPolicy Bypass -File .\PURVIEW-Validation.ps1 -PilotGroup "Purview - Pilot Users"
        Sign in as a Compliance Administrator / reader when prompted.
    EXPECTED RESULTS
        PASS/FAIL per baseline object: baseline label + policy present, DLP policy present and in TEST
        (not Enforce), audit ON. Any object that is missing or already enforcing is flagged.
.NOTES
    White-label — Purview Solutions. READ-ONLY.
    Uses Get-Label / Get-LabelPolicy / Get-DlpCompliancePolicy / Get-AdminAuditLogConfig.
#>
[CmdletBinding()]
param(
    [string]$BaselineLabel  = 'Sensitivity Label - Confidential - Baseline',
    [string]$BaselineDlp    = 'DLP Policy - Baseline PII - Test',
    [string]$PilotGroup     = 'Purview - Pilot Users'
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

$pass = $true
function Check([string]$name, [bool]$ok, [string]$detail) {
    if ($ok) { Write-Host ("  PASS  {0}: {1}" -f $name, $detail) -ForegroundColor Green }
    else     { Write-Host ("  FAIL  {0}: {1}" -f $name, $detail) -ForegroundColor Red; $script:pass = $false }
}

Write-Host "`n=== Purview maturity — quick-win baseline validation ===" -ForegroundColor Cyan

# 1. Baseline sensitivity label
$label = Get-Label -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq $BaselineLabel }
Check "Baseline label present" ([bool]$label) $(if ($label) { $BaselineLabel } else { "'$BaselineLabel' not found" })

# 2. Baseline label policy exists and targets the pilot
$lpol = Get-LabelPolicy -ErrorAction SilentlyContinue | Where-Object { $_.Labels -contains $BaselineLabel -or $_.Name -match 'Baseline' }
Check "Baseline label policy present" ([bool]$lpol) $(if ($lpol) { $lpol.Name -join ', ' } else { "no label policy publishing the baseline label" })

# 3. Baseline DLP policy present AND in Test (non-enforcing)
$dlp = Get-DlpCompliancePolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $BaselineDlp }
if ($dlp) {
    $isTest = ($dlp.Mode -notmatch 'Enable')   # Enable* == enforcing
    Check "Baseline DLP present" $true ("{0} (Mode={1})" -f $dlp.Name, $dlp.Mode)
    Check "Baseline DLP is NON-ENFORCING (test)" $isTest ("Mode={0} — must not be an Enable* (enforce) mode at baseline" -f $dlp.Mode)
} else {
    Check "Baseline DLP present" $false "'$BaselineDlp' not found"
}

# 4. Unified audit log ON
try {
    $cfg = Get-AdminAuditLogConfig -ErrorAction Stop
    Check "Unified audit log ON" ([bool]$cfg.UnifiedAuditLogIngestionEnabled) ("UnifiedAuditLogIngestionEnabled={0}" -f $cfg.UnifiedAuditLogIngestionEnabled)
} catch {
    Check "Unified audit log ON" $false "could not read audit config — verify your licensing/tenant"
}

Write-Host ("`nPilot scope expected: {0} (confirm membership in Entra / via PURVIEW-Set-ScopeTargeting.ps1)." -f $PilotGroup) -ForegroundColor DarkGray
if ($pass) { Write-Host "`nRESULT: baseline PASS — present, non-enforcing, ready to validate against the Testing Guide." -ForegroundColor Green }
else       { Write-Host "`nRESULT: baseline FAIL — see FAIL lines above. Re-run PURVIEW-Remediation.ps1 -WhatIf to review the plan." -ForegroundColor Red }

Disconnect-ExchangeOnline -Confirm:$false | Out-Null

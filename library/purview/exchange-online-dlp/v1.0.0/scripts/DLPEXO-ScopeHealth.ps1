<#
.SYNOPSIS
    DLPEXO-ScopeHealth.ps1 — Exchange DLP scope health: mail-flow coverage, policy precedence/overlap, licensing-readiness flags (read-only; -WhatIf for any scope change).
.DESCRIPTION
    PURPOSE
        Scope and health helper for Exchange Online DLP. Reports which DLP policies cover the Exchange location
        and their PRECEDENCE/priority (so you can see overlap/ordering), flags transport (mail-flow) rules that
        may conflict with DLP, checks message-encryption readiness for the encrypt scenario, and shows the pilot
        policy's current mode + rule sender-scope — so you can see what the policy WOULD cover before you widen
        it. Read-only by default; any scope change is preview-only via -WhatIf (this tool does not itself widen
        scope — it prints the command for you to run under change control).
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession). For transport-rule /
        encryption signals also connect Exchange Online (Connect-ExchangeOnline):
          Connect-IPPSSession
          .\DLPEXO-ScopeHealth.ps1
          .\DLPEXO-ScopeHealth.ps1 -PolicyName "DLPEXO-Pilot" -PilotGroup "SG-DLPEXO-Pilot" -WhatIf
    EXPECTED RESULTS
        A console summary: Exchange-location DLP policies with priority (precedence), overlapping transport rules,
        message-encryption readiness (IRM/OME), and the pilot policy's mode + rule scope. With -WhatIf, a PREVIEW
        of the scope-widening command (nothing is changed).
.NOTES
    White-label Microsoft Purview tooling. Read-only / -WhatIf only. No credentials stored. Uses standard
    Get-DlpCompliancePolicy / Get-DlpComplianceRule and, if available, Get-TransportRule / Get-IRMConfiguration;
    none invented. Precedence/priority and encryption readiness are signals — the authoritative view is the
    Purview / Exchange admin portal.
#>
[CmdletBinding()]
param(
    [switch]$WhatIf,
    [string]$PolicyName = "DLPEXO-Pilot",
    [string]$PilotGroup = "SG-DLPEXO-Pilot"
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPEXO ScopeHealth — Exchange DLP scope/precedence/readiness (read-only) ===" -ForegroundColor Cyan

try { Get-DlpCompliancePolicy -ErrorAction Stop | Out-Null }
catch { Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR §3)." -ForegroundColor Red; return }

# --- Exchange-location DLP policies + precedence (priority) ---
try {
    $pols = Get-DlpCompliancePolicy -ErrorAction Stop
    $exo  = @($pols | Where-Object { $_.ExchangeLocation -and @($_.ExchangeLocation).Count -gt 0 })
    Write-Host ("  Exchange-location DLP policies: {0} of {1}" -f @($exo).Count, @($pols).Count) -ForegroundColor Green
    foreach ($p in ($exo | Sort-Object Priority)) {
        Write-Host ("    - {0,-24} Priority={1,-3} Mode={2}" -f $p.Name, "$($p.Priority)", $p.Mode) -ForegroundColor Gray
    }
    if (@($exo).Count -gt 1) {
        Write-Host "  NOTE: multiple policies cover Exchange — LOWER priority number wins first. Review overlap so rules do not shadow each other." -ForegroundColor Yellow
    }
} catch { Write-Host "  WARN: could not read DLP policies: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Transport (mail-flow) rule overlap (R7) ---
try {
    if (Get-Command Get-TransportRule -ErrorAction SilentlyContinue) {
        $trs = Get-TransportRule -ErrorAction Stop
        $conflict = $trs | Where-Object {
            $_.RejectMessageReasonText -or $_.ApplyOME -or $_.ApplyRightsProtectionTemplate -or $_.DeleteMessage -or $_.MessageContainsDataClassifications
        }
        Write-Host ("  Transport rules that block/encrypt/delete on content: {0} of {1}" -f @($conflict).Count, @($trs).Count) -ForegroundColor Green
        foreach ($t in $conflict) { Write-Host ("    - {0}  (State={1})" -f $t.Name, $t.State) -ForegroundColor Yellow }
        if (@($conflict).Count -gt 0) { Write-Host "  ACTION: reconcile these with the DLP policy before enforcing (02-requirements R7)." -ForegroundColor Yellow }
    } else {
        Write-Host "  (Get-TransportRule not available — connect Exchange Online to check mail-flow overlap; review R7 manually.)" -ForegroundColor Gray
    }
} catch { Write-Host "  WARN: could not read transport rules: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Message-encryption readiness (for the encrypt scenario / R1) ---
try {
    if (Get-Command Get-IRMConfiguration -ErrorAction SilentlyContinue) {
        $irm = Get-IRMConfiguration -ErrorAction Stop
        $ready = ($irm.InternalLicensingEnabled -eq $true) -or ($irm.AzureRMSLicensingEnabled -eq $true)
        $col = if ($ready) { "Green" } else { "Yellow" }
        Write-Host ("  Message-encryption (IRM/AzureRMS) enabled: {0}  (needed for DLPEXO-Rule-Label-Encrypt)" -f $ready) -ForegroundColor $col
        if (-not $ready) { Write-Host "  FLAG: enable Purview Message Encryption before relying on the encrypt action (R1)." -ForegroundColor Yellow }
    } else {
        Write-Host "  (Get-IRMConfiguration not available — connect Exchange Online to check message-encryption readiness; verify R1 manually.)" -ForegroundColor Gray
    }
} catch { Write-Host "  WARN: could not read IRM configuration: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Pilot policy mode + rule sender-scope ---
try {
    $pol = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
    if ($pol) {
        Write-Host ("  Policy '{0}': Mode={1}; ExchangeLocation={2}" -f $PolicyName, $pol.Mode, (@($pol.ExchangeLocation) -join ', ')) -ForegroundColor Green
        $rules = @()
        try { $rules = Get-DlpComplianceRule -Policy $PolicyName -ErrorAction Stop } catch { }
        foreach ($r in $rules) {
            $scoped = if ("$($r.FromMemberOf)" -match [regex]::Escape($PilotGroup)) { "pilot-scoped" } else { "NOT pilot-scoped" }
            Write-Host ("    rule {0,-24} sender-scope: {1}" -f $r.Name, $scoped) -ForegroundColor Gray
        }
    } else {
        Write-Host ("  Policy '{0}' not found (run DLPEXO-Configure.ps1 -Commit first)." -f $PolicyName) -ForegroundColor Yellow
    }
} catch { Write-Host "  WARN: could not read the pilot policy/rules: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Scope-change PREVIEW only (this tool never widens scope itself) ---
if ($WhatIf) {
    Write-Host "`n  -WhatIf PREVIEW — to widen a rule beyond the pilot senders, run this yourself under change control:" -ForegroundColor Cyan
    Write-Host ("    Set-DlpComplianceRule -Identity 'DLPEXO-Rule-Ext-Block' -FromMemberOf `$null   # remove pilot condition -> all senders (VERIFY)") -ForegroundColor Gray
    Write-Host "  (No change was made. Re-validate with DLPEXO-Validate.ps1 after any scope change.)" -ForegroundColor DarkYellow
}

Write-Host "`nScopeHealth complete. Reconcile transport-rule overlap and confirm encryption readiness; then DLPEXO-Validate.ps1 for configuration gates." -ForegroundColor Cyan

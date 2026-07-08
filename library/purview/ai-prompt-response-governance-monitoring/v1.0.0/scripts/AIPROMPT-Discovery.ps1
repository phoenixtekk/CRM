<#
.SYNOPSIS
    AIPROMPT-Discovery.ps1 — inventory the levers and existing AI-governance config (read-only).
.DESCRIPTION
    PURPOSE
        Inventories the classification levers (sensitivity labels, sensitive information types), the DLP
        policies/rules (flagging any already scoped to a Copilot/AI location), and existing Communication
        Compliance policies — the baseline the AI governance policy will build on. Read-only.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell:
          Connect-IPPSSession
          .\AIPROMPT-Discovery.ps1
    EXPECTED RESULTS
        AI-Governance-Config-Estate-Discovery.csv listing labels, SITs, DLP policies/rules, and Communication
        Compliance policies. A thin taxonomy or no Copilot-scoped DLP is itself the first finding.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored.
    VERIFY IN YOUR TENANT: a "Copilot/AI location" on a DLP policy is detected heuristically here (locations
    surfaced by the cmdlet evolve); confirm the actual Copilot location in Purview -> DLP.
#>
[CmdletBinding()]
param(
    [string]$OutPath = ".\AI-Governance-Config-Estate-Discovery.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== AIPROMPT Discovery — AI governance config inventory (read-only) ===" -ForegroundColor Cyan
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    Write-Host "Security & Compliance PowerShell not available. Run Connect-IPPSSession first." -ForegroundColor Red
    return
}
$rows = New-Object System.Collections.Generic.List[object]
function Add-Row($type, $name, $detail) {
    $rows.Add([pscustomobject]@{ ItemType = $type; Name = $name; Detail = $detail })
}

# --- Sensitivity labels ---
Write-Host "`n[1/4] Sensitivity labels..." -ForegroundColor Cyan
try { foreach ($l in @(Get-Label -ErrorAction SilentlyContinue)) { Add-Row "SensitivityLabel" $l.DisplayName ("Priority={0}; Guid={1}" -f $l.Priority, $l.Guid) } }
catch { Write-Host "  Labels not readable (licensing/role?): $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Sensitive information types (levers the AI DLP/CC policy will match) ---
Write-Host "[2/4] Sensitive information types..." -ForegroundColor Cyan
try { foreach ($s in @(Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue)) { Add-Row "SensitiveInfoType" $s.Name ("Publisher={0}" -f $s.Publisher) } }
catch { Write-Host "  SITs not readable: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- DLP policies/rules (flag Copilot/AI-scoped) ---
Write-Host "[3/4] DLP policies/rules..." -ForegroundColor Cyan
try {
    foreach ($p in @(Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
        $aiHint = if ("$($p.Name) $($p.Comment) $($p.Workload)" -match "(?i)copilot|(\bAI\b)") { "COPILOT/AI-HINT" } else { "" }
        Add-Row "DlpPolicy" $p.Name ("Mode={0}; Enabled={1}; Workload={2} {3}" -f $p.Mode, $p.Enabled, $p.Workload, $aiHint)
    }
    foreach ($r in @(Get-DlpComplianceRule -ErrorAction SilentlyContinue)) {
        Add-Row "DlpRule" $r.Name ("Policy={0}; Disabled={1}" -f $r.Policy, $r.Disabled)
    }
} catch { Write-Host "  DLP not readable: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Communication Compliance policies ---
Write-Host "[4/4] Communication Compliance policies..." -ForegroundColor Cyan
if (Get-Command Get-SupervisoryReviewPolicyV2 -ErrorAction SilentlyContinue) {
    try { foreach ($c in @(Get-SupervisoryReviewPolicyV2 -ErrorAction SilentlyContinue)) { Add-Row "CommCompliancePolicy" $c.Name ("Reviewers configured; confirm Copilot/AI source + anonymization in portal") } }
    catch { Write-Host "  Communication Compliance not readable: $($_.Exception.Message)" -ForegroundColor Yellow }
} else {
    Write-Host "  Get-SupervisoryReviewPolicyV2 not available — check licensing/role (Req 2.4)." -ForegroundColor Yellow
}

$rows | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8
Write-Host ("`n{0} config item(s) -> {1}  (AI Governance Config - Estate - Discovery)" -f $rows.Count, $OutPath) -ForegroundColor Green
Write-Host "Next: baseline AI usage with AIPROMPT-Monitor.ps1." -ForegroundColor Cyan

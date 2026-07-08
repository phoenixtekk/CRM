<#
.SYNOPSIS
    IPASSESS-ScopeHealth.ps1 — confirm sessions and report which information-protection capabilities are readable (read-only).
.DESCRIPTION
    PURPOSE
        Scope/health helper for the Information Protection Assessment. Confirms the Security & Compliance
        PowerShell session (Connect-IPPSSession) and, optionally, Microsoft Graph, then probes which
        posture capabilities are actually READABLE in this tenant — sensitivity labels, label policies,
        DLP, auto-labeling, and sensitive information types. Licensing-gated capabilities (auto-labeling,
        advanced DLP) that cannot be read are reported as "not available — verify your licensing/tenant"
        rather than assumed present or absent. Makes no changes.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\IPASSESS-ScopeHealth.ps1
          .\IPASSESS-ScopeHealth.ps1 -CheckGraph      # also verify Connect-MgGraph for the pilot group
    EXPECTED RESULTS
        A readiness line per capability (READABLE / NOT AVAILABLE) so you know which of the six posture
        dimensions the assessment can score before you run IPASSESS-Discovery.ps1. A "not available" line
        is a valid finding (licensing), not a script failure.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. Cmdlets are standard Security
    & Compliance PowerShell / Microsoft Graph; none are invented. Feature availability is licensing-
    dependent — the script reports readability, it does not assert a capability exists.
#>
[CmdletBinding()]
param(
    [switch]$CheckGraph
)

$ErrorActionPreference = "Stop"
Write-Host "=== IPASSESS Scope/Health — information-protection readability (read-only) ===" -ForegroundColor Cyan

# --- Security & Compliance PowerShell session ---
Write-Host "`n-- Security & Compliance PowerShell session --" -ForegroundColor Cyan
try {
    Get-Label -ErrorAction Stop | Out-Null
    Write-Host "  S&C session      : CONNECTED (Get-Label responded)" -ForegroundColor Green
} catch {
    Write-Host "  S&C session      : NOT connected — run Connect-IPPSSession first (GR §3)." -ForegroundColor Red
    return
}

# --- Capability readability probe (each maps to a posture dimension) ---
Write-Host "`n-- Capability readability (posture dimensions) --" -ForegroundColor Cyan
function Test-Capability([string]$label, [scriptblock]$probe, [string]$note) {
    try {
        $n = @(& $probe).Count
        Write-Host ("  {0,-22}: READABLE ({1} object(s))" -f $label, $n) -ForegroundColor Green
    } catch {
        Write-Host ("  {0,-22}: NOT AVAILABLE — {1}" -f $label, $note) -ForegroundColor Yellow
    }
}

Test-Capability "Sensitivity labels"   { Get-Label -ErrorAction Stop }                     "verify your licensing/tenant (labels)"
Test-Capability "Label policies"        { Get-LabelPolicy -ErrorAction Stop }               "verify your licensing/tenant (publishing)"
Test-Capability "DLP policies"          { Get-DlpCompliancePolicy -ErrorAction Stop }       "verify your licensing/tenant (DLP)"
Test-Capability "DLP rules"             { Get-DlpComplianceRule -ErrorAction Stop }         "verify your licensing/tenant (DLP rules)"
Test-Capability "Auto-labeling"         { Get-AutoSensitivityLabelPolicy -ErrorAction Stop } "E5/E5 Compliance — verify your licensing/tenant (auto-labeling)"
Test-Capability "Sensitive info types"  { Get-DlpSensitiveInformationType -ErrorAction Stop } "verify your licensing/tenant (SITs)"

# --- Optional: Microsoft Graph (only needed to pilot a label publish to a pilot group) ---
if ($CheckGraph) {
    Write-Host "`n-- Microsoft Graph session (optional, for pilot group) --" -ForegroundColor Cyan
    try {
        if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
            Write-Host "  Graph module     : not installed — Install-Module Microsoft.Graph -Scope CurrentUser." -ForegroundColor Yellow
        } else {
            Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
            $ctx = Get-MgContext
            if ($ctx) { Write-Host ("  Graph session    : CONNECTED as {0}" -f $ctx.Account) -ForegroundColor Green }
            else      { Write-Host "  Graph session    : not connected — run Connect-MgGraph -Scopes 'Group.Read.All' if you will pilot a label publish." -ForegroundColor Yellow }
        }
    } catch {
        Write-Host "  Graph session    : unable to verify Graph context." -ForegroundColor Yellow
    }
}

Write-Host "`nCapabilities marked NOT AVAILABLE are licensing-gated findings — record them, do not assume the feature exists." -ForegroundColor DarkGray
Write-Host "Next: run IPASSESS-Discovery.ps1 to inventory the information-protection estate." -ForegroundColor Cyan

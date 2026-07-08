<#
.SYNOPSIS
    CMPHIPAA-Validation.ps1 — validate the underlying technical safeguards behind the mapped HIPAA actions
    (read-only).
.DESCRIPTION
    PURPOSE
        Read-only check of the Microsoft 365 technical signals that back the safeguard-mapped improvement
        actions, so you know which can auto-pass in Compliance Manager and which need manual evidence:
        unified audit ingestion (§164.312(b)), DLP / retention / sensitivity-label presence for ePHI
        (§164.308(a)(4), §164.312(a),(c),(e)), and Conditional Access / MFA (§164.312(a),(d), via Graph).
        Confirms present-vs-absent; it does NOT judge adequacy — that is a compliance/privacy/legal call.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPHIPAA-Validation.ps1
        PowerShell 5.1+ / 7+. Requires ExchangeOnlineManagement (Connect-IPPSSession) and, for the
        Conditional Access section, Microsoft.Graph with delegated Policy.Read.All. Interactive modern-auth
        sign-in; no secrets in code. Use -SkipGraphCA to skip the Conditional Access section.
    EXPECTED RESULTS
        A PASS/REVIEW line per safeguard signal: audit ingestion ON = PASS; >=1 DLP / retention / label
        policy present = REVIEW (confirm one targets ePHI); >=1 enabled Conditional Access policy = REVIEW.
        Absent signals are reported so the matching action is NOT marked implemented without proof.
.NOTES
    Purview category — HIPAA compliance program. Read-only. Presence != adequacy; whether a control
    satisfies a HIPAA safeguard is a compliance/privacy/legal determination. Feature availability is
    licensing-/tenant-dependent — verify against your entitlements.
#>
[CmdletBinding()]
param(
    [string]$UserPrincipalName,
    [switch]$SkipGraphCA           # skip the Conditional Access / MFA section if Graph is unavailable
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Pass($m){ Write-Host "PASS   $m" -ForegroundColor Green }
function Review($m){ Write-Host "REVIEW $m" -ForegroundColor Yellow }
function Absent($m){ Write-Host "ABSENT $m" -ForegroundColor Red }
function Info($m){ Write-Host $m -ForegroundColor Gray }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Review "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser"; return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$connectParams = @{ ShowBanner = $false }
if ($UserPrincipalName) { $connectParams['UserPrincipalName'] = $UserPrincipalName }
try { Connect-IPPSSession @connectParams -ErrorAction Stop | Out-Null }
catch { Review "Connect-IPPSSession failed: $($_.Exception.Message)"; return }

Write-Section "§164.312(b) Audit controls — unified audit log ingestion"
try {
    $cfg = Get-AdminAuditLogConfig -ErrorAction Stop
    if ($cfg.UnifiedAuditLogIngestionEnabled) { Pass "Unified audit log ingestion is ON — audit-controls action can auto-pass." }
    else { Absent "Unified audit log ingestion is OFF — do NOT mark §164.312(b) implemented. Enable in its own solution/change control (not retroactive)." }
} catch { Review "Could not read AdminAuditLogConfig: $($_.Exception.Message)" }

Write-Section "§164.308(a)(4)/§164.312(a),(e) Access & transmission — DLP for ePHI"
try {
    $dlp = @(Get-DlpCompliancePolicy -ErrorAction Stop)
    if ($dlp.Count -gt 0) {
        Review ("{0} DLP policy(ies) present. Confirm at least one targets ePHI (U.S. health SITs) and its mode (Test vs Enforce)." -f $dlp.Count)
        $dlp | Select-Object Name, Mode, Enabled | Format-Table -AutoSize | Out-String | Write-Host
    } else { Absent "No DLP policies found — ePHI access/transmission evidence is absent." }
} catch { Review "Could not enumerate DLP policies: $($_.Exception.Message)" }

Write-Section "§164.312(c)/§164.308(a)(7) Integrity & contingency — retention"
try {
    $ret = @(Get-RetentionCompliancePolicy -ErrorAction Stop)
    if ($ret.Count -gt 0) { Review ("{0} retention policy(ies) present. Confirm coverage of ePHI-bearing workloads (records/retention schedule is a records/legal determination)." -f $ret.Count) }
    else { Absent "No retention policies found — integrity/contingency evidence is absent." }
} catch { Review "Could not enumerate retention policies: $($_.Exception.Message)" }

Write-Section "§164.312(a),(e) Access & transmission — sensitivity labels"
try {
    $labels = @(Get-Label -ErrorAction Stop)
    if ($labels.Count -gt 0) { Review ("{0} sensitivity label(s) present. Confirm an ePHI/confidential label with encryption is published." -f $labels.Count) }
    else { Absent "No sensitivity labels found — label-based access/transmission evidence is absent." }
} catch { Review "Could not enumerate sensitivity labels: $($_.Exception.Message)" }

if (-not $SkipGraphCA) {
    Write-Section "§164.312(a),(d) Access control & authentication — Conditional Access / MFA (Graph)"
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Review "Microsoft.Graph not installed — skipping CA section. Install-Module Microsoft.Graph -Scope CurrentUser (or re-run with -SkipGraphCA)."
    } else {
        try {
            Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
            Connect-MgGraph -Scopes 'Policy.Read.All' -NoWelcome -ErrorAction Stop
            $ca = Invoke-MgGraphRequest -Method GET -Uri 'v1.0/identity/conditionalAccess/policies' -ErrorAction Stop
            $policies = @($ca.value)
            $enabled = @($policies | Where-Object { $_.state -eq 'enabled' })
            if ($enabled.Count -gt 0) { Review ("{0} enabled Conditional Access policy(ies) of {1} total. Confirm one enforces MFA for ePHI access." -f $enabled.Count, $policies.Count) }
            elseif ($policies.Count -gt 0) { Absent ("{0} CA policy(ies) exist but NONE are enabled — access-control/authentication evidence is absent." -f $policies.Count) }
            else { Absent "No Conditional Access policies found — access-control/authentication evidence is absent." }
        } catch { Review "Conditional Access check failed (need Policy.Read.All): $($_.Exception.Message)" }
    }
}

Write-Section "Done"
Info "Read-only. Presence != adequacy. Map each PASS/REVIEW to its action's test status in the portal; do not mark a safeguard implemented on an ABSENT signal."

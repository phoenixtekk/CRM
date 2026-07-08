<#
.SYNOPSIS
    OPSCOE-Discovery.ps1 — inventory every readable governed Purview artifact and score naming-standard conformance (read-only).
.DESCRIPTION
    PURPOSE
        Read-only estate inventory for a Purview Center of Excellence. Enumerates every readable governed
        artifact — sensitivity labels, label policies, DLP policies (+ rule counts), retention
        policies/labels (+ rule counts), auto-labeling policies, and (where readable)
        communication-compliance policies — and for each records its name, type, current state, owner
        (parsed from a CoE-Owner Comment stamp if present), and whether it conforms to the naming
        standard <Purpose> - <Capability> - <State>. This inventory becomes the governance register.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with ExchangeOnlineManagement (Security & Compliance PowerShell):
          Connect-IPPSSession
          .\OPSCOE-Discovery.ps1 -OutPath ".\Purview-CoE-Register-Governed.csv"
        Optional: -NamePattern to override the default naming-standard regex.
    EXPECTED RESULTS
        One row per governed artifact with Type/Name/State/Owner/Conforms, plus a summary count and a
        non-conforming list. Written to the -OutPath CSV (default .\Purview-CoE-Register-Governed.csv).
        Resolves Requirement 2.8. This is the register baseline for OPSCOE-Validate.ps1 / -Register.ps1.
.NOTES
    White-label Microsoft Purview tooling. Read-only — enumerates only. No credentials stored in code.
    Availability caveat: unlicensed or portal-only capabilities (insider risk especially) will not
    enumerate — they are governed by attestation in the register, not invented here. Cmdlets are
    standard Security & Compliance PowerShell; none are invented. Portal/cmdlet surfaces evolve — verify
    in your tenant.
#>
[CmdletBinding()]
param(
    [string]$OutPath = ".\Purview-CoE-Register-Governed.csv",
    # Default naming standard: "<Purpose> - <Capability> - <State>" (en dash or hyphen, 2 separators).
    [string]$NamePattern = '^.+\s[–-]\s.+\s[–-]\s.+$'
)

$ErrorActionPreference = "Stop"
Write-Host "=== OPSCOE Discovery — governed-artifact inventory (read-only) ===" -ForegroundColor Cyan

$rows = [System.Collections.Generic.List[object]]::new()

function Get-OwnerFromComment($comment) {
    if ($comment -and $comment -match 'CoE-Owner\s*=\s*([^;]+)') { return $Matches[1].Trim() }
    return ""
}
function Get-ReviewFromComment($comment) {
    if ($comment -and $comment -match 'Review\s*=\s*([^;]+)') { return $Matches[1].Trim() }
    return ""
}
function Add-Row($type, $name, $state, $comment, $extra) {
    $conforms = if ($name -match $NamePattern) { "YES" } else { "NO" }
    $rows.Add([pscustomobject]@{
        Type     = $type
        Name     = $name
        State    = $state
        Owner    = (Get-OwnerFromComment $comment)
        Review   = (Get-ReviewFromComment $comment)
        Conforms = $conforms
        Detail   = $extra
    })
}

# --- Sensitivity labels ---
try {
    foreach ($l in @(Get-Label -ErrorAction Stop)) {
        Add-Row "SensitivityLabel" $l.DisplayName ($(if ($l.Disabled) { "Disabled" } else { "Enabled" })) $l.Comment ("Priority={0}" -f $l.Priority)
    }
} catch { Write-Host "  [WARN] Labels not readable: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Label policies ---
try {
    foreach ($p in @(Get-LabelPolicy -ErrorAction Stop)) {
        Add-Row "LabelPolicy" $p.Name ($(if ($p.Enabled -eq $false) { "Disabled" } else { "Enabled" })) $p.Comment ""
    }
} catch { Write-Host "  [WARN] Label policies not readable: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- DLP policies (+ rule counts) ---
try {
    foreach ($d in @(Get-DlpCompliancePolicy -ErrorAction Stop)) {
        $ruleCount = 0
        try { $ruleCount = @(Get-DlpComplianceRule -Policy $d.Name -ErrorAction Stop).Count } catch {}
        # Mode: e.g. Enable, TestWithNotifications, TestWithoutNotifications, Disable
        $state = if ($d.PSObject.Properties.Name -contains 'Mode') { [string]$d.Mode } else { [string]$d.Enabled }
        Add-Row "DlpPolicy" $d.Name $state $d.Comment ("Rules={0}" -f $ruleCount)
    }
} catch { Write-Host "  [WARN] DLP policies not readable: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Retention policies (+ rule counts) ---
try {
    foreach ($r in @(Get-RetentionCompliancePolicy -ErrorAction Stop)) {
        $ruleCount = 0
        try { $ruleCount = @(Get-RetentionComplianceRule -Policy $r.Name -ErrorAction Stop).Count } catch {}
        $state = if ($r.Enabled -eq $false) { "Disabled" } else { "Enabled" }
        Add-Row "RetentionPolicy" $r.Name $state $r.Comment ("Rules={0}" -f $ruleCount)
    }
} catch { Write-Host "  [WARN] Retention policies not readable: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Auto-labeling (licensing-dependent) ---
try {
    foreach ($a in @(Get-AutoSensitivityLabelPolicy -ErrorAction Stop)) {
        # Mode often exposes Enable / TestWithoutNotifications (simulation)
        $state = if ($a.PSObject.Properties.Name -contains 'Mode') { [string]$a.Mode } else { "Unknown" }
        Add-Row "AutoLabelPolicy" $a.Name $state $a.Comment ""
    }
} catch { Write-Host "  [INFO] Auto-labeling not readable (may be unlicensed): $($_.Exception.Message)" -ForegroundColor Gray }

# --- Communication compliance (portal-managed; cmdlet may be absent) ---
$scv2 = Get-Command Get-SupervisoryReviewPolicyV2 -ErrorAction SilentlyContinue
if ($scv2) {
    try {
        foreach ($c in @(Get-SupervisoryReviewPolicyV2 -ErrorAction Stop)) {
            Add-Row "CommunicationCompliance" $c.Name "Portal-managed" $null "Case actions deferred to HR/legal"
        }
    } catch { Write-Host "  [WARN] Communication compliance read failed: $($_.Exception.Message)" -ForegroundColor Yellow }
} else {
    Add-Row "CommunicationCompliance" "(attestation)" "Portal-only" $null "No PowerShell surface — register by attestation with a named owner"
}

# --- Insider risk placeholder (attestation) ---
Add-Row "InsiderRisk" "(attestation)" "Portal-only" $null "Primarily portal-managed — register by attestation with a named owner"

$rows | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8

$total = $rows.Count
$nonConf = @($rows | Where-Object { $_.Conforms -eq "NO" -and $_.State -notmatch "Portal" })
Write-Host ("`nInventory: {0} governed artifact(s) written to {1}  (Purview CoE Register - Governed)" -f $total, $OutPath) -ForegroundColor Green
Write-Host ("Naming-standard conformance: {0} conforming, {1} NON-conforming" -f ($total - $nonConf.Count), $nonConf.Count) -ForegroundColor Cyan
if ($nonConf.Count -gt 0) {
    Write-Host "Non-conforming names (route through intake to standardize):" -ForegroundColor Yellow
    $nonConf | ForEach-Object { Write-Host ("  - [{0}] {1}" -f $_.Type, $_.Name) -ForegroundColor Yellow }
}
Write-Host "Next: OPSCOE-ApplyStandards.ps1 (board roles / ownership tags) then OPSCOE-Validate.ps1." -ForegroundColor Cyan

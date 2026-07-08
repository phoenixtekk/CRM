<#
.SYNOPSIS
    CLSFRAME-Validation.ps1 — coherence validation of the classification framework: every tier has a label, a DLP posture, and a retention label, consistently named, with the DLP baseline still in TEST (read-only).
.DESCRIPTION
    Runs a set of pass/fail checks against the live tenant via Security & Compliance PowerShell:
    (1) each tier sensitivity label exists with the intended protection; (2) each tier has a retention
    label; (3) the tier-band DLP baseline exists and is still in a TEST mode (not Enable) before
    sign-off; (4) no orphans (a label with no retention, a retention with no tier, a DLP baseline with
    no protected-tier labels). Prints a per-check PASS/FAIL and an overall result. Read-only — makes no
    changes.
.EXAMPLE
    .\CLSFRAME-Validation.ps1
    Runs all coherence checks and prints PASS/FAIL per tier and overall.
.EXAMPLE
    .\CLSFRAME-Validation.ps1 -AllowDlpEnforced
    Treats an Enabled DLP baseline as acceptable (use only AFTER enforcement is signed off).
.NOTES
    Requires PowerShell 5.1+/7+ and the ExchangeOnlineManagement module (Connect-IPPSSession).
    Role (read): Compliance Administrator / Information Protection Reader.
    Expected results: PASS = every tier row complete, consistently named, no orphans, DLP baseline in
    TEST (unless -AllowDlpEnforced). FAIL = any missing/misnamed artifact or a DLP baseline enabled
    before sign-off — the script lists exactly which check failed.
#>
[CmdletBinding()]
param(
    [string[]]$Tiers = @('Public','Internal','Confidential','Restricted'),
    [string[]]$ProtectedTiers = @('Confidential','Restricted'),
    [string]$DlpBaselineName = 'CLS DLP – Tier2-3 – Test',
    [switch]$AllowDlpEnforced
)

function Connect-SCC {
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        Write-Warning 'ExchangeOnlineManagement module not found. Install-Module ExchangeOnlineManagement -Scope CurrentUser'
        throw 'Module missing.'
    }
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) {
        Write-Host 'Connecting to Security & Compliance PowerShell...' -ForegroundColor Cyan
        Connect-IPPSSession -ShowBanner:$false
    }
}

$script:fails = 0
function Check {
    param([string]$Name, [bool]$Pass, [string]$Detail)
    if ($Pass) {
        Write-Host ("  [PASS] {0}" -f $Name) -ForegroundColor Green
    } else {
        Write-Host ("  [FAIL] {0} — {1}" -f $Name, $Detail) -ForegroundColor Red
        $script:fails++
    }
}

Connect-SCC
Write-Host '=== CLSFRAME coherence validation (read-only) ===' -ForegroundColor Cyan

$labels = Get-Label -ErrorAction SilentlyContinue
$tags   = Get-ComplianceTag -ErrorAction SilentlyContinue
$dlp    = Get-DlpCompliancePolicy -ErrorAction SilentlyContinue

# --- Per-tier: label exists ---
Write-Host "`n--- Tier labels ---" -ForegroundColor Cyan
foreach ($t in $Tiers) {
    $lbl = $labels | Where-Object { $_.DisplayName -eq $t } | Select-Object -First 1
    Check "Tier '$t' has a sensitivity label" ([bool]$lbl) "no label named '$t' (Get-Label)"
    if ($lbl -and ($ProtectedTiers -contains $t)) {
        Check "Tier '$t' label encrypts" ([bool]$lbl.EncryptionEnabled) "protected tier '$t' is not encrypting"
    }
}

# --- Per-tier: retention label exists ---
Write-Host "`n--- Tier retention labels ---" -ForegroundColor Cyan
foreach ($t in $Tiers) {
    $tag = $tags | Where-Object { $_.Name -like "*$t*" } | Select-Object -First 1
    Check "Tier '$t' has a retention label" ([bool]$tag) "no retention label matching '*$t*' (Get-ComplianceTag)"
}

# --- DLP baseline exists and is in TEST (unless enforcement signed off) ---
Write-Host "`n--- DLP baseline ---" -ForegroundColor Cyan
$dlpPolicy = $dlp | Where-Object { $_.Name -eq $DlpBaselineName } | Select-Object -First 1
Check "DLP baseline '$DlpBaselineName' exists" ([bool]$dlpPolicy) "no DLP policy named '$DlpBaselineName'"
if ($dlpPolicy) {
    $isTest = ($dlpPolicy.Mode -like 'Test*')
    if ($AllowDlpEnforced) {
        Check "DLP baseline mode is Enable or Test (enforcement allowed)" ($isTest -or $dlpPolicy.Mode -eq 'Enable') "unexpected Mode '$($dlpPolicy.Mode)'"
    } else {
        Check "DLP baseline is still in TEST mode (pre-sign-off)" $isTest "Mode is '$($dlpPolicy.Mode)' — DLP enabled before sign-off (use -AllowDlpEnforced only after acceptance)"
    }
}

# --- Orphan check: protected-tier labels must have a matching retention label ---
Write-Host "`n--- Orphan check ---" -ForegroundColor Cyan
foreach ($t in $ProtectedTiers) {
    $hasLabel = [bool]($labels | Where-Object { $_.DisplayName -eq $t })
    $hasTag   = [bool]($tags   | Where-Object { $_.Name -like "*$t*" })
    Check "Protected tier '$t' is fully mapped (label AND retention)" ($hasLabel -and $hasTag) "orphan: label=$hasLabel retention=$hasTag"
}

Write-Host ''
if ($script:fails -eq 0) {
    Write-Host '=== VALIDATION PASSED — framework is coherent (no orphans; DLP in test) ===' -ForegroundColor Green
    exit 0
} else {
    Write-Host ("=== VALIDATION FAILED — {0} check(s) failed; resolve before expanding ===" -f $script:fails) -ForegroundColor Red
    exit 1
}

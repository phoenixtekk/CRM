<#
.SYNOPSIS
    CLSFINGER-CreateFingerprint.ps1 — build a document fingerprint from a template and create/update the fingerprint SIT (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Creates a document fingerprint from a text-based form template (New-DlpFingerprint) and creates a new
        fingerprint sensitive information type, or ADDS the fingerprint to an existing one
        (New-/Set-DlpSensitiveInformationType). SAFE BY DEFAULT: with no -Commit it only reports what it
        WOULD do (-WhatIf). It never creates, modifies, or enforces a DLP policy. Use for both first-time
        fingerprinting and form-version refresh (add the revised template's fingerprint to the same SIT).
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession -UserPrincipalName admin@contoso.com
          # Preview (default, no change):
          .\CLSFINGER-CreateFingerprint.ps1 -TemplatePath .\Onboarding-Template.docx -SitName "Standard Forms - Fingerprint SIT - Classification"
          # Actually create/update the SIT:
          .\CLSFINGER-CreateFingerprint.ps1 -TemplatePath .\Onboarding-Template.docx -SitName "Standard Forms - Fingerprint SIT - Classification" -Commit
    EXPECTED RESULTS
        Without -Commit: prints the fingerprint description and whether the SIT would be created or updated.
        With -Commit: the fingerprint SIT exists / carries the new fingerprint (confirm with
        CLSFINGER-Validation.ps1). Non-text/image-only/oversized templates yield a poor or failed fingerprint
        — the script validates the file exists and warns.
.NOTES
    White-label Microsoft Purview tooling. -WhatIf by default; writes require -Commit. No credentials stored.
    Cmdlets (New-DlpFingerprint, New-/Set-/Get-DlpSensitiveInformationType) are standard Security & Compliance
    PowerShell; none are invented. Supported file types/size limits are licensing-/tenant-dependent — verify
    current limits for your tenant.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$TemplatePath,
    [Parameter(Mandatory = $true)][string]$SitName,
    [string]$FingerprintDescription,
    [string]$SitDescription = "Detects standard forms/templates via document fingerprinting.",
    [switch]$Commit
)

$ErrorActionPreference = "Stop"
$mode = if ($Commit) { "COMMIT (writes enabled)" } else { "WHATIF (no changes)" }
Write-Host "=== CLSFINGER Create Fingerprint — $mode ===" -ForegroundColor Cyan

# --- Validate the template file ---
if (-not (Test-Path -LiteralPath $TemplatePath)) {
    Write-Host "Template not found: $TemplatePath" -ForegroundColor Red; return
}
$file = Get-Item -LiteralPath $TemplatePath
Write-Host ("  Template: {0} ({1:N0} bytes)" -f $file.Name, $file.Length) -ForegroundColor Green
if ($file.Length -eq 0) { Write-Host "  ERROR: file is empty — cannot fingerprint." -ForegroundColor Red; return }
if ($file.Extension -notmatch '(?i)\.(docx|dotx|pdf|txt|rtf|xlsx|pptx)$') {
    Write-Host "  WARN: extension '$($file.Extension)' may not be a supported/text-based type — verify current supported types for your tenant. Image-only or password-protected files cannot be fingerprinted." -ForegroundColor Yellow
}
if (-not $FingerprintDescription) { $FingerprintDescription = "$($file.BaseName) - Fingerprint - Source" }

# --- Connection check ---
try { Get-DlpSensitiveInformationType -ErrorAction Stop | Out-Null }
catch { Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR #3)." -ForegroundColor Red; return }

# --- Does the SIT already exist? (refresh vs create) ---
$existing = $null
try { $existing = Get-DlpSensitiveInformationType -Identity $SitName -ErrorAction Stop } catch { $existing = $null }
$action = if ($existing) { "UPDATE (add fingerprint to existing SIT)" } else { "CREATE (new fingerprint SIT)" }
Write-Host ("  Fingerprint desc : {0}" -f $FingerprintDescription) -ForegroundColor Green
Write-Host ("  Target SIT       : {0}" -f $SitName) -ForegroundColor Green
Write-Host ("  Planned action   : {0}" -f $action) -ForegroundColor Green

if (-not $Commit) {
    Write-Host "`n[WHATIF] Would read the template bytes, build a fingerprint via New-DlpFingerprint, and $action." -ForegroundColor Yellow
    Write-Host "[WHATIF] Re-run with -Commit to apply. No DLP policy is touched by this script." -ForegroundColor Yellow
    return
}

# --- Read template bytes (PS 5.1 uses -Encoding Byte; PS 7 uses -AsByteStream) ---
try {
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        $bytes = Get-Content -LiteralPath $TemplatePath -AsByteStream -ReadCount 0
    } else {
        $bytes = Get-Content -LiteralPath $TemplatePath -Encoding Byte -ReadCount 0
    }
} catch { Write-Host "  ERROR reading template bytes: $($_.Exception.Message)" -ForegroundColor Red; return }

# --- Build the fingerprint ---
try {
    $fp = New-DlpFingerprint -FileData $bytes -Description $FingerprintDescription -ErrorAction Stop
    Write-Host "  Fingerprint built." -ForegroundColor Green
} catch { Write-Host "  ERROR: New-DlpFingerprint failed: $($_.Exception.Message)" -ForegroundColor Red; return }

# --- Create or update the SIT ---
try {
    if ($existing) {
        $current = @()
        if ($existing.Fingerprints) { $current = @($existing.Fingerprints) }
        Set-DlpSensitiveInformationType -Identity $SitName -Fingerprints ($current + $fp) -ErrorAction Stop | Out-Null
        Write-Host "  SIT updated: fingerprint added to '$SitName'." -ForegroundColor Green
    } else {
        New-DlpSensitiveInformationType -Name $SitName -Fingerprints $fp -Description $SitDescription -ErrorAction Stop | Out-Null
        Write-Host "  SIT created: '$SitName'." -ForegroundColor Green
    }
} catch { Write-Host "  ERROR creating/updating SIT: $($_.Exception.Message)" -ForegroundColor Red; return }

Write-Host "`nDone. Next: reference '$SitName' in a DLP policy IN SIMULATION, then run CLSFINGER-Validation.ps1." -ForegroundColor Cyan

<#
.SYNOPSIS
    CLSFINGER-Set-Scope.ps1 — report and (with -Commit) adjust a DLP policy's included/excluded scope, e.g. the pilot ring (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Scope and health helper for the fingerprint DLP policy. Read path: reports the target policy's mode
        and current Exchange included/excluded scope, and the health of the referenced fingerprint SIT.
        Write path (only with -Commit): sets the policy's INCLUDED distribution group (the pilot ring) and/or
        EXCLUDED group for the Exchange location, so enforcement can be constrained to a ring before
        expansion. SAFE BY DEFAULT: without -Commit it only previews (-WhatIf). It does NOT change a policy's
        enforce/simulation MODE — that transition stays a deliberate portal action (Impl. Phase 5).
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession -UserPrincipalName admin@contoso.com
          # Report only:
          .\CLSFINGER-Set-Scope.ps1 -PolicyName "DLP - Fingerprinted Forms - Simulation"
          # Preview scoping to the pilot ring (no change):
          .\CLSFINGER-Set-Scope.ps1 -PolicyName "DLP - Fingerprinted Forms - Simulation" -IncludeGroup "Fingerprint Pilot Ring - Stage1"
          # Apply:
          .\CLSFINGER-Set-Scope.ps1 -PolicyName "DLP - Fingerprinted Forms - Simulation" -IncludeGroup "Fingerprint Pilot Ring - Stage1" -Commit
    EXPECTED RESULTS
        Report: current mode + scope printed. Preview: prints the Set-DlpCompliancePolicy call that WOULD run.
        Commit: the policy's Exchange included/excluded scope is updated (confirm with CLSFINGER-Validation.ps1
        / portal). Mode is never changed by this script.
.NOTES
    White-label Microsoft Purview tooling. -WhatIf by default; writes require -Commit. No credentials stored.
    Cmdlets (Get-/Set-DlpCompliancePolicy, Get-DlpSensitiveInformationType) are standard Security & Compliance
    PowerShell; none are invented. Scope parameters shown apply to the Exchange location; other locations are
    scoped by their own site/account parameters — verify against your tenant.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PolicyName,
    [string]$IncludeGroup,
    [string]$ExcludeGroup,
    [string]$SitName,
    [switch]$Commit
)

$ErrorActionPreference = "Stop"
$mode = if ($Commit) { "COMMIT (writes enabled)" } else { "WHATIF (no changes)" }
Write-Host "=== CLSFINGER Set-Scope — $mode ===" -ForegroundColor Cyan

try { Get-DlpCompliancePolicy -ErrorAction Stop | Out-Null }
catch { Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR #3)." -ForegroundColor Red; return }

# --- Read the policy ---
$pol = $null
try { $pol = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction Stop } catch { $pol = $null }
if (-not $pol) { Write-Host "Policy '$PolicyName' not found." -ForegroundColor Red; return }

Write-Host ("  Policy   : {0}" -f $pol.Name) -ForegroundColor Green
Write-Host ("  Mode     : {0}  (this script never changes mode)" -f $pol.Mode) -ForegroundColor Green
Write-Host ("  Included : {0}" -f (($pol.ExchangeSenderMemberOf) -join '; ')) -ForegroundColor Green
Write-Host ("  Excluded : {0}" -f (($pol.ExchangeSenderMemberOfException) -join '; ')) -ForegroundColor Green

# --- Optional SIT health ---
if ($SitName) {
    try {
        $sit = Get-DlpSensitiveInformationType -Identity $SitName -ErrorAction Stop
        Write-Host ("  SIT      : '{0}' exists (Publisher={1})." -f $sit.Name, $sit.Publisher) -ForegroundColor Green
    } catch { Write-Host "  WARN: fingerprint SIT '$SitName' not found — create it with CLSFINGER-CreateFingerprint.ps1." -ForegroundColor Yellow }
}

if (-not $IncludeGroup -and -not $ExcludeGroup) {
    Write-Host "`nReport only (no -IncludeGroup/-ExcludeGroup supplied). Nothing to change." -ForegroundColor Cyan
    return
}

# --- Build the intended change ---
$set = @{ Identity = $PolicyName }
if ($IncludeGroup) { $set["ExchangeSenderMemberOf"] = $IncludeGroup }
if ($ExcludeGroup) { $set["ExchangeSenderMemberOfException"] = $ExcludeGroup }

$desc = ($set.GetEnumerator() | Where-Object { $_.Key -ne 'Identity' } | ForEach-Object { "$($_.Key)='$($_.Value)'" }) -join ', '
if (-not $Commit) {
    Write-Host "`n[WHATIF] Would run: Set-DlpCompliancePolicy -Identity '$PolicyName' $desc" -ForegroundColor Yellow
    Write-Host "[WHATIF] Re-run with -Commit to apply. Mode is not changed." -ForegroundColor Yellow
    return
}

try {
    Set-DlpCompliancePolicy @set -ErrorAction Stop
    Write-Host "`n  Applied: $desc" -ForegroundColor Green
    Write-Host "  Confirm with CLSFINGER-Validation.ps1 / the Purview portal. Mode unchanged." -ForegroundColor Cyan
} catch { Write-Host "  ERROR applying scope: $($_.Exception.Message)" -ForegroundColor Red }

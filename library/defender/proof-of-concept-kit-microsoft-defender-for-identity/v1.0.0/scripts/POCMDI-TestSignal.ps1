<#
.SYNOPSIS
    POCMDI-TestSignal.ps1 — generate BENIGN, simulated identity test signal for the MDI PoC. Safe only.
.DESCRIPTION
    PURPOSE
        Produces harmless, READ-ONLY identity signal so the MDI detection pipeline has something to
        catch. Run this from a domain-joined TEST WORKSTATION signed in as a TEST ACCOUNT. It:
          1. Runs benign directory enumeration (net group / net user / nltest / an LDAP read) — the
             same commands admins run daily. MDI flags the reconnaissance PATTERN; nothing is changed.
          2. Touches the honeytoken decoy account with a benign lookup so that clean, high-fidelity
             signal is raised.
        NO attack tooling, credential dumping, exploitation, or AD modification is ever performed.
        -WhatIf shows what it would run without running it.
    HOW TO RUN
        # Preview:
        powershell -ExecutionPolicy Bypass -File .\POCMDI-TestSignal.ps1 -WhatIf
        # Generate benign signal (run on the test workstation as the test account):
        powershell -ExecutionPolicy Bypass -File .\POCMDI-TestSignal.ps1 -HoneytokenSam "mdi-poc-honeytoken"
    EXPECTED RESULTS
        Reconnaissance and honeytoken detections appear in MDI for the PoC to validate.
.NOTES
    White-label. BENIGN, READ-ONLY signal only (enumeration + honeytoken lookup). Never real attacks.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$HoneytokenSam,
    [string]$Tag = 'MDI-PoC-TESTSIGNAL'
)

Write-Host "`n=== POCMDI — benign test signal ($Tag) ===" -ForegroundColor Cyan
Write-Host "SAFE ONLY: read-only directory enumeration + a honeytoken lookup. No attack tooling, no AD changes." -ForegroundColor Yellow

# Benign, read-only enumeration commands (the recon PATTERN is what MDI detects).
$recon = @(
    @{ Desc = 'Enumerate Domain Admins group'; Cmd = { net group "Domain Admins" /domain } },
    @{ Desc = 'Enumerate domain users';         Cmd = { net user /domain } },
    @{ Desc = 'Enumerate domain trusts';        Cmd = { nltest /domain_trusts } },
    @{ Desc = 'LDAP read of users (top 5)';     Cmd = {
        try {
            $searcher = New-Object DirectoryServices.DirectorySearcher
            $searcher.Filter = '(objectClass=user)'; $searcher.SizeLimit = 5
            $null = $searcher.FindAll()
            'LDAP read completed (5 objects)'
        } catch { "LDAP read skipped: $($_.Exception.Message)" }
      } }
)

foreach ($r in $recon) {
    if ($PSCmdlet.ShouldProcess($r.Desc, "Run benign read-only enumeration")) {
        Write-Host "`n  > $($r.Desc)" -ForegroundColor Cyan
        try { & $r.Cmd 2>&1 | Select-Object -First 8 | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray } }
        catch { Write-Host "    (command unavailable: $($_.Exception.Message))" -ForegroundColor Yellow }
    } else {
        Write-Host "  [WhatIf] Would run: $($r.Desc)" -ForegroundColor Yellow
    }
}

# Benign honeytoken lookup.
Write-Host "`n[Honeytoken benign touch]" -ForegroundColor Cyan
if ($HoneytokenSam) {
    if ($PSCmdlet.ShouldProcess($HoneytokenSam, "Benign read-only lookup of the honeytoken account")) {
        try {
            $s = New-Object DirectoryServices.DirectorySearcher
            $s.Filter = "(sAMAccountName=$HoneytokenSam)"
            $found = $s.FindOne()
            if ($found) { Write-Host "  Looked up honeytoken '$HoneytokenSam' (benign). Any touch of a decoy is a clean detection." -ForegroundColor Green }
            else { Write-Host "  Honeytoken '$HoneytokenSam' not found via LDAP — confirm the sAMAccountName." -ForegroundColor Yellow }
        } catch { Write-Host "  Honeytoken lookup skipped: $($_.Exception.Message)" -ForegroundColor Yellow }
    } else {
        Write-Host "  [WhatIf] Would perform a benign lookup of honeytoken '$HoneytokenSam'." -ForegroundColor Yellow
    }
} else {
    Write-Host "  Provide -HoneytokenSam <sAMAccountName> to touch the decoy account." -ForegroundColor Yellow
}

Write-Host ("`nSignal generated at: {0}  (record this for scorecard latency)." -f (Get-Date).ToString('u')) -ForegroundColor Cyan
Write-Host "Next: POCMDI-Validate.ps1" -ForegroundColor Cyan

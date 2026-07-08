<#
.SYNOPSIS
    DLPEXO-Report.ps1 — roll up Exchange DLP policy modes and rule-match / policy-tip / block events (Activity explorer export) read-only.
.DESCRIPTION
    PURPOSE
        Read-only operational + evidence report for Exchange Online DLP. Summarizes the DLP policies that cover
        the Exchange location and their mode (simulation vs enforce), and — where the tenant/licensing exposes
        it — exports recent DLP activity from Activity Explorer (rule matches, policy-tip shown, override, and
        block events) so you can see what the policy is recording. Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\DLPEXO-Report.ps1
          .\DLPEXO-Report.ps1 -Days 7
    EXPECTED RESULTS
        A console summary + .\DLPEXO-PolicyModes.csv (policies + mode + Exchange flag) and, where available,
        .\DLPEXO-Activity.csv (Activity Explorer DLP events). If activity export is not available in your
        tenant/licence, the script WARNS and reports policy modes only.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. Uses Get-DlpCompliancePolicy and
    Export-ActivityExplorerData (Security & Compliance PowerShell); none invented. Activity Explorer export is
    licensing-dependent — the script degrades gracefully (warns) rather than assuming availability. For DLP
    reports the Purview portal (Data loss prevention > Policy / Activity explorer) is the authoritative view.
#>
[CmdletBinding()]
param(
    [int]$Days = 7,
    [string]$ModesOutPath    = ".\DLPEXO-PolicyModes.csv",
    [string]$ActivityOutPath = ".\DLPEXO-Activity.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPEXO Report — Exchange DLP modes + activity (read-only) ===" -ForegroundColor Cyan

try { Get-DlpCompliancePolicy -ErrorAction Stop | Out-Null }
catch { Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR §3)." -ForegroundColor Red; return }

# --- Policy modes (which cover Exchange; simulation vs enforce) ---
$modeRows = [System.Collections.Generic.List[object]]::new()
try {
    $pols = Get-DlpCompliancePolicy -ErrorAction Stop
    foreach ($p in $pols) {
        $hasExchange = $false
        try { if ($p.ExchangeLocation -and @($p.ExchangeLocation).Count -gt 0) { $hasExchange = $true } } catch { }
        $modeRows.Add([pscustomobject]@{
            Policy          = $p.Name
            Mode            = "$($p.Mode)"
            ExchangeLocation= $hasExchange
            Enforcing       = ("$($p.Mode)" -eq "Enable")
        })
    }
    $modeRows | Export-Csv -Path $ModesOutPath -NoTypeInformation -Encoding UTF8
    Write-Host ("  Policies: {0}  (Exchange-location: {1}; enforcing: {2})" -f `
        @($modeRows).Count, @($modeRows | Where-Object ExchangeLocation).Count, @($modeRows | Where-Object Enforcing).Count) -ForegroundColor Green
    Write-Host ("  Policy modes written to {0}" -f $ModesOutPath) -ForegroundColor Green
    foreach ($m in ($modeRows | Where-Object ExchangeLocation)) {
        $col = if ($m.Enforcing) { "Yellow" } else { "Gray" }
        Write-Host ("    - {0,-24} Mode={1}" -f $m.Policy, $m.Mode) -ForegroundColor $col
    }
} catch { Write-Host "  WARN: could not read DLP policies: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- DLP activity via Activity Explorer export (licensing-dependent) ---
Write-Host "`n  Attempting Activity Explorer DLP-activity export (last $Days day(s))..." -ForegroundColor Cyan
try {
    $end   = (Get-Date)
    $start = $end.AddDays(-1 * [math]::Abs($Days))
    # Export-ActivityExplorerData returns classification/DLP activity; review for Exchange DLP events
    # (DLPRuleMatch, policy-tip shown, override, block).
    $data = Export-ActivityExplorerData -StartTime $start -EndTime $end -OutputFormat Json -PageSize 5000 -ErrorAction Stop
    $parsed = @()
    foreach ($d in $data) {
        try { $parsed += ($d | ConvertFrom-Json) } catch { $parsed += $d }
    }
    if (@($parsed).Count -gt 0) {
        $parsed | Export-Csv -Path $ActivityOutPath -NoTypeInformation -Encoding UTF8
        Write-Host ("  Activity rows exported: {0}  ->  {1}" -f @($parsed).Count, $ActivityOutPath) -ForegroundColor Green
        Write-Host "  Review for Exchange DLP events (rule match, policy tip shown, override with justification, block/encrypt)." -ForegroundColor Green
    } else {
        Write-Host "  No activity rows returned for the window (may be normal for a quiet pilot)." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  WARN: Activity Explorer export not available (licensing/permission/cmdlet): $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "        Fall back to Purview portal > Data loss prevention (Policy / Activity explorer) for Exchange DLP activity." -ForegroundColor Yellow
}

Write-Host "`nReport complete. Pair this with DLPEXO-Validate.ps1 for the configuration gates." -ForegroundColor Cyan

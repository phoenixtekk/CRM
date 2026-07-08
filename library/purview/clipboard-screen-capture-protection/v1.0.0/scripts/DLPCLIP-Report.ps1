<#
.SYNOPSIS
    DLPCLIP-Report.ps1 — roll up policy modes and export clipboard/screen-capture DLP match & block events to CSV (read-only).
.DESCRIPTION
    PURPOSE
        Read-only operational + evidence report for clipboard & screen-capture Endpoint DLP. Summarizes the DLP
        policies that cover the Devices location and their mode (simulation vs enforce), and — where the
        tenant/licensing exposes it — exports recent ENDPOINT activity from Activity Explorer filtered to
        copy-to-clipboard and screen-capture events (matches, audits, blocks, overrides) so you can measure
        volume and false positives. Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\DLPCLIP-Report.ps1
          .\DLPCLIP-Report.ps1 -Days 14
    EXPECTED RESULTS
        A console summary + .\DLPCLIP-PolicyModes.csv (policies + mode + Devices flag) and, where available,
        .\DLPCLIP-ClipScreenActivity.csv (clipboard/screen-capture endpoint events). If activity export is not
        available in your tenant/licence, the script WARNS and reports policy modes only.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. Uses Get-DlpCompliancePolicy and
    Export-ActivityExplorerData (Security & Compliance PowerShell); none invented. Activity Explorer export is
    licensing-dependent and screen-capture events are newer/preview — the script degrades gracefully (warns)
    rather than assuming availability. Verify your licensing/tenant.
#>
[CmdletBinding()]
param(
    [int]$Days = 14,
    [string]$ModesOutPath    = ".\DLPCLIP-PolicyModes.csv",
    [string]$ActivityOutPath = ".\DLPCLIP-ClipScreenActivity.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPCLIP Report — clipboard/screen-capture DLP modes + events (read-only) ===" -ForegroundColor Cyan

try { Get-DlpCompliancePolicy -ErrorAction Stop | Out-Null }
catch { Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR #3)." -ForegroundColor Red; return }

# --- Policy modes (which cover Devices; simulation vs enforce) ---
$modeRows = [System.Collections.Generic.List[object]]::new()
try {
    $pols = Get-DlpCompliancePolicy -ErrorAction Stop
    foreach ($p in $pols) {
        $hasDevices = $false
        try { if ($p.EndpointDlpLocation -and @($p.EndpointDlpLocation).Count -gt 0) { $hasDevices = $true } } catch { }
        $modeRows.Add([pscustomobject]@{
            Policy          = $p.Name
            Mode            = "$($p.Mode)"
            DevicesLocation = $hasDevices
            Enforcing       = ("$($p.Mode)" -eq "Enable")
        })
    }
    $modeRows | Export-Csv -Path $ModesOutPath -NoTypeInformation -Encoding UTF8
    Write-Host ("  Policies: {0}  (Devices-location: {1}; enforcing: {2})" -f `
        @($modeRows).Count, @($modeRows | Where-Object DevicesLocation).Count, @($modeRows | Where-Object Enforcing).Count) -ForegroundColor Green
    Write-Host ("  Policy modes written to {0}" -f $ModesOutPath) -ForegroundColor Green
    foreach ($m in ($modeRows | Where-Object DevicesLocation)) {
        $col = if ($m.Enforcing) { "Yellow" } else { "Gray" }
        Write-Host ("    - {0,-40} Mode={1}" -f $m.Policy, $m.Mode) -ForegroundColor $col
    }
} catch { Write-Host "  WARN: could not read DLP policies: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Clipboard/screen-capture endpoint activity via Activity Explorer export (licensing-dependent) ---
Write-Host "`n  Attempting Activity Explorer clipboard/screen-capture export (last $Days day(s))..." -ForegroundColor Cyan
$clipScreenTokens = @("Clipboard","CopyToClipboard","Copy to clipboard","ScreenCapture","Screen capture","Screenshot")
try {
    $end   = (Get-Date)
    $start = $end.AddDays(-1 * [math]::Abs($Days))
    # Export-ActivityExplorerData returns classification/DLP activity; filtered here to clipboard/screen-capture events.
    $data = Export-ActivityExplorerData -StartTime $start -EndTime $end -OutputFormat Json -PageSize 5000 -ErrorAction Stop
    $parsed = @()
    foreach ($d in $data) {
        try { $parsed += ($d | ConvertFrom-Json) } catch { $parsed += $d }
    }
    # Keep rows whose serialized content mentions a clipboard/screen-capture token (tenant field names vary).
    $filtered = @()
    foreach ($row in $parsed) {
        $blob = ($row | Out-String)
        if ($clipScreenTokens | Where-Object { $blob -match [regex]::Escape($_) }) { $filtered += $row }
    }
    if (@($filtered).Count -gt 0) {
        $filtered | Export-Csv -Path $ActivityOutPath -NoTypeInformation -Encoding UTF8
        Write-Host ("  Clipboard/screen-capture rows exported: {0}  ->  {1}" -f @($filtered).Count, $ActivityOutPath) -ForegroundColor Green
        Write-Host "  Classify each as true-positive vs false-positive to compute the FP rate (Gate B in 05-testing.md)." -ForegroundColor Green
    } elseif (@($parsed).Count -gt 0) {
        Write-Host ("  {0} activity rows returned, but none matched clipboard/screen-capture tokens (quiet pilot, or field naming differs)." -f @($parsed).Count) -ForegroundColor Yellow
        Write-Host "  Fall back to Purview portal > Activity explorer (filter to copy-to-clipboard / screen-capture)." -ForegroundColor Yellow
    } else {
        Write-Host "  No activity rows returned for the window (may be normal for a quiet pilot — widen -Days or run the 05-testing.md actions first)." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  WARN: Activity Explorer export not available (licensing/permission/cmdlet): $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "        Fall back to Purview portal > Activity explorer (filter to copy-to-clipboard / screen-capture) and DLP > Alerts." -ForegroundColor Yellow
}

Write-Host "`nReport complete. Pair this with DLPCLIP-Validate.ps1 for the configuration gates. Screen-capture events are newer/preview — verify your tenant." -ForegroundColor Cyan

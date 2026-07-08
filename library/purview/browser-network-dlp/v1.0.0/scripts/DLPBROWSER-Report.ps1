<#
.SYNOPSIS
    DLPBROWSER-Report.ps1 — roll up Devices-scoped DLP policy modes and export browser/network upload DLP match & block events to CSV (read-only).
.DESCRIPTION
    PURPOSE
        Read-only operational + evidence report for Browser & Network DLP. Summarizes the DLP policies that
        cover the Devices location and their mode (simulation vs enforce), and — where the tenant/licensing
        exposes it — exports recent browser/network UPLOAD activity from Activity Explorer (cloud-egress /
        upload-to-restricted-domain / unallowed-browser events) so you can see what the policy would have
        audited, warned, or blocked. Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\DLPBROWSER-Report.ps1
          .\DLPBROWSER-Report.ps1 -Days 14
    EXPECTED RESULTS
        A console summary + .\DLPBROWSER-PolicyModes.csv (policies + mode + Devices flag) and, where
        available, .\DLPBROWSER-UploadActivity.csv (Activity Explorer upload/egress events). If activity
        export is not available in your tenant/licence, the script WARNS and reports policy modes only.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. Uses Get-DlpCompliancePolicy and
    Export-ActivityExplorerData (Security & Compliance PowerShell); none invented. Activity Explorer export is
    licensing-dependent and the endpoint activity-type names EVOLVE — the script filters best-effort on
    upload/egress/browser keywords and degrades gracefully (warns) rather than assuming availability. This is
    EVIDENCE for the determination owners, not a verdict.
#>
[CmdletBinding()]
param(
    [int]$Days = 7,
    [string]$ModesOutPath    = ".\DLPBROWSER-PolicyModes.csv",
    [string]$ActivityOutPath = ".\DLPBROWSER-UploadActivity.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPBROWSER Report — Browser & Network DLP modes + upload activity (read-only) ===" -ForegroundColor Cyan

try { Get-DlpCompliancePolicy -ErrorAction Stop | Out-Null }
catch { Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR §3)." -ForegroundColor Red; return }

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

# --- Upload/egress activity via Activity Explorer export (licensing-dependent) ---
Write-Host "`n  Attempting Activity Explorer upload/egress export (last $Days day(s))..." -ForegroundColor Cyan
try {
    $end   = (Get-Date)
    $start = $end.AddDays(-1 * [math]::Abs($Days))
    $data = Export-ActivityExplorerData -StartTime $start -EndTime $end -OutputFormat Json -PageSize 5000 -ErrorAction Stop
    $parsed = @()
    foreach ($d in $data) {
        try { $parsed += ($d | ConvertFrom-Json) } catch { $parsed += $d }
    }

    # Best-effort filter to browser/network upload-relevant events (activity-type names evolve — keep broad).
    $keywords = 'upload|egress|cloud|browser|service *domain|restricted *domain|unallowed'
    $uploads = @($parsed | Where-Object {
        ($_ | Out-String) -match $keywords
    })

    if (@($uploads).Count -gt 0) {
        $uploads | Export-Csv -Path $ActivityOutPath -NoTypeInformation -Encoding UTF8
        Write-Host ("  Upload/egress rows exported: {0}  ->  {1}" -f @($uploads).Count, $ActivityOutPath) -ForegroundColor Green
        Write-Host "  Review for upload-to-restricted-domain / cloud-egress / unallowed-browser events (would-be Audit/Warn/Block)." -ForegroundColor Green
    } elseif (@($parsed).Count -gt 0) {
        # Fall back to exporting everything so the window isn't reported as empty when only the keyword filter missed.
        $parsed | Export-Csv -Path $ActivityOutPath -NoTypeInformation -Encoding UTF8
        Write-Host ("  No rows matched the upload/egress keywords; exported ALL {0} activity row(s) to {1} for manual review." -f @($parsed).Count, $ActivityOutPath) -ForegroundColor Yellow
    } else {
        Write-Host "  No activity rows returned for the window (may be normal for a quiet pilot)." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  WARN: Activity Explorer export not available (licensing/permission/cmdlet): $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "        Fall back to Purview portal > Activity explorer (filter to Devices + upload/egress activities) for browser/network activity." -ForegroundColor Yellow
}

Write-Host "`nReport complete. Pair this with DLPBROWSER-Validate.ps1 for the configuration gates." -ForegroundColor Cyan

<#
.SYNOPSIS
    DLPUSB-Report.ps1 — roll up removable-media DLP policy modes and endpoint activity (Activity explorer export) read-only.
.DESCRIPTION
    PURPOSE
        Read-only operational + evidence report for USB / removable-media DLP. Summarizes the DLP policies
        that cover the Devices location and their mode (simulation vs enforce), and — where the tenant/
        licensing exposes it — exports recent ENDPOINT activity from Activity Explorer so you can see the
        removable-media events the policy is recording. Changes nothing. (Device-control AUDIT events live in
        your management tool — pair this report with them.)
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\DLPUSB-Report.ps1
          .\DLPUSB-Report.ps1 -Days 7
    EXPECTED RESULTS
        A console summary + .\DLPUSB-PolicyModes.csv (policies + mode + Devices flag) and, where available,
        .\DLPUSB-EndpointActivity.csv (Activity Explorer endpoint events). If activity export is not
        available in your tenant/licence, the script WARNS and reports policy modes only.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. Uses Get-DlpCompliancePolicy and
    Export-ActivityExplorerData (Security & Compliance PowerShell); none invented. Activity Explorer export is
    licensing-dependent — the script degrades gracefully (warns) rather than assuming availability.
#>
[CmdletBinding()]
param(
    [int]$Days = 7,
    [string]$ModesOutPath    = ".\DLPUSB-PolicyModes.csv",
    [string]$ActivityOutPath = ".\DLPUSB-EndpointActivity.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPUSB Report — removable-media DLP modes + activity (read-only) ===" -ForegroundColor Cyan

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
            Policy         = $p.Name
            Mode           = "$($p.Mode)"
            DevicesLocation= $hasDevices
            Enforcing      = ("$($p.Mode)" -eq "Enable")
        })
    }
    $modeRows | Export-Csv -Path $ModesOutPath -NoTypeInformation -Encoding UTF8
    Write-Host ("  Policies: {0}  (Devices-location: {1}; enforcing: {2})" -f `
        @($modeRows).Count, @($modeRows | Where-Object DevicesLocation).Count, @($modeRows | Where-Object Enforcing).Count) -ForegroundColor Green
    Write-Host ("  Policy modes written to {0}" -f $ModesOutPath) -ForegroundColor Green
    foreach ($m in ($modeRows | Where-Object DevicesLocation)) {
        $col = if ($m.Enforcing) { "Yellow" } else { "Gray" }
        Write-Host ("    - {0,-24} Mode={1}" -f $m.Policy, $m.Mode) -ForegroundColor $col
    }
} catch { Write-Host "  WARN: could not read DLP policies: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Endpoint activity via Activity Explorer export (licensing-dependent) ---
Write-Host "`n  Attempting Activity Explorer endpoint-activity export (last $Days day(s))..." -ForegroundColor Cyan
try {
    $end   = (Get-Date)
    $start = $end.AddDays(-1 * [math]::Abs($Days))
    $data = Export-ActivityExplorerData -StartTime $start -EndTime $end -OutputFormat Json -PageSize 5000 -ErrorAction Stop
    $parsed = @()
    foreach ($d in $data) {
        try { $parsed += ($d | ConvertFrom-Json) } catch { $parsed += $d }
    }
    if (@($parsed).Count -gt 0) {
        $parsed | Export-Csv -Path $ActivityOutPath -NoTypeInformation -Encoding UTF8
        Write-Host ("  Activity rows exported: {0}  ->  {1}" -f @($parsed).Count, $ActivityOutPath) -ForegroundColor Green
        Write-Host "  Review for removable-media / USB copy events (filter to the Devices location)." -ForegroundColor Green
    } else {
        Write-Host "  No activity rows returned for the window (may be normal for a quiet pilot)." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  WARN: Activity Explorer export not available (licensing/permission/cmdlet): $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "        Fall back to Purview portal > Activity explorer (filter to Devices) for removable-media activity." -ForegroundColor Yellow
}

Write-Host "`nReport complete. Pair this with DLPUSB-Validate.ps1 (config gates) AND the device-control AUDIT events in your management tool." -ForegroundColor Cyan

<#
.SYNOPSIS
    DLPTEAMS-Report.ps1 — roll up Teams DLP policy modes/locations and DLP activity (Activity explorer export) read-only.
.DESCRIPTION
    PURPOSE
        Read-only operational + evidence report for Teams DLP. Summarizes the DLP policies that cover the
        Teams-messages / SharePoint / OneDrive locations and their mode (simulation vs enforce), and — where
        the tenant/licensing exposes it — exports recent DLP activity from Activity Explorer so you can see
        the message/file matches the policy is recording. Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\DLPTEAMS-Report.ps1
          .\DLPTEAMS-Report.ps1 -Days 7
    EXPECTED RESULTS
        A console summary + .\DLPTEAMS-PolicyModes.csv (policies + mode + Teams/SPO/OneDrive flags) and, where
        available, .\DLPTEAMS-Activity.csv (Activity Explorer DLP events). If activity export is not available
        in your tenant/licence, the script WARNS and reports policy modes only.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. Uses Get-DlpCompliancePolicy and
    Export-ActivityExplorerData (Security & Compliance PowerShell); none invented. Activity Explorer export is
    licensing-dependent — the script degrades gracefully (warns) rather than assuming availability.
#>
[CmdletBinding()]
param(
    [int]$Days = 7,
    [string]$ModesOutPath    = ".\DLPTEAMS-PolicyModes.csv",
    [string]$ActivityOutPath = ".\DLPTEAMS-Activity.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPTEAMS Report — Teams DLP modes/locations + activity (read-only) ===" -ForegroundColor Cyan

try { Get-DlpCompliancePolicy -ErrorAction Stop | Out-Null }
catch { Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR §3)." -ForegroundColor Red; return }

function Has-Location($val) { try { return ($null -ne $val -and @($val).Count -gt 0) } catch { return $false } }

# --- Policy modes + locations ---
$modeRows = [System.Collections.Generic.List[object]]::new()
try {
    $pols = Get-DlpCompliancePolicy -ErrorAction Stop
    foreach ($p in $pols) {
        $hasTeams = Has-Location $p.TeamsLocation
        $modeRows.Add([pscustomobject]@{
            Policy    = $p.Name
            Mode      = "$($p.Mode)"
            Teams     = $hasTeams
            SharePoint= Has-Location $p.SharePointLocation
            OneDrive  = Has-Location $p.OneDriveLocation
            Enforcing = ("$($p.Mode)" -eq "Enable")
        })
    }
    $modeRows | Export-Csv -Path $ModesOutPath -NoTypeInformation -Encoding UTF8
    Write-Host ("  Policies: {0}  (Teams-messages: {1}; enforcing: {2})" -f `
        @($modeRows).Count, @($modeRows | Where-Object Teams).Count, @($modeRows | Where-Object Enforcing).Count) -ForegroundColor Green
    Write-Host ("  Policy modes written to {0}" -f $ModesOutPath) -ForegroundColor Green
    foreach ($m in ($modeRows | Where-Object Teams)) {
        $col = if ($m.Enforcing) { "Yellow" } else { "Gray" }
        Write-Host ("    - {0,-24} Mode={1}  SPO={2} OneDrive={3}" -f $m.Policy, $m.Mode, $m.SharePoint, $m.OneDrive) -ForegroundColor $col
    }
} catch { Write-Host "  WARN: could not read DLP policies: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- DLP activity via Activity Explorer export (licensing-dependent) ---
Write-Host "`n  Attempting Activity Explorer DLP-activity export (last $Days day(s))..." -ForegroundColor Cyan
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
        Write-Host "  Review for Teams message + shared-file DLP matches." -ForegroundColor Green
    } else {
        Write-Host "  No activity rows returned for the window (may be normal for a quiet pilot)." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  WARN: Activity Explorer export not available (licensing/permission/cmdlet): $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "        Fall back to Purview portal > Activity explorer / DLP reports for Teams activity." -ForegroundColor Yellow
}

Write-Host "`nReport complete. Pair this with DLPTEAMS-Validate.ps1 for the configuration gates." -ForegroundColor Cyan

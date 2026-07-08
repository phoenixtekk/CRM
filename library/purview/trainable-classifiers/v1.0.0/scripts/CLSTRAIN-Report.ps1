<#
.SYNOPSIS
    CLSTRAIN-Report.ps1 — roll up auto-labeling/DLP policy modes and classification activity (Activity explorer export) read-only.
.DESCRIPTION
    PURPOSE
        Read-only operational + evidence report for trainable classifiers. Summarizes the auto-labeling (and
        DLP) policies that could act on a classifier and their mode (simulation vs enforce), and — where the
        tenant/licensing exposes it — exports recent classification/labeling activity from Activity Explorer
        so you can see what the wired control is matching/applying. Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\CLSTRAIN-Report.ps1
          .\CLSTRAIN-Report.ps1 -Days 7
    EXPECTED RESULTS
        A console summary + .\CLSTRAIN-PolicyModes.csv (auto-label/DLP policies + mode) and, where available,
        .\CLSTRAIN-Activity.csv (Activity Explorer classification/labeling events). If activity export is not
        available in your tenant/licence, the script WARNS and reports policy modes only.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. Uses Get-AutoSensitivityLabel
    Policy / Get-DlpCompliancePolicy / Export-ActivityExplorerData; none invented. Activity Explorer export is
    licensing-dependent — the script degrades gracefully (warns). Auto-labeling SIMULATION RESULTS themselves
    are reviewed in the portal.
#>
[CmdletBinding()]
param(
    [int]$Days = 7,
    [string]$ModesOutPath    = ".\CLSTRAIN-PolicyModes.csv",
    [string]$ActivityOutPath = ".\CLSTRAIN-Activity.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== CLSTRAIN Report — classifier-wiring modes + activity (read-only) ===" -ForegroundColor Cyan

$connected = $false
try { Get-AutoSensitivityLabelPolicy -ErrorAction Stop | Out-Null; $connected = $true } catch { }
if (-not $connected) {
    try { Get-DlpCompliancePolicy -ErrorAction Stop | Out-Null; $connected = $true } catch { }
}
if (-not $connected) { Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR §3)." -ForegroundColor Red; return }

# --- Policy modes (auto-labeling + DLP) ---
$modeRows = [System.Collections.Generic.List[object]]::new()
try {
    $al = Get-AutoSensitivityLabelPolicy -ErrorAction Stop
    foreach ($p in $al) {
        $modeRows.Add([pscustomobject]@{
            Type = "AutoLabel"; Policy = $p.Name; Mode = "$($p.Mode)"; Label = "$($p.ApplySensitivityLabel)"; Enforcing = ("$($p.Mode)" -eq "Enable")
        })
    }
} catch { Write-Host "  WARN: could not read auto-labeling policies (may be unlicensed): $($_.Exception.Message)" -ForegroundColor Yellow }
try {
    $dlp = Get-DlpCompliancePolicy -ErrorAction Stop
    foreach ($p in $dlp) {
        $modeRows.Add([pscustomobject]@{
            Type = "DLP"; Policy = $p.Name; Mode = "$($p.Mode)"; Label = ""; Enforcing = ("$($p.Mode)" -eq "Enable")
        })
    }
} catch { Write-Host "  WARN: could not read DLP policies: $($_.Exception.Message)" -ForegroundColor Yellow }

if (@($modeRows).Count -gt 0) {
    $modeRows | Export-Csv -Path $ModesOutPath -NoTypeInformation -Encoding UTF8
    Write-Host ("  Policies: {0}  (enforcing: {1})  -> {2}" -f @($modeRows).Count, @($modeRows | Where-Object Enforcing).Count, $ModesOutPath) -ForegroundColor Green
    foreach ($m in ($modeRows | Where-Object { $_.Type -eq "AutoLabel" })) {
        $col = if ($m.Enforcing) { "Yellow" } else { "Gray" }
        Write-Host ("    - [AutoLabel] {0,-24} Mode={1}  Label={2}" -f $m.Policy, $m.Mode, $m.Label) -ForegroundColor $col
    }
}

# --- Classification activity via Activity Explorer export (licensing-dependent) ---
Write-Host "`n  Attempting Activity Explorer classification-activity export (last $Days day(s))..." -ForegroundColor Cyan
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
        Write-Host "  Review for label-applied / classification events tied to the classifier." -ForegroundColor Green
    } else {
        Write-Host "  No activity rows returned for the window (may be normal for a quiet pilot)." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  WARN: Activity Explorer export not available (licensing/permission/cmdlet): $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "        Fall back to Purview portal > Activity explorer, and review the auto-labeling SIMULATION RESULTS in the portal." -ForegroundColor Yellow
}

Write-Host "`nReport complete. Pair this with CLSTRAIN-Validate.ps1 (wiring gates) and the portal accuracy/simulation results (Gate A/C)." -ForegroundColor Cyan

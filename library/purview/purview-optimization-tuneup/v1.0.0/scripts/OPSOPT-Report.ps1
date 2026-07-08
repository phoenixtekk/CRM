<#
.SYNOPSIS
    OPSOPT-Report.ps1 — read-only noise baseline: DLP match/override/false-positive volume by rule, plus alert volume by policy. Makes no changes.
.DESCRIPTION
    PURPOSE
        Produces the evidence you tune against. Uses Get-DlpDetailReport (Security & Compliance
        PowerShell) to rank DLP rules by match volume, user overrides, and reported false positives, and
        Search-UnifiedAuditLog / Get-ProtectionAlert to summarise alert volume by policy. Read-only.
    HOW TO RUN
        PowerShell 5.1+/7+. Connect first:
          Connect-IPPSSession                # for Get-DlpDetailReport
          Connect-ExchangeOnline             # for Search-UnifiedAuditLog
        Then:
          .\OPSOPT-Report.ps1 -Days 30 -OutputFolder .\OPSOPT-out
    EXPECTED RESULTS
        dlp-noise-by-rule.csv (matches / overrides / reported-false-positives per rule, noisiest first)
        and alert-volume.csv (alert count per policy over the window). No changes are made.
.NOTES
    Purview — Optimization & Tune-Up. Read-only. Get-DlpDetailReport availability/retention window is
    tenant-dependent (E5 / E5 Compliance) — verify your tenant. No credentials in code.
#>
[CmdletBinding()]
param(
    [int]$Days = 30,
    [string]$OutputFolder = '.\OPSOPT-out'
)

if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null }
$start = (Get-Date).AddDays(-$Days)
$end   = Get-Date
Write-Host ("=== OPSOPT Report — noise baseline, last {0} days (read-only) ===" -f $Days) -ForegroundColor Cyan

# --- DLP detail: rank rules by match volume, overrides, reported false positives ---
$dlpAgg = @{}
if (Get-Command Get-DlpDetailReport -ErrorAction SilentlyContinue) {
    try {
        $detail = Get-DlpDetailReport -StartDate $start -EndDate $end -ErrorAction Stop
        foreach ($d in $detail) {
            $key = ("{0} :: {1}" -f $d.DLPPolicy, $d.TransportRule)  # policy :: rule (field names vary by tenant/version)
            if (-not $dlpAgg.ContainsKey($key)) {
                $dlpAgg[$key] = [pscustomobject]@{ PolicyRule = $key; Matches = 0; Overrides = 0; FalsePositives = 0 }
            }
            $dlpAgg[$key].Matches++
            # Override / false-positive flags are surfaced when users act on a policy tip.
            if ($d.PSObject.Properties.Name -contains 'Overridden' -and $d.Overridden) { $dlpAgg[$key].Overrides++ }
            $fpField = $d.PSObject.Properties | Where-Object { $_.Name -match 'FalsePositive|Justification' } | Select-Object -First 1
            if ($fpField -and $fpField.Value -match 'false\s*positive') { $dlpAgg[$key].FalsePositives++ }
        }
    } catch {
        Write-Warning ("Get-DlpDetailReport failed or is unavailable in this tenant: {0}" -f $_.Exception.Message)
        Write-Warning "Falling back to Search-UnifiedAuditLog DLP records for volume only (no override/FP detail)."
    }
} else {
    Write-Warning "Get-DlpDetailReport not available — verify licensing/tenant. Using audit-log DLP volume only."
}

$dlpNoise = $dlpAgg.Values | Sort-Object Matches -Descending
if (@($dlpNoise).Count) {
    foreach ($n in $dlpNoise) {
        $n | Add-Member -NotePropertyName OverrideRatePct -NotePropertyValue ([math]::Round( ($n.Overrides + $n.FalsePositives) / [math]::Max($n.Matches,1) * 100, 1)) -Force
    }
    Write-Host "--- Noisiest DLP rules (by match volume) ---" -ForegroundColor Cyan
    $dlpNoise | Select-Object PolicyRule, Matches, Overrides, FalsePositives, OverrideRatePct | Format-Table -AutoSize
    $dlpNoise | Export-Csv (Join-Path $OutputFolder 'dlp-noise-by-rule.csv') -NoTypeInformation
}

# --- Alert volume by policy (unified audit log + protection alert config) ---
$alertVol = @()
if (Get-Command Search-UnifiedAuditLog -ErrorAction SilentlyContinue) {
    try {
        $events = Search-UnifiedAuditLog -StartDate $start -EndDate $end -RecordType ComplianceDLPExchange,ComplianceDLPSharePoint,DLPEndpoint -ResultSize 5000 -ErrorAction Stop
        $alertVol = $events | Group-Object RecordType | ForEach-Object {
            [pscustomobject]@{ Source = $_.Name; Events = $_.Count }
        }
        Write-Host "--- DLP-related audit event volume ---" -ForegroundColor Cyan
        $alertVol | Format-Table -AutoSize
    } catch {
        Write-Warning ("Search-UnifiedAuditLog failed: {0}" -f $_.Exception.Message)
    }
}
if (Get-Command Get-ProtectionAlert -ErrorAction SilentlyContinue) {
    $ap = Get-ProtectionAlert -ErrorAction SilentlyContinue |
          Select-Object Name, Threshold, AggregationType, Severity, Disabled
    $ap | Export-Csv (Join-Path $OutputFolder 'alert-policies-config.csv') -NoTypeInformation
    $alertVol | Export-Csv (Join-Path $OutputFolder 'alert-volume.csv') -NoTypeInformation
}

Write-Host ("Saved noise baseline to {0}" -f $OutputFolder) -ForegroundColor Green
Write-Host "=== Report complete (no changes made) ===" -ForegroundColor Cyan

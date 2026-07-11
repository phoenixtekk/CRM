<#
.SYNOPSIS
    CLDSEC-SecureScore.ps1 — read-only pull of Microsoft Secure Score and control profiles.
.DESCRIPTION
    PURPOSE
        Retrieves the current Microsoft Secure Score, the maximum attainable, the per-category control
        profiles (identity / device / apps / data), and the highest-impact improvement actions still open.
        These anchor the identity/endpoint/app pillar scores and populate the "quick wins" in the roadmap.
        Read-only; nothing is changed.
    HOW TO RUN
        Connect-MgGraph -Scopes "SecurityEvents.Read.All"
        pwsh -File .\CLDSEC-SecureScore.ps1 -OutputFolder "<secure path>"
        *Verify the current Graph Security Secure Score endpoints/permissions for your tenant.*
    EXPECTED RESULTS
        The current score vs max, per-category breakdown, and the top open improvement actions by points.
        A CSV of the control profiles is written to the output folder. Read-only.
.NOTES
    White-label. Read-only. Makes no changes.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$OutputFolder,
    [int]$TopActions = 15
)

$ErrorActionPreference = 'Continue'
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
Write-Host "CLDSEC Secure Score (read-only)`n" -ForegroundColor Cyan

# --- Latest Secure Score -----------------------------------------------------
try {
    $scores = Invoke-MgGraphRequest -Method GET -Uri 'v1.0/security/secureScores?$top=1' -ErrorAction Stop
    $latest = $scores.value | Select-Object -First 1
    if (-not $latest) { Write-Host "No Secure Score returned — confirm it is populated (R6)." -ForegroundColor Yellow; return }

    $current = [double]$latest.currentScore
    $max     = [double]$latest.maxScore
    $pct     = if ($max -gt 0) { [math]::Round(($current / $max) * 100, 1) } else { 0 }
    Write-Host "Secure Score: $current / $max  ($pct`%)  as of $($latest.createdDateTime)" -ForegroundColor Green

    # Per-category control-score averages
    if ($latest.averageComparativeScores) {
        Write-Host "`n--- Comparative (your tenant vs peers) ---" -ForegroundColor Cyan
        $latest.averageComparativeScores | ForEach-Object {
            [pscustomobject]@{ Basis=$_.basis; Average=$_.averageScore }
        } | Format-Table -AutoSize
    }

    # Control scores by control category
    if ($latest.controlScores) {
        $byCat = $latest.controlScores | Group-Object controlCategory | ForEach-Object {
            [pscustomobject]@{
                Category = $_.Name
                Controls = $_.Count
                Score    = [math]::Round((($_.Group | Measure-Object score -Sum).Sum),1)
            }
        }
        Write-Host "`n--- Score by pillar/category ---" -ForegroundColor Cyan
        $byCat | Sort-Object Category | Format-Table -AutoSize
        $catCsv = Join-Path $OutputFolder "CLDSEC-securescore-bycategory-$stamp.csv"
        $byCat | Export-Csv -Path $catCsv -NoTypeInformation -Encoding UTF8
    }
} catch {
    Write-Host "Could not retrieve Secure Score: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Confirm the SecurityEvents.Read.All scope (R3) and that Secure Score is populated (R6)." -ForegroundColor Yellow
    return
}

# --- Open improvement actions (highest impact first) -------------------------
try {
    $profiles = Invoke-MgGraphRequest -Method GET -Uri 'v1.0/security/secureScoreControlProfiles?$top=200' -ErrorAction SilentlyContinue
    if ($profiles.value) {
        $actions = $profiles.value | ForEach-Object {
            [pscustomobject]@{
                Control   = $_.title
                Category  = $_.controlCategory
                MaxScore  = $_.maxScore
                Tier      = $_.tier
                Service   = $_.service
                UserImpact= $_.userImpact
            }
        } | Sort-Object MaxScore -Descending | Select-Object -First $TopActions
        Write-Host "`n--- Top $TopActions improvement actions by potential points (feed the roadmap 'quick wins') ---" -ForegroundColor Cyan
        $actions | Format-Table -AutoSize
        $actCsv = Join-Path $OutputFolder "CLDSEC-securescore-actions-$stamp.csv"
        $actions | Export-Csv -Path $actCsv -NoTypeInformation -Encoding UTF8
        Write-Host "`nSaved improvement actions: $actCsv" -ForegroundColor Green
    }
} catch { Write-Host "Could not retrieve control profiles: $($_.Exception.Message)" -ForegroundColor Yellow }

Write-Host "`nSecure Score pull complete. Read-only; nothing was changed." -ForegroundColor Green

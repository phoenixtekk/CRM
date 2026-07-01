<#
.SYNOPSIS
    M365SEC-Report.ps1 — Secure Score + control-evidence report for the audit evidence pack (Graph).
.DESCRIPTION
    PURPOSE
        Produces the audit-facing report: the current Microsoft Secure Score with trend, and a
        control-evidence table listing each Secure Score control, its category, max score, and
        current implementation status. Exports to CSV/HTML so the output can be filed, dated, into
        the evidence pack 'Control Evidence Pack - Tenant Baseline - Audit', tied to each control /
        improvement action. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\M365SEC-Report.ps1 -OutputFolder .\evidence
        Requires the Microsoft Graph PowerShell SDK and consent to:
        SecurityEvents.Read.All.
    EXPECTED RESULTS
        A console summary plus, in the output folder, dated files:
            SecureScore-Trend-<date>.csv    (score history)
            Control-Evidence-<date>.csv     (per-control status)
            Control-Evidence-<date>.html    (readable evidence table)
        File these into the evidence pack against the mapped controls.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
    Uses /security/secureScores (history + latest controlScores) and
    /security/secureScoreControlProfiles (control metadata).
#>
[CmdletBinding()]
param(
    [string]$OutputFolder = (Join-Path (Get-Location) 'evidence')
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'SecurityEvents.Read.All' -NoWelcome

if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }
$stamp = Get-Date -Format 'yyyy-MM-dd'

Write-Host "`n=== Secure Score trend ===" -ForegroundColor Cyan
$trend = @()
try {
    $scores = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/security/secureScores?`$top=30").value
    foreach ($s in $scores) {
        $pct = if ($s.maxScore) { [math]::Round(($s.currentScore / $s.maxScore) * 100, 1) } else { 0 }
        $trend += [pscustomobject]@{
            Date        = $s.createdDateTime
            CurrentScore= $s.currentScore
            MaxScore    = $s.maxScore
            Percent     = $pct
        }
    }
    $trend | Select-Object -First 5 | ForEach-Object {
        Write-Host ("  {0}: {1}/{2} ({3}%)" -f $_.Date, $_.CurrentScore, $_.MaxScore, $_.Percent)
    }
    $trendPath = Join-Path $OutputFolder ("SecureScore-Trend-$stamp.csv")
    $trend | Export-Csv -Path $trendPath -NoTypeInformation -Encoding UTF8
    Write-Host ("  Saved: {0}" -f $trendPath) -ForegroundColor DarkGray
} catch {
    Write-Host ("  Could not read Secure Score trend: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

Write-Host "`n=== Control-evidence table ===" -ForegroundColor Cyan
$evidence = @()
try {
    $profiles = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/security/secureScoreControlProfiles?`$top=999").value
    $statusById = @{}
    if ($scores -and $scores[0].controlScores) {
        foreach ($cs in $scores[0].controlScores) { $statusById[$cs.controlName] = $cs.implementationStatus }
    }
    foreach ($p in $profiles) {
        $evidence += [pscustomobject]@{
            ControlId       = $p.id
            Category        = $p.controlCategory
            MaxScore        = $p.maxScore
            ActionType      = $p.actionType
            Status          = if ($statusById.ContainsKey($p.id)) { $statusById[$p.id] } else { '<not reported>' }
            EvidenceCapturedOn = $stamp
        }
    }
    $csvPath  = Join-Path $OutputFolder ("Control-Evidence-$stamp.csv")
    $htmlPath = Join-Path $OutputFolder ("Control-Evidence-$stamp.html")
    $evidence | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    $evidence | ConvertTo-Html -Title "Control Evidence Pack - Tenant Baseline - Audit ($stamp)" |
        Out-File -FilePath $htmlPath -Encoding UTF8
    Write-Host ("  {0} controls written." -f $evidence.Count)
    Write-Host ("  Saved: {0}" -f $csvPath) -ForegroundColor DarkGray
    Write-Host ("  Saved: {0}" -f $htmlPath) -ForegroundColor DarkGray
} catch {
    Write-Host ("  Could not build control-evidence table: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

Write-Host "`nFile these outputs into 'Control Evidence Pack - Tenant Baseline - Audit', dated, per control." -ForegroundColor Yellow
Disconnect-MgGraph | Out-Null

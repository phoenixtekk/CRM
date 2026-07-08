<#
.SYNOPSIS
    OPSCOE-Register.ps1 - produce the CoE governance scorecard from the register + validation output (read-only).
.DESCRIPTION
    PURPOSE
        Rolls the governance register (OPSCOE-Discovery.ps1) and the lifecycle-review results
        (OPSCOE-Validate.ps1) into the board's standing artifact: "Purview CoE Scorecard - Report" - counts
        by capability, % naming-conformant, % owned, % with a review date, count enforced-without-evidence
        (target 0), and the next-review-due list. Read-only - aggregates the two inputs, changes nothing.
    HOW TO RUN
        .\OPSCOE-Register.ps1 -Register .\Purview-CoE-Register-Governed.csv -Validation .\Purview-CoE-Lifecycle-Review.csv -OutPath .\Purview-CoE-Scorecard-Report.csv
        Optional: -ReviewCadenceDays 90 to set the "next review due" horizon.
    EXPECTED RESULTS
        A per-capability scorecard CSV plus a printed summary. The board's audit answer: enforced-without-
        evidence should be 0; naming/owned/review percentages trend to 100%. PASS = scorecard produced and
        enforced-without-evidence = 0.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials in code. Portal-only capabilities are
    counted as attestation rows. Verify capability availability/cmdlets in your tenant.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Register,
    [Parameter(Mandatory)][string]$Validation,
    [string]$OutPath = ".\Purview-CoE-Scorecard-Report.csv",
    [int]$ReviewCadenceDays = 90
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }

if (-not (Test-Path $Register))   { Write-Host "[FAIL] register not found: $Register" -ForegroundColor Red; return }
if (-not (Test-Path $Validation)) { Write-Host "[FAIL] validation output not found: $Validation" -ForegroundColor Red; return }

$reg = @(Import-Csv -Path $Register)
$val = @(Import-Csv -Path $Validation)

# Index validation FAIL/WARN per artifact name for the enforce-evidence count.
$enforceFail = @($val | Where-Object { $_.Check -eq 'EnforceEvidence' -and $_.Status -eq 'FAIL' })

$byCap = $reg | Group-Object Type
$scorecard = New-Object System.Collections.Generic.List[object]
foreach ($g in $byCap) {
    $items = @($g.Group)
    $inScope = @($items | Where-Object { "$($_.State)" -notmatch 'Portal' })   # portal-only exempt from naming
    $named   = @($inScope | Where-Object { "$($_.Conforms)" -eq 'YES' }).Count
    $owned   = @($items   | Where-Object { -not [string]::IsNullOrWhiteSpace($_.Owner) }).Count
    $reviewed= @($items   | Where-Object { -not [string]::IsNullOrWhiteSpace($_.Review) }).Count
    $encFail = @($enforceFail | Where-Object { $_.Type -eq $g.Name }).Count
    $scorecard.Add([pscustomobject]@{
        Capability             = $g.Name
        Count                  = $items.Count
        NamingConformantPct    = $(if ($inScope.Count) { [math]::Round(100.0*$named/$inScope.Count,0) } else { 'N/A' })
        OwnedPct               = $(if ($items.Count) { [math]::Round(100.0*$owned/$items.Count,0) } else { 0 })
        ReviewDatedPct         = $(if ($items.Count) { [math]::Round(100.0*$reviewed/$items.Count,0) } else { 0 })
        EnforcedWithoutEvidence= $encFail
    })
}

# Next-review-due list (within the cadence horizon or overdue)
$dueSoon = New-Object System.Collections.Generic.List[object]
$horizon = (Get-Date).AddDays($ReviewCadenceDays)
foreach ($a in $reg) {
    $d = $null
    if (-not [string]::IsNullOrWhiteSpace($a.Review)) { [datetime]::TryParse($a.Review, [ref]$d) | Out-Null }
    if ($d) {
        $due = $d.AddDays($ReviewCadenceDays)
        if ($due -le $horizon) { $dueSoon.Add([pscustomobject]@{ Type=$a.Type; Name=$a.Name; LastReview=$a.Review; NextDue=$due.ToString('yyyy-MM-dd'); Owner=$a.Owner }) }
    }
}

$scorecard | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8
$duePath = [System.IO.Path]::ChangeExtension($OutPath, $null) + 'NextReviewDue.csv'
$dueSoon | Sort-Object NextDue | Export-Csv -Path $duePath -NoTypeInformation -Encoding UTF8

Write-Section 'Purview CoE Scorecard - Report'
$scorecard | Format-Table -AutoSize | Out-String | Write-Host
$totalEncFail = @($enforceFail).Count
Write-Host ("Scorecard -> {0}" -f $OutPath) -ForegroundColor Green
Write-Host ("Next-review-due -> {0}  ({1} artifact(s) due within {2} days)" -f $duePath, $dueSoon.Count, $ReviewCadenceDays) -ForegroundColor Green
if ($totalEncFail -gt 0) {
    Write-Host ("[GATE] Enforced-without-evidence = $totalEncFail (target 0) - remediate via intake before sign-off.") -ForegroundColor Red
} else {
    Write-Host '[GATE] Enforced-without-evidence = 0. This scorecard is the board''s standing artifact and audit answer.' -ForegroundColor Green
}

<#
.SYNOPSIS
    SOAREM-Report.ps1 — produce the change-tracked remediation evidence report (what changed, when, by
    whom, stage, before/after score). Read-only.
.DESCRIPTION
    PURPOSE
        Combines the remediation plan, the change record(s) from SOAREM-Remediate.ps1, the post-change
        verification, and the re-score into a single auditable evidence report proving each finding was
        remediated pilot-first, verified, and re-scored. READ-ONLY — it assembles evidence; it changes
        nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SOAREM-Report.ps1 `
            -RemediationPlanPath ".\Remediation Plan - Defender SOA - Assess.json" `
            -ChangeRecordPath ".\SOAREM-change-record.json" `
            -ValidationPath ".\SOAREM-validation.json" `
            -RescorePath ".\Rescore Result - Defender SOA - Validate.json" `
            -OutputPath ".\Evidence Report - Defender SOA - Validate.json"
        -ChangeRecordPath accepts a single file or a folder of change records.
    EXPECTED RESULTS
        A remediation evidence report (JSON + console summary): per-finding change-tracking and the
        before/after score — the auditable proof the backlog closed.
.NOTES
    White-label. Read-only. Store the evidence report securely (Requirements R7). Production
    change-approval and risk-acceptance remain the customer's decisions.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RemediationPlanPath,
    [string]$ChangeRecordPath,
    [string]$ValidationPath,
    [string]$RescorePath,
    [string]$OutputPath = ".\Evidence Report - Defender SOA - Validate.json"
)

$ErrorActionPreference = 'Stop'
$plan = Get-Content $RemediationPlanPath -Raw | ConvertFrom-Json

$changeRecords = @()
if ($ChangeRecordPath -and (Test-Path $ChangeRecordPath)) {
    if ((Get-Item $ChangeRecordPath).PSIsContainer) {
        Get-ChildItem $ChangeRecordPath -Filter '*.json' | ForEach-Object { $changeRecords += (Get-Content $_.FullName -Raw | ConvertFrom-Json) }
    } else {
        $changeRecords += (Get-Content $ChangeRecordPath -Raw | ConvertFrom-Json)
    }
}
$validation = if ($ValidationPath -and (Test-Path $ValidationPath)) { Get-Content $ValidationPath -Raw | ConvertFrom-Json } else { $null }
$rescore    = if ($RescorePath -and (Test-Path $RescorePath)) { Get-Content $RescorePath -Raw | ConvertFrom-Json } else { $null }

$entries = @()
foreach ($p in @($plan.plan)) {
    $cr = $changeRecords | Where-Object { $_.findingId -eq $p.findingId } | Select-Object -First 1
    $ve = if ($validation -and $validation.findingId -eq $p.findingId) { $validation } else { $null }
    $entries += [ordered]@{
        findingId    = $p.findingId
        domain       = $p.domain
        control      = $p.control
        severity     = $p.severity
        remediation  = $p.remediation
        gate         = $p.gate
        pilotScope   = if ($cr) { $cr.pilotScope } else { $null }
        applied      = if ($cr) { [bool]$cr.applyRequested } else { $false }
        whatIfOnly   = if ($cr) { [bool]$cr.whatIf } else { $true }
        changeDetail = if ($cr) { $cr.changeDetail } else { 'no change record — not yet applied' }
        appliedBy    = if ($cr) { $cr.appliedBy } else { $null }
        appliedUtc   = if ($cr) { $cr.appliedUtc } else { $null }
        verification = if ($ve) { $ve.result } else { 'not verified' }
        status       = if ($cr -and -not $cr.whatIf -and $ve -and $ve.result -eq 'Pass') { 'remediated' } elseif ($cr -and $cr.whatIf) { 'previewed' } else { 'planned' }
    }
}

$report = [ordered]@{
    solution      = "SOAREM"
    title         = "Evidence Report - Defender SOA - Validate"
    generatedUtc  = (Get-Date).ToUniversalTime().ToString("o")
    readOnly      = $true
    sourceSolution= $plan.sourceSolution
    entries       = $entries
    rescore       = if ($rescore) { [ordered]@{ overallBefore=$rescore.overallBefore; overallAfter=$rescore.overallAfter; overallDelta=$rescore.overallDelta; verdict=$rescore.verdict } } else { "no re-score supplied" }
    note          = "Auditable remediation evidence. Store securely (Requirements R7). Change-approval, risk-acceptance, and priority are the customer's decisions."
}
$report | ConvertTo-Json -Depth 8 | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host "Remediation evidence report:" -ForegroundColor Cyan
$entries | ForEach-Object { Write-Host ("  [{0}]  {1}  ({2})  verify={3}" -f $_.status, $_.control, $_.domain, $_.verification) -ForegroundColor Yellow }
if ($rescore) { Write-Host ("  Re-score: {0} -> {1} (delta {2}) — {3}" -f $rescore.overallBefore, $rescore.overallAfter, $rescore.overallDelta, $rescore.verdict) -ForegroundColor Green }
Write-Host "Written: $OutputPath (read-only). Store securely — it is sensitive." -ForegroundColor Green

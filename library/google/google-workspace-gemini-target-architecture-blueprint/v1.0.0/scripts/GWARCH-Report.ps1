<#
.SYNOPSIS
    GWARCH-Report.ps1 — read-only coverage/gap report rolling discovery + validation into an ARB-ready view.
.DESCRIPTION
    PURPOSE
        Combines the current-state discovery and the conformance-validation outputs into a single
        coverage/gap report across the five architecture domains (identity, collaboration, Drive
        replacement, data governance/retention, AI enablement). Shows per-domain readiness and the open
        gaps the Architecture Review Board weighs for the Pilot-to-Expand decision. Read-only: it reads
        the JSON reports the other scripts produced; it does not touch live systems.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWARCH-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\GWARCH-Report.ps1 -DiscoveryPath .\gwarch-discovery.json -ValidationPath .\gwarch-validation.json -OutputPath .\gwarch-coverage-report.md
        Requires: the JSON outputs of GWARCH-Discovery.ps1 and GWARCH-Validation.ps1 (no Graph scopes).
    EXPECTED RESULTS
        A Markdown coverage/gap report (per-domain readiness + open gaps + FAIL count) the ARB uses to
        gate a wave. No live-system changes.
.NOTES
    White-label — the repeatable way. Read-only where it reads live systems.
#>

[CmdletBinding()]
param(
    [string]$DiscoveryPath  = ".\gwarch-discovery.json",
    [string]$ValidationPath = ".\gwarch-validation.json",
    [string]$OutputPath     = ".\gwarch-coverage-report.md"
)

$ErrorActionPreference = 'Stop'

function Import-Json {
    param([string]$Path, [string]$Label)
    if (-not (Test-Path $Path)) {
        Write-Host "  $Label report not found at $Path — run the producing script first." -ForegroundColor Yellow
        return $null
    }
    try { Get-Content $Path -Raw | ConvertFrom-Json }
    catch { Write-Host "  Could not parse $Label report: $($_.Exception.Message)" -ForegroundColor Yellow; $null }
}

Write-Host "GWARCH-Report — coverage/gap report across the five architecture domains" -ForegroundColor Cyan
$disc = Import-Json -Path $DiscoveryPath  -Label 'Discovery'
$val  = Import-Json -Path $ValidationPath -Label 'Validation'

$domains = @(
    @{ name='Identity integration';         key='ID';  principle='GWARCH-ID-1/2/3' }
    @{ name='Collaboration';                key='COL'; principle='GWARCH-COL-1/2/3' }
    @{ name='Drive / content replacement';  key='DRV'; principle='GWARCH-DRV-1/2/3' }
    @{ name='Data governance & retention';  key='GOV'; principle='GWARCH-GOV-1/2/3' }
    @{ name='AI enablement';                key='AI';  principle='GWARCH-AI-1/2/3' }
)

$checks = @()
if ($val -and $val.checks) { $checks = $val.checks }
$failCount = ($checks | Where-Object { $_.status -eq 'FAIL' }).Count

# Map validation checks (source-side, Gates 0-2) to the domains they inform
function Get-DomainStatus {
    param([string]$Key)
    switch ($Key) {
        'ID'  { $rel = $checks | Where-Object { $_.principle -like 'GWARCH-ID*' -or $_.id -in @('C1','C2') } }
        'COL' { $rel = $checks | Where-Object { $_.id -eq 'C4' } }
        'DRV' { $rel = @() }
        'GOV' { $rel = @() }
        'AI'  { $rel = @() }
    }
    if (-not $rel -or $rel.Count -eq 0) { return @{ status='DESIGN-REVIEW'; note='No source-side machine check; assessed at ARB design review.' } }
    if ($rel | Where-Object { $_.status -eq 'FAIL' }) { return @{ status='GAP'; note=(($rel | Where-Object {$_.status -eq 'FAIL'} | ForEach-Object { $_.detail }) -join ' ') } }
    return @{ status='READY (source-side)'; note='Source-side checks pass; confirm target-side design at ARB.' }
}

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("# Target-Architecture Coverage / Gap Report")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Generated: $((Get-Date).ToUniversalTime().ToString('o'))")
[void]$sb.AppendLine("")
if ($disc) {
    [void]$sb.AppendLine("## Current-state snapshot (source M365/Entra)")
    [void]$sb.AppendLine("- Organization: $($disc.organization.displayName)")
    [void]$sb.AppendLine("- Users: $($disc.counts.users)  |  Groups: $($disc.counts.groups)")
    [void]$sb.AppendLine("- On-prem directory sync: $($disc.identity.onPremDirSyncEnabled)")
    [void]$sb.AppendLine("")
}
[void]$sb.AppendLine("## Per-domain coverage")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Domain | Principles | Status | Notes |")
[void]$sb.AppendLine("| --- | --- | --- | --- |")
foreach ($d in $domains) {
    $st = Get-DomainStatus -Key $d.key
    [void]$sb.AppendLine("| $($d.name) | $($d.principle) | $($st.status) | $($st.note) |")
}
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Open source-side conformance gaps")
[void]$sb.AppendLine("")
$fails = $checks | Where-Object { $_.status -eq 'FAIL' }
if ($fails) {
    foreach ($f in $fails) { [void]$sb.AppendLine("- **[$($f.gate)] $($f.check)** ($($f.principle)): $($f.detail)") }
} else {
    [void]$sb.AppendLine("- None from the source-side machine checks. Remaining coverage is assessed at ARB design review (Gates 3-7).")
}
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## ARB gate decision")
[void]$sb.AppendLine("")
$verdict = if ($failCount -gt 0) { "**HOLD** — $failCount source-side FAIL(s) to remediate or carry as exception ADRs before Pilot-to-Expand." }
           else { "**PROCEED to ARB design review** — no source-side FAILs; validate Gates 3-7 (Drive, governance, AI, NFRs, ADR completeness) at the board." }
[void]$sb.AppendLine($verdict)
[void]$sb.AppendLine("")
[void]$sb.AppendLine("_Note: Drive, governance, and AI domains have no source-side machine check; their conformance is a human ARB design-review decision per 05-testing.md._")

$sb.ToString() | Out-File -FilePath $OutputPath -Encoding utf8
Write-Host ""
Write-Host "Coverage/gap report written to $OutputPath" -ForegroundColor Green
Write-Host ("Source-side FAILs: {0}" -f $failCount) -ForegroundColor $(if ($failCount) {'Red'} else {'Green'})
Write-Host $verdict

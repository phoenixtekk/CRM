<#
.SYNOPSIS
    TIER1LIC-Remediation.ps1 — propose safe gap-closure actions for tier-1 over-deployment.
.DESCRIPTION
    PURPOSE
        Reads the exposure register and the mapped deployment and produces a remediation work list
        for products in shortfall: candidate uninstalls of unused installs, consolidation of
        processor-counted software onto fewer hosts, and removal of unentitled options/users. It is
        SAFE BY DEFAULT — it runs in -WhatIf mode and only proposes actions; it never uninstalls,
        moves, or changes any system. Approved actions must be performed through your normal change
        process. Re-run Validation and Report after each change.
    HOW TO RUN
        Preview (default, changes nothing):
            powershell -ExecutionPolicy Bypass -File .\TIER1LIC-Remediation.ps1 `
                -RegisterCsv .\exposure-register-Oracle.csv -MappingCsv .\mapping-Oracle.csv `
                -Publisher Oracle
        Emit the approved work list to CSV for the change process:
            ... -OutCsv .\remediation-worklist-Oracle.csv
        (There is no execute mode: this tool proposes only. Pass -Execute to acknowledge it is a
        no-op and confirm the proposal-only design.)
    EXPECTED RESULTS
        A proposed, prioritized work list of gap-closure candidates. No system is modified.
.NOTES
    White-label SAM tooling — Asset Mgt. Proposal-only; default -WhatIf. Acting on a proposal is a
    business decision governed by your contracts and change process.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
param(
    [Parameter(Mandatory)] [string] $RegisterCsv,
    [Parameter(Mandatory)] [string] $MappingCsv,
    [Parameter(Mandatory)] [ValidateSet('Oracle','IBM','SAP')] [string] $Publisher,
    [string] $OutCsv,
    [switch] $WhatIf = $true,   # default ON: safe preview
    [switch] $Execute           # acknowledged no-op; this tool never changes a system
)

foreach ($f in @($RegisterCsv, $MappingCsv)) { if (-not (Test-Path $f)) { Write-Error "File not found: $f"; return } }
$register = Import-Csv -Path $RegisterCsv
$map      = Import-Csv -Path $MappingCsv

Write-Host "`n=== Remediation proposal (preview — no changes) — $Publisher ===" -ForegroundColor Cyan
if ($Execute) { Write-Host "Note: -Execute is acknowledged but this tool is proposal-only and performs no system changes." -ForegroundColor Yellow }

$shortfalls = @($register | Where-Object { $_.Position -eq 'SHORTFALL' })
if (-not $shortfalls) { Write-Host "No shortfalls in the exposure register — nothing to propose." -ForegroundColor Green; return }

$worklist = foreach ($s in $shortfalls) {
    # Find the installs that contribute to this product's consumption, largest first (best candidates).
    $installs = $map | Where-Object { $_.Product -eq $s.Product -and -not $_.Flag } |
                Sort-Object { [double]($_.MetricQuantity) } -Descending

    $action = switch -Regex ($s.Metric) {
        'Processor|PVU' { 'Consolidate onto fewer hosts / remove unused installs to reduce counted cores' }
        'NamedUser|NUP' { 'Remove or reassign unentitled named users' }
        'Digital'       { 'Reduce indirect document volume or license the digital access gap' }
        default         { 'Review deployment to reduce consumption' }
    }

    [pscustomobject]@{
        Publisher          = $Publisher
        Product            = $s.Product
        Metric             = $s.Metric
        ExposureToClose    = $s.Exposure
        Unit               = $s.Unit
        Severity           = $s.Severity
        ProposedAction     = $action
        TopCandidateHost   = ($installs | Select-Object -First 1).Host
        Candidates         = ($installs | Select-Object -First 3 | ForEach-Object { $_.Host }) -join '; '
        RequiresApproval   = 'YES — owner sign-off + change process'
    }
}

$worklist | Format-Table Product, Metric, ExposureToClose, Severity, ProposedAction, TopCandidateHost -AutoSize | Out-Host
Write-Host ("Proposed items: {0}. PREVIEW ONLY — no system changed." -f $worklist.Count) -ForegroundColor Green
Write-Host  "Get owner approval, perform actions via change control, then re-run Validation + Report." -ForegroundColor Cyan

if ($OutCsv) { $worklist | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8; Write-Host "Work list written: $OutCsv" -ForegroundColor Green }

<#
.SYNOPSIS
    GWAUTO-Validation.ps1 — check Apps Script and AppSheet guardrail conformance against the gates.
.DESCRIPTION
    PURPOSE
        Evaluates the automation inventory (from GWAUTO-Discovery.ps1) and your recorded admin-guardrail
        posture against the Testing-guide conformance gates: app access posture, external sharing,
        external data sources, require sign-in, deploy control, and owner/environment discipline.
        Emits per-gate Pass/Fail with the offending artifacts. Read-only — it evaluates data you
        supply and changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWAUTO-Validation.ps1 -InventoryCsv C:\Temp\automation-inventory.csv -PostureJson C:\Temp\guardrail-posture.json
        InventoryCsv columns: Platform,ArtifactId,Name,Owner,Scopes,DataSources,Sharing,Environment,Tier
        PostureJson keys (record your Admin/AppSheet console settings for your-domain), e.g.:
            { "UnconfiguredApps":"Blocked", "HighRiskScopeRestriction":true,
              "AppSheetExternalSharing":"Blocked", "AppSheetExternalSources":"Blocked",
              "RequireSignIn":true, "DeployControl":true }
        Read-only Workspace/AppSheet admin visibility is enough to populate both inputs.
    EXPECTED RESULTS
        A per-gate result (Pass / Fail / N-A) with the artifacts that fail each gate. The pilot expands
        only when the required gates pass. No system is changed. Exit code 0 = all required gates pass;
        3 = one or more required gates failed.
.NOTES
    White-label — the repeatable way. Read-only where it reads live systems.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InventoryCsv,
    [Parameter(Mandatory)][string]$PostureJson
)

foreach ($f in @($InventoryCsv, $PostureJson)) {
    if (-not (Test-Path $f)) { Write-Host "Input not found: $f" -ForegroundColor Red; exit 2 }
}
$rows    = Import-Csv $InventoryCsv
$posture = Get-Content $PostureJson -Raw | ConvertFrom-Json

$results = New-Object System.Collections.Generic.List[object]
function Add-Gate([string]$name, [bool]$pass, [string]$detail) {
    $results.Add([pscustomobject]@{ Gate = $name; Result = if ($pass) { 'Pass' } else { 'Fail' }; Detail = $detail })
}

# Gate 1 — App access control posture: unconfigured apps must not be left open.
$g1 = $posture.UnconfiguredApps -and $posture.UnconfiguredApps -ne 'AllowAny'
Add-Gate 'App access control posture' $g1 ("UnconfiguredApps = {0}" -f $posture.UnconfiguredApps)

# Gate 2 — High-risk OAuth scope restriction (edition-gated; N-A allowed).
if ($null -eq $posture.HighRiskScopeRestriction) {
    $results.Add([pscustomobject]@{ Gate = 'High-risk OAuth scope restriction'; Result = 'N-A'; Detail = 'edition-gated / not recorded' })
} else {
    Add-Gate 'High-risk OAuth scope restriction' ([bool]$posture.HighRiskScopeRestriction) ("restricted = {0}" -f $posture.HighRiskScopeRestriction)
}

# Gate 3 — AppSheet external sharing blocked (posture) AND no app currently shared externally.
$extShared = $rows | Where-Object { $_.Platform -eq 'AppSheet' -and $_.Sharing -in 'External','Anyone' }
$g3 = ($posture.AppSheetExternalSharing -eq 'Blocked') -and (-not $extShared)
Add-Gate 'AppSheet external sharing blocked' $g3 (
    "posture={0}; externally-shared apps={1}" -f $posture.AppSheetExternalSharing, ($extShared | Measure-Object).Count)

# Gate 4 — AppSheet external data sources / webhooks restricted.
$g4 = $posture.AppSheetExternalSources -eq 'Blocked'
Add-Gate 'AppSheet external sources restricted' $g4 ("posture = {0}" -f $posture.AppSheetExternalSources)

# Gate 5 — Require sign-in.
$g5 = [bool]$posture.RequireSignIn
Add-Gate 'Require sign-in (AppSheet)' $g5 ("RequireSignIn = {0}" -f $posture.RequireSignIn)

# Gate 6 — Deploy control (review model enforceable).
$g6 = [bool]$posture.DeployControl
Add-Gate 'Deploy control enforced' $g6 ("DeployControl = {0}" -f $posture.DeployControl)

# Gate 7 — Owner of record on every deployed artifact.
$noOwnerProd = $rows | Where-Object { $_.Environment -eq 'Production' -and [string]::IsNullOrWhiteSpace($_.Owner) }
$g7 = -not $noOwnerProd
Add-Gate 'Owner of record (production)' $g7 ("ownerless production artifacts = {0}" -f ($noOwnerProd | Measure-Object).Count)

Write-Host "`n=== Guardrail conformance gates ===" -ForegroundColor Cyan
$results | Format-Table Gate, Result, Detail -AutoSize

if ($extShared) {
    Write-Host "`nAppSheet apps shared externally (review or remediate):" -ForegroundColor Yellow
    $extShared | Format-Table Name, Owner, Sharing -AutoSize
}
if ($noOwnerProd) {
    Write-Host "Production artifacts with no owner of record:" -ForegroundColor Yellow
    $noOwnerProd | Format-Table Platform, Name, Environment -AutoSize
}

$failed = $results | Where-Object { $_.Result -eq 'Fail' }
if ($failed) {
    Write-Host ("`n{0} required gate(s) failed — do not expand the pilot until resolved." -f $failed.Count) -ForegroundColor Red
    exit 3
}
Write-Host "`nAll required gates pass (Gate 2 Pass or documented N-A). Safe to proceed." -ForegroundColor Green
exit 0

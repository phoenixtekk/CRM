<#
.SYNOPSIS
    LICCOMP-Validation.ps1 — confirm the entitlement and deployment inputs are reconcilable.
.DESCRIPTION
    PURPOSE
        Gate-checks the two ELP inputs before you trust the numbers. Confirms the
        "Entitlement Baseline - <Publisher/Product> - Source" and the
        "Deployment Inventory - <Publisher/Product> - Discovered" are present, have the required
        columns, carry a proof reference per entitlement line, and share at least one common product
        key after normalization. Read-only — it changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\LICCOMP-Validation.ps1 `
          -EntitlementCsv .\entitlements.csv -DeploymentCsv .\deployment.csv
        Entitlement CSV expected columns: Product, Edition, Metric, Quantity, ProofRef
        Deployment  CSV expected columns: Device/User, Product, Edition, Version
    EXPECTED RESULTS
        "INPUTS RECONCILABLE" (exit 0) when both inputs are complete and share a product key;
        otherwise a list of the gaps to fix (exit 1).
.NOTES
    Workplace Marketplace — Asset Mgt. Read-only. Generic CSV in.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$EntitlementCsv,
    [Parameter(Mandatory)] [string]$DeploymentCsv
)

$issues = @()
function Need($path,$label){ if (-not (Test-Path $path)) { $script:issues += "Missing $label : $path"; return $null } Import-Csv -Path $path }

Write-Host "`n=== ELP input validation ===" -ForegroundColor Cyan
$ent = Need $EntitlementCsv "entitlement baseline"
$dep = Need $DeploymentCsv "deployment inventory"

if ($ent) {
    $entCols = ($ent | Get-Member -MemberType NoteProperty).Name
    foreach ($c in 'Product','Edition','Metric','Quantity','ProofRef') {
        if ($entCols -notcontains $c) { $issues += "Entitlement baseline missing column: $c" }
    }
    if ($entCols -contains 'ProofRef') {
        $unproven = @($ent | Where-Object { -not $_.ProofRef })
        if ($unproven.Count -gt 0) { $issues += ("{0} entitlement line(s) have no ProofRef (count as zero in an audit)" -f $unproven.Count) }
    }
    Write-Host ("Entitlement lines : {0}" -f @($ent).Count)
}
if ($dep) {
    $depCols = ($dep | Get-Member -MemberType NoteProperty).Name
    if ($depCols -notcontains 'Product') { $issues += "Deployment inventory missing column: Product" }
    Write-Host ("Deployment records: {0}" -f @($dep).Count)
}

# Shared product key check (case-insensitive, trimmed).
if ($ent -and $dep) {
    $entKeys = $ent | ForEach-Object { ($_.Product).Trim().ToLower() } | Sort-Object -Unique
    $depKeys = $dep | ForEach-Object { ($_.Product).Trim().ToLower() } | Sort-Object -Unique
    $common  = $entKeys | Where-Object { $depKeys -contains $_ }
    Write-Host ("Common product keys: {0}" -f @($common).Count)
    if (@($common).Count -eq 0) { $issues += "No common product key after trim/lowercase — add a normalization mapping in the ELP workbook" }
}

if ($issues.Count -eq 0) {
    Write-Host "`nResult: INPUTS RECONCILABLE" -ForegroundColor Green; exit 0
} else {
    Write-Host "`nResult: NOT RECONCILABLE — fix:" -ForegroundColor Yellow
    $issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    exit 1
}

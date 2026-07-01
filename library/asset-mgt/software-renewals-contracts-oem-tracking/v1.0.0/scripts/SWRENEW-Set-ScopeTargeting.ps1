<#
.SYNOPSIS
    SWRENEW-Set-ScopeTargeting.ps1 — build the renewal-owner routing groups (pilot and all-products).
.DESCRIPTION
    PURPOSE
        Derives the renewal-owner routing from the Contract & Entitlement Repository CSV and writes
        two routing artifacts used to send lead-time alerts to the right person:
          - "Renewal Owners - Pilot Scope - Group"  (contracts in the pilot product family)
          - "Renewal Owners - All Products - Group"  (every contract with an owner)
        Each group maps Owner -> the contracts they are responsible for. Optionally creates matching
        Microsoft Entra security groups via Graph for alert distribution.
    HOW TO RUN
        CSV routing only:   powershell -ExecutionPolicy Bypass -File .\SWRENEW-Set-ScopeTargeting.ps1 -CsvPath .\repository.csv -PilotProductFamily "Adobe" -OutDir .\reports
        Also create Entra groups: add -CreateEntraGroups  (requires Group.ReadWrite.All)
    EXPECTED RESULTS
        Two CSV routing files in -OutDir (pilot and all-products), each listing Owner, contracts, and
        contract count. With -CreateEntraGroups, the two named security groups are created if missing.
.NOTES
    Software Asset Management — repeatable renewal/contract process.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)][string]$CsvPath,
    [string]$PilotProductFamily,
    [string]$OutDir = '.\reports',
    [switch]$CreateEntraGroups
)

Write-Host "=== Software Renewals — Scope Targeting ===" -ForegroundColor Cyan
if (-not (Test-Path $CsvPath)) { Write-Host "Repository not found: $CsvPath" -ForegroundColor Red; exit 1 }
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

$rows = @(Import-Csv $CsvPath) | Where-Object { $_.Owner }

function Build-Routing($set) {
    $set | Group-Object Owner | ForEach-Object {
        [pscustomobject]@{
            Owner     = $_.Name
            Contracts = (($_.Group | ForEach-Object { $_.Product }) -join '; ')
            Count     = $_.Count
        }
    } | Sort-Object Owner
}

# All-products group
$allRouting = Build-Routing $rows
$allPath = Join-Path $OutDir 'renewal-owners-all-products-group.csv'
$allRouting | Export-Csv -Path $allPath -NoTypeInformation
Write-Host ("Renewal Owners - All Products - Group : {0} owner(s) -> {1}" -f @($allRouting).Count, $allPath) -ForegroundColor Green

# Pilot-scope group
if ($PilotProductFamily) {
    $pilotRows = $rows | Where-Object { $_.Product -like "*$PilotProductFamily*" -or $_.Vendor -like "*$PilotProductFamily*" }
    $pilotRouting = Build-Routing $pilotRows
    $pilotPath = Join-Path $OutDir 'renewal-owners-pilot-scope-group.csv'
    $pilotRouting | Export-Csv -Path $pilotPath -NoTypeInformation
    Write-Host ("Renewal Owners - Pilot Scope - Group  : {0} owner(s) -> {1}" -f @($pilotRouting).Count, $pilotPath) -ForegroundColor Green
} else {
    Write-Host "No -PilotProductFamily given; pilot-scope group skipped." -ForegroundColor Yellow
}

# Optional: create matching Entra security groups for alert distribution
if ($CreateEntraGroups) {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'Group.ReadWrite.All' -NoWelcome
    $names = @('Renewal Owners - All Products - Group')
    if ($PilotProductFamily) { $names += 'Renewal Owners - Pilot Scope - Group' }
    foreach ($n in $names) {
        $existing = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'" -f $n)).value
        if ($existing) { Write-Host ("Exists: {0}" -f $n) -ForegroundColor Green; continue }
        $body = @{ displayName=$n; mailEnabled=$false; mailNickname=($n -replace '[^a-zA-Z0-9]',''); securityEnabled=$true }
        Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json) | Out-Null
        Write-Host ("Created: {0}" -f $n) -ForegroundColor Green
    }
    Disconnect-MgGraph | Out-Null
}

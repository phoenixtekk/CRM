<#
.SYNOPSIS
    WS1POL-Validation.ps1 — parity check between the Workspace ONE source inventory and deployed Intune policy.
.DESCRIPTION
    PURPOSE
        Reads the normalized source inventory (from WS1POL-Discovery.ps1) and the deployed Intune
        configuration + compliance policies, then reports parity per platform: which mapped policies
        exist in Intune for each platform and the source-versus-target setting counts. This is the
        data behind the parity gate; the human gap register records map/substitute/defer/accept-gap
        decisions that a tool cannot infer.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WS1POL-Validation.ps1 -InventoryCsv C:\Temp\ws1-inventory.csv
        Requires Microsoft Graph SDK and DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        Per-platform: source setting count, the matching 'Mapped Config - <Platform>' settings-catalog
        policy and its setting count, and the 'Mapped Compliance - <Platform>' policy. A platform with
        no matching mapped policy is flagged for follow-up.
.NOTES
    Workspace ONE to Intune migration — read-only against Microsoft Graph.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)][string]$InventoryCsv
)

if (-not (Test-Path $InventoryCsv)) { Write-Host "Inventory not found: $InventoryCsv (run WS1POL-Discovery.ps1 first)" -ForegroundColor Yellow; exit 1 }
$inv = Import-Csv -Path $InventoryCsv

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' -NoWelcome

# Settings catalog configuration policies (configurationPolicies) with setting counts.
$cfgPolicies = @()
$uri = '/beta/deviceManagement/configurationPolicies?$select=id,name,platforms'
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $cfgPolicies += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)

# Compliance policies (deviceCompliancePolicies).
$compPolicies = @()
$uri = '/v1.0/deviceManagement/deviceCompliancePolicies?$select=id,displayName'
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $compPolicies += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)

function Get-SettingCount($policyId) {
    try { (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies/$policyId/settings").value.Count }
    catch { 0 }
}

$platforms = @('Windows','iOS','Android','macOS')
Write-Host "`n=== Parity check (source inventory vs Intune) ===" -ForegroundColor Cyan
foreach ($pf in $platforms) {
    $srcCount = ($inv | Where-Object { $_.Platform -match $pf }).Count
    $mappedCfg = $cfgPolicies | Where-Object { $_.name -match "Mapped Config - $pf" }
    $mappedComp = $compPolicies | Where-Object { $_.displayName -match "Mapped Compliance - $pf" }
    Write-Host ("`n[{0}] source settings: {1}" -f $pf, $srcCount)
    if ($mappedCfg) {
        foreach ($c in $mappedCfg) { Write-Host ("  config : {0}  ({1} settings)" -f $c.name, (Get-SettingCount $c.id)) -ForegroundColor Green }
    } else { Write-Host "  config : NONE found — expected 'Mapped Config - $pf - ...'" -ForegroundColor Yellow }
    if ($mappedComp) {
        foreach ($c in $mappedComp) { Write-Host ("  compliance : {0}" -f $c.displayName) -ForegroundColor Green }
    } else { Write-Host "  compliance : NONE found — expected 'Mapped Compliance - $pf - ...'" -ForegroundColor Yellow }
}

Write-Host "`nParity gate passes per platform only when every source setting is mapped/substituted/deferred/" -ForegroundColor Cyan
Write-Host "accepted-gap in the gap register, effective values match, and compliance gates the same access." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null

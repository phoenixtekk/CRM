<#
.SYNOPSIS
    DGSNOW-Discover.ps1 — Inventory Purview Data Map collections, registered sources, scans, and integration
    runtimes (read-only).
.DESCRIPTION
    PURPOSE
        Reports the current Data Map state for planning Snowflake onboarding: the collections, existing
        registered data sources and their scans, and any registered integration runtimes. Uses the Purview
        Data Map REST API with a bearer token acquired at runtime (Connect-AzAccount). Read-only — makes no
        change and stores no secret.
    HOW TO RUN
        .\DGSNOW-Discover.ps1 -PurviewAccount "<your-purview-account>"
        PowerShell 5.1+/7+. Connect first with Connect-AzAccount (modern-auth/MFA admin). Az.Accounts module.
    EXPECTED RESULTS
        A list of collections, sources+scans, and integration runtimes — captured into
        'Snowflake Governance - Map'. Makes no configuration change.
.NOTES
    Purview — Snowflake Data Governance. Read-only discovery. Verify your licensing/tenant: the Data Map
    REST surface + Snowflake connector are evolving; confirm the current API version and portal flow.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$PurviewAccount,
    [string]$ApiVersion = '2022-07-01-preview'      # verify the current Data Map API version for your account
)

function Get-PurviewToken {
    try { return (Get-AzAccessToken -ResourceUrl 'https://purview.azure.net' -ErrorAction Stop).Token }
    catch { Write-Host "Could not acquire a Purview token. Run Connect-AzAccount first." -ForegroundColor Yellow; return $null }
}

$token = Get-PurviewToken
if (-not $token) { return }
$headers = @{ Authorization = "Bearer $token" }
$base = "https://$PurviewAccount.purview.azure.com"

function Invoke-Pv([string]$Path) {
    try { return Invoke-RestMethod -Method GET -Uri ("{0}{1}" -f $base, $Path) -Headers $headers -ErrorAction Stop }
    catch { Write-Host ("  GET {0} failed: {1}" -f $Path, $_.Exception.Message) -ForegroundColor DarkYellow; return $null }
}

Write-Host "`n=== Snowflake Data Governance — discovery (read-only) ===" -ForegroundColor Cyan
Write-Host ("Purview account: {0}" -f $PurviewAccount) -ForegroundColor DarkGray

# Collections
$col = Invoke-Pv "/collections?api-version=2019-11-01-preview"
if ($col -and $col.value) {
    Write-Host ("`nCollections ({0}):" -f $col.value.Count) -ForegroundColor Green
    $col.value | Select-Object name, friendlyName | Format-Table -AutoSize
} else { Write-Host "`nNo collections read (verify account name + permissions + API version)." -ForegroundColor DarkGray }

# Registered sources (scan dataSources)
$src = Invoke-Pv "/scan/datasources?api-version=$ApiVersion"
if ($src -and $src.value) {
    Write-Host ("Registered sources ({0}):" -f $src.value.Count) -ForegroundColor Green
    foreach ($s in $src.value) {
        Write-Host ("  Source: {0} | Kind: {1}" -f $s.name, $s.kind) -ForegroundColor White
        $scans = Invoke-Pv ("/scan/datasources/{0}/scans?api-version={1}" -f $s.name, $ApiVersion)
        if ($scans -and $scans.value) { foreach ($sc in $scans.value) { Write-Host ("    Scan: {0} | Kind: {1}" -f $sc.name, $sc.kind) -ForegroundColor DarkGray } }
    }
} else { Write-Host "Registered sources: none read (or none registered yet)." -ForegroundColor DarkGray }

# Integration runtimes
$ir = Invoke-Pv "/scan/integrationruntimes?api-version=$ApiVersion"
if ($ir -and $ir.value) {
    Write-Host ("Integration runtimes ({0}):" -f $ir.value.Count) -ForegroundColor Green
    $ir.value | Select-Object name, @{n='type';e={$_.properties.type}} | Format-Table -AutoSize
} else { Write-Host "Integration runtimes: none read (a self-hosted IR may be required for Snowflake)." -ForegroundColor DarkGray }

Write-Host "`nRecord collections, sources/scans, and runtimes in 'Snowflake Governance - Map'." -ForegroundColor DarkGray

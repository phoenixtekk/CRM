<#
.SYNOPSIS
    UPRTG-Discovery.ps1 — read-only discovery of Universal Print state on a GCC High tenant.
.DESCRIPTION
    PURPOSE
        Inventories the current Universal Print footprint on a US sovereign-cloud (GCC High)
        tenant: printers, printer shares, and connectors as seen by Microsoft Graph US Gov,
        plus a reachability check of the GCC High Universal Print service endpoints. Read-only:
        it changes nothing. Use it at the Assess gate to baseline the 'from' state.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\UPRTG-Discovery.ps1
        (Graph scopes: Printer.Read.All, PrinterShare.Read.All, PrintConnector.Read.All; -Environment USGov)
        Optional: -OutputPath 'your-output-folder' to write a CSV inventory.
    EXPECTED RESULTS
        Sign-in opens login.microsoftonline.us. The script prints whether Universal Print is
        reachable, counts of printers/shares/connectors, and PASS/FAIL for each GCC High
        endpoint. PASS overall = UP reachable and endpoints reachable.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string]$OutputPath = "."
)

$ErrorActionPreference = 'Stop'

# GCC High Universal Print service endpoints (US sovereign cloud).
$GccHighEndpoints = @(
    'https://print.print.azure.us',
    'https://register.print.azure.us',
    'https://discovery.print.azure.us',
    'https://notification.print.azure.us',
    'https://graph.print.azure.us',
    'https://login.microsoftonline.us',
    'https://graph.microsoft.us'
)

function Write-Section([string]$Title) {
    Write-Host ""
    Write-Host "==== $Title ====" -ForegroundColor Cyan
}

Write-Section "Universal Print Discovery (GCC High) — read-only"

# --- Ensure Microsoft Graph module ---
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Warning "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    return
}

# --- Connect to US Gov Graph (GCC High) ---
try {
    Write-Host "Connecting to Microsoft Graph (US Gov / GCC High)..." -ForegroundColor Yellow
    Connect-MgGraph -Environment USGov -Scopes "Printer.Read.All","PrinterShare.Read.All","PrintConnector.Read.All" -NoWelcome
    $ctx = Get-MgContext
    Write-Host "Connected as: $($ctx.Account)  Environment: $($ctx.Environment)" -ForegroundColor Green
    if ($ctx.Environment -ne 'USGov') {
        Write-Warning "Graph environment is '$($ctx.Environment)', not 'USGov'. GCC High requires -Environment USGov."
    }
}
catch {
    Write-Warning "Graph sign-in failed: $($_.Exception.Message)"
    Write-Warning "For GCC High you must sign in at login.microsoftonline.us via -Environment USGov."
    return
}

$overallPass = $true

# --- Universal Print reachability via Graph (read-only) ---
Write-Section "Universal Print inventory (via graph.microsoft.us)"
$printers = @(); $shares = @(); $connectors = @()

# Read Universal Print objects via the Graph /print resource (works against graph.microsoft.us
# because the connection was established with -Environment USGov).
try {
    $printers = @(Invoke-MgGraphRequest -Method GET -Uri "/v1.0/print/printers" -ErrorAction Stop).value
    Write-Host ("Printers registered: {0}" -f $printers.Count) -ForegroundColor Green
    foreach ($p in $printers) { Write-Host ("  - {0}" -f $p.displayName) }
}
catch {
    $overallPass = $false
    Write-Warning "Could not read /print/printers: $($_.Exception.Message)"
    Write-Warning "Confirm the account holds an eligible GCC High Universal Print license (all users incl. admins)."
}

try {
    $shares = @(Invoke-MgGraphRequest -Method GET -Uri "/v1.0/print/shares" -ErrorAction Stop).value
    Write-Host ("Printer shares: {0}" -f $shares.Count) -ForegroundColor Green
    foreach ($s in $shares) { Write-Host ("  - {0}" -f $s.displayName) }
}
catch {
    Write-Warning "Could not read /print/shares: $($_.Exception.Message)"
}

try {
    $connectors = @(Invoke-MgGraphRequest -Method GET -Uri "/v1.0/print/connectors" -ErrorAction Stop).value
    Write-Host ("Connectors: {0}" -f $connectors.Count) -ForegroundColor Green
    foreach ($c in $connectors) { Write-Host ("  - {0}  (registered: {1})" -f $c.displayName, $c.registeredDateTime) }
}
catch {
    Write-Warning "Could not read /print/connectors: $($_.Exception.Message)"
}

# --- Endpoint reachability (GCC High) ---
Write-Section "GCC High endpoint reachability (outbound 443)"
$endpointResults = foreach ($url in $GccHighEndpoints) {
    $targetHost = ([System.Uri]$url).Host
    $ok = Test-NetConnection -ComputerName $targetHost -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($ok) { Write-Host ("  PASS  {0}" -f $url) -ForegroundColor Green }
    else     { Write-Host ("  FAIL  {0}" -f $url) -ForegroundColor Red; $overallPass = $false }
    [pscustomobject]@{ Endpoint = $url; Reachable = [bool]$ok }
}

# --- Optional CSV output ---
try {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }
    $endpointResults | Export-Csv (Join-Path $OutputPath "UPRTG-Discovery-endpoints-$stamp.csv") -NoTypeInformation
    $printers | Select-Object displayName,id | Export-Csv (Join-Path $OutputPath "UPRTG-Discovery-printers-$stamp.csv") -NoTypeInformation
    Write-Host "`nCSV inventory written to $OutputPath" -ForegroundColor Green
}
catch { Write-Warning "Could not write CSV output: $($_.Exception.Message)" }

# --- Summary ---
Write-Section "Discovery summary"
Write-Host ("Printers: {0}  Shares: {1}  Connectors: {2}" -f $printers.Count, $shares.Count, $connectors.Count)
if ($overallPass) { Write-Host "OVERALL: PASS — Universal Print reachable on GCC High and endpoints reachable." -ForegroundColor Green }
else              { Write-Host "OVERALL: FAIL — see warnings above (licensing, -Environment USGov, or endpoint access)." -ForegroundColor Red }

Disconnect-MgGraph | Out-Null

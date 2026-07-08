<#
.SYNOPSIS
    DGSNOW-Validate.ps1 — Validate the Snowflake source is registered, the scan exists, and the last run
    completed (read-only).
.DESCRIPTION
    PURPOSE
        The pilot/expansion gate. Confirms PASS/FAIL that 'Snowflake - Source' is registered, 'Snowflake -
        Scan' exists, and the most recent scan run completed successfully — via the Purview Data Map REST
        API with a token acquired at runtime. Read-only; stores no secret. Run on the pilot before expanding.
    HOW TO RUN
        .\DGSNOW-Validate.ps1 -PurviewAccount "<your-purview-account>"
        PowerShell 5.1+/7+. Connect first with Connect-AzAccount. No secret is stored in the script.
    EXPECTED RESULTS
        A PASS/FAIL line per gate; overall PASS only when the source + scan exist and the last run succeeded.
        Any FAIL names the specific missing object or the failed run status. (Confirm classifications in the
        catalog UI — the deep asset/classification check is done in the portal.)
.NOTES
    Purview — Snowflake Data Governance. Read-only gate. Verify your licensing/tenant: the scan-run status
    schema + API version evolve; confirm against your account.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$PurviewAccount,
    [string]$SourceName = 'Snowflake - Source',
    [string]$ScanName   = 'Snowflake - Scan',
    [string]$ApiVersion = '2022-07-01-preview'
)

function Get-PurviewToken {
    try { return (Get-AzAccessToken -ResourceUrl 'https://purview.azure.net' -ErrorAction Stop).Token }
    catch { Write-Host "Could not acquire a Purview token. Run Connect-AzAccount first." -ForegroundColor Yellow; return $null }
}

$token = Get-PurviewToken
if (-not $token) { return }
$headers = @{ Authorization = "Bearer $token" }
$base = "https://$PurviewAccount.purview.azure.com"
$fail = 0
function Gate([string]$Name, [bool]$Ok, [string]$Detail) {
    if ($Ok) { Write-Host ("PASS  {0} — {1}" -f $Name, $Detail) -ForegroundColor Green }
    else     { Write-Host ("FAIL  {0} — {1}" -f $Name, $Detail) -ForegroundColor Red; $script:fail++ }
}
function Invoke-Pv([string]$Path) {
    try { return Invoke-RestMethod -Method GET -Uri ("{0}{1}" -f $base, $Path) -Headers $headers -ErrorAction Stop }
    catch { return $null }
}

Write-Host "`n=== Snowflake Data Governance — validation gate (read-only) ===" -ForegroundColor Cyan

$src = Invoke-Pv ("/scan/datasources/{0}?api-version={1}" -f $SourceName, $ApiVersion)
Gate ("Source registered: {0}" -f $SourceName) ([bool]$src) $(if($src){("kind = {0}" -f $src.kind)}else{'not found — register it (Implementation Step 3)'})

$scan = Invoke-Pv ("/scan/datasources/{0}/scans/{1}?api-version={2}" -f $SourceName, $ScanName, $ApiVersion)
Gate ("Scan exists: {0}" -f $ScanName) ([bool]$scan) $(if($scan){'found'}else{'not found — create it (Implementation Step 4)'})

if ($scan) {
    $runs = Invoke-Pv ("/scan/datasources/{0}/scans/{1}/runs?api-version={2}" -f $SourceName, $ScanName, $ApiVersion)
    $last = if ($runs -and $runs.value) { $runs.value | Select-Object -First 1 } else { $null }
    if ($last) {
        $status = $last.status
        $ok = ("{0}" -f $status) -match 'Succeeded|Completed'
        Gate 'Last scan run completed' $ok ("status = {0}" -f $status)
    } else {
        Gate 'Last scan run completed' $false 'no runs found — trigger a scan (-Action RunScan) on the pilot scope'
    }
}

Write-Host "`nConfirm in the Purview catalog (portal): the pilot database's tables/columns are discoverable as" -ForegroundColor Cyan
Write-Host "assets and expected classifications applied to sensitive columns." -ForegroundColor Cyan

Write-Host ""
if ($fail -eq 0) { Write-Host "OVERALL: PASS — source + scan present and last run completed. Confirm assets/classifications in the catalog, then expand." -ForegroundColor Green }
else             { Write-Host ("OVERALL: FAIL — {0} gate(s) failed. Remediate before expanding." -f $fail) -ForegroundColor Red }

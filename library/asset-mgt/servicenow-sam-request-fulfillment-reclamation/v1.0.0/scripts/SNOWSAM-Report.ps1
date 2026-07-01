<#
.SYNOPSIS
    SNOWSAM-Report.ps1 — request and reclamation KPI report from ServiceNow (read-only).
.DESCRIPTION
    PURPOSE
        Builds the "KPI Set - Request & Reclamation - Reporting" snapshot from ServiceNow via the REST
        Table API: request volume and state breakdown, average time-to-fulfill, reclamation count and
        reclaimed units, and entitlement pool utilization (available vs allocated). Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SNOWSAM-Report.ps1 `
            -InstanceUrl https://<your-instance>.service-now.com -Credential (Get-Credential) `
            -CsvPath C:\Temp\snowsam-kpi.csv
    EXPECTED RESULTS
        Console KPI summary plus an optional per-entitlement CSV (product, purchased, allocated,
        available, utilization%).
.NOTES
    Read-only. Table/field names are instance-specific placeholders — confirm in ServiceNow's Table API
    docs and override via parameters. Time-to-fulfill assumes a fulfillment timestamp is stamped at
    fulfillment (see Implementation Step 5).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$InstanceUrl,
    [Parameter(Mandatory)] [pscredential]$Credential,
    # INSTANCE-SPECIFIC: confirm/override these table names for your instance.
    [string]$RequestTable     = 'sc_req_item',
    [string]$EntitlementTable = 'samp_sw_entitlement',
    [string]$ReclamationTable = 'samp_sw_reclamation',
    [int]$Limit = 1000,
    [string]$CsvPath
)

function Get-SnowTable {
    param([string]$Table, [string]$Query, [string]$Fields)
    $uri = "$($InstanceUrl.TrimEnd('/'))/api/now/table/$Table?sysparm_limit=$Limit"
    if ($Query)  { $uri += "&sysparm_query=$([uri]::EscapeDataString($Query))" }
    if ($Fields) { $uri += "&sysparm_fields=$([uri]::EscapeDataString($Fields))" }
    try { return (Invoke-RestMethod -Method GET -Uri $uri -Credential $Credential -Headers @{ Accept='application/json' } -ErrorAction Stop).result }
    catch { Write-Host ("  Could not read '{0}': {1}" -f $Table, $_.Exception.Message) -ForegroundColor Yellow; return @() }
}

Write-Host "`n=== KPI Set - Request & Reclamation - Reporting ($InstanceUrl) ===" -ForegroundColor Cyan

# --- Requests ---
$reqs = Get-SnowTable -Table $RequestTable -Fields 'number,state,sys_created_on,closed_at'
Write-Host ("Total request records  : {0}" -f @($reqs).Count)
if ($reqs) {
    $reqs | Group-Object state | Sort-Object Count -Descending |
        Select-Object Count, @{n='State';e={$_.Name}} | Format-Table -AutoSize
    $durations = foreach ($r in $reqs) {
        if ($r.sys_created_on -and $r.closed_at) {
            $c = $null; $f = $null
            if ([datetime]::TryParse($r.sys_created_on,[ref]$c) -and [datetime]::TryParse($r.closed_at,[ref]$f)) { ($f - $c).TotalHours }
        }
    }
    $durations = @($durations | Where-Object { $_ -ne $null })
    if ($durations.Count) {
        $avg = ($durations | Measure-Object -Average).Average
        Write-Host ("Avg time-to-fulfill    : {0:N1} hours over {1} closed requests" -f $avg, $durations.Count) -ForegroundColor Cyan
    }
}

# --- Reclamation ---
$recl = Get-SnowTable -Table $ReclamationTable -Fields 'number,units,sys_created_on'
$reclUnits = 0
foreach ($x in $recl) { $u = 0; [void][int]::TryParse("$($x.units)",[ref]$u); $reclUnits += $u }
Write-Host ("Reclamation events     : {0}; reclaimed units: {1}" -f @($recl).Count, $reclUnits) -ForegroundColor Cyan

# --- Pool utilization ---
$ents = Get-SnowTable -Table $EntitlementTable -Fields 'display_name,rights,allocated'
$poolReport = foreach ($e in $ents) {
    $p = 0; $a = 0; [void][int]::TryParse("$($e.rights)",[ref]$p); [void][int]::TryParse("$($e.allocated)",[ref]$a)
    [pscustomobject]@{
        Product = $e.display_name; Purchased = $p; Allocated = $a; Available = ($p - $a)
        UtilizationPct = $(if ($p -gt 0) { [math]::Round(($a / $p) * 100, 1) } else { 0 })
    }
}
if ($poolReport) {
    Write-Host "`n--- Entitlement pool utilization ---" -ForegroundColor Cyan
    $poolReport | Sort-Object UtilizationPct -Descending | Format-Table -AutoSize
    if ($CsvPath) { $poolReport | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" -ForegroundColor Green }
}
Write-Host "`nReport complete (read-only)." -ForegroundColor Green

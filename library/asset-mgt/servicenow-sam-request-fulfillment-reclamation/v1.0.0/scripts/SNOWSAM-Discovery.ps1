<#
.SYNOPSIS
    SNOWSAM-Discovery.ps1 — read request, entitlement, and usage records from ServiceNow (read-only).
.DESCRIPTION
    PURPOSE
        Reads the current SAM posture from a ServiceNow instance via the REST Table API: open software
        requests, software entitlement records (purchased vs allocated), and software usage/install
        records. Read-only — it makes only GET calls and changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SNOWSAM-Discovery.ps1 `
            -InstanceUrl https://<your-instance>.service-now.com -Credential (Get-Credential)
        Optionally pass -EntitlementTable / -RequestTable / -UsageTable to match your instance's tables.
    EXPECTED RESULTS
        A summary count of open requests, entitlement records with available = purchased - allocated,
        and usage records, plus an optional CSV export.
.NOTES
    Read-only. ServiceNow table/field names are instance-specific — the defaults below are generic
    placeholders. Confirm the correct table names for your instance in ServiceNow's Table API docs and
    override with the parameters; do not assume these tables exist as-is.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$InstanceUrl,
    [Parameter(Mandatory)] [pscredential]$Credential,
    # INSTANCE-SPECIFIC: replace with the actual table names in your ServiceNow SAM instance.
    [string]$RequestTable     = 'sc_req_item',
    [string]$EntitlementTable = 'samp_sw_entitlement',
    [string]$UsageTable       = 'samp_sw_install',
    [int]$Limit = 200,
    [string]$CsvPath
)

function Get-SnowTable {
    param([string]$Table, [string]$Query, [string]$Fields)
    # Generic ServiceNow REST Table API GET. See ServiceNow's Table API documentation for query syntax.
    $uri = "$($InstanceUrl.TrimEnd('/'))/api/now/table/$Table?sysparm_limit=$Limit"
    if ($Query)  { $uri += "&sysparm_query=$([uri]::EscapeDataString($Query))" }
    if ($Fields) { $uri += "&sysparm_fields=$([uri]::EscapeDataString($Fields))" }
    try {
        $resp = Invoke-RestMethod -Method GET -Uri $uri -Credential $Credential `
            -Headers @{ Accept = 'application/json' } -ErrorAction Stop
        return $resp.result
    } catch {
        Write-Host ("  Could not read table '{0}': {1}" -f $Table, $_.Exception.Message) -ForegroundColor Yellow
        return @()
    }
}

Write-Host "`n=== ServiceNow SAM — Discovery ($InstanceUrl) ===" -ForegroundColor Cyan

$requests = Get-SnowTable -Table $RequestTable -Query 'active=true' -Fields 'number,short_description,sys_created_on,state'
Write-Host ("Open request records   : {0}" -f @($requests).Count)

$ents = Get-SnowTable -Table $EntitlementTable -Fields 'display_name,rights,allocated'
$entReport = foreach ($e in $ents) {
    $purchased = 0; $allocated = 0
    [void][int]::TryParse("$($e.rights)", [ref]$purchased)
    [void][int]::TryParse("$($e.allocated)", [ref]$allocated)
    [pscustomobject]@{ Product = $e.display_name; Purchased = $purchased; Allocated = $allocated; Available = ($purchased - $allocated) }
}
Write-Host ("Entitlement records    : {0}" -f @($entReport).Count)
if ($entReport) { $entReport | Sort-Object Available | Format-Table -AutoSize }

$usage = Get-SnowTable -Table $UsageTable -Fields 'display_name,last_used,installed_on'
Write-Host ("Usage/install records  : {0}" -f @($usage).Count)

if ($CsvPath -and $entReport) { $entReport | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" -ForegroundColor Green }
Write-Host "`nDiscovery complete (read-only)." -ForegroundColor Green

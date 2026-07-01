<#
.SYNOPSIS
    SNOWSAM-Validation.ps1 — confirm the workflow artifacts and entitlement data are present (read-only).
.DESCRIPTION
    PURPOSE
        Verifies the named workflow artifacts exist and are consistent in ServiceNow via the REST Table
        API: the intake catalog items, the triage/entitlement/fulfillment/reclamation flows, the
        software models, and the entitlement records. Read-only — only GET calls.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SNOWSAM-Validation.ps1 `
            -InstanceUrl https://<your-instance>.service-now.com -Credential (Get-Credential)
    EXPECTED RESULTS
        "WORKFLOW PRESENT" when the expected catalog items, flows, and entitlement records are found;
        otherwise a list of what is missing.
.NOTES
    Read-only. Catalog/flow/entitlement table names are instance-specific — the defaults are generic
    placeholders. Confirm them in ServiceNow's Table API docs and override via parameters. Artifact
    names follow the convention <Purpose> - <Scope> - <Stage> used in the implementation guide.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$InstanceUrl,
    [Parameter(Mandatory)] [pscredential]$Credential,
    # INSTANCE-SPECIFIC: confirm/override these table names for your instance.
    [string]$CatalogItemTable = 'sc_cat_item',
    [string]$FlowTable        = 'sys_hub_flow',
    [string]$EntitlementTable = 'samp_sw_entitlement'
)

function Test-SnowName {
    param([string]$Table, [string]$NameField, [string]$NameValue)
    $q = "$NameField=$NameValue"
    $uri = "$($InstanceUrl.TrimEnd('/'))/api/now/table/$Table?sysparm_limit=1&sysparm_fields=sys_id&sysparm_query=$([uri]::EscapeDataString($q))"
    try {
        $resp = Invoke-RestMethod -Method GET -Uri $uri -Credential $Credential -Headers @{ Accept = 'application/json' } -ErrorAction Stop
        return (@($resp.result).Count -gt 0)
    } catch {
        Write-Host ("  Lookup failed for '{0}' in {1}: {2}" -f $NameValue, $Table, $_.Exception.Message) -ForegroundColor Yellow
        return $false
    }
}

Write-Host "=== ServiceNow SAM — Validation ($InstanceUrl) ===" -ForegroundColor Cyan
$missing = @()

$catalogItems = @('Software Request - Standard - Intake', 'Software Request - Restricted - Intake')
foreach ($c in $catalogItems) {
    $ok = Test-SnowName -Table $CatalogItemTable -NameField 'name' -NameValue $c
    Write-Host ("Catalog item : {0,-45} {1}" -f $c, ($(if($ok){'FOUND'}else{'MISSING'}))) -ForegroundColor ($(if($ok){'Green'}else{'Yellow'}))
    if (-not $ok) { $missing += $c }
}

$flows = @('Request Triage - Software - Triage','Entitlement Check - Software - Entitlement','License Fulfillment - Software - Fulfillment','License Reclamation - Unused - Reclamation')
foreach ($f in $flows) {
    $ok = Test-SnowName -Table $FlowTable -NameField 'name' -NameValue $f
    Write-Host ("Flow         : {0,-45} {1}" -f $f, ($(if($ok){'FOUND'}else{'MISSING'}))) -ForegroundColor ($(if($ok){'Green'}else{'Yellow'}))
    if (-not $ok) { $missing += $f }
}

# Entitlement consistency: available should not be negative (allocated must not exceed purchased).
$entUri = "$($InstanceUrl.TrimEnd('/'))/api/now/table/$EntitlementTable?sysparm_limit=500&sysparm_fields=display_name,rights,allocated"
$overAllocated = @()
try {
    $ents = (Invoke-RestMethod -Method GET -Uri $entUri -Credential $Credential -Headers @{ Accept='application/json' } -ErrorAction Stop).result
    foreach ($e in $ents) {
        $p = 0; $a = 0; [void][int]::TryParse("$($e.rights)",[ref]$p); [void][int]::TryParse("$($e.allocated)",[ref]$a)
        if ($a -gt $p) { $overAllocated += $e.display_name }
    }
    Write-Host ("Entitlement records read : {0}; over-allocated: {1}" -f @($ents).Count, @($overAllocated).Count) -ForegroundColor ($(if($overAllocated){'Yellow'}else{'Green'}))
    if ($overAllocated) { $overAllocated | ForEach-Object { Write-Host "  OVER-ALLOCATED: $_" -ForegroundColor Yellow } }
} catch {
    Write-Host ("Entitlement read failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    $missing += 'entitlement-data'
}

if (-not $missing -and -not $overAllocated) { Write-Host "`nResult: WORKFLOW PRESENT" -ForegroundColor Green; exit 0 }
else { Write-Host "`nResult: NOT FULLY PRESENT — build/fix the items above (see Implementation Guide)" -ForegroundColor Yellow; exit 1 }

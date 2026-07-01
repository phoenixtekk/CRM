<#
.SYNOPSIS
    SNOWSAM-Set-ScopeTargeting.ps1 — record and expand which products and groups are in workflow scope.
.DESCRIPTION
    PURPOSE
        Maintains the targeting scope for the request-to-reclamation workflow: which software products
        (models) and which catalog audiences / groups the workflow currently covers. Use it to define the
        pilot scope ("Pilot Scope - First Product Family - Pilot") and to expand to further product
        families after the pilot passes. Writes a local scope manifest (JSON) and, optionally, verifies
        the listed products and groups exist in ServiceNow via the read-only REST Table API.
    HOW TO RUN
        Define/expand the local scope manifest:
          powershell -ExecutionPolicy Bypass -File .\SNOWSAM-Set-ScopeTargeting.ps1 `
            -Products 'Product Family A','Product Family B' `
            -Groups 'Fulfillment Group - Software - Fulfillment','Approval Group - Restricted Software - Triage' `
            -ScopePath .\snowsam-scope.json
        Optionally verify against the instance (read-only):
          ... -InstanceUrl https://<your-instance>.service-now.com -Credential (Get-Credential) -Verify
    EXPECTED RESULTS
        A written/updated scope manifest listing in-scope products and groups; with -Verify, a
        FOUND/MISSING check of each against ServiceNow (read-only — no changes to the instance).
.NOTES
    The manifest write is local and safe. -Verify makes read-only GET calls only. Table/field names are
    instance-specific placeholders — confirm in ServiceNow's Table API docs and override via parameters.
    Actual catalog audience/scope changes are made in the Service Catalog designer (see Implementation
    Guide Step 9); this script records intent and verifies prerequisites, it does not re-scope catalog
    items in the platform.
#>
[CmdletBinding()]
param(
    [string[]]$Products = @(),
    [string[]]$Groups = @(),
    [string]$ScopePath = '.\snowsam-scope.json',
    [switch]$Verify,
    [string]$InstanceUrl,
    [pscredential]$Credential,
    # INSTANCE-SPECIFIC: confirm/override for -Verify.
    [string]$SoftwareModelTable = 'cmdb_software_product_model',
    [string]$GroupTable         = 'sys_user_group'
)

Write-Host "`n=== ServiceNow SAM — Scope Targeting ===" -ForegroundColor Cyan

# Load existing manifest (merge) or start fresh.
$scope = [ordered]@{ products = @(); groups = @(); updated = $null }
if (Test-Path $ScopePath) {
    try {
        $existing = Get-Content $ScopePath -Raw | ConvertFrom-Json
        if ($existing.products) { $scope.products = @($existing.products) }
        if ($existing.groups)   { $scope.groups   = @($existing.groups) }
    } catch { Write-Host "  Existing manifest unreadable; starting fresh." -ForegroundColor Yellow }
}

if ($Products) { $scope.products = @(($scope.products + $Products) | Select-Object -Unique) }
if ($Groups)   { $scope.groups   = @(($scope.groups   + $Groups)   | Select-Object -Unique) }
$scope.updated = (Get-Date).ToString('s')

$scope | ConvertTo-Json -Depth 5 | Set-Content -Path $ScopePath -Encoding UTF8
Write-Host ("Scope manifest written: {0}" -f $ScopePath) -ForegroundColor Green
Write-Host ("  In-scope products: {0}" -f ($scope.products -join ', '))
Write-Host ("  In-scope groups  : {0}" -f ($scope.groups -join ', '))

if ($Verify) {
    if (-not $InstanceUrl -or -not $Credential) { Write-Host "`n-Verify needs -InstanceUrl and -Credential." -ForegroundColor Yellow; exit 1 }
    $base = $InstanceUrl.TrimEnd('/')
    function Test-SnowName {
        param([string]$Table, [string]$Field, [string]$Value)
        $uri = "$base/api/now/table/$Table?sysparm_limit=1&sysparm_fields=sys_id&sysparm_query=$([uri]::EscapeDataString("$Field=$Value"))"
        try { return (@((Invoke-RestMethod -Method GET -Uri $uri -Credential $Credential -Headers @{Accept='application/json'} -ErrorAction Stop).result).Count -gt 0) }
        catch { Write-Host ("  Lookup failed for '{0}': {1}" -f $Value, $_.Exception.Message) -ForegroundColor Yellow; return $false }
    }
    Write-Host "`n--- Verify against instance (read-only) ---" -ForegroundColor Cyan
    foreach ($p in $scope.products) {
        $ok = Test-SnowName -Table $SoftwareModelTable -Field 'display_name' -Value $p
        Write-Host ("  Product {0,-30} {1}" -f $p, ($(if($ok){'FOUND'}else{'MISSING'}))) -ForegroundColor ($(if($ok){'Green'}else{'Yellow'}))
    }
    foreach ($g in $scope.groups) {
        $ok = Test-SnowName -Table $GroupTable -Field 'name' -Value $g
        Write-Host ("  Group   {0,-45} {1}" -f $g, ($(if($ok){'FOUND'}else{'MISSING'}))) -ForegroundColor ($(if($ok){'Green'}else{'Yellow'}))
    }
}
Write-Host "`nScope targeting complete." -ForegroundColor Green

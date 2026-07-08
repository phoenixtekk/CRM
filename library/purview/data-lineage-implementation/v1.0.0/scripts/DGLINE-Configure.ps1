<#
.SYNOPSIS
    DGLINE-Configure.ps1 — push custom data lineage (Atlas Process entities) to Purview; -WhatIf by default (safe).
.DESCRIPTION
    PURPOSE
        For source->report paths not covered by an automatic connector, creates CUSTOM lineage by pushing
        Apache Atlas "Process" entities (inputs/outputs referenced by qualified name) to the Purview catalog
        data-plane API, from a coverage-map CSV. SAFE BY DEFAULT: -WhatIf previews the exact payload and
        makes no changes; -Commit applies. Prints the created GUID and the reverse DELETE for rollback.
        Stores no secrets.
    HOW TO RUN
        Preview (default, no changes):
          powershell -File .\DGLINE-Configure.ps1 -Account <acct> -MapPath .\LineageMap.csv -WhatIf
        Apply (pilot path first):
          powershell -File .\DGLINE-Configure.ps1 -Account <acct> -MapPath .\LineageMap.csv -Commit
        MapPath CSV columns: ProcessName,ProcessType,InputQualifiedName,InputType,OutputQualifiedName,OutputType
        PowerShell 5.1+ or 7+. Requires Az.Accounts. Data curator role on the in-scope collection.
    EXPECTED RESULTS
        -WhatIf prints one Atlas Process payload per row and flags unresolved assets, changing nothing.
        -Commit creates each Process and prints its GUID + the reverse DELETE. PASS = pilot lineage renders
        (validate with DGLINE-Validate.ps1) and can be removed via the printed reverse command.
.NOTES
    Purview — Data Lineage Implementation (DGLINE). Write-gated by -Commit; -WhatIf default. No secrets in code.
    Atlas entity/lineage endpoints + api-version are cited as of authoring and evolving — verify in your tenant.
    Never deletes underlying data assets — only the Process (lineage) entities this script created.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
param(
    [Parameter(Mandatory)][string]$Account,
    [Parameter(Mandatory)][string]$MapPath,
    [switch]$Commit,
    [string]$ResourceUrl   = 'https://purview.azure.net',
    [string]$CatalogApiVer = '2022-03-01-preview',
    [string]$ReportName    = 'Data Lineage Connections - DGLINE - Configure'
)

$ErrorActionPreference = 'Stop'
$endpoint = "https://$Account.purview.azure.com"
Write-Host ("=== {0} — {1} ===" -f $ReportName, $endpoint) -ForegroundColor Cyan
if (-not $Commit) { Write-Host "MODE: PREVIEW (-WhatIf). No changes will be made. Pass -Commit to apply." -ForegroundColor Yellow }
if (-not (Test-Path $MapPath)) { throw "MapPath not found: $MapPath" }

if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    Install-Module Az.Accounts -Scope CurrentUser -Force -AllowClobber
}
Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
$token   = (Get-AzAccessToken -ResourceUrl $ResourceUrl).Token
$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }

# Resolve an asset by qualified name via the catalog search (read-only). Returns $true if found.
function Test-AssetExists([string]$qn) {
    if ([string]::IsNullOrWhiteSpace($qn)) { return $false }
    try {
        $searchUri  = "$endpoint/catalog/api/search/query?api-version=$CatalogApiVer"
        $body       = @{ keywords = $qn; limit = 1 } | ConvertTo-Json
        $r          = Invoke-RestMethod -Method POST -Uri $searchUri -Headers $headers -Body $body
        return (@($r.value).Count -gt 0)
    } catch { return $false }
}

$rows = Import-Csv -Path $MapPath
Write-Host ("Coverage-map rows: {0}" -f $rows.Count) -ForegroundColor Cyan
$results = @()

foreach ($row in $rows) {
    $inOk  = Test-AssetExists $row.InputQualifiedName
    $outOk = Test-AssetExists $row.OutputQualifiedName

    # Atlas Process entity: inputs/outputs referenced by uniqueAttributes.qualifiedName.
    $processEntity = @{
        entity = @{
            typeName   = $(if ($row.ProcessType) { $row.ProcessType } else { 'Process' })
            attributes = @{
                qualifiedName = "process://$($row.ProcessName)"
                name          = $row.ProcessName
                inputs        = @(@{ typeName = $row.InputType;  uniqueAttributes = @{ qualifiedName = $row.InputQualifiedName } })
                outputs       = @(@{ typeName = $row.OutputType; uniqueAttributes = @{ qualifiedName = $row.OutputQualifiedName } })
            }
        }
    }
    $json = $processEntity | ConvertTo-Json -Depth 8

    Write-Host ("--- Process: {0}  [{1} -> {2}]" -f $row.ProcessName, $row.InputQualifiedName, $row.OutputQualifiedName) -ForegroundColor Cyan
    if (-not $inOk)  { Write-Host ("  [WARN] input asset not resolvable in catalog: {0}"  -f $row.InputQualifiedName)  -ForegroundColor Yellow }
    if (-not $outOk) { Write-Host ("  [WARN] output asset not resolvable in catalog: {0}" -f $row.OutputQualifiedName) -ForegroundColor Yellow }

    if (-not $Commit) {
        Write-Host "  [PREVIEW] Would POST this Atlas Process entity:" -ForegroundColor Yellow
        Write-Host $json
        $results += [pscustomobject]@{ Process=$row.ProcessName; Action='preview'; InputResolved=$inOk; OutputResolved=$outOk; Guid='' }
        continue
    }

    if ($PSCmdlet.ShouldProcess($row.ProcessName, "POST Atlas Process (create lineage)")) {
        $entityUri = "$endpoint/catalog/api/atlas/v2/entity?api-version=$CatalogApiVer"
        try {
            $resp = Invoke-RestMethod -Method POST -Uri $entityUri -Headers $headers -Body $json
            $guid = ($resp.guidAssignments.PSObject.Properties | Select-Object -First 1).Value
            Write-Host ("  [OK] Process created. GUID: {0}" -f $guid) -ForegroundColor Green
            Write-Host ("  [ROLLBACK] Invoke-RestMethod -Method DELETE -Uri '{0}/catalog/api/atlas/v2/entity/guid/{1}?api-version={2}' -Headers `$headers" -f $endpoint, $guid, $CatalogApiVer) -ForegroundColor DarkYellow
            $results += [pscustomobject]@{ Process=$row.ProcessName; Action='created'; InputResolved=$inOk; OutputResolved=$outOk; Guid=$guid }
        } catch {
            Write-Host ("  [ERROR] Create failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
            $results += [pscustomobject]@{ Process=$row.ProcessName; Action='error'; InputResolved=$inOk; OutputResolved=$outOk; Guid='' }
        }
    }
}

$results | Format-Table -AutoSize
Write-Host ("Configure complete ({0}). Validate rendered lineage with DGLINE-Validate.ps1." -f $(if ($Commit) {'-Commit'} else {'preview only'})) -ForegroundColor Green

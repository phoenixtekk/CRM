<#
.SYNOPSIS
    DGDBX-Set-Scope.ps1 — Record the Databricks pilot/expansion scan scope & schedule (SAFE: preview by default; schedule write gated by -Commit).
.DESCRIPTION
    PURPOSE
        Captures a scope manifest for the Databricks pilot (or an expansion wave): the target collection,
        the workspace, the in-scope catalog/schema to scan first (with owner/steward and the credential
        name), the scan rule set intent, and the scan schedule. SAFE BY DEFAULT: it always writes a LOCAL
        JSON manifest (no tenant change) and only PREVIEWS the schedule it WOULD apply to the scan; it holds
        NO Databricks secret (the credential is referenced by name). Pass -Commit to actually set the scan
        schedule in Purview via the data-plane REST API — do this only after the scope has validated.
    HOW TO RUN
        Preview (default — writes local manifest, prints the schedule it would set, no tenant change):
          powershell -ExecutionPolicy Bypass -File .\DGDBX-Set-Scope.ps1 -Collection DGDBX-Collection-Pilot `
            -WorkspaceUrl https://adb-1234567890123456.7.azuredatabricks.net `
            -Catalog contoso_prod -Schema finance -Credential DGDBX-Cred-Databricks-KV `
            -Recurrence Weekly -OutFile .\dgdbx-pilot-scope.json
        Apply the schedule to an existing scan (only after validation):
          ... same args ... -PurviewAccount contoso-purview -SourceName dbx-lakehouse-01 -ScanName dbx-lakehouse-01-scan-pilot -Commit
    EXPECTED RESULTS
        A dgdbx-pilot-scope.json manifest (collection, workspace, catalog/schema, owner/steward
        placeholders, credential name, rule set, schedule) and a printed summary. With -Commit: the scan's
        recurring trigger is set (HTTP 200/201) and the script prints the result.
.NOTES
    Purview — Databricks Data Governance. Local manifest is always safe; the schedule write is gated behind
    -Commit. Names are white-label placeholders. Verify the current scan-trigger/schedule API shape and
    api-version for your tenant before -Commit — the Data Governance experience is evolving. No secrets.
#>
[CmdletBinding()]
param(
    [string]$Collection    = 'DGDBX-Collection-Pilot',
    [string]$WorkspaceUrl,                                    # e.g. https://adb-xxxx.NN.azuredatabricks.net
    [string]$Catalog,                                        # bounded pilot scope: one catalog ...
    [string]$Schema,                                         # ... and one schema
    [string]$Credential    = 'DGDBX-Cred-Databricks-KV',     # NAME of the Purview credential (Key Vault-backed)
    [string]$ScanRuleSet   = 'DGDBX-ScanRuleSet-Pilot',
    [ValidateSet('OneTime','Daily','Weekly','Monthly')]
    [string]$Recurrence    = 'OneTime',                      # keep OneTime until the scope validates
    [string]$OutFile       = '.\dgdbx-pilot-scope.json',
    # --- the following are only needed with -Commit (to set the schedule on an existing scan) ---
    [string]$PurviewAccount,
    [string]$SourceName,
    [string]$ScanName,
    [switch]$Commit
)

# --- Always write the local scope manifest (safe, no tenant change) -------------------------------
$scope = [ordered]@{
    generatedUtc = (Get-Date).ToUniversalTime().ToString('o')
    collection   = $Collection
    workspaceUrl = $WorkspaceUrl
    scanRuleSet  = $ScanRuleSet
    recurrence   = $Recurrence
    scope        = [ordered]@{
        catalog = $(if($Catalog){$Catalog}else{'<in-scope catalog>'})
        schema  = $(if($Schema){$Schema}else{'<in-scope schema (one, pilot-first)>'})
        credential = $Credential
        owner   = '<assign owner>'
        steward = '<assign steward>'
    }
}
$scope | ConvertTo-Json -Depth 6 | Set-Content -Path $OutFile -Encoding UTF8

Write-Host "`n=== Purview Databricks Data Governance — scope recorded ===" -ForegroundColor Cyan
Write-Host ("Collection       : {0}" -f $Collection)
Write-Host ("Workspace        : {0}" -f $(if($WorkspaceUrl){$WorkspaceUrl}else{'<set -WorkspaceUrl>'}))
Write-Host ("Scan rule set    : {0}" -f $ScanRuleSet)
Write-Host ("Scope            : catalog {0} / schema {1} (bounded, pilot-first)" -f $scope.scope.catalog, $scope.scope.schema)
Write-Host ("Recurrence       : {0}" -f $Recurrence) -ForegroundColor ($(if($Recurrence -eq 'OneTime'){'Green'}else{'Yellow'}))
Write-Host ("Manifest written : {0}" -f (Resolve-Path $OutFile)) -ForegroundColor Green
Write-Host "Assign a real owner and steward and confirm the catalog/schema before registering." -ForegroundColor Cyan
Write-Host "Credential is referenced BY NAME only — no Databricks token or secret is ever written to this manifest." -ForegroundColor DarkGray

# --- Optionally set the scan schedule (gated behind -Commit) --------------------------------------
if (-not $Commit) {
    Write-Host "`n[Preview] No schedule was applied to any scan. Re-run with -Commit (and -PurviewAccount/-SourceName/-ScanName) to set the recurring trigger — only after the scope validates." -ForegroundColor Yellow
    if ($Recurrence -ne 'OneTime') { Write-Host ("[Preview] Would set a {0} recurring trigger on the scan." -f $Recurrence) -ForegroundColor Yellow }
    return
}

if (-not ($PurviewAccount -and $SourceName -and $ScanName)) {
    Write-Host "`n-Commit requires -PurviewAccount, -SourceName, and -ScanName (the existing scan to schedule)." -ForegroundColor Yellow
    return
}
if ($Recurrence -eq 'OneTime') {
    Write-Host "`nRecurrence is OneTime — nothing to schedule. Choose Daily/Weekly/Monthly to set a recurring trigger." -ForegroundColor Yellow
    return
}

Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Write-Host "Not signed in. Run Connect-AzAccount first." -ForegroundColor Yellow; return }
$token = (Get-AzAccessToken -ResourceUrl 'https://purview.azure.net').Token
$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }
$Endpoint = "https://$PurviewAccount.purview.azure.com"

# NOTE: the exact trigger/recurrence property shape is tenant-/version-dependent — verify against Microsoft's docs.
$triggerBody = @{
    properties = [ordered]@{
        recurrence = [ordered]@{
            frequency = $Recurrence
            interval  = 1
            startTime = (Get-Date).ToUniversalTime().ToString('o')
        }
        recurrenceInterval = $Recurrence
        scanLevel = 'Incremental'   # verify: Full vs Incremental for your connector
    }
} | ConvertTo-Json -Depth 6
$triggerUri = "$Endpoint/scan/datasources/$SourceName/scans/$ScanName/triggers/default`?api-version=2018-12-01-preview"

Write-Host ("`n[Commit] Setting {0} schedule on scan {1} (source {2})" -f $Recurrence, $ScanName, $SourceName) -ForegroundColor Cyan
Write-Host ("[Commit] PUT {0}" -f $triggerUri) -ForegroundColor DarkGray
try {
    Invoke-RestMethod -Method PUT -Uri $triggerUri -Headers $headers -Body $triggerBody -ErrorAction Stop | Out-Null
    Write-Host "[Commit] Schedule set. Monitor the scheduled runs with DGDBX-Report.ps1 and watch Databricks/Azure cost as scope grows." -ForegroundColor Green
} catch {
    Write-Host ("[Commit] FAILED to set schedule: {0}" -f $_.Exception.Message) -ForegroundColor Red
    Write-Host "Verify the current scan-trigger API shape and api-version for your tenant." -ForegroundColor Yellow
}

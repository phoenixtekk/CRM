<#
.SYNOPSIS
    DGINSIGHT-Configure-Quality.ps1 — Author data-quality rules and run scoring (SAFE: -WhatIf by default).
.DESCRIPTION
    PURPOSE
        Stages data-quality rules for a data product from a scope manifest and, with -RunScan, triggers
        the scoring scan. DEFAULTS TO -WhatIf: it prints exactly the rules/thresholds it would create (or
        the scan it would run) and changes NOTHING. Add -Commit to author rules; add -RunScan (with
        -Commit) to start the scoring scan; add -Remove to preview/delete a rule set. No credentials or
        secrets are stored — the data-quality connection uses the Purview managed identity / Key Vault
        configured in the portal.
    HOW TO RUN
        # Preview the rules that would be authored (safe):
        powershell -ExecutionPolicy Bypass -File .\DGINSIGHT-Configure-Quality.ps1 `
            -PurviewAccount contoso-purview -ScopeFile .\DGI-scope.json
        # Author them for real:
        .\DGINSIGHT-Configure-Quality.ps1 -PurviewAccount contoso-purview -ScopeFile .\DGI-scope.json -Commit
        # Run the scoring scan on the pilot data product:
        .\DGINSIGHT-Configure-Quality.ps1 -PurviewAccount contoso-purview -ScopeFile .\DGI-scope.json -RunScan -Commit
        Requires Az.Accounts + Connect-AzAccount as a Data Quality steward on the domain.
    EXPECTED RESULTS
        -WhatIf: a printed plan (rules + thresholds, or the scan to run) and NO changes. -Commit: each
        rule authored / scan started with a PASS line. A failure prints the reason and stops.
.NOTES
    Purview — Data Quality. SAFE BY DEFAULT (-WhatIf). A data-quality scan READS LIVE DATA on the bounded
    scope — run least-privilege with the owner's agreement. API versions/paths below are EXAMPLES —
    verify current Data Quality API for your tenant (may be preview). No secrets in code.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PurviewAccount,
    [Parameter(Mandatory = $true)][string]$ScopeFile,
    [switch]$RunScan,
    [switch]$Remove,
    [switch]$Commit,
    [switch]$WhatIf = $true,
    [string]$Endpoint = "https://$PurviewAccount.purview.azure.com"
)

# -Commit turns the safe default off; without -Commit we always run in preview.
if ($Commit) { $WhatIf = $false }
$mode = if ($WhatIf) { 'WHATIF (no changes)' } else { 'COMMIT (writes)' }

if (-not (Test-Path $ScopeFile)) { Write-Host "Scope file not found: $ScopeFile — run DGINSIGHT-Set-Scope.ps1 first." -ForegroundColor Red; return }
$scope = Get-Content $ScopeFile -Raw | ConvertFrom-Json

Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Write-Host "Not signed in. Run Connect-AzAccount first." -ForegroundColor Yellow; return }
$token = (Get-AzAccessToken -ResourceUrl 'https://purview.azure.net').Token
$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }

function Invoke-Purview([string]$Path, [string]$Method = 'GET', $Body = $null) {
    $p = @{ Method = $Method; Uri = ("{0}{1}" -f $Endpoint, $Path); Headers = $headers; ErrorAction = 'Stop' }
    if ($Body) { $p.Body = ($Body | ConvertTo-Json -Depth 8) }
    Invoke-RestMethod @p
}

Write-Host "`n=== Data Quality configuration — mode: $mode ===" -ForegroundColor Cyan
Write-Host ("Domain / product : {0} / {1}" -f $scope.governanceDomain, $scope.dataProduct)
Write-Host ("Rule set         : DGI-DQ-Ruleset-Pilot")

# --- Remove path (preview/delete a rule set) ---
if ($Remove) {
    Write-Host "`n[Remove] Rule set DGI-DQ-Ruleset-Pilot on $($scope.dataProduct)" -ForegroundColor Yellow
    if ($WhatIf) { Write-Host "  WHATIF: would delete the rule set and its rules. Re-run with -Commit to apply." -ForegroundColor DarkYellow; return }
    try {
        # Example endpoint — verify the current Data Quality rule API for your tenant.
        Invoke-Purview ("/datagovernance/quality/dataproducts/{0}/rulesets/DGI-DQ-Ruleset-Pilot?api-version=2024-02-01-preview" -f $scope.dataProduct) 'DELETE' | Out-Null
        Write-Host "  PASS: rule set removed." -ForegroundColor Green
    } catch { Write-Host ("  FAILED: {0}" -f $_.Exception.Message) -ForegroundColor Red }
    return
}

# --- Author rules from the manifest ---
Write-Host "`n[Author] Rules from ${ScopeFile}:" -ForegroundColor Cyan
foreach ($cde in $scope.criticalDataElements) {
    foreach ($rule in $cde.rules) {
        $line = ("  {0}  [{1}]  threshold={2}  ({3})" -f $rule.ruleName, $rule.dimension, $rule.threshold, $cde.cde)
        if ($WhatIf) {
            Write-Host ("  WHATIF would author: {0}" -f $line) -ForegroundColor DarkYellow
        } else {
            $body = @{
                name        = $rule.ruleName
                dimension   = $rule.dimension
                targetCde   = $cde.cde
                threshold   = $rule.threshold
                description  = $rule.intent
            }
            try {
                # Example endpoint — verify the current Data Quality rule API for your tenant.
                Invoke-Purview ("/datagovernance/quality/dataproducts/{0}/rulesets/DGI-DQ-Ruleset-Pilot/rules?api-version=2024-02-01-preview" -f $scope.dataProduct) 'PUT' $body | Out-Null
                Write-Host ("  PASS authored: {0}" -f $line) -ForegroundColor Green
            } catch { Write-Host ("  FAILED {0}: {1}" -f $rule.ruleName, $_.Exception.Message) -ForegroundColor Red }
        }
    }
}

# --- Run the scoring scan (bounded, one-time) ---
if ($RunScan) {
    Write-Host "`n[Scan] Data-quality scoring on $($scope.dataProduct) (reads live data on the bounded scope)" -ForegroundColor Cyan
    if ($WhatIf) {
        Write-Host "  WHATIF: would start a one-time scoring scan. Re-run with -RunScan -Commit to start it." -ForegroundColor DarkYellow
    } else {
        try {
            Invoke-Purview ("/datagovernance/quality/dataproducts/{0}/scans?api-version=2024-02-01-preview" -f $scope.dataProduct) 'POST' @{ rulesetName = 'DGI-DQ-Ruleset-Pilot'; runType = 'OnDemand' } | Out-Null
            Write-Host "  PASS: scoring scan started. Review results with DGINSIGHT-Report.ps1 when it completes." -ForegroundColor Green
        } catch { Write-Host ("  FAILED to start scan: {0}" -f $_.Exception.Message) -ForegroundColor Red }
    }
}

Write-Host "`nSafety: default is -WhatIf. A scan does not modify source data (it reads and scores). To back out, -Remove the rule set and cancel the run in the portal." -ForegroundColor Cyan
Write-Host "Note: API versions/paths above are EXAMPLES — verify the current Data Quality API for your tenant (may be preview)." -ForegroundColor DarkGray

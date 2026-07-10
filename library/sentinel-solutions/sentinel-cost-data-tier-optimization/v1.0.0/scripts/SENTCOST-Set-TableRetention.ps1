<#
.SYNOPSIS
    SENTCOST-Set-TableRetention.ps1 — safely apply a table's interactive/archive retention per the tier decision.
.DESCRIPTION
    PURPOSE
        Applies interactive and total (archive) retention to a single table so it matches your
        'Tier Decision - <TableName> - Pilot' record. Defaults to -WhatIf (reports what it WOULD set,
        changes nothing). Retention changes affect cost and data availability — this is deliberately
        gated and single-table.
    HOW TO RUN
        Connect-AzAccount first. Preview (default, safe):
        powershell -ExecutionPolicy Bypass -File .\SENTCOST-Set-TableRetention.ps1 -ResourceGroup <rg> -WorkspaceName "..." -TableName AzureDiagnostics -InteractiveRetentionDays 30 -TotalRetentionDays 180
        Apply for real (must pass -WhatIf:$false):
        powershell -ExecutionPolicy Bypass -File .\SENTCOST-Set-TableRetention.ps1 -ResourceGroup <rg> -WorkspaceName "..." -TableName AzureDiagnostics -InteractiveRetentionDays 30 -TotalRetentionDays 180 -WhatIf:$false
        Requires modules: Az.Accounts, Az.OperationalInsights. Requires Contributor (Requirement 2.3).
    EXPECTED RESULTS
        In preview: prints current vs proposed interactive/total retention for the table. When applied:
        sets the retention. Does NOT change the table plan (Analytics/Basic/Auxiliary) — do that
        deliberately in the portal after verifying tier eligibility.
.NOTES
    Sentinel Solutions. Mutating only when -WhatIf:$false is passed. Single-table by design.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory)] [string]$ResourceGroup,
    [Parameter(Mandatory)] [string]$WorkspaceName,
    [Parameter(Mandatory)] [string]$TableName,
    [Parameter(Mandatory)] [int]$InteractiveRetentionDays,
    [Parameter(Mandatory)] [int]$TotalRetentionDays,
    [bool]$WhatIf = $true
)

if ($WhatIf) { $WhatIfPreference = $true }

Write-Host "=== SENTCOST Set Table Retention — safe, single-table ===" -ForegroundColor Cyan
if ($TotalRetentionDays -lt $InteractiveRetentionDays) {
    Write-Host "Total retention cannot be less than interactive retention. Aborting." -ForegroundColor Yellow
    return
}

$ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction Stop
$tbl = Get-AzOperationalInsightsTable -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -TableName $TableName -ErrorAction SilentlyContinue
if (-not $tbl) { Write-Host ("Table '{0}' not found in workspace." -f $TableName) -ForegroundColor Yellow; return }

$curInteractive = if ($null -ne $tbl.RetentionInDays) { $tbl.RetentionInDays } else { $ws.RetentionInDays }
$curTotal = if ($null -ne $tbl.TotalRetentionInDays) { $tbl.TotalRetentionInDays } else { $curInteractive }

Write-Host ("Table                 : {0}  (plan {1})" -f $TableName, ($(if($tbl.Plan){$tbl.Plan}else{'Analytics'})))
Write-Host ("Current interactive   : {0} d   ->  proposed {1} d" -f $curInteractive, $InteractiveRetentionDays)
Write-Host ("Current total/archive : {0} d   ->  proposed {1} d" -f $curTotal, $TotalRetentionDays)

if ($PSCmdlet.ShouldProcess($TableName, "Set interactive=$InteractiveRetentionDays d, total=$TotalRetentionDays d")) {
    Update-AzOperationalInsightsTable -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -TableName $TableName `
        -RetentionInDays $InteractiveRetentionDays -TotalRetentionInDays $TotalRetentionDays -ErrorAction Stop | Out-Null
    Write-Host "Applied. Re-run SENTCOST-Validate.ps1 to confirm, and SENTCOST-Audit.ps1 after a window to measure savings." -ForegroundColor Green
} else {
    Write-Host "`nPreview only — re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow
    Write-Host "Remember: confirm this matches your compliance-owned retention policy (Requirement 2.5) before applying." -ForegroundColor Yellow
}

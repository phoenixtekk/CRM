<#
.SYNOPSIS
    SENTCOST-Validate.ps1 — confirm table plans and retention match the tier decisions.
.DESCRIPTION
    PURPOSE
        Reads each table's configured plan (Analytics/Basic/Auxiliary) and interactive/total retention
        from the workspace and reports them, so you can confirm they match your 'Tier Decision' records
        and your retention policy. Optionally checks a supplied list of tables. Read-only — no changes.
    HOW TO RUN
        Connect-AzAccount first, then:
        powershell -ExecutionPolicy Bypass -File .\SENTCOST-Validate.ps1 -ResourceGroup <rg> -WorkspaceName "..." -Tables "AzureDiagnostics,SecurityEvent"
        Omit -Tables to list every table with a non-default plan or explicit retention.
        Requires modules: Az.Accounts, Az.OperationalInsights.
    EXPECTED RESULTS
        A per-table line: plan, interactive retention (days), total/archive retention (days). Compare
        against your Tier Decision records and retention policy (Requirements 2.4/2.5).
.NOTES
    Sentinel Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ResourceGroup,
    [Parameter(Mandatory)] [string]$WorkspaceName,
    [string]$Tables = ''
)

Write-Host "=== SENTCOST Validate — table plans and retention ===" -ForegroundColor Cyan
$ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction SilentlyContinue
if (-not $ws) { Write-Host "Workspace NOT FOUND." -ForegroundColor Yellow; return }
Write-Host ("Workspace default retention (days) : {0}" -f $ws.RetentionInDays)

$filter = @($Tables -split '[,; ]+' | Where-Object { $_ } | ForEach-Object { $_.Trim() })

try {
    $tbls = Get-AzOperationalInsightsTable -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction Stop
} catch {
    Write-Host ("Could not read tables: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "Requires a role that can read table configuration (Requirement 2.3)." -ForegroundColor Yellow
    return
}

Write-Host ("`n{0,-40} {1,-12} {2,14} {3,14}" -f 'Table', 'Plan', 'Interactive(d)', 'Total(d)') -ForegroundColor Cyan
Write-Host ("-" * 84)
foreach ($t in ($tbls | Sort-Object Name)) {
    $name = $t.Name
    if ($filter.Count -gt 0 -and ($filter -notcontains $name)) { continue }
    $plan = if ($t.Plan) { $t.Plan } else { 'Analytics' }
    $interactive = if ($null -ne $t.RetentionInDays) { $t.RetentionInDays } else { $ws.RetentionInDays }
    $total = if ($null -ne $t.TotalRetentionInDays) { $t.TotalRetentionInDays } else { $interactive }
    $color = if ($plan -ne 'Analytics') { 'Green' } else { 'Gray' }
    # If no filter, only surface tables that differ from the workspace default (the interesting ones)
    if ($filter.Count -eq 0 -and $plan -eq 'Analytics' -and $interactive -eq $ws.RetentionInDays -and $total -eq $ws.RetentionInDays) { continue }
    Write-Host ("{0,-40} {1,-12} {2,14} {3,14}" -f $name, $plan, $interactive, $total) -ForegroundColor $color
}
Write-Host "`nCompare each row against your 'Tier Decision - <TableName> - Pilot' records and retention policy."

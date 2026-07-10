<#
.SYNOPSIS
    OBSAZMON-Discovery.ps1 — inventory the Azure estate and its current monitoring coverage (read-only).
.DESCRIPTION
    PURPOSE
        Baselines the observability starting point before you build the foundation: subscriptions and
        resources by type, any existing Log Analytics workspaces, current diagnostic-settings coverage
        (which resources already send logs and where), existing action groups and alert rules, and your
        effective rights. Read-only — makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\OBSAZMON-Discovery.ps1 -CsvFolder C:\Temp\obsazmon
        Requires Az PowerShell (Az.Accounts, Az.Resources, Az.Monitor, Az.OperationalInsights) and
        Connect-AzAccount. Reports on the current subscription context (Set-AzContext to change it).
    EXPECTED RESULTS
        Console tables + optional CSVs: resource counts by type, workspaces, diagnostic-settings coverage
        (the gap the policy will close), action groups, and alert rules. Use it to plan retention, the
        pilot scope, and the diagnostics policy.
.NOTES
    White-label. Read-only against Azure Resource Manager / Azure Monitor. No credentials stored.
.EXAMPLE
    .\OBSAZMON-Discovery.ps1 -CsvFolder C:\Temp\obsazmon
#>
[CmdletBinding()] param([string]$CsvFolder)

foreach ($m in 'Az.Accounts','Az.Resources','Az.Monitor','Az.OperationalInsights') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module $m -Scope CurrentUser -Force -AllowClobber }
    Import-Module $m -ErrorAction Stop
}
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }

function Save-Csv($rows, $name) {
    if ($CsvFolder -and $rows) {
        if (-not (Test-Path $CsvFolder)) { New-Item -ItemType Directory -Path $CsvFolder | Out-Null }
        $p = Join-Path $CsvFolder "$name.csv"; $rows | Export-Csv -Path $p -NoTypeInformation
        Write-Host "  saved $p" -ForegroundColor Green
    }
}

$ctx = Get-AzContext
Write-Host "`nSigned in as: $($ctx.Account.Id)  |  Subscription: $($ctx.Subscription.Name)" -ForegroundColor Cyan

# --- Resources by type ---------------------------------------------------------
Write-Host "`n=== Resources by type ===" -ForegroundColor Cyan
$res = Get-AzResource
$byType = $res | Group-Object ResourceType | Sort-Object Count -Descending |
    ForEach-Object { [pscustomobject]@{ ResourceType=$_.Name; Count=$_.Count } }
$byType | Format-Table -AutoSize
Save-Csv $byType 'resources-by-type'

# --- Existing Log Analytics workspaces ----------------------------------------
Write-Host "`n=== Log Analytics workspaces ===" -ForegroundColor Cyan
$ws = Get-AzOperationalInsightsWorkspace -ErrorAction SilentlyContinue
$wsRows = $ws | ForEach-Object {
    [pscustomobject]@{ Name=$_.Name; RG=$_.ResourceGroupName; Location=$_.Location;
                       RetentionDays=$_.RetentionInDays; Sku=$_.Sku }
}
$wsRows | Format-Table -AutoSize
Save-Csv $wsRows 'workspaces'

# --- Diagnostic-settings coverage (the gap) -----------------------------------
Write-Host "`n=== Diagnostic-settings coverage (sampling supported resource types) ===" -ForegroundColor Cyan
$covered = 0; $uncovered = 0; $gap = @()
foreach ($r in $res) {
    try {
        $ds = Get-AzDiagnosticSetting -ResourceId $r.ResourceId -ErrorAction Stop
        if ($ds) { $covered++ } else { $uncovered++; $gap += $r }
    } catch { $uncovered++; $gap += $r }   # unsupported / none => treated as gap for reporting
}
Write-Host ("  With diagnostic settings : {0}" -f $covered) -ForegroundColor Green
Write-Host ("  Without / unsupported     : {0}" -f $uncovered) -ForegroundColor Yellow
Save-Csv ($gap | Select-Object Name,ResourceType,ResourceGroupName,ResourceId) 'diagnostics-gap'

# --- Action groups -------------------------------------------------------------
Write-Host "`n=== Action groups ===" -ForegroundColor Cyan
$ag = Get-AzActionGroup -ErrorAction SilentlyContinue
$agRows = $ag | ForEach-Object { [pscustomobject]@{ Name=$_.Name; RG=$_.ResourceGroupName; ShortName=$_.GroupShortName } }
$agRows | Format-Table -AutoSize
Save-Csv $agRows 'action-groups'

# --- Alert rules (metric + scheduled query) -----------------------------------
Write-Host "`n=== Metric alert rules ===" -ForegroundColor Cyan
$mar = Get-AzMetricAlertRuleV2 -ErrorAction SilentlyContinue
$marRows = $mar | ForEach-Object { [pscustomobject]@{ Name=$_.Name; RG=$_.ResourceGroupName; Enabled=$_.Enabled; Severity=$_.Severity } }
$marRows | Format-Table -AutoSize
Save-Csv $marRows 'metric-alert-rules'

Write-Host "`nDiscovery complete. Review the diagnostics gap to size the policy and pick the pilot scope." -ForegroundColor Cyan

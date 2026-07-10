<#
.SYNOPSIS
    SOCXDRG-Validate.ps1 — confirm the Defender XDR connector is connected and incidents are arriving.
.DESCRIPTION
    PURPOSE
        Validates the unified-queue pipeline: the Microsoft Defender XDR connector is present, and
        Defender incidents/alerts have actually landed in the workspace (SecurityIncident /
        SecurityAlert) within a recent window. Read-only — makes no changes.
    HOW TO RUN
        Connect-AzAccount -Environment AzureUSGovernment first (US Gov / GCC High — verify endpoints for your cloud), then:
        powershell -ExecutionPolicy Bypass -File .\SOCXDRG-Validate.ps1 -ResourceGroup <rg> -WorkspaceName "Security Telemetry - SOC - Workspace" [-LookbackHours 24]
        Requires modules: Az.Accounts, Az.OperationalInsights, Az.SecurityInsights, Az.OperationalInsights (query).
    EXPECTED RESULTS
        Connector present = yes/no; recent SecurityIncident and SecurityAlert row counts > 0 when sync
        is healthy. Flags an empty result as "no data arriving — check sync".
.NOTES
    Sentinel Solutions. White-label. Read-only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ResourceGroup,
    [Parameter(Mandatory)] [string]$WorkspaceName,
    [int]$LookbackHours = 24
)

Write-Host "=== SOCXDRG Validate — connector & incident sync ===" -ForegroundColor Cyan
$ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction Stop
$cid = $ws.CustomerId.Guid

# Connector present?
try {
    $connectors = Get-AzSentinelDataConnector -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction Stop
    $xdr = $connectors | Where-Object { $_.Kind -match 'MicrosoftThreatProtection|Microsoft365Defender|MicrosoftDefenderXDR|MTP' }
    Write-Host ("Defender XDR connector : {0}" -f ($(if($xdr){'PRESENT'}else{'NOT FOUND — connect it (Implementation Step 3)'}))) -ForegroundColor ($(if($xdr){'Green'}else{'Yellow'}))
} catch { Write-Host ("Connector check failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# Data actually arriving? (query the workspace)
function Invoke-WsQuery([string]$q) {
    try { return (Invoke-AzOperationalInsightsQuery -WorkspaceId $cid -Query $q -ErrorAction Stop).Results }
    catch { Write-Host ("  Query failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow; return $null }
}

Write-Host "`n--- Recent data ($LookbackHours h) ---" -ForegroundColor Cyan
$inc = Invoke-WsQuery "SecurityIncident | where TimeGenerated > ago(${LookbackHours}h) | summarize c=count()"
$alr = Invoke-WsQuery "SecurityAlert   | where TimeGenerated > ago(${LookbackHours}h) | summarize c=count()"
$incCount = if ($inc) { [int]$inc[0].c } else { 0 }
$alrCount = if ($alr) { [int]$alr[0].c } else { 0 }

Write-Host ("SecurityIncident rows : {0}" -f $incCount) -ForegroundColor ($(if($incCount -gt 0){'Green'}else{'Yellow'}))
Write-Host ("SecurityAlert rows    : {0}" -f $alrCount) -ForegroundColor ($(if($alrCount -gt 0){'Green'}else{'Yellow'}))

if ($incCount -eq 0 -and $alrCount -eq 0) {
    Write-Host "`nNo Defender data in the window. Confirm incident sync is ON and allow the first sync to complete, then re-run. See Troubleshooting B." -ForegroundColor Yellow
} else {
    Write-Host "`nSync is delivering data. Next: SOCXDRG-Report.ps1 to confirm no duplicate rules and review the hand-off list." -ForegroundColor Green
}

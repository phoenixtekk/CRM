<#
.SYNOPSIS
    SENTLOG-Validation.ps1 — confirm Entra ID/Intune telemetry is actually being ingested into the workspace.
.DESCRIPTION
    PURPOSE
        Validates the pipeline end-to-end: checks the Microsoft Entra ID data connector state and queries
        the workspace for recent rows in the pilot tables (SigninLogs, AuditLogs). Read-only.
    HOW TO RUN
        Connect-AzAccount first, then:
        powershell -ExecutionPolicy Bypass -File .\SENTLOG-Validation.ps1 -ResourceGroup <rg> -WorkspaceName "Security Telemetry - Tenant - Workspace"
        Requires modules: Az.Accounts, Az.OperationalInsights, Az.SecurityInsights.
    EXPECTED RESULTS
        "INGESTION OK" when the pilot tables have rows in the last 24h. Reports connector state and
        per-table recent row counts; exits 1 if no data is found.
.NOTES
    Sentinel Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ResourceGroup,
    [Parameter(Mandatory)] [string]$WorkspaceName,
    [string[]]$Tables = @('SigninLogs','AuditLogs')
)

Write-Host "=== SENTLOG Validation — ingestion check ===" -ForegroundColor Cyan
$ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction Stop

# Connector state (best-effort; connector inventory varies by tenant/module version)
try {
    $connectors = Get-AzSentinelDataConnector -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction Stop
    $entra = $connectors | Where-Object { $_.Kind -match 'AzureActiveDirectory|EntraID|AadDataConnector' }
    Write-Host ("Entra ID connector present : {0}" -f ($(if($entra){'YES'}else{'not detected'}))) -ForegroundColor ($(if($entra){'Green'}else{'Yellow'}))
} catch {
    Write-Host ("Connector query skipped: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

# Query each pilot table for recent rows
$allOk = $true
Write-Host "`n--- Recent row counts (last 24h) ---" -ForegroundColor Cyan
foreach ($t in $Tables) {
    $kql = "$t | where TimeGenerated > ago(24h) | count"
    try {
        $r = Invoke-AzOperationalInsightsQuery -WorkspaceId $ws.CustomerId -Query $kql -ErrorAction Stop
        $count = [int]($r.Results | Select-Object -First 1).Count
        $color = $(if($count -gt 0){'Green'}else{'Yellow'})
        Write-Host ("  {0,-14} : {1} rows" -f $t, $count) -ForegroundColor $color
        if ($count -le 0) { $allOk = $false }
    } catch {
        Write-Host ("  {0,-14} : query failed ({1})" -f $t, $_.Exception.Message) -ForegroundColor Yellow
        $allOk = $false
    }
}

if ($allOk) { Write-Host "`nResult: INGESTION OK" -ForegroundColor Green; exit 0 }
else { Write-Host "`nResult: NO/PARTIAL DATA — check the diagnostic setting and connector (see Troubleshooting A)." -ForegroundColor Yellow; exit 1 }

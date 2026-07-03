<#
.SYNOPSIS
    SENTLOGG-Validation.ps1 — confirm Entra ID/Intune telemetry is being ingested into the workspace (GCC High).
.DESCRIPTION
    PURPOSE
        Validates the pipeline end-to-end in Azure Government: checks the Microsoft Entra ID data connector
        state and queries the workspace for recent rows in the pilot tables (SigninLogs, AuditLogs,
        IntuneAuditLogs). Read-only. Use your-resource-group and your-workspace-name.
    HOW TO RUN
        Connect-AzAccount -Environment AzureUSGovernment first, then:
        powershell -ExecutionPolicy Bypass -File .\SENTLOGG-Validation.ps1 -ResourceGroup your-resource-group -WorkspaceName "Security Telemetry - Tenant - Workspace"
        Requires modules: Az.Accounts, Az.OperationalInsights, Az.SecurityInsights.
    EXPECTED RESULTS
        "INGESTION OK" (pass) when the pilot tables have rows in the last 24h. Reports connector state and
        per-table recent row counts; exits 1 (fail) if no data is found.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph/Azure US Gov endpoints.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ResourceGroup,
    [Parameter(Mandatory)] [string]$WorkspaceName,
    [string[]]$Tables = @('SigninLogs','AuditLogs','IntuneAuditLogs')
)

Write-Host "=== SENTLOGG Validation — ingestion check (GCC High / Azure Government) ===" -ForegroundColor Cyan

# Confirm sovereign cloud context
$ctx = Get-AzContext -ErrorAction SilentlyContinue
if (-not $ctx) { Write-Host "Not connected. Run: Connect-AzAccount -Environment AzureUSGovernment" -ForegroundColor Yellow; exit 1 }
if ($ctx.Environment.Name -ne 'AzureUSGovernment') {
    Write-Host ("WARNING: Az environment is '{0}', not 'AzureUSGovernment' — you may be querying the wrong cloud." -f $ctx.Environment.Name) -ForegroundColor Yellow
}

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
        Write-Host ("  {0,-16} : {1} rows" -f $t, $count) -ForegroundColor $color
        if ($count -le 0) { $allOk = $false }
    } catch {
        Write-Host ("  {0,-16} : query failed ({1})" -f $t, $_.Exception.Message) -ForegroundColor Yellow
        $allOk = $false
    }
}

Write-Host "`n(Note: Intune DeviceComplianceOrg / IntuneDevices exports can lag up to 48h; IntuneAuditLogs arrive within ~30 min.)"

if ($allOk) { Write-Host "`nResult: INGESTION OK" -ForegroundColor Green; exit 0 }
else { Write-Host "`nResult: NO/PARTIAL DATA — check the diagnostic settings and connector in the .us portals (see Troubleshooting A/B)." -ForegroundColor Yellow; exit 1 }

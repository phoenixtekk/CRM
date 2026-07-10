<#
.SYNOPSIS
    AIFOUNDRY-Report.ps1 — read-only posture, usage, and cost report for the secure Azure OpenAI platform.
.DESCRIPTION
    PURPOSE
        Produces a review-and-drift report for one AI platform resource group: the security posture of
        each Azure OpenAI resource (public access, keys, subdomain, private endpoints, diagnostics), the
        model deployments and their TPM ceilings, recent request/token volume pulled from Log Analytics,
        and the cost budget / alert status. Use it in regular reviews to confirm nothing has drifted
        away from private-keyless-bounded-monitored.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AIFOUNDRY-Report.ps1 -SubscriptionId "<sub id>" `
            -ResourceGroup rg-aiplatform-nonprod [-LogAnalyticsWorkspaceId <customerId GUID>]
        Requires Az.Accounts, Az.CognitiveServices, Az.Monitor, Az.Consumption, and (for usage)
        Az.OperationalInsights. Run Connect-AzAccount first. *Verify current Az module versions.*
    EXPECTED RESULTS
        Printed posture/usage/cost sections. Read-only — no changes are made.
.NOTES
    White-label. Read-only. Makes no changes.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$SubscriptionId,
    [Parameter(Mandatory = $true)] [string]$ResourceGroup,
    [string]$LogAnalyticsWorkspaceId = "",
    [int]$UsageLookbackHours = 24
)

$ErrorActionPreference = 'Continue'
try { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }
catch { Write-Error "Set context failed. Connect-AzAccount first. $_"; exit 1 }

Write-Host "AIFOUNDRY posture/usage/cost report — RG '$ResourceGroup' (read-only)`n" -ForegroundColor Cyan

# --- 1. Security posture per resource ---------------------------------------
Write-Host "== 1. Security posture ==" -ForegroundColor Cyan
$accounts = Get-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue
foreach ($a in $accounts) {
    $p = $a.Properties
    $keysUsable = if ($null -ne $p.DisableLocalAuth) { -not $p.DisableLocalAuth } else { $true }
    Write-Host ("  {0}" -f $a.AccountName) -ForegroundColor White
    Write-Host ("     public access : {0}" -f $p.PublicNetworkAccess) -ForegroundColor $(if ($p.PublicNetworkAccess -eq 'Disabled') {'Green'} else {'Red'})
    Write-Host ("     keys usable   : {0}" -f $keysUsable) -ForegroundColor $(if ($keysUsable) {'Red'} else {'Green'})
    Write-Host ("     subdomain     : {0}" -f ($(if ($p.CustomSubDomainName) { $p.CustomSubDomainName } else { '(none)' }))) -ForegroundColor $(if ($p.CustomSubDomainName) {'Green'} else {'Red'})
    Write-Host ("     private EPs   : {0}" -f (($p.PrivateEndpointConnections | Measure-Object).Count))
    $diag = @(); try { $diag = Get-AzDiagnosticSetting -ResourceId $a.Id -ErrorAction SilentlyContinue } catch {}
    Write-Host ("     diagnostics   : {0}" -f ($(if ($diag) { 'configured' } else { 'NONE' }))) -ForegroundColor $(if ($diag) {'Green'} else {'Red'})

    # Deployments + TPM
    try {
        $deps = Get-AzCognitiveServicesAccountDeployment -ResourceGroupName $ResourceGroup -AccountName $a.AccountName -ErrorAction SilentlyContinue
        foreach ($d in $deps) {
            Write-Host ("     model deploy  : {0}  model={1}/{2}  TPM(k)={3}" -f `
                $d.Name, $d.Properties.Model.Name, $d.Properties.Model.Version, $d.Sku.Capacity)
        }
    } catch { Write-Host "     (could not list deployments)" -ForegroundColor Yellow }
}
if (-not $accounts) { Write-Host "  (no Cognitive Services / OpenAI accounts in this RG)" -ForegroundColor Yellow }

# --- 2. Recent usage (tokens / requests) from Log Analytics -----------------
Write-Host "`n== 2. Recent usage (last $UsageLookbackHours h) ==" -ForegroundColor Cyan
if ($LogAnalyticsWorkspaceId) {
    # KQL over AzureMetrics/AzureDiagnostics for Cognitive Services. Table/metric
    # names vary by diagnostic category — *verify current schema*.
    $kql = @"
AzureMetrics
| where TimeGenerated > ago(${UsageLookbackHours}h)
| where ResourceProvider == "MICROSOFT.COGNITIVESERVICES"
| where MetricName in ("TokenTransaction","ProcessedPromptTokens","GeneratedTokens","TotalCalls")
| summarize Total=sum(Total) by MetricName, Resource
| order by MetricName asc
"@
    try {
        $res = Invoke-AzOperationalInsightsQuery -WorkspaceId $LogAnalyticsWorkspaceId -Query $kql -ErrorAction Stop
        if ($res.Results) { $res.Results | Format-Table -AutoSize } else { Write-Host "  (no usage rows returned)" -ForegroundColor Yellow }
    } catch {
        Write-Host "  Usage query failed (verify workspace ID / KQL schema): $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  Pass -LogAnalyticsWorkspaceId <customerId GUID> to include token/request volume." -ForegroundColor Yellow
}

# --- 3. Cost budget status --------------------------------------------------
Write-Host "`n== 3. Cost budget / alerts ==" -ForegroundColor Cyan
try {
    $budgets = Get-AzConsumptionBudget -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue
    if ($budgets) {
        foreach ($b in $budgets) {
            Write-Host ("  {0}: amount={1} {2}  current={3}" -f $b.Name, $b.Amount, $b.Category, $b.CurrentSpend.Amount)
        }
    } else {
        Write-Host "  NO budget on this RG — an AI platform without a spend alarm is a bill-shock risk (R6/G8)." -ForegroundColor Red
    }
} catch { Write-Host "  (could not read budgets: $($_.Exception.Message))" -ForegroundColor Yellow }

Write-Host "`nReport complete. Read-only — no changes were made." -ForegroundColor Green

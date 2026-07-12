<#
.SYNOPSIS
    ENTIDP-RiskHunt.ps1 — hunt risky sign-ins and CAE/token events via KQL (Log Analytics/Sentinel) or a Graph fallback.
.DESCRIPTION
    PURPOSE
        Runs the ongoing risk-operations hunt. If Entra sign-in and risk logs are exported to a Log
        Analytics / Microsoft Sentinel workspace, it runs the embedded KQL queries there. If no
        workspace is provided, it falls back to a read-only Microsoft Graph query of recent risk
        detections and risky sign-ins so the hunt still works without a workspace.
    HOW TO RUN
        KQL mode:   powershell -ExecutionPolicy Bypass -File .\ENTIDP-RiskHunt.ps1 -WorkspaceId "<LA workspace GUID>"
                    (requires the Az.OperationalInsights module and reader access to the workspace)
        Graph mode: powershell -ExecutionPolicy Bypass -File .\ENTIDP-RiskHunt.ps1
                    (Microsoft Graph SDK; read-only: IdentityRiskEvent.Read.All, AuditLog.Read.All)
    EXPECTED RESULTS
        A list of recent medium/high-risk sign-ins and risk detections (and, in KQL mode, CAE/token
        signals). Read-only — no changes are made. Verify sign-in/risk log export exists for KQL mode.
.NOTES
    White-label — Entra ID Solutions. Read-only. KQL requires SignInLogs/RiskyUsers/UserRiskEvents exported.
#>
[CmdletBinding()]
param(
    [string]$WorkspaceId,
    [int]$Days = 7
)

# ---- Embedded KQL (also usable directly in Sentinel / Log Analytics) --------------------------
$kqlRiskySignIns = @"
SigninLogs
| where TimeGenerated > ago(${Days}d)
| where RiskLevelDuringSignIn in ('medium','high') or RiskLevelAggregated in ('medium','high')
| summarize Count=count(), Levels=make_set(RiskLevelDuringSignIn) by UserPrincipalName, AppDisplayName, IPAddress, tostring(LocationDetails.countryOrRegion)
| sort by Count desc
"@

$kqlUserRiskEvents = @"
AADUserRiskEvents
| where TimeGenerated > ago(${Days}d)
| summarize Detections=count(), Types=make_set(RiskEventType) by UserPrincipalName, RiskLevel
| sort by Detections desc
"@

$kqlCaeTokenSignals = @"
SigninLogs
| where TimeGenerated > ago(${Days}d)
| where ResultType != 0
| extend CA = parse_json(ConditionalAccessStatus)
| where AuthenticationRequirement has 'multiFactorAuthentication' or ConditionalAccessStatus == 'failure'
| summarize Failures=count() by UserPrincipalName, ConditionalAccessStatus, ResultDescription
| sort by Failures desc
"@

if ($WorkspaceId) {
    Write-Host "`n=== ENTIDP RiskHunt — KQL mode (workspace $WorkspaceId) ===" -ForegroundColor Cyan
    if (-not (Get-Module -ListAvailable -Name Az.OperationalInsights)) { Install-Module Az.OperationalInsights -Scope CurrentUser -Force -AllowClobber }
    Import-Module Az.OperationalInsights -ErrorAction Stop
    if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
    foreach ($q in @(@{n='Risky sign-ins';k=$kqlRiskySignIns}, @{n='User risk events';k=$kqlUserRiskEvents}, @{n='CAE / token failures';k=$kqlCaeTokenSignals})) {
        Write-Host "`n--- $($q.n) ---" -ForegroundColor Yellow
        try {
            $r = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceId -Query $q.k
            $r.Results | Select-Object -First 25 | Format-Table -AutoSize
        } catch { Write-Host "  Query failed — verify the log category is exported to this workspace." -ForegroundColor Yellow }
    }
    Write-Host "`nKQL text is embedded above — reuse it directly in Sentinel hunting." -ForegroundColor Cyan
}
else {
    Write-Host "`n=== ENTIDP RiskHunt — Graph fallback (no workspace supplied) ===" -ForegroundColor Cyan
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'IdentityRiskEvent.Read.All','AuditLog.Read.All' -NoWelcome
    try {
        $rd = @((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/identityProtection/riskDetections?`$top=100&`$orderby=detectedDateTime desc").value)
        $medHigh = @($rd | Where-Object { $_.riskLevel -in @('medium','high') })
        Write-Host ("Recent medium/high risk detections: {0}" -f $medHigh.Count)
        $medHigh | Select-Object -First 25 | ForEach-Object {
            Write-Host ("  {0}  {1}  {2}  {3}" -f $_.detectedDateTime, $_.riskLevel, $_.riskEventType, $_.userPrincipalName)
        }
        if ($medHigh.Count -eq 0) { Write-Host "  No medium/high detections in the returned window (verify P2 signal)." -ForegroundColor Yellow }
    } catch { Write-Host "  Graph risk query failed — verify Entra ID P2 licensing/permissions." -ForegroundColor Yellow }
    Write-Host "`nFor trend/CAE hunting, export SignInLogs/AADUserRiskEvents to a workspace and re-run with -WorkspaceId." -ForegroundColor Cyan
    Disconnect-MgGraph | Out-Null
}

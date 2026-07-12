<#
.SYNOPSIS
    ENTPAW-Report.ps1 — surface privileged sign-ins from non-PAW / non-compliant devices (KQL or Graph fallback).
.DESCRIPTION
    PURPOSE
        The core monitoring report: finds administrative sign-ins that came from a device that is NOT a
        compliant PAW, so exceptions and gaps are visible before and after enforcement. If Entra sign-in
        logs are exported to a Log Analytics / Microsoft Sentinel workspace, it runs the embedded KQL
        there; otherwise it falls back to a read-only Microsoft Graph query of recent sign-ins to the
        admin surfaces and flags those from non-compliant devices.
    HOW TO RUN
        KQL mode:   powershell -ExecutionPolicy Bypass -File .\ENTPAW-Report.ps1 -WorkspaceId "<LA workspace GUID>"
                    (requires Az.OperationalInsights and reader access to the workspace)
        Graph mode: powershell -ExecutionPolicy Bypass -File .\ENTPAW-Report.ps1
                    (Microsoft Graph SDK; read-only: AuditLog.Read.All, Directory.Read.All)
    EXPECTED RESULTS
        A list of privileged sign-ins from non-PAW/non-compliant devices. Read-only — no changes made.
        Verify sign-in log export exists for KQL mode.
.NOTES
    White-label — Entra ID Solutions. Read-only. KQL requires SigninLogs exported to a workspace.
#>
[CmdletBinding()]
param([string]$WorkspaceId, [int]$Days = 7)

# ---- Embedded KQL (also usable directly in Sentinel / Log Analytics) --------------------------
$kqlNonPawAdmin = @"
let AdminApps = dynamic(['Microsoft Azure Management','Azure Active Directory PowerShell','Microsoft Graph PowerShell','Microsoft Admin Portals','Windows Azure Service Management API']);
SigninLogs
| where TimeGenerated > ago(${Days}d)
| where AppDisplayName in (AdminApps) or ResourceDisplayName in (AdminApps)
| extend Compliant = tostring(DeviceDetail.isCompliant)
| where Compliant != 'true'
| summarize SignIns=count(), Apps=make_set(AppDisplayName), Devices=make_set(DeviceDetail.displayName)
    by UserPrincipalName, Compliant, IPAddress
| sort by SignIns desc
"@

if ($WorkspaceId) {
    Write-Host "`n=== ENTPAW Report — KQL mode (workspace $WorkspaceId) ===" -ForegroundColor Cyan
    if (-not (Get-Module -ListAvailable -Name Az.OperationalInsights)) { Install-Module Az.OperationalInsights -Scope CurrentUser -Force -AllowClobber }
    Import-Module Az.OperationalInsights -ErrorAction Stop
    if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
    Write-Host "`n--- Privileged sign-ins from non-compliant (non-PAW) devices ---" -ForegroundColor Yellow
    try {
        $r = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceId -Query $kqlNonPawAdmin
        $r.Results | Select-Object -First 50 | Format-Table -AutoSize
    } catch { Write-Host "  Query failed — verify SigninLogs is exported to this workspace." -ForegroundColor Yellow }
    Write-Host "`nKQL text is embedded above — reuse it directly in Sentinel hunting." -ForegroundColor Cyan
}
else {
    Write-Host "`n=== ENTPAW Report — Graph fallback (no workspace supplied) ===" -ForegroundColor Cyan
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'AuditLog.Read.All','Directory.Read.All' -NoWelcome
    $adminApps = @('Microsoft Azure Management','Microsoft Admin Portals','Microsoft Graph PowerShell','Windows Azure Service Management API')
    try {
        $since = (Get-Date).AddDays(-$Days).ToString('yyyy-MM-ddTHH:mm:ssZ')
        $signins = @((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/auditLogs/signIns?`$filter=createdDateTime ge $since&`$top=200").value)
        $adminSignins = @($signins | Where-Object { $adminApps -contains $_.appDisplayName -or $adminApps -contains $_.resourceDisplayName })
        $nonPaw = @($adminSignins | Where-Object { $_.deviceDetail.isCompliant -ne $true })
        Write-Host ("Admin sign-ins in window       : {0}" -f $adminSignins.Count)
        Write-Host ("From non-compliant (non-PAW)   : {0}" -f $nonPaw.Count) -ForegroundColor ($(if($nonPaw.Count -gt 0){'Yellow'}else{'Green'}))
        $nonPaw | Select-Object -First 50 | ForEach-Object {
            Write-Host ("  {0}  {1}  app={2}  device='{3}' compliant={4}" -f $_.createdDateTime, $_.userPrincipalName, $_.appDisplayName, $_.deviceDetail.displayName, $_.deviceDetail.isCompliant)
        }
        if ($nonPaw.Count -gt 0) { Write-Host "`n  Investigate each: privileged access should only come from a compliant PAW." -ForegroundColor Yellow }
    } catch { Write-Host "  Sign-in query failed — verify AuditLog.Read.All and licensing." -ForegroundColor Yellow }
    Write-Host "`nFor richer trend/hunting, export SigninLogs to a workspace and re-run with -WorkspaceId." -ForegroundColor Cyan
    Disconnect-MgGraph | Out-Null
}

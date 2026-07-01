<#
.SYNOPSIS
    RHELP-SessionReport.ps1 — report Remote Help session/usage activity for auditing (Graph).
.DESCRIPTION
    PURPOSE
        Surfaces Remote Help audit/usage activity so you can see who assisted whom and when. Uses
        Intune audit events filtered to Remote Help where available.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\RHELP-SessionReport.ps1 -Days 30 -CsvPath C:\Temp\remotehelp.csv
        Requires Microsoft Graph SDK and DeviceManagementApps.Read.All / AuditLog.Read.All.
    EXPECTED RESULTS
        A list of recent Remote Help related activities (best-effort) and an optional CSV.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only against Graph.
    For full session detail, also see Intune > Tenant administration > Remote Help (usage report).
#>
[CmdletBinding()] param([int]$Days = 30, [string]$CsvPath)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All' -NoWelcome
$rows = @()
try {
    $events = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/auditEvents?$top=200').value
    $rh = $events | Where-Object { ($_.category -match 'RemoteAssistance|RemoteHelp') -or ($_.displayName -match 'Remote Help|Remote Assistance') }
    $rows = $rh | ForEach-Object { [pscustomobject]@{ Time=$_.activityDateTime; Activity=$_.displayName; Actor=$_.actor.userPrincipalName; Category=$_.category } }
} catch {}
if ($rows.Count) {
    $rows | Sort-Object Time -Descending | Select-Object -First 40 | Format-Table -AutoSize
    Write-Host ("Remote Help related activities: {0}" -f $rows.Count) -ForegroundColor Cyan
    if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }
} else {
    Write-Host "No Remote Help audit activities surfaced via Graph in the window. Use Intune > Tenant administration > Remote Help for the usage report." -ForegroundColor Yellow
}
Disconnect-MgGraph | Out-Null

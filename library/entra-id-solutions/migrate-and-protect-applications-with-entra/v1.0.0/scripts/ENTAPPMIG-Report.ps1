<#
.SYNOPSIS
    ENTAPPMIG-Report.ps1 — export sign-in evidence for the migrated apps (Graph + optional KQL, read-only).
.DESCRIPTION
    PURPOSE
        The cutover/audit evidence tool. Pulls Entra sign-in logs for the migrated apps (those named
        ENTAPPMIG*, or any -AppNameLike you pass) and summarizes who signed in, via which app, the result,
        and the Conditional Access status — the proof that the app authenticates through Entra and that CA
        is applying. Optionally runs the same query as KQL against a Log Analytics workspace.
    HOW TO RUN
        Graph sign-in logs:  .\ENTAPPMIG-Report.ps1 -Hours 24 -CsvFolder C:\Temp\entappmig
        KQL (Log Analytics): Connect-AzAccount; .\ENTAPPMIG-Report.ps1 -WorkspaceId <guid> -Hours 24
        Graph path needs AuditLog.Read.All; the KQL path needs Az.OperationalInsights + LA Reader.
    EXPECTED RESULTS
        A table of sign-ins per migrated app with result + CA status, plus optional CSV. PASS = pilot users
        appear signing into the ENTAPPMIG apps through Entra with the expected CA outcome.
.NOTES
    White-label — Entra ID Solutions. Read-only. No credentials stored.
.EXAMPLE
    .\ENTAPPMIG-Report.ps1 -Hours 48
#>
[CmdletBinding()]
param(
    [string]$AppNameLike = 'ENTAPPMIG',
    [int]$Hours = 24,
    [string]$WorkspaceId,
    [string]$CsvFolder
)

function Save-Csv($rows, $name) {
    if ($CsvFolder -and $rows) {
        if (-not (Test-Path $CsvFolder)) { New-Item -ItemType Directory -Path $CsvFolder | Out-Null }
        $p = Join-Path $CsvFolder "$name.csv"; $rows | Export-Csv -Path $p -NoTypeInformation
        Write-Host "  saved $p" -ForegroundColor Green
    }
}

# --- KQL path (Log Analytics) -------------------------------------------------
if ($WorkspaceId) {
    if (-not (Get-Module -ListAvailable -Name Az.OperationalInsights)) {
        Install-Module Az.OperationalInsights -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Az.OperationalInsights -ErrorAction Stop
    if (-not (Get-AzContext)) { Write-Host "Run Connect-AzAccount first." -ForegroundColor Yellow; Connect-AzAccount | Out-Null }
    $q = @"
SigninLogs
| where TimeGenerated > ago(${Hours}h)
| where AppDisplayName startswith '$AppNameLike'
| summarize Signins = count() by AppDisplayName, UserPrincipalName, ResultType, ConditionalAccessStatus
| order by Signins desc
"@
    Write-Host "`n=== Sign-ins to migrated apps (KQL) ===" -ForegroundColor Cyan
    try {
        $res = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceId -Query $q -ErrorAction Stop
        if ($res.Results) { $res.Results | Format-Table -AutoSize; Save-Csv $res.Results 'signins-kql' }
        else { Write-Host "  (no rows — check the workspace and that sign-in logs are exported)" -ForegroundColor Yellow }
    } catch { Write-Host "  Query failed: $($_.Exception.Message)" -ForegroundColor Yellow }
    return
}

# --- Graph path (default) -----------------------------------------------------
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'AuditLog.Read.All','Directory.Read.All' -NoWelcome

$since = (Get-Date).AddHours(-$Hours).ToString('yyyy-MM-ddTHH:mm:ssZ')
$uri = "/v1.0/auditLogs/signIns?`$filter=createdDateTime ge $since and startswith(appDisplayName,'$AppNameLike')&`$top=200"
Write-Host "`n=== Sign-ins to migrated apps (Graph, last $Hours h) ===" -ForegroundColor Cyan
$rows = @()
do {
    try { $r = Invoke-MgGraphRequest -Method GET -Uri $uri } catch { Write-Host "  $($_.Exception.Message)" -ForegroundColor Yellow; break }
    $rows += $r.value | ForEach-Object {
        [pscustomobject]@{
            Time   = $_.createdDateTime
            App    = $_.appDisplayName
            User   = $_.userPrincipalName
            Result = $_.status.errorCode
            CA     = $_.conditionalAccessStatus
            IP     = $_.ipAddress
        }
    }
    $uri = $r.'@odata.nextLink'
} while ($uri)

if ($rows) {
    $rows | Group-Object App | ForEach-Object {
        Write-Host ("`n  {0} — {1} sign-ins" -f $_.Name, $_.Count) -ForegroundColor White
        $_.Group | Select-Object -First 20 | Format-Table -AutoSize
    }
    Save-Csv $rows 'signins-graph'
} else { Write-Host "  (no sign-ins for '$AppNameLike*' in the window — generate pilot traffic)" -ForegroundColor Yellow }

Write-Host "`nReport complete. Attach the CSV as cutover / audit evidence." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null

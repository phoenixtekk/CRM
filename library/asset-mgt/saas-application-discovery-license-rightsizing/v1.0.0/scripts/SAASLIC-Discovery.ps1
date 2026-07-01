<#
.SYNOPSIS
    SAASLIC-Discovery.ps1 — discover Entra ID SaaS (enterprise) apps and per-app sign-in activity.
.DESCRIPTION
    PURPOSE
        Builds the 'App Inventory - SaaS - Discovered' artifact: every enterprise application in Entra
        ID (the SSO-integrated SaaS estate) with its app sign-in count and last sign-in over a window.
        Read-only — it reads the directory and the sign-in audit logs, and changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SAASLIC-Discovery.ps1 -Days 30 -CsvPath C:\Temp\saas-inventory.csv
        Requires the Microsoft Graph PowerShell SDK and the scopes Application.Read.All and
        AuditLog.Read.All (and Directory.Read.All). See SAASLIC-Validation.ps1.
    EXPECTED RESULTS
        A table of SaaS apps with sign-in counts and last sign-in, and (with -CsvPath) a CSV export to
        record as 'App Inventory - SaaS - Discovered'. Add non-SSO apps manually afterwards.
.NOTES
    Workplace Marketplace — Asset Mgt. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param(
    [int]$Days = 30,
    [string]$CsvPath
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Application.Read.All','AuditLog.Read.All','Directory.Read.All' -NoWelcome

$since = (Get-Date).ToUniversalTime().AddDays(-$Days).ToString('yyyy-MM-ddTHH:mm:ssZ')
Write-Host ("=== SaaS app discovery (last {0} days) ===" -f $Days) -ForegroundColor Cyan

# Enterprise applications = service principals of type Application (exclude managed identities)
$apps = @(); $uri = "/v1.0/servicePrincipals?`$filter=servicePrincipalType eq 'Application'&`$select=id,appId,displayName,accountEnabled&`$top=999"
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $apps += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)

# Sign-in activity per app over the window (interactive + non-interactive)
$signins = @{}; $lastSeen = @{}
$siUri = "/v1.0/auditLogs/signIns?`$filter=createdDateTime ge $since&`$select=appId,appDisplayName,createdDateTime&`$top=1000"
do {
    $sr = Invoke-MgGraphRequest -Method GET -Uri $siUri
    foreach ($e in $sr.value) {
        if (-not $e.appId) { continue }
        $signins[$e.appId] = ($signins[$e.appId] + 1)
        if (-not $lastSeen[$e.appId] -or $e.createdDateTime -gt $lastSeen[$e.appId]) { $lastSeen[$e.appId] = $e.createdDateTime }
    }
    $siUri = $sr.'@odata.nextLink'
} while ($siUri)

$report = foreach ($a in $apps) {
    [pscustomobject]@{
        App         = $a.displayName
        AppId       = $a.appId
        Enabled     = $a.accountEnabled
        SignIns     = [int]($signins[$a.appId])
        LastSignIn  = $lastSeen[$a.appId]
    }
}
$report = $report | Sort-Object SignIns -Descending
$report | Select-Object App, SignIns, LastSignIn, Enabled | Format-Table -AutoSize
Write-Host ("Total SaaS (enterprise) apps: {0}" -f $report.Count) -ForegroundColor Cyan
Write-Host ("Apps with zero sign-ins in window: {0}" -f (@($report | Where-Object { $_.SignIns -eq 0 })).Count) -ForegroundColor Yellow
if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath (record as 'App Inventory - SaaS - Discovered')." -ForegroundColor Green }
Disconnect-MgGraph | Out-Null

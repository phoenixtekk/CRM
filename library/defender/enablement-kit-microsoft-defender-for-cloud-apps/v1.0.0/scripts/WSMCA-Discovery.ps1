<#
.SYNOPSIS
    WSMCA-Discovery.ps1 — read-only discovery for the Defender for Cloud Apps workshop: MDA alerts,
    OAuth app inventory summary, and connected-app signal.
.DESCRIPTION
    PURPOSE
        Read-only environment discovery for the "Workshop — Microsoft Defender for Cloud Apps"
        enablement package. Confirms there is data to teach against: recent Defender-for-Cloud-Apps
        alerts (via Microsoft Graph Security), a count/summary of OAuth applications (service
        principals) with risk hints, and a note on connected-app signal. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WSMCA-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\WSMCA-Discovery.ps1 -OutputPath .\wsmca-discovery.json
        Requires the Microsoft.Graph modules. Connects with READ-ONLY delegated scopes; consent as a
        Security Reader / Security Administrator when prompted.
    EXPECTED RESULTS
        A console summary plus a JSON file: MDA alert count by severity, OAuth app count with a few
        risk hints, and reminders for the portal-only checks (Cloud Discovery, connectors). Use it in
        Lab 0 (readiness).
.NOTES
    White-label. Read-only. Reports configuration/identifiers only; makes no changes.
    Feature/licensing facts are indicative — verify current availability in your tenant.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\wsmca-discovery.json"
)

$ErrorActionPreference = 'Continue'
$scopes = @('SecurityAlert.Read.All','Application.Read.All','Directory.Read.All')
foreach ($m in 'Microsoft.Graph.Authentication','Microsoft.Graph.Security','Microsoft.Graph.Applications') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Installing Microsoft.Graph modules (one-time)..." -ForegroundColor Yellow
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber; break
    }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

Write-Host "`n=== Defender for Cloud Apps workshop — discovery (read-only) ===" -ForegroundColor Cyan
try { Connect-MgGraph -Scopes $scopes -NoWelcome -ErrorAction Stop }
catch { Write-Host "  Could not connect: $($_.Exception.Message)" -ForegroundColor Red; return }

$result = [ordered]@{ Timestamp = (Get-Date).ToString('s') }

# --- MDA alerts (read-only) ---
Write-Host "`n-- Recent Defender for Cloud Apps alerts --" -ForegroundColor Cyan
$mdaAlerts = @()
try {
    $alerts = Get-MgSecurityAlertV2 -All -ErrorAction Stop |
        Where-Object { $_.ServiceSource -match 'CloudApp' -or $_.DetectionSource -match 'CloudApp' }
    foreach ($a in $alerts) { $mdaAlerts += [pscustomobject]@{ Title=$a.Title; Severity=$a.Severity; Status=$a.Status; Created=$a.CreatedDateTime } }
    if ($mdaAlerts.Count -eq 0) { Write-Host "   No MDA alerts returned (quiet tenant is OK for teaching)." -ForegroundColor Yellow }
    else {
        $bySev = $mdaAlerts | Group-Object Severity | ForEach-Object { "{0}={1}" -f $_.Name,$_.Count }
        Write-Host ("   Total MDA alerts: {0}  ({1})" -f $mdaAlerts.Count, ($bySev -join ', ')) -ForegroundColor Green
        $mdaAlerts | Sort-Object Created -Descending | Select-Object -First 10 | Format-Table Title,Severity,Status,Created -AutoSize
    }
} catch { Write-Host "   Could not read alerts: $($_.Exception.Message)" -ForegroundColor Yellow }
$result.MdaAlertCount = $mdaAlerts.Count
$result.MdaAlerts = $mdaAlerts | Select-Object -First 25

# --- OAuth apps (service principals) with basic risk hints (read-only) ---
Write-Host "`n-- OAuth applications (service principals) --" -ForegroundColor Cyan
$oauth = @()
try {
    Import-Module Microsoft.Graph.Applications -ErrorAction Stop
    $sps = Get-MgServicePrincipal -All -Property 'displayName','appId','publisherName','verifiedPublisher','servicePrincipalType' -ErrorAction Stop |
        Where-Object { $_.ServicePrincipalType -eq 'Application' }
    foreach ($sp in $sps) {
        $verified = if ($sp.VerifiedPublisher -and $sp.VerifiedPublisher.DisplayName) { $true } else { $false }
        $oauth += [pscustomobject]@{ DisplayName=$sp.DisplayName; AppId=$sp.AppId; Publisher=$sp.PublisherName; VerifiedPublisher=$verified }
    }
    $unverified = ($oauth | Where-Object { -not $_.VerifiedPublisher }).Count
    Write-Host ("   OAuth apps: {0} total; {1} without a verified publisher (review in Lab 3)." -f $oauth.Count, $unverified) -ForegroundColor Green
    $oauth | Where-Object { -not $_.VerifiedPublisher } | Select-Object -First 15 | Format-Table DisplayName,Publisher,VerifiedPublisher -AutoSize
} catch { Write-Host "   Could not enumerate service principals: $($_.Exception.Message)" -ForegroundColor Yellow }
$result.OAuthAppCount = $oauth.Count
$result.OAuthUnverified = ($oauth | Where-Object { -not $_.VerifiedPublisher } | Select-Object -First 25)

Write-Host "`n-- Portal-only reminders --" -ForegroundColor Cyan
Write-Host "   Confirm in the portal: Cloud apps -> Cloud Discovery (data present, R2) and Connected apps (>=1, R3)." -ForegroundColor Yellow

$result | ConvertTo-Json -Depth 6 | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "`nSaved discovery to $OutputPath" -ForegroundColor Cyan
Write-Host "This script is READ-ONLY — it changed nothing." -ForegroundColor Green
Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null

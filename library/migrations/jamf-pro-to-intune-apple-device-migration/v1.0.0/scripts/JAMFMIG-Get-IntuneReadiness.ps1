<#
.SYNOPSIS
    Report Intune Apple enrollment readiness — MDM push certificate, ADE (enrollment program) tokens,
    and VPP (Apps and Books) tokens — before migrating.

.DESCRIPTION
    Phase 1. A lapsed Apple MDM push certificate unenrolls the entire Apple fleet, and you cannot
    enroll or license apps without the ADE and VPP tokens. This reports each with expiry.

.HOW TO RUN
    .\JAMFMIG-Get-IntuneReadiness.ps1
    Sovereign cloud: add  -Environment USGov.

.EXPECTED RESULT
    Console + CSV: push cert expiry, ADE tokens with expiry, VPP tokens with expiry/state. Fix any gap
    before migrating.

.NOTES
    Migrations — read-only (Microsoft Graph).
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".",
    [string]$Environment = "Global"
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.Read.All','DeviceManagementConfiguration.Read.All' -Environment $Environment -NoWelcome
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$rows = @()

Write-Host "=== Apple MDM push certificate ===" -ForegroundColor Cyan
try {
    $push = Get-MgDeviceManagementApplePushNotificationCertificate -ErrorAction Stop
    $days = ([datetime]$push.ExpirationDateTime - (Get-Date)).Days
    Write-Host ("  AppleId={0}  expires {1}  ({2} days)" -f $push.AppleIdentifier, $push.ExpirationDateTime, $days) -ForegroundColor $(if($days -lt 30){'Yellow'}else{'Green'})
    $rows += [pscustomobject]@{ Item='ApplePushCert'; Name=$push.AppleIdentifier; Expires=$push.ExpirationDateTime; DaysLeft=$days }
} catch { Write-Warning "  No Apple push certificate found: $($_.Exception.Message)" }

Write-Host "=== ADE (enrollment program) tokens ===" -ForegroundColor Cyan
try {
    $dep = Get-MgDeviceManagementDepOnboardingSetting -All -ErrorAction Stop
    foreach ($d in $dep) {
        $days = if ($d.TokenExpirationDateTime) { ([datetime]$d.TokenExpirationDateTime - (Get-Date)).Days } else { $null }
        Write-Host ("  {0}  expires {1}  ({2} days)" -f $d.TokenName, $d.TokenExpirationDateTime, $days)
        $rows += [pscustomobject]@{ Item='ADEToken'; Name=$d.TokenName; Expires=$d.TokenExpirationDateTime; DaysLeft=$days }
    }
    if (-not $dep) { Write-Warning "  No ADE tokens — upload one from ABM." }
} catch { Write-Warning "  ADE token read failed: $($_.Exception.Message)" }

Write-Host "=== VPP (Apps and Books) tokens ===" -ForegroundColor Cyan
try {
    $vpp = Get-MgDeviceAppManagementVppToken -All -ErrorAction Stop
    foreach ($v in $vpp) {
        $days = if ($v.ExpirationDateTime) { ([datetime]$v.ExpirationDateTime - (Get-Date)).Days } else { $null }
        Write-Host ("  {0}  state={1}  expires {2}  ({3} days)" -f $v.OrganizationName, $v.State, $v.ExpirationDateTime, $days)
        $rows += [pscustomobject]@{ Item='VPPToken'; Name=$v.OrganizationName; Expires=$v.ExpirationDateTime; DaysLeft=$days }
    }
    if (-not $vpp) { Write-Warning "  No VPP token — connect Apps and Books in Intune." }
} catch { Write-Warning "  VPP token read failed: $($_.Exception.Message)" }

$out = Join-Path $OutputPath "JAMFMIG-IntuneReadiness-$stamp.csv"
$rows | Export-Csv $out -NoTypeInformation -Encoding UTF8
Write-Host "`nExported: $out" -ForegroundColor Green
$rows | Where-Object { $_.DaysLeft -ne $null -and $_.DaysLeft -lt 45 } | ForEach-Object { Write-Host "WARNING: '$($_.Name)' expires in $($_.DaysLeft) days." -ForegroundColor Yellow }

<#
.SYNOPSIS
    ABMPROVG-Report.ps1 — read-only health snapshot of the ABM + Intune Government deployment.
.DESCRIPTION
    PURPOSE
        Produces a point-in-time health snapshot for records and phase reviews: US Gov connection,
        APNs and ABM token expiries, ADE-enrolled Apple device counts, and pilot group membership.
        Optionally writes a CSV/JSON copy. It changes nothing. Set your-output-folder with -OutputPath
        if you want a saved copy (default: no file, console only).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ABMPROVG-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\ABMPROVG-Report.ps1 -OutputPath .\abmprovg-report
        (Graph scopes: DeviceManagementServiceConfig.Read.All, DeviceManagementManagedDevices.Read.All,
         Group.Read.All; -Environment USGov)
    EXPECTED RESULTS
        A readable snapshot table in the console (and optional .csv/.json files). Use it after each
        expansion wave and before each token/certificate renewal.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string]$PilotDeviceGroup = 'ABM-Apple-Pilot-Devices',
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$snapshot = [ordered]@{}

Write-Host "=== ABMPROVG Report (GCC High / US Gov) ===" -ForegroundColor White

# --- Connect ---
try {
    $scopes = @(
        'DeviceManagementServiceConfig.Read.All',
        'DeviceManagementManagedDevices.Read.All',
        'Group.Read.All'
    )
    Connect-MgGraph -Environment USGov -Scopes $scopes -NoWelcome
    $ctx = Get-MgContext
    if ($ctx.Environment -ne 'USGov') {
        Write-Host "[FAIL] Connected environment is '$($ctx.Environment)', expected 'USGov'. Reconnect with -Environment USGov." -ForegroundColor Red
        return
    }
    $snapshot['GeneratedUtc'] = (Get-Date).ToUniversalTime().ToString('u')
    $snapshot['Environment']  = $ctx.Environment
    $snapshot['TenantId']     = $ctx.TenantId
    Write-Host "Connected to US Gov Graph. Tenant: $($ctx.TenantId)" -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Could not connect: $($_.Exception.Message)" -ForegroundColor Red
    return
}

# --- APNs ---
try {
    $apns = Get-MgDeviceManagementApplePushNotificationCertificate -ErrorAction SilentlyContinue
    if ($apns -and $apns.AppleIdentifier) {
        $snapshot['ApnsAppleId'] = $apns.AppleIdentifier
        $snapshot['ApnsExpires'] = $apns.ExpirationDateTime
        $snapshot['ApnsDaysLeft'] = if ($apns.ExpirationDateTime) { [int]([datetime]$apns.ExpirationDateTime - (Get-Date)).TotalDays } else { 'n/a' }
    } else {
        $snapshot['ApnsAppleId'] = 'NOT CONFIGURED'
    }
}
catch { $snapshot['ApnsAppleId'] = "error: $($_.Exception.Message)" }

# --- ABM tokens ---
try {
    $tokens = Get-MgDeviceManagementDepOnboardingSetting -All -ErrorAction SilentlyContinue
    $tokenLines = @()
    foreach ($t in $tokens) {
        $name = if ($t.TokenName) { $t.TokenName } else { $t.AppleIdentifier }
        $daysLeft = if ($t.TokenExpirationDateTime) { [int]([datetime]$t.TokenExpirationDateTime - (Get-Date)).TotalDays } else { 'n/a' }
        $tokenLines += ("{0} (expires in {1} day(s); last sync {2})" -f $name, $daysLeft, $t.LastSuccessfulSyncDateTime)
    }
    $snapshot['AbmTokens'] = if ($tokenLines) { $tokenLines -join ' | ' } else { 'NONE' }
}
catch { $snapshot['AbmTokens'] = "error: $($_.Exception.Message)" }

# --- Enrolled Apple devices (approximate via managed devices) ---
try {
    $appleDevices = Get-MgDeviceManagementManagedDevice -All -Filter "operatingSystem eq 'iOS' or operatingSystem eq 'macOS' or operatingSystem eq 'iPadOS'" -ErrorAction SilentlyContinue
    $snapshot['AppleManagedDeviceCount'] = ($appleDevices | Measure-Object).Count
}
catch { $snapshot['AppleManagedDeviceCount'] = "error: $($_.Exception.Message)" }

# --- Pilot group membership ---
try {
    $g = Get-MgGroup -Filter "displayName eq '$PilotDeviceGroup'" -ErrorAction SilentlyContinue
    if ($g) {
        $members = Get-MgGroupMember -GroupId $g.Id -All -ErrorAction SilentlyContinue
        $snapshot['PilotGroup'] = $PilotDeviceGroup
        $snapshot['PilotGroupMembers'] = ($members | Measure-Object).Count
    } else {
        $snapshot['PilotGroup'] = "$PilotDeviceGroup (NOT FOUND)"
        $snapshot['PilotGroupMembers'] = 0
    }
}
catch { $snapshot['PilotGroup'] = "error: $($_.Exception.Message)" }

# --- Output ---
Write-Host "`n-- Snapshot --" -ForegroundColor White
foreach ($k in $snapshot.Keys) { Write-Host ("{0,-26}: {1}" -f $k, $snapshot[$k]) }

if ($OutputPath) {
    try {
        $obj = [pscustomobject]$snapshot
        $obj | Export-Csv -Path "$OutputPath.csv" -NoTypeInformation -Encoding UTF8
        $obj | ConvertTo-Json -Depth 4 | Out-File -FilePath "$OutputPath.json" -Encoding UTF8
        Write-Host "`nSaved $OutputPath.csv and $OutputPath.json" -ForegroundColor Green
    }
    catch { Write-Host "Could not write output files: $($_.Exception.Message)" -ForegroundColor Yellow }
}

Write-Host "`nParity note: no SCIM/federation provisioning figures are reported — that path is unsupported in national clouds." -ForegroundColor Cyan

<#
.SYNOPSIS
    MACVPP-Discovery.ps1 — tenant readiness check for macOS app deployment via Apple VPP.
.DESCRIPTION
    PURPOSE
        Confirms the Intune tenant is ready to deploy and license Mac apps through Apple VPP:
        the Apple VPP token(s) status and expiry, last successful license sync, the count of
        synced App Store apps, and per-app VPP license totals. Flags any token expiring within
        30 days or a stale last-sync time. Uses placeholders like your-location-token, not
        angle-bracket placeholders.
    HOW TO RUN
        Install the SDK once:  Install-Module Microsoft.Graph -Scope CurrentUser
        Then:                  powershell -ExecutionPolicy Bypass -File .\MACVPP-Discovery.ps1
        Required Graph scopes: DeviceManagementServiceConfig.Read.All, DeviceManagementApps.Read.All
        Reads only — makes no changes.
    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall verdict. A READY tenant shows a Valid VPP token
        (expiry greater than 30 days), a recent last-sync, and at least one synced App Store app
        with VPP licenses.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.Read.All','DeviceManagementApps.Read.All' | Out-Null

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}
function DaysLeft($iso) { if (-not $iso) { return $null }; [int]([datetime]$iso - (Get-Date)).TotalDays }

$results = New-Object System.Collections.Generic.List[object]

# 1) Apple VPP token(s) present & valid > 30 days
$tokens = @()
try {
    $vpp = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/deviceAppManagement/vppTokens'
    $tokens = @($vpp.value)
    if ($tokens.Count -gt 0) {
        $minDays = ($tokens | ForEach-Object { DaysLeft $_.expirationDateTime } | Measure-Object -Minimum).Minimum
        $names   = ($tokens | ForEach-Object { $_.displayName -as [string]; if (-not $_.displayName) { $_.appleId } }) -join ', '
        $results.Add( (R 'VPP token present & valid >30d' ($minDays -gt 30) "$($tokens.Count) token(s) [$names]; soonest expiry in $minDays day(s)") )
    } else {
        $results.Add( (R 'VPP token present & valid >30d' $false 'No Apple VPP token — connect one (Requirements R3).') )
    }
} catch { $results.Add( (R 'VPP token present & valid >30d' $false "Could not read VPP tokens: $($_.Exception.Message)") ); $tokens = @() }

# 2) Token state = valid and a recent last-sync
foreach ($t in $tokens) {
    $stateOk  = ("$($t.state)" -match 'valid')
    $syncDays = DaysLeft $t.lastSyncDateTime  # negative = days since sync
    $syncAge  = if ($syncDays -ne $null) { [math]::Abs($syncDays) } else { $null }
    $syncOk   = ($syncAge -ne $null -and $syncAge -le 7)
    $label    = if ($t.displayName) { $t.displayName } else { $t.appleId }
    $results.Add( (R "Token '$label' state=valid" $stateOk "state=$($t.state)") )
    $results.Add( (R "Token '$label' synced <=7d"  $syncOk  "last sync ~$syncAge day(s) ago") )
}

# 3) Synced VPP (App Store) apps present, with license totals
try {
    $apps = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.macOsVppApp')"
    $vppApps = @($apps.value)
    if ($vppApps.Count -eq 0) {
        # Some tenants surface VPP apps only via the iOS/macOS VPP type name; try a broad contains as a fallback signal.
        $results.Add( (R 'Synced App Store (VPP) apps present' $false 'No macOS VPP apps found — Sync the token (Implementation Step 4).') )
    } else {
        $totalLic = ($vppApps | ForEach-Object { [int]($_.totalLicenseCount) } | Measure-Object -Sum).Sum
        $results.Add( (R 'Synced App Store (VPP) apps present' $true "$($vppApps.Count) macOS VPP app(s); $totalLic total license(s)") )
    }
} catch { $results.Add( (R 'Synced App Store (VPP) apps present' $false "Could not read VPP apps: $($_.Exception.Message)") ) }

$results | Format-Table -AutoSize
$fail = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: READY — tenant is prepared for macOS app deployment via Apple VPP.' -ForegroundColor Green }
else { Write-Host "OVERALL: NOT READY — $fail check(s) failed. Resolve before assigning apps." -ForegroundColor Yellow }

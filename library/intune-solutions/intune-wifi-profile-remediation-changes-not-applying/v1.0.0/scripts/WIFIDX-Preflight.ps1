<#
.SYNOPSIS
    WIFIDX-Preflight.ps1 — verify the Graph SDK, sign-in, scopes, and cloud environment before you start.
.DESCRIPTION
    PURPOSE
        Confirms the workstation is ready to diagnose Intune Wi-Fi profiles: the Microsoft Graph SDK is
        installed, you can sign in to the correct cloud (Commercial / US Gov / US Gov DoD), the read
        scopes are consented, and at least one Wi-Fi configuration profile is visible. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WIFIDX-Preflight.ps1
        powershell -ExecutionPolicy Bypass -File .\WIFIDX-Preflight.ps1 -Environment USGov
        Requires Microsoft Graph SDK and scope DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        A short readiness report: SDK present, connected tenant + environment, scopes granted, and a
        count of Wi-Fi configuration profiles found. Any missing prerequisite is called out with the fix.
.NOTES
    Intune Solutions — read-only. Cloud-aware (Global | USGov | USGovDoD).
#>
[CmdletBinding()]
param(
    [ValidateSet('Global','USGov','USGovDoD')]
    [string]$Environment = 'Global'
)

Write-Host "`n=== WIFIDX Preflight ===" -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Host "  Microsoft Graph SDK not found. Installing (CurrentUser)..." -ForegroundColor Yellow
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Write-Host "  [OK] Microsoft.Graph.Authentication available." -ForegroundColor Green

try {
    Connect-MgGraph -Environment $Environment -Scopes 'DeviceManagementConfiguration.Read.All' -NoWelcome
} catch {
    Write-Host "  [FAIL] Could not connect to Graph ($Environment): $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "         Sign in as an admin who can consent, or have a Global Admin grant admin consent." -ForegroundColor Yellow
    return
}

$ctx = Get-MgContext
Write-Host ("  [OK] Connected. Tenant: {0}  Account: {1}  Environment: {2}" -f $ctx.TenantId, $ctx.Account, $Environment) -ForegroundColor Green
Write-Host ("  Scopes: {0}" -f ($ctx.Scopes -join ', ')) -ForegroundColor Gray

# Beta endpoint for configuration policies; SDK targets the correct sovereign host automatically.
try {
    $all = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/configurationPolicies?$top=100').value
    $wifi = @($all | Where-Object { $_.name -match 'wifi|wi-fi|wireless' -or $_.templateReference.templateFamily -match 'wifi' })
    # also count legacy device configuration Wi-Fi templates
    $legacy = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations?`$filter=isof('microsoft.graph.windowsWifiConfiguration') or isof('microsoft.graph.iosWiFiConfiguration') or isof('microsoft.graph.androidWorkProfileWiFiConfiguration')").value 2>$null
    $total = $wifi.Count + @($legacy).Count
    Write-Host ("  [OK] Wi-Fi-related configuration profiles visible: {0}" -f $total) -ForegroundColor Green
    if ($total -eq 0) {
        Write-Host "       No Wi-Fi profiles found — check you signed in to the correct tenant/environment." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [WARN] Could not enumerate profiles: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n  Preflight complete. If all lines are [OK], run WIFIDX-Get-WifiProfiles.ps1 next." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null

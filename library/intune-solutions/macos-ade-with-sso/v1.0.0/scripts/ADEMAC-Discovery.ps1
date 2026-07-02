<#
.SYNOPSIS
    ADEMAC-Discovery.ps1 — tenant readiness check for macOS ADE + Platform SSO.

.DESCRIPTION
    PURPOSE
        Confirms the Intune tenant is ready to auto-enroll Macs and register Platform SSO:
        Apple MDM Push (APNs) certificate, Automated Device Enrollment (ADE) token,
        macOS enrollment profile(s), Company Portal assignment, and a Platform SSO
        (SSO app extension) configuration profile. Flags anything expiring within 30 days.

    HOW TO RUN
        Install the SDK once:  Install-Module Microsoft.Graph -Scope CurrentUser
        Then:                  .\ADEMAC-Discovery.ps1
        Reads only — makes no changes.

    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall verdict. A READY tenant shows an Active
        APNs cert and ADE token (both >30 days from expiry), at least one macOS enrollment
        profile, Company Portal assigned, and a Platform SSO profile present.

.NOTES
    White-label — Intune Solutions. Read-only. Uses Microsoft Graph beta
    for DEP/enrollment-profile resources.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.Read.All','DeviceManagementConfiguration.Read.All','DeviceManagementApps.Read.All' | Out-Null

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}
function DaysLeft($iso) { if (-not $iso) { return $null }; [int]([datetime]$iso - (Get-Date)).TotalDays }

$results = New-Object System.Collections.Generic.List[object]

# 1) APNs certificate
try {
    $apns = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/applePushNotificationCertificate'
    $d = DaysLeft $apns.expirationDateTime
    $results.Add( (R 'APNs certificate present & valid >30d' ($d -ne $null -and $d -gt 30) "AppleID=$($apns.appleIdentifier); expires in $d day(s)") )
} catch { $results.Add( (R 'APNs certificate present & valid >30d' $false 'Not configured — create it (Requirements R2).') ) }

# 2) ADE / enrollment program token(s)
try {
    $dep = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/deviceManagement/depOnboardingSettings'
    $tokens = @($dep.value)
    if ($tokens.Count -gt 0) {
        $minDays = ($tokens | ForEach-Object { DaysLeft $_.tokenExpirationDateTime } | Measure-Object -Minimum).Minimum
        $results.Add( (R 'ADE token present & valid >30d' ($minDays -gt 30) "$($tokens.Count) token(s); soonest expiry in $minDays day(s)") )
    } else {
        $results.Add( (R 'ADE token present & valid >30d' $false 'No ADE/ABM token — connect ABM (Requirements R3).') )
    }
} catch { $results.Add( (R 'ADE token present & valid >30d' $false "Could not read DEP settings: $($_.Exception.Message)") ); $tokens = @() }

# 3) macOS enrollment profile(s)
$macProfiles = 0
foreach ($t in $tokens) {
    try {
        $p = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/depOnboardingSettings/$($t.id)/enrollmentProfiles"
        $macProfiles += @($p.value | Where-Object { "$($_.'@odata.type')" -match 'depMacOS' -or $_.platform -eq 'macOS' }).Count
    } catch {}
}
$results.Add( (R 'macOS enrollment profile exists' ($macProfiles -gt 0) "$macProfiles macOS profile(s) found") )

# 4) Company Portal app for macOS
try {
    $apps = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.macOSOfficeSuiteApp') or contains(displayName,'Company Portal')"
    $cp = @($apps.value | Where-Object { $_.displayName -match 'Company Portal' })
    $results.Add( (R 'Company Portal (macOS) added' ($cp.Count -gt 0) "$($cp.Count) match(es)") )
} catch { $results.Add( (R 'Company Portal (macOS) added' $false $_.Exception.Message) ) }

# 5) Platform SSO / SSO app-extension profile
$ssoFound = $false; $ssoDetail = 'none'
try {
    $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'macOS'"
    foreach ($pol in $cfg.value) {
        $settings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($pol.id)/settings"
        if (("$($settings | ConvertTo-Json -Depth 20)") -match 'extensiblesinglesignon|ssoextension|platformsso') { $ssoFound = $true; $ssoDetail = $pol.name; break }
    }
} catch { $ssoDetail = $_.Exception.Message }
$results.Add( (R 'Platform SSO profile present' $ssoFound "Profile: $ssoDetail") )

$results | Format-Table -AutoSize
$fail = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: READY — tenant is prepared for macOS ADE + Platform SSO.' -ForegroundColor Green }
else { Write-Host "OVERALL: NOT READY — $fail check(s) failed. Resolve before enrolling devices." -ForegroundColor Yellow }

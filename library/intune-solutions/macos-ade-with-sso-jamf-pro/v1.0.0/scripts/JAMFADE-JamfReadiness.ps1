<#
.SYNOPSIS
    JAMFADE-JamfReadiness.ps1 — Jamf Pro (MDM-side) readiness for macOS ADE + Platform SSO.

.DESCRIPTION
    PURPOSE
        Confirms the Jamf Pro side is ready to auto-enroll Macs and deploy Platform SSO:
          - an Automated Device Enrollment (ADE) instance with a token >30 days from expiry,
          - at least one macOS PreStage Enrollment,
          - a configuration profile containing the Single Sign-On Extensions (Platform SSO) payload.
        This is the Jamf counterpart to JAMFADE-Discovery.ps1 (which checks the Intune/Entra side).
        Jamf — not Intune — holds the APNs and ADE tokens, so they are validated here.

    HOW TO RUN
        # Use a Jamf Pro account (or API client) with read access to enrollment + config profiles.
        $cred = Get-Credential                       # Jamf username / password (or API client id/secret)
        .\JAMFADE-JamfReadiness.ps1 -JamfUrl https://yourorg.jamfcloud.com -Credential $cred
        # Or pass an existing bearer token:
        .\JAMFADE-JamfReadiness.ps1 -JamfUrl https://yourorg.jamfcloud.com -BearerToken <token>
        Reads only — makes no changes.

    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall verdict. READY shows an ADE instance/token >30 days,
        a macOS PreStage, and a Platform SSO configuration profile present. APNs expiry is surfaced as
        an advisory (verify in Jamf → Settings → Global → Push certificates).

.NOTES
    White-label — Intune Solutions. Read-only. Uses the Jamf Pro API (bearer
    token) and the Classic API (osxconfigurationprofiles) for the SSO-profile check.
#>
[CmdletBinding(DefaultParameterSetName='Cred')]
param(
    [Parameter(Mandatory)] [string]$JamfUrl,
    [Parameter(Mandatory, ParameterSetName='Cred')] [pscredential]$Credential,
    [Parameter(Mandatory, ParameterSetName='Token')] [string]$BearerToken
)

$ErrorActionPreference = 'Stop'
$JamfUrl = $JamfUrl.TrimEnd('/')

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}
function DaysLeft($iso) { if (-not $iso) { return $null }; try { [int]([datetime]$iso - (Get-Date)).TotalDays } catch { $null } }

# --- obtain a bearer token ---
if ($PSCmdlet.ParameterSetName -eq 'Cred') {
    $pair  = "$($Credential.UserName):$($Credential.GetNetworkCredential().Password)"
    $basic = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($pair))
    $tok   = Invoke-RestMethod -Method POST -Uri "$JamfUrl/api/v1/auth/token" -Headers @{ Authorization = "Basic $basic" }
    $BearerToken = $tok.token
}
$H = @{ Authorization = "Bearer $BearerToken"; Accept = 'application/json' }

$results = New-Object System.Collections.Generic.List[object]

# 1) Automated Device Enrollment instance + token expiry
try {
    $de = Invoke-RestMethod -Method GET -Uri "$JamfUrl/api/v1/device-enrollments?page=0&page-size=100" -Headers $H
    $instances = @($de.results)
    if ($instances.Count -gt 0) {
        $minDays = ($instances | ForEach-Object { DaysLeft $_.tokenExpirationDate } | Where-Object { $_ -ne $null } | Measure-Object -Minimum).Minimum
        $results.Add( (R 'ADE instance present & token >30d' ($minDays -ne $null -and $minDays -gt 30) "$($instances.Count) instance(s); soonest token expiry in $minDays day(s)") )
    } else {
        $results.Add( (R 'ADE instance present & token >30d' $false 'No Automated Device Enrollment instance — connect ABM to Jamf (Requirements R4).') )
    }
} catch { $results.Add( (R 'ADE instance present & token >30d' $false "Could not read device-enrollments: $($_.Exception.Message)") ) }

# 2) macOS PreStage Enrollment
try {
    $ps = Invoke-RestMethod -Method GET -Uri "$JamfUrl/api/v2/computer-prestages?page=0&page-size=100" -Headers $H
    $count = @($ps.results).Count
    $results.Add( (R 'macOS PreStage Enrollment exists' ($count -gt 0) "$count computer PreStage(s)") )
} catch { $results.Add( (R 'macOS PreStage Enrollment exists' $false "Could not read computer-prestages: $($_.Exception.Message)") ) }

# 3) Platform SSO (Single Sign-On Extensions) config profile — Classic API
$ssoFound = $false; $ssoDetail = 'none'
try {
    $list = Invoke-RestMethod -Method GET -Uri "$JamfUrl/JSSResource/osxconfigurationprofiles" -Headers $H
    foreach ($p in $list.os_x_configuration_profiles.os_x_configuration_profile) {
        try {
            $detail = Invoke-RestMethod -Method GET -Uri "$JamfUrl/JSSResource/osxconfigurationprofiles/id/$($p.id)" -Headers $H
            $payloads = "$($detail.os_x_configuration_profile.general.payloads)"
            if ($payloads -match 'extensiblesso|ExtensibleSingleSignOn|CompanyPortalMac.ssoextension|PlatformSSO') { $ssoFound = $true; $ssoDetail = $p.name; break }
        } catch {}
    }
} catch { $ssoDetail = $_.Exception.Message }
$results.Add( (R 'Platform SSO configuration profile present' $ssoFound "Profile: $ssoDetail") )

$results | Format-Table -AutoSize
$fail = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: READY — Jamf is prepared for macOS ADE + Platform SSO.' -ForegroundColor Green }
else { Write-Host "OVERALL: NOT READY — $fail check(s) failed. Resolve before enrolling devices." -ForegroundColor Yellow }
Write-Host 'Advisory: verify the Jamf APNs (MDM Push) certificate expiry in Settings -> Global -> Push certificates (renew annually, same Apple ID).' -ForegroundColor Cyan
Write-Host 'Reminder: also run JAMFADE-Discovery.ps1 to validate the Intune/Entra side.' -ForegroundColor Cyan

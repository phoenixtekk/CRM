<#
.SYNOPSIS
    IOSSSOEXT-Validation.ps1 — validate assignment and per-device applied state of the iOS SSO app extension.
.DESCRIPTION
    PURPOSE
        Validates the iOS/iPadOS Enterprise SSO app-extension profile is assigned to the intended
        group and applied on target devices. Confirms the profile exists (Microsoft Entra ID /
        Redirect SSO extension), that it is assigned, and reports each iOS device's applied state
        (Succeeded / Error / Not applied). Read-only. Validates the app/browser SSO extension only,
        not shared-device identity or enrollment.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IOSSSOEXT-Validation.ps1 -ProfileName "iOS SSO App Extension - Pilot"
        Optional: -GroupId your-entra-group-object-id  (assert the profile is assigned to this group)
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.Read.All
    EXPECTED RESULTS
        A PASS/FAIL summary: profile found, assigned (to -GroupId if supplied), and a per-device
        applied-state table. PASS when the profile is assigned and pilot devices report Succeeded.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$ProfileName = 'iOS SSO App Extension - Pilot',
    [string]$GroupId
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' | Out-Null

$ExtensionId = 'com.microsoft.azureauthenticator.ssoextension'

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}
$results = New-Object System.Collections.Generic.List[object]

# Locate the profile (Device features template first, then settings catalog)
$profile = $null; $kind = 'none'
try {
    $tpl = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?`$filter=isof('microsoft.graph.iosDeviceFeaturesConfiguration')"
    foreach ($p in @($tpl.value)) { if ($p.displayName -eq $ProfileName) { $profile = $p; $kind = 'template'; break } }
    if (-not $profile) {
        foreach ($p in @($tpl.value)) {
            if (("$($p | ConvertTo-Json -Depth 30)") -match 'singleSignOnExtension') { $profile = $p; $kind = 'template'; break }
        }
    }
    if (-not $profile) {
        $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'iOS'"
        foreach ($pol in @($cfg.value)) {
            if ($pol.name -eq $ProfileName) { $profile = $pol; $kind = 'catalog'; break }
            $settings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($pol.id)/settings"
            if (("$($settings | ConvertTo-Json -Depth 25)") -match [regex]::Escape($ExtensionId)) { $profile = $pol; $kind = 'catalog'; break }
        }
    }
} catch {}
$pName = if ($profile) { if ($kind -eq 'template') { $profile.displayName } else { $profile.name } } else { $null }
$results.Add( (R 'iOS SSO app-extension profile found' ($null -ne $profile) $(if ($profile) { "'$pName' ($kind, id $($profile.id))" } else { "Not found: $ProfileName" })) )

if (-not $profile) { $results | Format-Table -AutoSize; Write-Host 'OVERALL: FAIL — profile not found.' -ForegroundColor Yellow; return }

# Assignment + per-device applied state (endpoint differs by profile kind)
$base = if ($kind -eq 'template') { "deviceConfigurations/$($profile.id)" } else { "configurationPolicies/$($profile.id)" }

$groups = @(); $assigned = $false; $toGroup = $false
try {
    $asg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/$base/assignments"
    $groups = @($asg.value | ForEach-Object { $_.target.groupId } | Where-Object { $_ })
    $assigned = @($asg.value).Count -gt 0
    if ($GroupId) { $toGroup = $groups -contains $GroupId }
} catch {}
$results.Add( (R 'Profile is assigned' $assigned "$(@($groups).Count) group assignment(s)") )
if ($GroupId) { $results.Add( (R 'Assigned to the specified group' $toGroup "GroupId=$GroupId") ) }

$deviceRows = @()
try {
    $stat = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/$base/deviceStatuses"
    $deviceRows = @($stat.value | ForEach-Object {
        [pscustomobject]@{ Device = $_.deviceDisplayName; User = $_.userPrincipalName; State = $_.status }
    })
} catch {}
$succeeded = @($deviceRows | Where-Object { $_.State -match 'success|compliant' }).Count
$results.Add( (R 'At least one device reports applied' ($succeeded -gt 0) "$succeeded device(s) Succeeded of $(@($deviceRows).Count)") )

$results | Format-Table -AutoSize
if ($deviceRows.Count) { Write-Host ''; Write-Host 'Per-device applied state:' -ForegroundColor Cyan; $deviceRows | Format-Table -AutoSize }

$fail = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: PASS — iOS SSO app extension is assigned and applying.' -ForegroundColor Green }
else { Write-Host "OVERALL: NEEDS ATTENTION — $fail check(s) failed." -ForegroundColor Yellow }

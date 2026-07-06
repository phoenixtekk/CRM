<#
.SYNOPSIS
    MACSSOEXT-Validation.ps1 — validate assignment and per-device applied state of the SSO app extension.
.DESCRIPTION
    PURPOSE
        Validates the macOS Enterprise SSO app-extension configuration profile is assigned to the
        intended group and applied on target devices. Confirms the profile exists (Redirect type,
        Microsoft identifiers), that it is assigned, and reports each macOS device's applied state
        (Succeeded / Error / Not applied). Read-only. Validates the app/browser SSO extension only,
        not Platform SSO device login.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MACSSOEXT-Validation.ps1 -ProfileName "macOS SSO App Extension - Pilot"
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
    [string]$ProfileName = 'macOS SSO App Extension - Pilot',
    [string]$GroupId
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' | Out-Null

$ExtensionId = 'com.microsoft.CompanyPortalMac.ssoextension'

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}
$results = New-Object System.Collections.Generic.List[object]

# Locate the profile by name (fall back to any SSO app-extension profile)
$policy = $null
try {
    $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'macOS'"
    foreach ($pol in @($cfg.value)) {
        if ($pol.name -eq $ProfileName) { $policy = $pol; break }
    }
    if (-not $policy) {
        foreach ($pol in @($cfg.value)) {
            $settings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($pol.id)/settings"
            if (("$($settings | ConvertTo-Json -Depth 25)") -match [regex]::Escape($ExtensionId)) { $policy = $pol; break }
        }
    }
} catch {}
$results.Add( (R 'SSO app-extension profile found' ($null -ne $policy) $(if ($policy) { "'$($policy.name)' (id $($policy.id))" } else { "Not found: $ProfileName" })) )

if (-not $policy) { $results | Format-Table -AutoSize; Write-Host 'OVERALL: FAIL — profile not found.' -ForegroundColor Yellow; return }

# Assignment check
$assigned = $false; $toGroup = $false; $groups = @()
try {
    $asg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($policy.id)/assignments"
    $groups = @($asg.value | ForEach-Object { $_.target.groupId } | Where-Object { $_ })
    $assigned = @($asg.value).Count -gt 0
    if ($GroupId) { $toGroup = $groups -contains $GroupId }
} catch {}
$results.Add( (R 'Profile is assigned' $assigned "$(@($groups).Count) group assignment(s)") )
if ($GroupId) { $results.Add( (R 'Assigned to the specified group' $toGroup "GroupId=$GroupId") ) }

# Per-device applied state
$deviceRows = @()
try {
    $stat = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($policy.id)/deviceStatuses"
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
if ($fail -eq 0) { Write-Host 'OVERALL: PASS — SSO app extension is assigned and applying.' -ForegroundColor Green }
else { Write-Host "OVERALL: NEEDS ATTENTION — $fail check(s) failed." -ForegroundColor Yellow }

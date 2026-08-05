<#
.SYNOPSIS
    WINSECOPT-Validation.ps1 — validate assignment and per-device applied state of the Windows hardening profile.
.DESCRIPTION
    PURPOSE
        Validates the Windows interactive-logon & network-access Settings Catalog profile is assigned to
        the intended group and applied on target devices. Confirms the profile exists, that it is
        assigned (optionally to a specified -GroupId), and reports each Windows device's applied state
        (Succeeded / Error / Not applied). Read-only. Validates THIS gap-only pack only — not NTLM/SMB,
        RDP, credential-theft, or full-baseline hardening.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WINSECOPT-Validation.ps1 -ProfileName "Interactive Logon & Network-Access Hardening - Pilot"
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
    [string]$ProfileName = 'Interactive Logon & Network-Access Hardening - Pilot',
    [string]$GroupId
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' | Out-Null

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}
$results = New-Object System.Collections.Generic.List[object]

# Locate the Settings Catalog profile (by name first, then by carried settings)
$profile = $null
try {
    $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'windows10'"
    foreach ($pol in @($cfg.value)) { if ($pol.name -eq $ProfileName) { $profile = $pol; break } }
    if (-not $profile) {
        foreach ($pol in @($cfg.value)) {
            $settings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($pol.id)/settings"
            $json = ("$($settings | ConvertTo-Json -Depth 30)").ToLower()
            if ($json -match 'dontdisplaynetworkselectionui' -and $json -match 'smartcardremovalbehavior') { $profile = $pol; break }
        }
    }
} catch {}
$results.Add( (R 'Hardening profile found' ($null -ne $profile) $(if ($profile) { "'$($profile.name)' (id $($profile.id))" } else { "Not found: $ProfileName" })) )

if (-not $profile) { $results | Format-Table -AutoSize; Write-Host 'OVERALL: FAIL — profile not found.' -ForegroundColor Yellow; return }

# Assignment
$groups = @(); $assigned = $false; $toGroup = $false
try {
    $asg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($profile.id)/assignments"
    $groups = @($asg.value | ForEach-Object { $_.target.groupId } | Where-Object { $_ })
    $assigned = @($asg.value).Count -gt 0
    if ($GroupId) { $toGroup = $groups -contains $GroupId }
} catch {}
$results.Add( (R 'Profile is assigned' $assigned "$(@($groups).Count) group assignment(s)") )
if ($GroupId) { $results.Add( (R 'Assigned to the specified group' $toGroup "GroupId=$GroupId") ) }

# Per-device applied state
$deviceRows = @()
try {
    $stat = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($profile.id)/deviceStatuses"
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
if ($fail -eq 0) { Write-Host 'OVERALL: PASS — the hardening profile is assigned and applying.' -ForegroundColor Green }
else { Write-Host "OVERALL: NEEDS ATTENTION — $fail check(s) failed." -ForegroundColor Yellow }

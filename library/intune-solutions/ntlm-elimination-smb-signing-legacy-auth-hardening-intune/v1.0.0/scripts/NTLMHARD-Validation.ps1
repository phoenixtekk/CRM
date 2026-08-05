<#
.SYNOPSIS
    NTLMHARD-Validation.ps1 — validate assignment and per-device applied state of the NTLM/SMB hardening policy.
.DESCRIPTION
    PURPOSE
        Validates the Windows NTLM/SMB legacy-auth hardening Settings Catalog policy is assigned to the
        intended group and applied on target devices. Confirms the policy exists, that it is assigned, and
        reports each Windows device's applied state (Succeeded / Error / Conflict / Not applied).
        Read-only. Validates the endpoint hardening policy only, not domain-controller NTLM policy or a
        full CIS/STIG baseline.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\NTLMHARD-Validation.ps1 -ProfileName "NTLM-SMB Hardening - Pilot"
        Optional: -GroupId your-entra-group-object-id  (assert the policy is assigned to this group)
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.Read.All
    EXPECTED RESULTS
        A PASS/FAIL summary: policy found, assigned (to -GroupId if supplied), and a per-device
        applied-state table. PASS when the policy is assigned and pilot devices report Succeeded with no
        Conflict.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$ProfileName = 'NTLM-SMB Hardening - Pilot',
    [string]$GroupId
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' | Out-Null

$anchors = @('lmcompatibilitylevel','requiresecuritysignature','allowinsecureguestauth','restrictremoteclients')

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}
$results = New-Object System.Collections.Generic.List[object]

# Locate the Settings Catalog policy (by name, then by settings content)
$policy = $null
try {
    $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'windows10'"
    foreach ($p in @($cfg.value)) { if ($p.name -eq $ProfileName) { $policy = $p; break } }
    if (-not $policy) {
        foreach ($p in @($cfg.value)) {
            $settings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($p.id)/settings"
            $json = ("$($settings | ConvertTo-Json -Depth 30)").ToLower()
            if (($anchors | Where-Object { $json -match [regex]::Escape($_) }).Count -ge 2) { $policy = $p; break }
        }
    }
} catch {}
$results.Add( (R 'NTLM/SMB hardening policy found' ($null -ne $policy) $(if ($policy) { "'$($policy.name)' (id $($policy.id))" } else { "Not found: $ProfileName" })) )

if (-not $policy) { $results | Format-Table -AutoSize; Write-Host 'OVERALL: FAIL — policy not found.' -ForegroundColor Yellow; return }

# Assignment
$groups = @(); $assigned = $false; $toGroup = $false
try {
    $asg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($policy.id)/assignments"
    $groups = @($asg.value | ForEach-Object { $_.target.groupId } | Where-Object { $_ })
    $assigned = @($asg.value).Count -gt 0
    if ($GroupId) { $toGroup = $groups -contains $GroupId }
} catch {}
$results.Add( (R 'Policy is assigned' $assigned "$(@($groups).Count) group assignment(s)") )
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
$conflict  = @($deviceRows | Where-Object { $_.State -match 'conflict' }).Count
$results.Add( (R 'At least one device reports applied' ($succeeded -gt 0) "$succeeded device(s) Succeeded of $(@($deviceRows).Count)") )
$results.Add( (R 'No conflict reported (single owning policy)' ($conflict -eq 0) "$conflict device(s) in Conflict") )

$results | Format-Table -AutoSize
if ($deviceRows.Count) { Write-Host ''; Write-Host 'Per-device applied state:' -ForegroundColor Cyan; $deviceRows | Format-Table -AutoSize }

$fail = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: PASS — NTLM/SMB hardening policy is assigned and applying without conflict.' -ForegroundColor Green }
else { Write-Host "OVERALL: NEEDS ATTENTION — $fail check(s) failed." -ForegroundColor Yellow }

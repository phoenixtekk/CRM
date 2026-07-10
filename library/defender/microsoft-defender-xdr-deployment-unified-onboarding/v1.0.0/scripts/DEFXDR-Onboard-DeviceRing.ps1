<#
.SYNOPSIS
    DEFXDR-Onboard-DeviceRing.ps1 — assign the Intune EDR onboarding profile to the pilot device
    ring. SAFE PREVIEW by default (-WhatIf); makes changes only when explicitly confirmed.
.DESCRIPTION
    PURPOSE
        Change helper for the "Microsoft Defender XDR Deployment & Unified Onboarding" solution.
        Assigns the Intune endpoint-detection-and-response (EDR) onboarding policy
        'MDE Onboarding - Pilot Ring - Pilot' to the pilot device group of the same name, so the
        pilot ring onboards to Defender for Endpoint. This is the only script that can change
        configuration, and it defaults to a safe preview.
    HOW TO RUN
        # Preview (default — shows what WOULD change, changes nothing):
        powershell -ExecutionPolicy Bypass -File .\DEFXDR-Onboard-DeviceRing.ps1 `
            -PolicyName 'MDE Onboarding - Pilot Ring - Pilot' -GroupName 'MDE Onboarding - Pilot Ring - Pilot'
        # Apply (explicit — required to make the change):
        powershell -ExecutionPolicy Bypass -File .\DEFXDR-Onboard-DeviceRing.ps1 `
            -PolicyName 'MDE Onboarding - Pilot Ring - Pilot' -GroupName 'MDE Onboarding - Pilot Ring - Pilot' -Apply
        Requires Microsoft.Graph with DeviceManagementConfiguration.ReadWrite.All and Group.Read.All.
    EXPECTED RESULTS
        Preview: prints the resolved policy id and group id and the assignment it WOULD create.
        Apply: creates the assignment and confirms; onboard a few devices first, validate, then expand.
.NOTES
    White-label. DEFAULTS TO -WhatIf/preview. Pilot-first: assign to the pilot ring only.
    Automated response stays approval-gated regardless of this script.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$PolicyName,
    [Parameter(Mandatory)] [string]$GroupName,
    [switch]$Apply
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes 'DeviceManagementConfiguration.ReadWrite.All','Group.Read.All' -NoWelcome | Out-Null
}

$whatIf = -not $Apply
Write-Host "`n=== DEFXDR onboard pilot device ring ===" -ForegroundColor Cyan
Write-Host ("Mode: {0}" -f ($(if ($whatIf) { 'PREVIEW (-WhatIf) — no changes' } else { 'APPLY — will create assignment' }))) -ForegroundColor $(if ($whatIf) { 'Yellow' } else { 'Red' })

# Resolve the group.
$grp = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $GroupName)).value | Select-Object -First 1
if (-not $grp) { Write-Host ("Group '{0}' not found. Create it first (Implementation Step 1)." -f $GroupName) -ForegroundColor Red; return }
Write-Host ("Group : {0}  ({1})" -f $grp.displayName, $grp.id)

# Resolve the EDR policy (configuration policy / intent by name).
$pol = $null
try {
    $pol = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=name eq '{0}'" -f $PolicyName)).value | Select-Object -First 1
} catch { }
if (-not $pol) {
    Write-Host ("EDR policy '{0}' not found via configurationPolicies. Confirm the policy name/type in Intune" -f $PolicyName) -ForegroundColor Yellow
    Write-Host "(Endpoint security -> Endpoint detection and response). Create it per Implementation Step 2." -ForegroundColor Yellow
    return
}
Write-Host ("Policy: {0}  ({1})" -f $pol.name, $pol.id)

if ($whatIf) {
    Write-Host "`nWOULD assign the policy to the pilot group above (include assignment)." -ForegroundColor Yellow
    Write-Host "Re-run with -Apply to create the assignment." -ForegroundColor Yellow
    return
}

# Apply: create the include assignment to the pilot group.
$assignBody = @{
    assignments = @(
        @{ target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $grp.id } }
    )
} | ConvertTo-Json -Depth 6

try {
    Invoke-MgGraphRequest -Method POST -Uri ("https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/{0}/assign" -f $pol.id) -Body $assignBody -ContentType 'application/json' | Out-Null
    Write-Host "`nAPPLIED — policy assigned to the pilot ring. Validate with DEFXDR-Validate.ps1 -Pillar Endpoint." -ForegroundColor Green
} catch {
    Write-Host ("Assignment failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
}

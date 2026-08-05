<#
.SYNOPSIS
    RDPHARD-Remediation.ps1 — safely fix a missing or mis-scoped Windows RDP hardening profile.
.DESCRIPTION
    PURPOSE
        Remediates the common gaps that leave endpoint RDP hardening undeployed on managed Windows
        devices: if the RDP hardening Settings Catalog profile exists but is not assigned to the intended
        group, it (re)assigns it; if no RDP hardening profile exists at all, it reports exactly what the
        guide's profile must contain and does NOT invent one. Defaults to -WhatIf, so it previews every
        change and modifies nothing until re-run with -WhatIf:$false. Remediates the endpoint RDP
        hardening profile's ASSIGNMENT only — it does not author the RDP setting values (those are built
        in Intune per Implementation Phase 2, because the exact Settings Catalog / ADMX setting
        identifiers are tenant-verifiable) and it never touches network controls or the credential-theft
        program.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\RDPHARD-Remediation.ps1 -GroupId your-entra-group-object-id
        Apply the change:
          powershell -ExecutionPolicy Bypass -File .\RDPHARD-Remediation.ps1 -GroupId your-entra-group-object-id -WhatIf:$false
        Optional: -ProfileName "RDP Hardening - Pilot"
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.ReadWrite.All
    EXPECTED RESULTS
        In preview: a report of what is missing and exactly what WOULD be assigned (or the settings the
        guide's profile must carry, if the profile is absent).
        When applied: the RDP hardening profile is assigned to the target group. Re-run
        RDPHARD-Discovery.ps1 / RDPHARD-Validation.ps1 to confirm.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf; changes require -WhatIf:$false.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$GroupId,
    [string]$ProfileName = 'RDP Hardening - Pilot'
)

# Default to preview: if the caller did not pass -WhatIf, turn it on.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.ReadWrite.All' | Out-Null

# The RDP settings the guide's profile must carry (registry anchors — stable across label revisions).
$RequiredSettings = @(
    'Set client connection encryption level = High (MinEncryptionLevel=3)',
    'Always prompt for password upon connection (fPromptForPassword=1)',
    'Do not allow drive redirection (fDisableCdm=1)',
    'Do not allow passwords to be saved (DisablePasswordSaving=1)',
    'Configure Solicited Remote Assistance = Disabled (fAllowToGetHelp=0); Offer Remote Assistance = Disabled (fAllowUnsolicited=0)',
    'Require NLA (UserAuthentication=1)'
)

# Locate the profile (by name, else by RDP setting content)
$profile = $null
try {
    $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'windows10'"
    foreach ($pol in @($cfg.value)) { if ($pol.name -eq $ProfileName) { $profile = $pol; break } }
    if (-not $profile) {
        foreach ($pol in @($cfg.value)) {
            $s = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($pol.id)/settings"
            if (("$($s | ConvertTo-Json -Depth 30)").ToLower() -match 'minencryptionlevel|fpromptforpassword') { $profile = $pol; break }
        }
    }
} catch {}

if (-not $profile) {
    Write-Host "No Windows RDP hardening profile found (looked for '$ProfileName')." -ForegroundColor Yellow
    Write-Host "This script does not invent the RDP settings payload — build the profile in Intune per Implementation Phase 2." -ForegroundColor Yellow
    Write-Host "The profile must be a Windows 10 and later Settings Catalog profile named '$ProfileName' carrying:" -ForegroundColor Cyan
    $RequiredSettings | ForEach-Object { Write-Host "   - $_" -ForegroundColor Cyan }
    Write-Host "Then re-run this script to assign it to group $GroupId." -ForegroundColor Yellow
    return
}

Write-Host "RDP hardening profile present: '$($profile.name)' (id $($profile.id))." -ForegroundColor Green

# Determine current assignment
$assignedGroupIds = @()
try {
    $asg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($profile.id)/assignments"
    $assignedGroupIds = @($asg.value | ForEach-Object { $_.target.groupId } | Where-Object { $_ })
} catch {}

if ($assignedGroupIds -contains $GroupId) {
    Write-Host "Already assigned to group $GroupId — nothing to remediate." -ForegroundColor Green
    return
}

# Preserve existing assignments and add the target group.
$desiredGroupIds = @($assignedGroupIds + $GroupId | Select-Object -Unique)
$body = @{ assignments = @($desiredGroupIds | ForEach-Object {
    @{ target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $_ } }
}) }

if ($PSCmdlet.ShouldProcess($profile.name, "Set assignments to group(s): $($desiredGroupIds -join ', ')")) {
    Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($profile.id)/assign" -Body ($body | ConvertTo-Json -Depth 6) -ContentType 'application/json' | Out-Null
    Write-Host "Assigned '$($profile.name)' -> $($desiredGroupIds -join ', ')." -ForegroundColor Green
} else {
    Write-Host "WhatIf: would set '$($profile.name)' assignments -> $($desiredGroupIds -join ', ')." -ForegroundColor Yellow
}

Write-Host ''
if ($WhatIfPreference) { Write-Host 'Preview only (-WhatIf). Re-run with -WhatIf:$false to apply.' -ForegroundColor Yellow }
else { Write-Host 'Remediation complete. Re-run RDPHARD-Validation.ps1 to confirm.' -ForegroundColor Green }

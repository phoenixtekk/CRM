<#
.SYNOPSIS
    DCPG-Remediation.ps1 — safely correct common GCC High compliance-policy scoping drift (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Previews and (only with -Commit) applies safe corrective actions to the Device
        Compliance Policies (GCC High) deployment. The primary fix is re-scoping the
        baseline policy that has drifted to an All-devices/All-users assignment back to the
        intended pilot group, so Conditional Access can never enforce on an unintended
        population. Connects to US Gov Graph. DEFAULTS TO -WhatIf — nothing changes unless
        you pass -Commit.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DCPG-Remediation.ps1
        (previews only; add -Commit to apply)
        (Graph scopes: DeviceManagementConfiguration.ReadWrite.All, Group.Read.All; -Environment USGov)
    EXPECTED RESULTS
        In preview (default): a list of the changes that WOULD be made, each prefixed
        [WHATIF]. With -Commit: each change is applied and reported [APPLIED]. If no drift
        is found, the script reports the policy is already correctly scoped.
.NOTES
    White-label — the repeatable way. Read-only planning by default; changes only with -Commit,
    against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [ValidateSet('USGov', 'USGovDoD')]
    [string]$Environment = 'USGov',

    [string]$PolicyName = 'CP-Win-Baseline-GovHigh',
    [string]$PilotGroupName = 'SG-Compliance-Pilot',

    # Safety: default is preview-only. Pass -Commit to actually apply.
    [switch]$Commit
)

$ErrorActionPreference = 'Stop'
$WhatIfMode = -not $Commit

function Write-Plan {
    param([string]$Message)
    $tag = if ($WhatIfMode) { '[WHATIF]' } else { '[APPLIED]' }
    $color = if ($WhatIfMode) { 'Yellow' } else { 'Green' }
    Write-Host "$tag $Message" -ForegroundColor $color
}

try {
    $scopes = @('DeviceManagementConfiguration.ReadWrite.All', 'Group.Read.All')
    Write-Host "Connecting to Microsoft Graph (Environment: $Environment)..." -ForegroundColor Cyan
    Connect-MgGraph -Environment $Environment -Scopes $scopes | Out-Null
    $ctx = Get-MgContext
    if ($ctx.Environment -ne $Environment) {
        throw "Connected to '$($ctx.Environment)', expected '$Environment'. Reconnect with -Environment $Environment."
    }
    Write-Host "Connected. Environment: $($ctx.Environment)" -ForegroundColor Green
    if ($WhatIfMode) {
        Write-Host "MODE: PREVIEW (-WhatIf). No changes will be made. Re-run with -Commit to apply.`n" -ForegroundColor Yellow
    } else {
        Write-Host "MODE: COMMIT. Changes WILL be applied.`n" -ForegroundColor Red
    }

    # Resolve the pilot group.
    $pilot = Get-MgGroup -Filter "displayName eq '$PilotGroupName'" -Property 'id,displayName' -ErrorAction SilentlyContinue
    if (-not $pilot) { throw "Pilot group '$PilotGroupName' not found. Create it (or run DCPG-Set-ScopeTargeting.ps1) first." }

    # Resolve the policy.
    $policies = Get-MgDeviceManagementDeviceCompliancePolicy -All -ExpandProperty 'assignments' -ErrorAction Stop
    $policy = $policies | Where-Object { $_.DisplayName -eq $PolicyName } | Select-Object -First 1
    if (-not $policy) { throw "Compliance policy '$PolicyName' not found in this ($Environment) tenant." }

    # Inspect current assignments for fleet-wide drift.
    $isFleetWide = $false
    foreach ($a in $policy.Assignments) {
        $t = $a.Target.AdditionalProperties.'@odata.type'
        if ($t -in @('#microsoft.graph.allDevicesAssignmentTarget', '#microsoft.graph.allLicensedUsersAssignmentTarget')) {
            $isFleetWide = $true
        }
    }

    if (-not $isFleetWide) {
        Write-Host "No scoping drift found: '$PolicyName' is not assigned to All devices/All users. Nothing to remediate." -ForegroundColor Green
        return
    }

    Write-Plan "Re-scope '$PolicyName' from All-devices/All-users to pilot group '$PilotGroupName' ($($pilot.Id))."

    if (-not $WhatIfMode) {
        # Build a single pilot-group assignment and replace the existing assignments.
        $assignParams = @{
            Assignments = @(
                @{
                    target = @{
                        '@odata.type' = '#microsoft.graph.groupAssignmentTarget'
                        groupId       = $pilot.Id
                    }
                }
            )
        }
        Set-MgDeviceManagementDeviceCompliancePolicyAssignment -DeviceCompliancePolicyId $policy.Id -BodyParameter $assignParams -ErrorAction Stop
        Write-Host "Re-scope applied. Verify with DCPG-Validation.ps1." -ForegroundColor Green
    } else {
        Write-Host "`nPreview complete. Re-run with -Commit to apply the re-scope." -ForegroundColor Yellow
    }
}
finally {
    if (Get-MgContext) { Disconnect-MgGraph | Out-Null; Write-Host "`nDisconnected from Microsoft Graph." -ForegroundColor DarkGray }
}

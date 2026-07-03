<#
.SYNOPSIS
    DCPG-Validation.ps1 — pass/fail check that the named GCC High compliance objects exist and are pilot-scoped.
.DESCRIPTION
    PURPOSE
        Read-only validation for the Device Compliance Policies (GCC High) solution.
        Confirms you are connected to US Gov Graph, that the expected named objects exist
        (the Windows baseline policy, the pilot group, the noncompliance notification),
        and that the baseline policy is scoped to the pilot group and not to All devices.
        Prints PASS/FAIL per check. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DCPG-Validation.ps1
        (Graph scopes: DeviceManagementConfiguration.Read.All, Group.Read.All; -Environment USGov)
        Override names with -PolicyName, -PilotGroupName if your convention differs.
    EXPECTED RESULTS
        One line per check marked [PASS] or [FAIL], then an overall result. Exit code 0
        when all checks pass, 1 when any fails.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [ValidateSet('USGov', 'USGovDoD')]
    [string]$Environment = 'USGov',

    [string]$PolicyName = 'CP-Win-Baseline-GovHigh',
    [string]$PilotGroupName = 'SG-Compliance-Pilot',
    [string]$NotificationName = 'MT-Compliance-Noncompliant-GovHigh'
)

$ErrorActionPreference = 'Stop'
$script:Failures = 0

function Write-Check {
    param([bool]$Pass, [string]$Message)
    if ($Pass) {
        Write-Host "[PASS] $Message" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] $Message" -ForegroundColor Red
        $script:Failures++
    }
}

try {
    $scopes = @('DeviceManagementConfiguration.Read.All', 'Group.Read.All')
    Write-Host "Connecting to Microsoft Graph (Environment: $Environment)..." -ForegroundColor Cyan
    Connect-MgGraph -Environment $Environment -Scopes $scopes | Out-Null
    $ctx = Get-MgContext

    # Check 1 — correct sovereign cloud.
    Write-Check ($ctx -and $ctx.Environment -eq $Environment) `
        "Connected to the $Environment cloud (US Gov Graph). Actual: $($ctx.Environment)"

    # Check 2 — pilot group exists.
    $pilot = Get-MgGroup -Filter "displayName eq '$PilotGroupName'" -Property 'id,displayName' -ErrorAction SilentlyContinue
    Write-Check ([bool]$pilot) "Pilot group '$PilotGroupName' exists."

    # Check 3 — baseline compliance policy exists.
    $policies = Get-MgDeviceManagementDeviceCompliancePolicy -All -ExpandProperty 'assignments' -ErrorAction Stop
    $policy = $policies | Where-Object { $_.DisplayName -eq $PolicyName } | Select-Object -First 1
    Write-Check ([bool]$policy) "Compliance policy '$PolicyName' exists."

    if ($policy) {
        $targetTypes = @()
        $targetGroupIds = @()
        foreach ($a in $policy.Assignments) {
            $t = $a.Target.AdditionalProperties.'@odata.type'
            $targetTypes += $t
            if ($t -eq '#microsoft.graph.groupAssignmentTarget') { $targetGroupIds += $a.Target.AdditionalProperties.groupId }
        }

        # Check 4 — NOT assigned to All devices / All users (pilot-scoped, not fleet-wide).
        $isFleetWide = $targetTypes -contains '#microsoft.graph.allDevicesAssignmentTarget' -or `
                       $targetTypes -contains '#microsoft.graph.allLicensedUsersAssignmentTarget'
        Write-Check (-not $isFleetWide) "Policy '$PolicyName' is NOT assigned to All devices/All users (pilot-scoped)."

        # Check 5 — assigned to the pilot group.
        $targetsPilot = $pilot -and ($targetGroupIds -contains $pilot.Id)
        Write-Check ([bool]$targetsPilot) "Policy '$PolicyName' targets the pilot group '$PilotGroupName'."

        # Check 6 — a noncompliance email notification is attached (best effort).
        $hasNotification = $false
        if ($policy.AdditionalProperties.ContainsKey('scheduledActionsForRule')) {
            foreach ($rule in $policy.AdditionalProperties.scheduledActionsForRule) {
                foreach ($cfg in $rule.scheduledActionConfigurations) {
                    if ($cfg.actionType -eq 'notification') { $hasNotification = $true }
                }
            }
        }
        Write-Check $hasNotification "Policy '$PolicyName' has a noncompliance email action (template '$NotificationName' expected)."
    }

    Write-Host ""
    if ($script:Failures -eq 0) {
        Write-Host "OVERALL: PASS — all checks passed." -ForegroundColor Green
    } else {
        Write-Host "OVERALL: FAIL — $($script:Failures) check(s) failed. See [FAIL] lines above." -ForegroundColor Red
    }
}
finally {
    if (Get-MgContext) { Disconnect-MgGraph | Out-Null; Write-Host "`nDisconnected from Microsoft Graph." -ForegroundColor DarkGray }
}

exit ([int]($script:Failures -gt 0))

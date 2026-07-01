<#
.SYNOPSIS
    WS1COEX-Remediation.ps1 — safe rollback helper for a cohort cutover (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Executes the Rollback Plan – Cohort – Validate when a go/no-go gate fails: it removes a cohort
        group from the cohort-scoped Conditional Access policy (so a not-yet-compliant cohort is no
        longer blocked) and removes the cohort group from a named Intune configuration/compliance
        policy assignment (so the cohort stops drawing target policy). This returns the cohort toward
        Workspace ONE management with no user lockout.
        SAFETY: runs in -WhatIf mode BY DEFAULT — it only PREVIEWS the changes. Re-run with
        -Execute (and without -WhatIf) to apply them. Re-enrolling/retaining the device in Workspace
        ONE is performed in the source console (see VMware docs); this helper covers the Intune/Entra
        side only.
    HOW TO RUN
        Preview (default):
          powershell -ExecutionPolicy Bypass -File .\WS1COEX-Remediation.ps1 -CohortGroupId <guid> -CaPolicyId <guid>
        Apply:
          powershell -ExecutionPolicy Bypass -File .\WS1COEX-Remediation.ps1 -CohortGroupId <guid> -CaPolicyId <guid> -Execute
        Requires the Microsoft Graph PowerShell SDK. Scopes (write):
        Policy.ReadWrite.ConditionalAccess, DeviceManagementConfiguration.ReadWrite.All, Group.Read.All.
    EXPECTED RESULTS
        In preview: a list of the exact removals that WOULD occur. When applied: the cohort group is
        removed from the named CA policy's include-groups and from the named Intune policy assignment;
        re-run WS1COEX-Report.ps1 to confirm the cohort is reverting to its pre-cutover state.
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact='High')]
param(
    [Parameter(Mandatory)][string]$CohortGroupId,
    [string]$CaPolicyId,
    [string]$IntunePolicyId,
    [switch]$Execute
)

# Default to preview unless -Execute is explicitly supplied.
$WhatIfPreference = -not $Execute

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Policy.ReadWrite.ConditionalAccess','DeviceManagementConfiguration.ReadWrite.All','Group.Read.All' -NoWelcome

Write-Host ("=== WS1COEX Rollback Helper — mode: {0} ===" -f $(if($Execute){'EXECUTE'}else{'WHATIF (preview only)'})) -ForegroundColor Cyan

# 1 — Remove the cohort group from the cohort-scoped Conditional Access policy
if ($CaPolicyId) {
    $pol = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/identity/conditionalAccess/policies/$CaPolicyId"
    $inc = @($pol.conditions.users.includeGroups)
    if ($inc -contains $CohortGroupId) {
        $new = @($inc | Where-Object { $_ -ne $CohortGroupId })
        if ($PSCmdlet.ShouldProcess("CA policy '$($pol.displayName)'","Remove cohort group $CohortGroupId from includeGroups")) {
            $body = @{ conditions = @{ users = @{ includeGroups = $new } } } | ConvertTo-Json -Depth 6
            Invoke-MgGraphRequest -Method PATCH -Uri "/v1.0/identity/conditionalAccess/policies/$CaPolicyId" -Body $body
            Write-Host "  Removed cohort from CA policy '$($pol.displayName)'." -ForegroundColor Green
        }
    } else { Write-Host "  Cohort group is not in CA policy '$($pol.displayName)' include-groups — nothing to do." -ForegroundColor DarkGray }
} else { Write-Host "  (No -CaPolicyId supplied; skipping CA rollback.)" -ForegroundColor DarkGray }

# 2 — Remove the cohort group assignment from a named Intune device-management policy
if ($IntunePolicyId) {
    $assigns = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations/$IntunePolicyId/assignments").value
    $match = @($assigns | Where-Object { $_.target.groupId -eq $CohortGroupId })
    if ($match) {
        foreach ($a in $match) {
            if ($PSCmdlet.ShouldProcess("Intune policy $IntunePolicyId","Remove assignment $($a.id) for cohort $CohortGroupId")) {
                Invoke-MgGraphRequest -Method DELETE -Uri "/beta/deviceManagement/deviceConfigurations/$IntunePolicyId/assignments/$($a.id)"
                Write-Host "  Removed Intune assignment $($a.id)." -ForegroundColor Green
            }
        }
    } else { Write-Host "  Cohort group is not assigned to Intune policy $IntunePolicyId — nothing to do." -ForegroundColor DarkGray }
} else { Write-Host "  (No -IntunePolicyId supplied; skipping Intune-assignment rollback.)" -ForegroundColor DarkGray }

Write-Host "`nReminder: re-enroll/retain these devices in Workspace ONE via the source console (see VMware docs)," -ForegroundColor Yellow
Write-Host "then run WS1COEX-Report.ps1 to confirm the cohort returned to its pre-cutover state." -ForegroundColor Yellow
if (-not $Execute) { Write-Host "`nThis was a PREVIEW. Re-run with -Execute to apply." -ForegroundColor Cyan }
Disconnect-MgGraph | Out-Null

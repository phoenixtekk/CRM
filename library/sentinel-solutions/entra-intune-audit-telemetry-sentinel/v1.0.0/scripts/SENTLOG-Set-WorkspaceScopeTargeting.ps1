<#
.SYNOPSIS
    SENTLOG-Set-WorkspaceScopeTargeting.ps1 — report and apply scoped Microsoft Sentinel RBAC on the workspace.
.DESCRIPTION
    PURPOSE
        Workspace/RBAC scoping helper. Reports who currently has Sentinel-relevant roles on the workspace,
        and (optionally) assigns a least-privilege role to a named group at workspace scope so analysts and
        operators get exactly the access they need. Defaults to report-only (-WhatIf).
    HOW TO RUN
        Connect-AzAccount first. Report current assignments (safe):
        powershell -ExecutionPolicy Bypass -File .\SENTLOG-Set-WorkspaceScopeTargeting.ps1 -ResourceGroup <rg> -WorkspaceName "Security Telemetry - Tenant - Workspace"
        Apply a scoped role:
        powershell -ExecutionPolicy Bypass -File .\SENTLOG-Set-WorkspaceScopeTargeting.ps1 -ResourceGroup <rg> -WorkspaceName "..." -PrincipalObjectId <group-object-id> -Role "Microsoft Sentinel Reader" -WhatIf:$false
        Requires modules: Az.Accounts, Az.OperationalInsights, Az.Resources. Requires rights to manage IAM
        on the workspace.
    EXPECTED RESULTS
        A table of current Sentinel-relevant role assignments. When applied: the chosen role assigned to the
        principal at workspace scope (recorded as "<Role> - Workspace - <Stage>").
.NOTES
    Sentinel Solutions. Mutating only when -WhatIf:$false is passed.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory)] [string]$ResourceGroup,
    [Parameter(Mandatory)] [string]$WorkspaceName,
    [string]$PrincipalObjectId,
    [ValidateSet('Microsoft Sentinel Reader','Microsoft Sentinel Responder','Microsoft Sentinel Contributor')]
    [string]$Role = 'Microsoft Sentinel Reader',
    [bool]$WhatIf = $true
)

if ($WhatIf) { $WhatIfPreference = $true }

Write-Host "=== SENTLOG Workspace Scope / RBAC ===" -ForegroundColor Cyan
$ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction Stop
$scope = $ws.ResourceId
Write-Host ("Workspace scope: {0}" -f $scope)

# Report current Sentinel-relevant assignments at this scope
Write-Host "`n--- Current Sentinel-relevant role assignments ---" -ForegroundColor Cyan
$current = Get-AzRoleAssignment -Scope $scope -ErrorAction SilentlyContinue |
    Where-Object { $_.RoleDefinitionName -match 'Sentinel|Log Analytics' }
if ($current) {
    $current | Select-Object DisplayName, SignInName, RoleDefinitionName, ObjectType | Format-Table -AutoSize
} else {
    Write-Host "  (none found at workspace scope)" -ForegroundColor Yellow
}

# Optional: apply a scoped role
if ($PrincipalObjectId) {
    Write-Host ("`nWould assign '{0}' to {1} at workspace scope." -f $Role, $PrincipalObjectId) -ForegroundColor Cyan
    if ($PSCmdlet.ShouldProcess($PrincipalObjectId, "Assign '$Role' at $scope")) {
        New-AzRoleAssignment -ObjectId $PrincipalObjectId -RoleDefinitionName $Role -Scope $scope -ErrorAction Stop | Out-Null
        Write-Host ("Assigned. Record as '{0} - Workspace - Pilot'." -f $Role) -ForegroundColor Green
    } else {
        Write-Host "Preview only — re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow
    }
} else {
    Write-Host "`nNo -PrincipalObjectId supplied — report-only." -ForegroundColor Cyan
}

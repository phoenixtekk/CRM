<#
.SYNOPSIS
    SENTLOGG-Set-ScopeTargeting.ps1 — report and apply scoped Microsoft Sentinel RBAC on the workspace (GCC High).
.DESCRIPTION
    PURPOSE
        Workspace/RBAC scoping helper for Azure Government. Reports who currently has Sentinel-relevant
        roles on the workspace, and (optionally) assigns a least-privilege role to a named group at
        workspace scope so analysts and operators get exactly the access they need. Defaults to
        report-only (-WhatIf). Use your-resource-group, your-workspace-name, your-group-object-id.
    HOW TO RUN
        Connect-AzAccount -Environment AzureUSGovernment first. Report current assignments (safe):
        powershell -ExecutionPolicy Bypass -File .\SENTLOGG-Set-ScopeTargeting.ps1 -ResourceGroup your-resource-group -WorkspaceName "Security Telemetry - Tenant - Workspace"
        Apply a scoped role:
        powershell -ExecutionPolicy Bypass -File .\SENTLOGG-Set-ScopeTargeting.ps1 -ResourceGroup your-resource-group -WorkspaceName "Security Telemetry - Tenant - Workspace" -PrincipalObjectId your-group-object-id -Role "Microsoft Sentinel Reader" -WhatIf:$false
        Requires modules: Az.Accounts, Az.OperationalInsights, Az.Resources. Requires rights to manage IAM
        on the workspace.
    EXPECTED RESULTS
        A table of current Sentinel-relevant role assignments (pass = expected principals only). When
        applied: the chosen role assigned to the principal at workspace scope (recorded as
        "<Role> - Workspace - <Stage>").
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph/Azure US Gov endpoints unless -WhatIf:$false is passed.
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

Write-Host "=== SENTLOGG Workspace Scope / RBAC (GCC High / Azure Government) ===" -ForegroundColor Cyan

$ctx = Get-AzContext -ErrorAction SilentlyContinue
if (-not $ctx) { Write-Host "Not connected. Run: Connect-AzAccount -Environment AzureUSGovernment" -ForegroundColor Yellow; return }
if ($ctx.Environment.Name -ne 'AzureUSGovernment') {
    Write-Host ("STOP: Az environment is '{0}', not 'AzureUSGovernment'. Re-connect to the sovereign cloud." -f $ctx.Environment.Name) -ForegroundColor Yellow
    return
}

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

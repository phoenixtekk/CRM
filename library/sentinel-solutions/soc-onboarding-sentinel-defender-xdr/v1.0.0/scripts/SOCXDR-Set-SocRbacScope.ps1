<#
.SYNOPSIS
    SOCXDR-Set-SocRbacScope.ps1 — report and (optionally) apply the scoped SOC RBAC on the workspace.
.DESCRIPTION
    PURPOSE
        Workspace/RBAC scoping helper for the SOC. Reports current role assignments on the workspace,
        and can assign 'Microsoft Sentinel Responder' to the SOC analyst group at the workspace scope.
        Defaults to -WhatIf (reports what it WOULD do, changes nothing).
    HOW TO RUN
        Connect-AzAccount first. Preview (default, safe):
        powershell -ExecutionPolicy Bypass -File .\SOCXDR-Set-SocRbacScope.ps1 -ResourceGroup <rg> -WorkspaceName "Security Telemetry - SOC - Workspace" -SocGroupObjectId <entra-group-object-id>
        Apply for real (must pass -WhatIf:$false):
        powershell -ExecutionPolicy Bypass -File .\SOCXDR-Set-SocRbacScope.ps1 -ResourceGroup <rg> -WorkspaceName "..." -SocGroupObjectId <id> -WhatIf:$false
        Requires modules: Az.Accounts, Az.Resources, Az.OperationalInsights. Requires Owner/User Access
        Administrator on the workspace scope to assign roles.
    EXPECTED RESULTS
        In preview: lists existing assignments and prints the assignment it WOULD create. When applied:
        assigns 'Microsoft Sentinel Responder' to the SOC group at the workspace scope
        (recorded as 'Microsoft Sentinel Responder - SOC - Pilot').
.NOTES
    Sentinel Solutions. White-label. Mutating only when -WhatIf:$false is passed.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory)] [string]$ResourceGroup,
    [Parameter(Mandatory)] [string]$WorkspaceName,
    [Parameter(Mandatory)] [string]$SocGroupObjectId,
    [string]$RoleName = 'Microsoft Sentinel Responder',
    [bool]$WhatIf = $true
)

if ($WhatIf) { $WhatIfPreference = $true }

Write-Host "=== SOCXDR RBAC scope — Microsoft Sentinel Responder for the SOC ===" -ForegroundColor Cyan
$ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction Stop
$scope = $ws.ResourceId

Write-Host "`n--- Current role assignments on the workspace ---" -ForegroundColor Cyan
try {
    Get-AzRoleAssignment -Scope $scope -ErrorAction Stop |
        Where-Object { $_.RoleDefinitionName -match 'Sentinel|Reader|Contributor' } |
        Sort-Object RoleDefinitionName |
        ForEach-Object { Write-Host ("  {0,-32} {1}" -f $_.RoleDefinitionName, $_.DisplayName) }
} catch { Write-Host ("  Could not read assignments: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# Already assigned?
$existing = Get-AzRoleAssignment -Scope $scope -ObjectId $SocGroupObjectId -RoleDefinitionName $RoleName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host ("`n'{0}' already assigned to the SOC group at this scope. Nothing to do." -f $RoleName) -ForegroundColor Green
    return
}

Write-Host ("`nWould assign role : {0}" -f $RoleName) -ForegroundColor Cyan
Write-Host ("  To group        : {0}" -f $SocGroupObjectId)
Write-Host ("  At scope        : {0}" -f $scope)

if ($PSCmdlet.ShouldProcess($SocGroupObjectId, "Assign '$RoleName' at $scope")) {
    New-AzRoleAssignment -ObjectId $SocGroupObjectId -RoleDefinitionName $RoleName -Scope $scope -ErrorAction Stop | Out-Null
    Write-Host "Assigned. Recorded as 'Microsoft Sentinel Responder - SOC - Pilot'." -ForegroundColor Green
} else {
    Write-Host "`nPreview only — re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow
}

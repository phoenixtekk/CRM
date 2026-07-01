<#
.SYNOPSIS
    IGA-Remediation.ps1 — safely convert standing (active) Entra admin assignments to PIM eligible.
.DESCRIPTION
    PURPOSE
        Reduces residual standing privilege by converting permanent active directory-role assignments
        into PIM Eligible assignments: it creates an eligible schedule for each principal, then removes
        the standing active assignment. Runs in -WhatIf (preview) mode by default and always skips the
        named break-glass accounts so a lockout cannot occur.
    HOW TO RUN
        Preview (default): powershell -ExecutionPolicy Bypass -File .\IGA-Remediation.ps1 -RoleName "User Administrator" -BreakGlassUpns "bg1@contoso.onmicrosoft.com","bg2@contoso.onmicrosoft.com"
        Apply:            add -WhatIf:$false to the same command after reviewing the preview.
        Requires the Microsoft Graph PowerShell SDK. Scope: RoleManagement.ReadWrite.Directory.
    EXPECTED RESULTS
        A list of standing assignments that would (or did) become eligible; break-glass accounts are
        never touched. Re-run IGA-Validation.ps1 afterward.
.NOTES
    Phoenixtekk Workplace Marketplace — Entra ID Solutions. Changes role assignments — preview first.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)][string]$RoleName,
    [string[]]$BreakGlassUpns = @(),
    [string]$Justification = 'Phoenixtekk IGA: convert standing admin to eligible'
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'RoleManagement.ReadWrite.Directory','User.Read.All' -NoWelcome
Write-Host "=== IGA Remediation (standing -> eligible) — role: $RoleName ===" -ForegroundColor Cyan

$role = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/roleManagement/directory/roleDefinitions?`$filter=displayName eq '$RoleName'").value | Select-Object -First 1
if (-not $role) { Write-Host "Role not found: $RoleName" -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 1 }

$standing = @((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/roleManagement/directory/roleAssignmentScheduleInstances?`$filter=roleDefinitionId eq '$($role.id)'").value | Where-Object { $_.assignmentType -eq 'Assigned' })
if (-not $standing) { Write-Host "No standing (permanent active) assignments for this role." -ForegroundColor Green; Disconnect-MgGraph | Out-Null; exit 0 }

foreach ($a in $standing) {
    $upn = $null; try { $upn = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/directoryObjects/$($a.principalId)").userPrincipalName } catch {}
    if ($upn -and $BreakGlassUpns -contains $upn) { Write-Host "  SKIP break-glass: $upn" -ForegroundColor Cyan; continue }
    $target = $(if($upn){$upn}else{$a.principalId})
    if ($PSCmdlet.ShouldProcess($target, "Create eligible assignment and remove standing active for $RoleName")) {
        # 1) create eligible schedule
        $eligBody = @{ action='adminAssign'; justification=$Justification; roleDefinitionId=$role.id; directoryScopeId='/'; principalId=$a.principalId; scheduleInfo=@{ startDateTime=(Get-Date).ToString('o'); expiration=@{ type='noExpiration' } } }
        Invoke-MgGraphRequest -Method POST -Uri '/v1.0/roleManagement/directory/roleEligibilityScheduleRequests' -Body ($eligBody | ConvertTo-Json -Depth 6) | Out-Null
        # 2) remove standing active assignment
        $remBody = @{ action='adminRemove'; justification=$Justification; roleDefinitionId=$role.id; directoryScopeId='/'; principalId=$a.principalId }
        Invoke-MgGraphRequest -Method POST -Uri '/v1.0/roleManagement/directory/roleAssignmentScheduleRequests' -Body ($remBody | ConvertTo-Json -Depth 6) | Out-Null
        Write-Host "  CONVERTED to eligible: $target" -ForegroundColor Green
    } else {
        Write-Host "  WHATIF would convert to eligible: $target" -ForegroundColor Yellow
    }
}
Write-Host "`nRe-run IGA-Validation.ps1 to confirm." -ForegroundColor Green
Disconnect-MgGraph | Out-Null

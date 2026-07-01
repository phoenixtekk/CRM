<#
.SYNOPSIS
    AZSEC-Remediation.ps1 — safe remediation: remove a standing Owner assignment (replacing with a
    least-privilege role) or set a guardrail policy assignment's effect (audit / deny).
.DESCRIPTION
    PURPOSE
        Safe, targeted fixes for the "Azure Security Baseline & Governance" solution. Two actions:
          'TightenRbac' — remove a standing Owner role assignment for a principal at a scope, after
                          (optionally) granting the least-privilege custom role
                          'Resource Operator LeastPriv - Pilot Sub - Prod' at the same scope;
          'SetPolicyEffect' — set the 'effect' parameter of a named guardrail assignment to Audit or
                          Deny (the audit-before-deny gate / rollback).
        DEFAULTS TO -WhatIf — it prints the change it would make and changes nothing until you pass
        -Execute.
    HOW TO RUN
        Preview (default, no change):
            powershell -ExecutionPolicy Bypass -File .\AZSEC-Remediation.ps1 -Action TightenRbac -PrincipalObjectId '<obj id>' -Scope '/subscriptions/<sub id>'
            powershell -ExecutionPolicy Bypass -File .\AZSEC-Remediation.ps1 -Action SetPolicyEffect -AssignmentName 'Security Baseline Guardrails - Pilot MG - Audit' -Effect Deny -Scope '/providers/Microsoft.Management/managementGroups/<mg id>'
        Apply for real (explicit):
            ... -Execute
        Requires Az.Accounts, Az.Resources. Run Connect-AzAccount first, or the script will prompt.
        TightenRbac requires Owner / User Access Administrator; SetPolicyEffect requires Resource
        Policy Contributor at the scope.
    EXPECTED RESULTS
        In -WhatIf mode (default): a printed description of the RBAC removal (+ optional grant) or the
        policy-effect change — nothing changes. With -Execute: the change is applied.
.NOTES
    Workplace Marketplace — Azure Solutions. Defaults to -WhatIf. The repeatable way.
    TightenRbac removes only the Owner assignment you name for the principal at the scope; it does not
    touch other assignments. SetPolicyEffect edits only the named assignment's effect parameter.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [ValidateSet('TightenRbac','SetPolicyEffect')] [string]$Action,
    [Parameter(Mandatory)] [string]$Scope,
    [string]$PrincipalObjectId,                                   # for TightenRbac
    [string]$LeastPrivRoleName = 'Resource Operator LeastPriv - Pilot Sub - Prod',  # granted before removing Owner
    [switch]$GrantLeastPrivFirst,                                 # for TightenRbac
    [string]$AssignmentName,                                      # for SetPolicyEffect
    [ValidateSet('Audit','Deny')] [string]$Effect,               # for SetPolicyEffect
    [string]$SubscriptionId,
    [switch]$Execute                                             # omit for -WhatIf (default safe mode)
)

foreach ($m in 'Az.Accounts','Az.Resources') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Az -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.Resources -ErrorAction Stop

if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }

$whatIf = -not $Execute

switch ($Action) {

    'TightenRbac' {
        if (-not $PrincipalObjectId) { Write-Host "TightenRbac requires -PrincipalObjectId." -ForegroundColor Red; return }

        # Optionally grant the least-privilege custom role first, so the principal keeps working access.
        if ($GrantLeastPrivFirst) {
            if ($whatIf) {
                Write-Host ("[WhatIf] Would assign '{0}' to {1} at {2}. No change made. Re-run with -Execute." -f $LeastPrivRoleName, $PrincipalObjectId, $Scope) -ForegroundColor Yellow
            } else {
                try {
                    New-AzRoleAssignment -ObjectId $PrincipalObjectId -RoleDefinitionName $LeastPrivRoleName -Scope $Scope -ErrorAction Stop | Out-Null
                    Write-Host ("Assigned '{0}' to {1} at {2}." -f $LeastPrivRoleName, $PrincipalObjectId, $Scope) -ForegroundColor Green
                } catch {
                    Write-Host ("Grant failed (may already exist, or role not created yet): {0}" -f $_.Exception.Message) -ForegroundColor Yellow
                }
            }
        }

        # Remove the standing Owner assignment for this principal at the scope.
        $owner = Get-AzRoleAssignment -ObjectId $PrincipalObjectId -Scope $Scope -ErrorAction SilentlyContinue |
                 Where-Object { $_.RoleDefinitionName -eq 'Owner' -and $_.Scope -eq $Scope }
        if (-not $owner) {
            Write-Host ("No standing Owner assignment for {0} at {1}. Nothing to remove." -f $PrincipalObjectId, $Scope) -ForegroundColor Green
            return
        }
        if ($whatIf) {
            Write-Host ("[WhatIf] Would REMOVE Owner from {0} at {1}. No change made. Re-run with -Execute." -f $PrincipalObjectId, $Scope) -ForegroundColor Yellow
        } else {
            try {
                Remove-AzRoleAssignment -ObjectId $PrincipalObjectId -RoleDefinitionName 'Owner' -Scope $Scope -ErrorAction Stop
                Write-Host ("Removed standing Owner from {0} at {1}." -f $PrincipalObjectId, $Scope) -ForegroundColor Green
            } catch {
                Write-Host ("Owner removal failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
            }
        }
    }

    'SetPolicyEffect' {
        if (-not $AssignmentName) { Write-Host "SetPolicyEffect requires -AssignmentName." -ForegroundColor Red; return }
        if (-not $Effect)         { Write-Host "SetPolicyEffect requires -Effect (Audit or Deny)." -ForegroundColor Red; return }

        $assignment = Get-AzPolicyAssignment -Scope $Scope -ErrorAction SilentlyContinue |
                      Where-Object { $_.Name -eq $AssignmentName -or $_.Properties.DisplayName -eq $AssignmentName } | Select-Object -First 1
        if (-not $assignment) { Write-Host ("Assignment '{0}' not found at {1}." -f $AssignmentName, $Scope) -ForegroundColor Red; return }

        if ($whatIf) {
            Write-Host ("[WhatIf] Would set effect of '{0}' to '{1}' at {2}. No change made. Re-run with -Execute." -f $AssignmentName, $Effect, $Scope) -ForegroundColor Yellow
        } else {
            try {
                $params = @{ effect = @{ value = $Effect } }
                Set-AzPolicyAssignment -Id $assignment.ResourceId -PolicyParameterObject $params -ErrorAction Stop | Out-Null
                Write-Host ("Set effect of '{0}' to '{1}'." -f $AssignmentName, $Effect) -ForegroundColor Green
            } catch {
                Write-Host ("Set-effect failed (confirm the initiative exposes an 'effect' parameter): {0}" -f $_.Exception.Message) -ForegroundColor Red
            }
        }
    }
}

Write-Host ("`nRemediation complete ({0})." -f $(if ($whatIf){'WhatIf — no changes'}else{'executed'})) -ForegroundColor ($(if ($whatIf){'Yellow'}else{'Green'}))

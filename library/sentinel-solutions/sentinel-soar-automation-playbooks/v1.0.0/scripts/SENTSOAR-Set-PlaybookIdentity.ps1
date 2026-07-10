<#
.SYNOPSIS
    SENTSOAR-Set-PlaybookIdentity.ps1 — managed-identity and least-privilege role helper for playbooks.
.DESCRIPTION
    PURPOSE
        Reports each playbook's system-assigned managed identity and its role assignments so you can
        confirm least privilege (Microsoft Sentinel Responder for incident updates; NO enforced-action
        role on the response playbook during the pilot). Can OPTIONALLY assign Microsoft Sentinel
        Responder to a playbook's identity — but defaults to -WhatIf (reports only, changes nothing).
    HOW TO RUN
        Connect-AzAccount first. Report only (default, safe):
        powershell -ExecutionPolicy Bypass -File .\SENTSOAR-Set-PlaybookIdentity.ps1 -SoarResourceGroup rg-sentinel-soar -WorkspaceResourceId <workspace-resource-id>
        Assign Responder to one playbook's identity (must pass -WhatIf:$false):
        powershell -ExecutionPolicy Bypass -File .\SENTSOAR-Set-PlaybookIdentity.ps1 -SoarResourceGroup rg-sentinel-soar -WorkspaceResourceId <id> -AssignResponderTo "Enrichment - Incident - Pilot" -WhatIf:$false
        Requires modules: Az.Accounts, Az.LogicApp, Az.Resources.
    EXPECTED RESULTS
        Per-playbook identity + role list. In preview: prints the role it WOULD assign. When applied:
        grants Microsoft Sentinel Responder to the named playbook's identity at the workspace scope.
.NOTES
    Sentinel Solutions. Mutating only when -AssignResponderTo is set AND -WhatIf:$false is passed.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [string]$SoarResourceGroup = 'rg-sentinel-soar',
    [Parameter(Mandatory)] [string]$WorkspaceResourceId,
    [string]$AssignResponderTo,
    [bool]$WhatIf = $true
)

if ($WhatIf) { $WhatIfPreference = $true }
$responderRole = 'Microsoft Sentinel Responder'

Write-Host "=== SENTSOAR Playbook Identity — least-privilege review ===" -ForegroundColor Cyan

$apps = Get-AzLogicApp -ResourceGroupName $SoarResourceGroup -ErrorAction SilentlyContinue
if (-not $apps) { Write-Host ("No Logic Apps in {0}." -f $SoarResourceGroup) -ForegroundColor Yellow; return }

foreach ($app in $apps) {
    $res = Get-AzResource -ResourceGroupName $SoarResourceGroup -Name $app.Name -ResourceType 'Microsoft.Logic/workflows' -ExpandProperties -ErrorAction SilentlyContinue
    $principalId = $null
    if ($res -and $res.Identity -and $res.Identity.Type -match 'SystemAssigned') { $principalId = $res.Identity.PrincipalId }
    Write-Host ("`n[{0}]" -f $app.Name) -ForegroundColor Cyan
    if (-not $principalId) { Write-Host "  Managed identity : NONE — enable System assigned (Implementation Step 6)." -ForegroundColor Yellow; continue }
    Write-Host ("  Managed identity : {0}" -f $principalId) -ForegroundColor Green
    $ras = Get-AzRoleAssignment -ObjectId $principalId -ErrorAction SilentlyContinue
    if ($ras) { $ras | ForEach-Object { Write-Host ("    role: {0,-32} scope: {1}" -f $_.RoleDefinitionName, $_.Scope) } }
    else { Write-Host "    (no role assignments)" -ForegroundColor Yellow }

    if ($app.Name -like 'Response - Contain*') {
        $enforcing = $ras | Where-Object { $_.RoleDefinitionName -match 'Endpoint|Security Admin|User Admin|Global' }
        if ($enforcing) { Write-Host "    WARNING: response playbook holds an enforced-action role — remove it during the simulate-only pilot." -ForegroundColor Red }
        else { Write-Host "    OK: no enforced-action role (simulate-first posture preserved)." -ForegroundColor Green }
    }
}

# Optional: assign Responder to one playbook's identity
if ($AssignResponderTo) {
    Write-Host ("`n--- Assign '{0}' to {1} ---" -f $responderRole, $AssignResponderTo) -ForegroundColor Cyan
    $target = $apps | Where-Object { $_.Name -eq $AssignResponderTo }
    if (-not $target) { Write-Host ("  Playbook '{0}' not found." -f $AssignResponderTo) -ForegroundColor Yellow; return }
    $tres = Get-AzResource -ResourceGroupName $SoarResourceGroup -Name $AssignResponderTo -ResourceType 'Microsoft.Logic/workflows' -ExpandProperties -ErrorAction SilentlyContinue
    $pid = if ($tres -and $tres.Identity) { $tres.Identity.PrincipalId } else { $null }
    if (-not $pid) { Write-Host "  Target has no managed identity — enable it first (Implementation Step 6)." -ForegroundColor Yellow; return }

    if ($PSCmdlet.ShouldProcess($AssignResponderTo, "Assign '$responderRole' at $WorkspaceResourceId")) {
        New-AzRoleAssignment -ObjectId $pid -RoleDefinitionName $responderRole -Scope $WorkspaceResourceId -ErrorAction Stop | Out-Null
        Write-Host "  Assigned. Re-run without -AssignResponderTo to confirm." -ForegroundColor Green
    } else {
        Write-Host ("  PREVIEW: would assign '{0}' to identity {1} at {2}" -f $responderRole, $pid, $WorkspaceResourceId) -ForegroundColor Yellow
        Write-Host "  Re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow
    }
}

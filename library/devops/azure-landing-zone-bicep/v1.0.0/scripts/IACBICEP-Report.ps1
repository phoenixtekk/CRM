<#
.SYNOPSIS
    IACBICEP-Report.ps1 — governance posture and drift report for the Bicep landing zone.
.DESCRIPTION
    PURPOSE
        Produces a read-only posture report for the deployed landing zone: policy-compliance summary
        and the list of non-compliant resources, the guardrail assignment and its effect, an RBAC /
        standing-Owner summary, and deployment-stack drift (resources the stack manages vs. what exists).
        Useful before promoting guardrails from Audit to Deny and on each governance cycle.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IACBICEP-Report.ps1 -ManagementGroupId alz
        powershell -ExecutionPolicy Bypass -File .\IACBICEP-Report.ps1 -ManagementGroupId alz -OutFile posture.csv
        Requires Az modules (Az.Accounts, Az.Resources, Az.PolicyInsights). Run Connect-AzAccount first.
        *Verify current Az module versions.*
    EXPECTED RESULTS
        A console report (and optional CSV) of compliance, guardrail effect, RBAC posture, and drift.
        No changes are made.
.NOTES
    White-label. Read-only reporting. Makes no changes.
#>
[CmdletBinding()]
param(
    [string]$ManagementGroupId = 'alz',
    [string]$StackName = 'alz-stack – Sandbox – NonProd',
    [string]$OutFile
)

$ErrorActionPreference = 'Continue'
Import-Module Az.Accounts -ErrorAction SilentlyContinue
Import-Module Az.Resources -ErrorAction SilentlyContinue
Import-Module Az.PolicyInsights -ErrorAction SilentlyContinue
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }

$scope = "/providers/Microsoft.Management/managementGroups/$ManagementGroupId"
function Write-Section($t) { Write-Host "`n===== $t =====" -ForegroundColor Cyan }

Write-Section "Guardrail assignment and effect"
try {
    Get-AzPolicyAssignment -Scope $scope |
        Where-Object { $_.Name -eq 'Guardrails-LandingZones' } |
        Select-Object Name,
            @{n='DisplayName';e={$_.Properties.DisplayName}},
            @{n='Effect';e={$_.Properties.Parameters.effect.value}},
            @{n='EnforcementMode';e={$_.Properties.EnforcementMode}} |
        Format-Table -AutoSize
} catch { Write-Warning $_.Exception.Message }

Write-Section "Policy compliance summary"
$noncompliant = @()
try {
    $states = Get-AzPolicyState -ManagementGroupName $ManagementGroupId -ErrorAction Stop
    $summary = $states | Group-Object ComplianceState | Select-Object Name, Count
    $summary | Format-Table -AutoSize
    $noncompliant = $states | Where-Object ComplianceState -eq 'NonCompliant' |
        Select-Object ResourceId, PolicyDefinitionName -Unique
    Write-Host ("Non-compliant resources: {0}" -f $noncompliant.Count) -ForegroundColor Yellow
    $noncompliant | Select-Object -First 20 | Format-Table -AutoSize
} catch { Write-Warning "Compliance read failed (run 'az policy state trigger-scan' first): $($_.Exception.Message)" }

Write-Section "RBAC / standing-Owner posture"
try {
    $owners = Get-AzRoleAssignment -RoleDefinitionName 'Owner' -ErrorAction Stop
    Write-Host ("Standing Owner assignments: {0}" -f $owners.Count) -ForegroundColor Yellow
    $owners | Select-Object DisplayName, Scope, ObjectType | Format-Table -AutoSize
} catch { Write-Warning $_.Exception.Message }

Write-Section "Deployment-stack drift ($StackName)"
try {
    $stack = az stack mg show --name $StackName --management-group-id $ManagementGroupId -o json 2>$null | ConvertFrom-Json
    if ($stack) {
        Write-Host ("Managed resources: {0} | ProvisioningState: {1}" -f $stack.resources.Count, $stack.provisioningState)
    } else { Write-Warning "Stack '$StackName' not found — was it deployed via 'az stack' (Test 7)?" }
} catch { Write-Warning $_.Exception.Message }

if ($OutFile -and $noncompliant) {
    $noncompliant | Export-Csv -Path $OutFile -NoTypeInformation
    Write-Host "`nNon-compliant detail written to $OutFile" -ForegroundColor Green
}
Write-Host "`nReport complete." -ForegroundColor Green

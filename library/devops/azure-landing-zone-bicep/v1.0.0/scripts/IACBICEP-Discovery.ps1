<#
.SYNOPSIS
    IACBICEP-Discovery.ps1 — read-only inventory of the Azure estate before deploying a Bicep landing zone.
.DESCRIPTION
    PURPOSE
        Discovery for the "Azure Landing Zone with Bicep" solution. Reports the existing management-group
        hierarchy, policy assignments and their effect, custom role definitions, standing Owner role
        assignments, and every virtual-network address range (the address-overlap check for the hub-spoke
        plan). Makes NO changes — this is your baseline snapshot.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IACBICEP-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\IACBICEP-Discovery.ps1 -ManagementGroupId alz
        Requires the Az modules (Az.Accounts, Az.Resources, Az.Network). Run Connect-AzAccount first,
        or the script will prompt. *Verify current Az module versions — cmdlet surfaces change between versions.*
    EXPECTED RESULTS
        A per-section snapshot: management groups, policy assignments (with effect), custom roles,
        standing Owner assignments (highlighted), and existing VNet CIDRs — a single readiness picture
        before you scaffold main.bicep and deploy.
.NOTES
    White-label. Read-only — reports on configuration/identifiers only; makes no changes.
#>
[CmdletBinding()]
param(
    [string]$ManagementGroupId = 'alz',
    [string]$SubscriptionId
)

$ErrorActionPreference = 'Stop'
foreach ($m in 'Az.Accounts','Az.Resources','Az.Network') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Warning "Module $m not found. Install with: Install-Module Az -Scope CurrentUser"
    }
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.Resources -ErrorAction Stop
Import-Module Az.Network -ErrorAction Stop

if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }

function Write-Section($t) { Write-Host "`n===== $t =====" -ForegroundColor Cyan }

Write-Section "Management groups"
try {
    Get-AzManagementGroup | Select-Object Name, DisplayName |
        Format-Table -AutoSize
} catch { Write-Warning "Could not enumerate management groups: $($_.Exception.Message)" }

Write-Section "Policy assignments at management-group scope ($ManagementGroupId)"
try {
    $scope = "/providers/Microsoft.Management/managementGroups/$ManagementGroupId"
    Get-AzPolicyAssignment -Scope $scope |
        Select-Object Name,
            @{n='DisplayName';e={$_.Properties.DisplayName}},
            @{n='Effect';e={$_.Properties.Parameters.effect.value}} |
        Format-Table -AutoSize
} catch { Write-Warning "Policy assignment read failed: $($_.Exception.Message)" }

Write-Section "Custom role definitions"
try {
    Get-AzRoleDefinition | Where-Object { -not $_.IsCustom -eq $false } |
        Where-Object IsCustom -eq $true |
        Select-Object Name, Id | Format-Table -AutoSize
} catch { Write-Warning "Role definition read failed: $($_.Exception.Message)" }

Write-Section "STANDING OWNER assignments (review for least-privilege)"
try {
    $owners = Get-AzRoleAssignment -RoleDefinitionName 'Owner'
    if ($owners) {
        $owners | Select-Object DisplayName, SignInName, Scope, ObjectType |
            Format-Table -AutoSize
        Write-Host ("  {0} standing Owner assignment(s) found — plan controlled reduction." -f $owners.Count) -ForegroundColor Yellow
    } else { Write-Host "  No standing Owner assignments in the current scope." -ForegroundColor Green }
} catch { Write-Warning "Owner assignment read failed: $($_.Exception.Message)" }

Write-Section "Existing VNet address ranges (address-overlap check for hub-spoke)"
try {
    Get-AzVirtualNetwork | ForEach-Object {
        [pscustomobject]@{
            VNet          = $_.Name
            ResourceGroup = $_.ResourceGroupName
            AddressSpace  = ($_.AddressSpace.AddressPrefixes -join ', ')
        }
    } | Format-Table -AutoSize
} catch { Write-Warning "VNet read failed: $($_.Exception.Message)" }

Write-Host "`nDiscovery complete. Save this output as your pre-deployment baseline." -ForegroundColor Green

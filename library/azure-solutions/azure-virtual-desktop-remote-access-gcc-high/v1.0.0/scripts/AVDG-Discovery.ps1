<#
.SYNOPSIS
    AVDG-Discovery.ps1 — read-only inventory of Azure Virtual Desktop on an Azure Government (GCC High) tenant.
.DESCRIPTION
    PURPOSE
        Snapshots the current state of AVD in Azure Government so you can Assess before you Configure.
        Reports the connected cloud/environment, Microsoft.DesktopVirtualization registration, AVD host
        pools / workspaces / application groups, session hosts, and application-group assignments.
        Read-only — makes no changes. Replace placeholders like 'your-subscription-id' with your values.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AVDG-Discovery.ps1
        Modules: Az.Accounts, Az.Resources, Az.DesktopVirtualization, Microsoft.Graph.Authentication
        Scopes/sign-in (US Gov): Connect-AzAccount -Environment AzureUSGovernment ; Connect-MgGraph -Environment USGov
        Optional: -SubscriptionId your-subscription-id -ResourceGroupName your-resource-group
    EXPECTED RESULTS
        A console + object summary. PASS = environment is AzureUSGovernment, provider Registered, and AVD
        objects/hosts listed. FAIL/WARN lines flag a Commercial context, unregistered provider, or missing objects.
.NOTES
    White-label — the repeatable way. Read-only against Azure/Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$ResourceGroupName,
    [string]$AzureEnvironment = 'AzureUSGovernment',
    [string]$GraphEnvironment = 'USGov'
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Write-Pass($t){ Write-Host "[PASS] $t" -ForegroundColor Green }
function Write-WarnLine($t){ Write-Host "[WARN] $t" -ForegroundColor Yellow }
function Write-FailLine($t){ Write-Host "[FAIL] $t" -ForegroundColor Red }

Write-Section 'Connect (Azure Government)'
try {
    $ctx = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $ctx) {
        Write-Host "Signing in to Azure ($AzureEnvironment)..."
        Connect-AzAccount -Environment $AzureEnvironment | Out-Null
        $ctx = Get-AzContext
    }
    if ($SubscriptionId) { Set-AzContext -Subscription $SubscriptionId | Out-Null; $ctx = Get-AzContext }
    $envName = $ctx.Environment.Name
    if ($envName -eq 'AzureUSGovernment') { Write-Pass "Connected to $envName (subscription: $($ctx.Subscription.Name))" }
    else { Write-FailLine "Connected environment is '$envName', not 'AzureUSGovernment'. This solution targets Azure Government (portal.azure.us). Re-run: Connect-AzAccount -Environment AzureUSGovernment" }
} catch { Write-FailLine "Azure sign-in failed: $($_.Exception.Message)"; return }

Write-Section 'Microsoft Graph (US Gov) — optional for group/assignment detail'
try {
    if (Get-Command Connect-MgGraph -ErrorAction SilentlyContinue) {
        if (-not (Get-MgContext)) { Connect-MgGraph -Environment $GraphEnvironment -Scopes 'Group.Read.All','Directory.Read.All' -NoWelcome -ErrorAction Stop }
        Write-Pass "Graph connected ($GraphEnvironment)."
    } else { Write-WarnLine 'Microsoft.Graph module not present; skipping Graph-based group detail.' }
} catch { Write-WarnLine "Graph connect skipped: $($_.Exception.Message)" }

Write-Section 'Resource provider: Microsoft.DesktopVirtualization'
try {
    $rp = Get-AzResourceProvider -ProviderNamespace 'Microsoft.DesktopVirtualization' -ErrorAction Stop
    $state = ($rp | Select-Object -First 1).RegistrationState
    if ($state -eq 'Registered') { Write-Pass "Provider Registered." }
    else { Write-FailLine "Provider state = '$state'. Register it (AVDG-Remediation.ps1 or Register-AzResourceProvider)." }
} catch { Write-FailLine "Could not read provider state: $($_.Exception.Message)" }

Write-Section 'Current roles (deploying account)'
try {
    $me = (Get-AzContext).Account.Id
    $scope = "/subscriptions/$((Get-AzContext).Subscription.Id)"
    $roles = Get-AzRoleAssignment -SignInName $me -Scope $scope -ErrorAction SilentlyContinue | Select-Object -Expand RoleDefinitionName -Unique
    if ($roles) { Write-Host ("Roles: " + ($roles -join ', ')) } else { Write-WarnLine 'No direct role assignments resolved (may be group-inherited).' }
    if ($roles -match 'Owner|Contributor|Desktop Virtualization') { Write-Pass 'A sufficient role for AVD deployment appears present.' }
    else { Write-WarnLine 'Confirm Contributor/Owner + Desktop Virtualization Contributor (may be inherited via group/PIM).' }
} catch { Write-WarnLine "Role read skipped: $($_.Exception.Message)" }

Write-Section 'AVD host pools'
try {
    $hpParams = @{}; if ($ResourceGroupName) { $hpParams['ResourceGroupName'] = $ResourceGroupName }
    $pools = Get-AzWvdHostPool @hpParams -ErrorAction Stop
    if ($pools) {
        foreach ($p in $pools) {
            Write-Host ("HostPool: {0} | Type: {1} | LoadBalancer: {2}" -f $p.Name, $p.HostPoolType, $p.LoadBalancerType)
            $rg = ($p.Id -split '/resourceGroups/')[1].Split('/')[0]
            $hosts = Get-AzWvdSessionHost -HostPoolName $p.Name -ResourceGroupName $rg -ErrorAction SilentlyContinue
            if ($hosts) { foreach ($h in $hosts) { Write-Host ("    SessionHost: {0} | Status: {1} | AgentVer: {2}" -f ($h.Name -split '/')[-1], $h.Status, $h.AgentVersion) } }
            else { Write-WarnLine "    No session hosts in $($p.Name)." }
        }
        Write-Pass "$($pools.Count) host pool(s) found."
    } else { Write-WarnLine 'No AVD host pools found in scope.' }
} catch { Write-FailLine "Host pool enumeration failed: $($_.Exception.Message)" }

Write-Section 'AVD workspaces & application groups'
try {
    $wsParams = @{}; if ($ResourceGroupName) { $wsParams['ResourceGroupName'] = $ResourceGroupName }
    $ws = Get-AzWvdWorkspace @wsParams -ErrorAction SilentlyContinue
    if ($ws) { foreach ($w in $ws) { Write-Host ("Workspace: {0} | AppGroups registered: {1}" -f $w.Name, (($w.ApplicationGroupReference | Measure-Object).Count)) }; Write-Pass "$($ws.Count) workspace(s)." }
    else { Write-WarnLine 'No workspaces found in scope.' }

    $ag = Get-AzWvdApplicationGroup @wsParams -ErrorAction SilentlyContinue
    if ($ag) { foreach ($a in $ag) { Write-Host ("AppGroup: {0} | Type: {1}" -f $a.Name, $a.ApplicationGroupType) }; Write-Pass "$($ag.Count) application group(s)." }
    else { Write-WarnLine 'No application groups found in scope.' }
} catch { Write-WarnLine "Workspace/app-group read: $($_.Exception.Message)" }

Write-Section 'Discovery complete'
Write-Host 'Read-only snapshot only. Review WARN/FAIL lines, then proceed per 02-requirements.md and 03-implementation.md.'

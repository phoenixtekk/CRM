<#
.SYNOPSIS
    MIM365-Discovery.ps1 — inventory Azure Logic Apps and Function Apps, whether each has a managed
    identity (system- or user-assigned), and which application (app-role) Graph permissions each
    identity holds.
.DESCRIPTION
    PURPOSE
        Read-only discovery for the "Managed Identities for Azure Logic Apps & Functions" solution.
        Enumerates the Logic Apps and Function Apps in the subscription, reports each resource's
        managed identity (system-assigned principal and/or attached user-assigned identities), and for
        each identity lists the application app-role assignments (e.g. Mail.Read) granted on Microsoft
        Graph. Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MIM365-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\MIM365-Discovery.ps1 -SubscriptionId '<sub id>'
        Requires Az PowerShell (Az.Accounts, Az.Resources) to enumerate compute + identities, and the
        Microsoft.Graph SDK to resolve app-role assignments. Run Connect-AzAccount and
        Connect-MgGraph first, or the script will prompt.
    GRAPH SCOPES (least privilege, read-only)
        Application.Read.All, AppRoleAssignment.Read.All, Directory.Read.All
        (Connect-MgGraph -Scopes 'Application.Read.All','AppRoleAssignment.Read.All','Directory.Read.All')
    EXPECTED RESULTS
        A per-resource snapshot: each Logic App / Function App, its managed-identity kind (system /
        user-assigned / none), and the Graph application app-roles assigned to each identity — the
        readiness picture before you grant permissions or migrate secret-based flows.
.NOTES
    Azure Solutions — read-only. The repeatable way.
    Reports on configuration/identifiers only; makes no changes to identities, permissions, or workflows.
    White-label sample tenant: contoso.com.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId
)

foreach ($m in 'Az.Accounts','Az.Resources') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Az -Scope CurrentUser -Force -AllowClobber; break }
}
if (-not (Get-Module -ListAvailable -Name 'Microsoft.Graph')) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.Resources -ErrorAction Stop
Import-Module Microsoft.Graph.Applications -ErrorAction Stop

if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes 'Application.Read.All','AppRoleAssignment.Read.All','Directory.Read.All' | Out-Null
}

# Resolve the Microsoft Graph service principal once (app-roles are defined on it).
$graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'" -ErrorAction SilentlyContinue

function Show-IdentityAppRoles([string]$principalId, [string]$indent) {
    if (-not $principalId) { return }
    try {
        $grants = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $principalId -ErrorAction Stop
        if (-not $grants) { Write-Host ("{0}(no application app-roles granted)" -f $indent) -ForegroundColor Yellow; return }
        foreach ($g in $grants) {
            $roleName = '(unknown app-role)'
            if ($graphSp -and $g.ResourceId -eq $graphSp.Id) {
                $role = $graphSp.AppRoles | Where-Object Id -eq $g.AppRoleId
                if ($role) { $roleName = $role.Value }
            }
            Write-Host ("{0}app-role: {1,-28} on {2}" -f $indent, $roleName, $g.ResourceDisplayName)
        }
    } catch {
        Write-Host ("{0}Could not read app-role assignments: {1}" -f $indent, $_.Exception.Message) -ForegroundColor Yellow
    }
}

Write-Host "`n=== Managed Identities for Logic Apps & Functions — discovery ===" -ForegroundColor Cyan
$ctx = Get-AzContext
Write-Host ("Subscription: {0}" -f $ctx.Subscription.Id)

# Logic Apps (Microsoft.Logic/workflows) and Function Apps (Microsoft.Web/sites kind=functionapp).
$targets  = @()
$targets += Get-AzResource -ResourceType 'Microsoft.Logic/workflows' -ErrorAction SilentlyContinue
$targets += Get-AzResource -ResourceType 'Microsoft.Web/sites' -ErrorAction SilentlyContinue |
            Where-Object { $_.Kind -match 'functionapp' }

if (-not $targets) { Write-Host "No Logic Apps or Function Apps found in this subscription." -ForegroundColor Yellow; return }

foreach ($t in $targets) {
    $full = Get-AzResource -ResourceId $t.ResourceId -ExpandProperties -ErrorAction SilentlyContinue
    $idty = $full.Identity
    $kind = if ($t.ResourceType -match 'Logic') { 'Logic App' } else { 'Function App' }
    Write-Host ("`n[{0}] {1}" -f $kind, $t.Name) -ForegroundColor Cyan

    if (-not $idty -or $idty.Type -eq 'None' -or -not $idty.Type) {
        Write-Host "   Managed identity: NONE" -ForegroundColor Yellow
        continue
    }
    Write-Host ("   Managed identity type: {0}" -f $idty.Type)

    if ($idty.Type -match 'SystemAssigned' -and $idty.PrincipalId) {
        Write-Host ("   System-assigned principalId: {0}" -f $idty.PrincipalId)
        Show-IdentityAppRoles $idty.PrincipalId '      '
    }
    if ($idty.Type -match 'UserAssigned' -and $idty.UserAssignedIdentities) {
        foreach ($ua in $idty.UserAssignedIdentities.PSObject.Properties) {
            $uaPrincipal = $ua.Value.principalId
            Write-Host ("   User-assigned: {0}" -f ($ua.Name -split '/')[-1])
            Write-Host ("      principalId: {0}" -f $uaPrincipal)
            Show-IdentityAppRoles $uaPrincipal '      '
        }
    }
}

Write-Host "`nDiscovery complete (read-only)." -ForegroundColor Green

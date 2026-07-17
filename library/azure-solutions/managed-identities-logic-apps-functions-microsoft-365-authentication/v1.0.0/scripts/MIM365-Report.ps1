<#
.SYNOPSIS
    MIM365-Report.ps1 — identity/permission inventory across the estate, exported to CSV.
.DESCRIPTION
    PURPOSE
        Reporting for the "Managed Identities for Azure Logic Apps & Functions" solution. Walks every
        Logic App and Function App in the subscription and produces one row per (resource, identity,
        app-role): the resource name and type, the managed-identity kind (system / user-assigned /
        none), the identity's principalId, and each application Graph app-role it holds. Writes a CSV
        for auditing and trend tracking. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MIM365-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\MIM365-Report.ps1 -SubscriptionId '<sub id>' -OutputCsv '.\MIM365-identity-inventory.csv'
        Requires Az.Accounts, Az.Resources and the Microsoft.Graph SDK. Run Connect-AzAccount and
        Connect-MgGraph first, or the script will prompt.
    GRAPH SCOPES (least privilege, read-only)
        Application.Read.All, AppRoleAssignment.Read.All, Directory.Read.All
    EXPECTED RESULTS
        A console table and a CSV (default .\MIM365-identity-inventory.csv) listing each Logic App /
        Function App, its managed-identity kind, principalId, and granted Graph application app-roles —
        the estate inventory to audit least privilege and track drift each cycle.
.NOTES
    Azure Solutions — read-only. The repeatable way.
    Reports on configuration/identifiers only; makes no changes. White-label sample tenant: contoso.com.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$OutputCsv = ".\MIM365-identity-inventory.csv"
)

foreach ($m in 'Az.Accounts','Az.Resources') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Az -Scope CurrentUser -Force -AllowClobber; break }
}
if (-not (Get-Module -ListAvailable -Name 'Microsoft.Graph')) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.Resources -ErrorAction Stop
Import-Module Microsoft.Graph.Applications -ErrorAction Stop

if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'Application.Read.All','AppRoleAssignment.Read.All','Directory.Read.All' | Out-Null }

$graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'" -ErrorAction SilentlyContinue

function Get-AppRoles([string]$principalId) {
    $roles = @()
    if (-not $principalId) { return $roles }
    try {
        $grants = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $principalId -ErrorAction Stop
        foreach ($g in $grants) {
            if ($graphSp -and $g.ResourceId -eq $graphSp.Id) {
                $role = $graphSp.AppRoles | Where-Object Id -eq $g.AppRoleId
                if ($role) { $roles += $role.Value }
            }
        }
    } catch {}
    return ($roles | Select-Object -Unique)
}

$ctx = Get-AzContext
$rows = @()

$targets  = @()
$targets += Get-AzResource -ResourceType 'Microsoft.Logic/workflows' -ErrorAction SilentlyContinue
$targets += Get-AzResource -ResourceType 'Microsoft.Web/sites' -ErrorAction SilentlyContinue | Where-Object { $_.Kind -match 'functionapp' }

foreach ($t in $targets) {
    $full = Get-AzResource -ResourceId $t.ResourceId -ExpandProperties -ErrorAction SilentlyContinue
    $idty = $full.Identity
    $kind = if ($t.ResourceType -match 'Logic') { 'Logic App' } else { 'Function App' }

    if (-not $idty -or -not $idty.Type -or $idty.Type -eq 'None') {
        $rows += [pscustomobject]@{ Resource=$t.Name; Type=$kind; IdentityKind='None'; PrincipalId=''; AppRoles='' }
        continue
    }
    if ($idty.Type -match 'SystemAssigned' -and $idty.PrincipalId) {
        $rows += [pscustomobject]@{ Resource=$t.Name; Type=$kind; IdentityKind='SystemAssigned'; PrincipalId=$idty.PrincipalId; AppRoles=((Get-AppRoles $idty.PrincipalId) -join '; ') }
    }
    if ($idty.Type -match 'UserAssigned' -and $idty.UserAssignedIdentities) {
        foreach ($ua in $idty.UserAssignedIdentities.PSObject.Properties) {
            $pid = $ua.Value.principalId
            $rows += [pscustomobject]@{ Resource=$t.Name; Type=$kind; IdentityKind=("UserAssigned:" + ($ua.Name -split '/')[-1]); PrincipalId=$pid; AppRoles=((Get-AppRoles $pid) -join '; ') }
        }
    }
}

if (-not $rows) { Write-Host "No Logic Apps or Function Apps found." -ForegroundColor Yellow; return }

Write-Host "`n=== MIM365 identity/permission inventory (subscription $($ctx.Subscription.Id)) ===" -ForegroundColor Cyan
$rows | Format-Table -AutoSize
$rows | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
Write-Host ("`nCSV written: {0}" -f (Resolve-Path $OutputCsv)) -ForegroundColor Green

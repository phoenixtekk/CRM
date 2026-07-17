<#
.SYNOPSIS
    MIM365-Validate.ps1 — PASS/FAIL check that a target Logic App / Function App has a managed
    identity holding the expected least-privilege application permission and no leftover secret-based
    connection.
.DESCRIPTION
    PURPOSE
        Validation for the "Managed Identities for Azure Logic Apps & Functions" solution. For a named
        Logic App or Function App, confirms: (1) it has a managed identity; (2) that identity holds the
        expected application app-role (e.g. Mail.Read) on Microsoft Graph; (3) it holds NOTHING broader
        than the expected set (least privilege); and (4) — for a Logic App — no stored/secret-based
        API connection remains in its resource group. Prints PASS/FAIL per check. Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MIM365-Validate.ps1 -ResourceName 'Graph Automation LogicApp - Contoso - Pilot' -ResourceGroup '<rg>' -ExpectedAppRoles 'Mail.Read'
        powershell -ExecutionPolicy Bypass -File .\MIM365-Validate.ps1 -ResourceName 'Graph Automation FuncApp - Contoso - Pilot' -ResourceGroup '<rg>' -ExpectedAppRoles 'Mail.Read' -SubscriptionId '<sub id>'
        Requires Az.Accounts, Az.Resources and the Microsoft.Graph SDK. Run Connect-AzAccount and
        Connect-MgGraph first, or the script will prompt.
    GRAPH SCOPES (least privilege, read-only)
        Application.Read.All, AppRoleAssignment.Read.All, Directory.Read.All
    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall verdict. Least privilege FAILS if the identity holds
        any application app-role not in -ExpectedAppRoles; the secret check FAILS if a stored API
        connection is still present for a Logic App.
.NOTES
    Azure Solutions — read-only PASS/FAIL. The repeatable way.
    Reports on configuration only; makes no changes. Mailbox-permission scoping is validated separately
    per companion product #4. White-label sample tenant: contoso.com.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ResourceName,
    [Parameter(Mandatory)] [string]$ResourceGroup,
    [string[]]$ExpectedAppRoles = @('Mail.Read'),
    [string]$SubscriptionId
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

$overall = $true
function Check([string]$label, [bool]$pass, [string]$detail) {
    $tag = if ($pass) { 'PASS' } else { 'FAIL' }
    $col = if ($pass) { 'Green' } else { 'Red' }
    Write-Host ("[{0}] {1}{2}" -f $tag, $label, $(if($detail){" — $detail"}else{''})) -ForegroundColor $col
    if (-not $pass) { $script:overall = $false }
}

Write-Host "`n=== MIM365 validation: $ResourceName ===" -ForegroundColor Cyan

$res = Get-AzResource -ResourceGroupName $ResourceGroup -Name $ResourceName -ExpandProperties -ErrorAction SilentlyContinue
if (-not $res) { Write-Host "Resource not found — check name/resource group." -ForegroundColor Red; return }

# 1) Managed identity present
$idty = $res.Identity
$hasIdentity = $idty -and $idty.Type -and $idty.Type -ne 'None'
Check "Managed identity enabled" $hasIdentity $(if($idty){"type: $($idty.Type)"}else{'none'})

# Collect the identity principal(s) to check.
$principalIds = @()
if ($hasIdentity) {
    if ($idty.PrincipalId) { $principalIds += $idty.PrincipalId }
    if ($idty.UserAssignedIdentities) {
        foreach ($ua in $idty.UserAssignedIdentities.PSObject.Properties) { if ($ua.Value.principalId) { $principalIds += $ua.Value.principalId } }
    }
}

$graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'" -ErrorAction SilentlyContinue
$grantedRoles = @()
foreach ($pid in ($principalIds | Select-Object -Unique)) {
    try {
        $grants = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $pid -ErrorAction Stop
        foreach ($g in $grants) {
            if ($graphSp -and $g.ResourceId -eq $graphSp.Id) {
                $role = $graphSp.AppRoles | Where-Object Id -eq $g.AppRoleId
                if ($role) { $grantedRoles += $role.Value }
            }
        }
    } catch {}
}
$grantedRoles = $grantedRoles | Select-Object -Unique

# 2) Expected least-privilege permission present
$missing = $ExpectedAppRoles | Where-Object { $_ -notin $grantedRoles }
Check "Expected app-role(s) granted" ($missing.Count -eq 0) ("expected: {0}; granted: {1}" -f ($ExpectedAppRoles -join ','), ($grantedRoles -join ',' ))

# 3) Least privilege — nothing broader than expected
$extra = $grantedRoles | Where-Object { $_ -notin $ExpectedAppRoles }
Check "Least privilege (no extra app-roles)" ($extra.Count -eq 0) $(if($extra){"extra: $($extra -join ',')"}else{'none beyond expected'})

# 4) No leftover secret-based API connection (Logic App resource group)
if ($res.ResourceType -match 'Logic') {
    $conns = Get-AzResource -ResourceGroupName $ResourceGroup -ResourceType 'Microsoft.Web/connections' -ErrorAction SilentlyContinue
    Check "No stored API connection remains" (-not $conns) $(if($conns){"found: $(( $conns.Name ) -join ', ')"}else{'none'})
} else {
    Write-Host "[INFO] Secret-in-app-settings check for Functions: confirm no client secret / service-account password is stored in Application settings (manual)." -ForegroundColor Yellow
}

Write-Host ("`nOverall: {0}" -f $(if($overall){'PASS'}else{'FAIL'})) -ForegroundColor $(if($overall){'Green'}else{'Red'})

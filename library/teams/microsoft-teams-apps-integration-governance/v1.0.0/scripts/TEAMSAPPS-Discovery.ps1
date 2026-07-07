<#
.SYNOPSIS
    TEAMSAPPS-Discovery.ps1 — read-only inventory of Teams app permission/setup policies, the app catalog (by distribution method), and installed apps.
.DESCRIPTION
    PURPOSE
        Builds the authoritative Teams app-governance baseline: every app permission policy and app
        setup policy (MicrosoftTeams module), the full Teams app catalog with each app's distribution
        method (store / organization / sideloaded) from Microsoft Graph, and the apps actually
        installed per team. Risk-flags sideloaded (uploaded) and organization-published (LOB) apps for
        review. Read-only — makes no changes.
    HOW TO RUN
        .\TEAMSAPPS-Discovery.ps1 -CsvPath C:\Temp\TEAMSAPPS-Catalog.csv
        (PowerShell 5.1+/7+; MicrosoftTeams module + Microsoft Graph SDK)
        Connect: Connect-MicrosoftTeams   and   Connect-MgGraph with read scopes
        AppCatalog.Read.All, Directory.Read.All, Team.ReadBasic.All, TeamsAppInstallation.ReadForTeam.All.
    EXPECTED RESULTS
        Console summary: count of permission/setup policies, and a catalog table grouped by
        distribution method with sideloaded/LOB apps flagged. Optional per-app CSV.
.NOTES
    Teams — Microsoft Teams Apps & Integration Governance. Read-only; no changes, no stored credentials.
    Some org-wide app settings are admin-center-only — verify PowerShell/Graph parity in your tenant.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [switch]$IncludeInstalled   # also enumerate installed apps per team (slower on large tenants)
)

# --- Modules ---
if (-not (Get-Module -ListAvailable -Name MicrosoftTeams))            { Install-Module MicrosoftTeams -Scope CurrentUser -Force -AllowClobber }
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module MicrosoftTeams -ErrorAction Stop
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

Connect-MicrosoftTeams | Out-Null
Connect-MgGraph -Scopes 'AppCatalog.Read.All','Directory.Read.All','Team.ReadBasic.All','TeamsAppInstallation.ReadForTeam.All' -NoWelcome

Write-Host '=== TEAMSAPPS Discovery (read-only) ===' -ForegroundColor Cyan

# --- Policies (MicrosoftTeams module) ---
$permPolicies  = @(Get-CsTeamsAppPermissionPolicy)
$setupPolicies = @(Get-CsTeamsAppSetupPolicy)
Write-Host ('--- App permission policies: {0} | App setup policies: {1} ---' -f $permPolicies.Count, $setupPolicies.Count) -ForegroundColor Cyan
$permPolicies  | Select-Object Identity, DefaultCatalogAppsType, GlobalCatalogAppsType, PrivateCatalogAppsType | Format-Table -AutoSize
$setupPolicies | Select-Object Identity, AllowUserPinning, AllowSideLoading | Format-Table -AutoSize

# --- App catalog by distribution method (Graph) ---
# distributionMethod: store (third-party), organization (tenant/LOB), sideloaded (uploaded).
$catalog = @()
$uri = "/v1.0/appCatalogs/teamsApps?`$expand=appDefinitions&`$top=100"
do {
    $r = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($app in $r.value) {
        $def = $app.appDefinitions | Select-Object -First 1
        $dist = $app.distributionMethod
        $catalog += [pscustomobject]@{
            AppId              = $app.id
            DisplayName        = $def.displayName
            Publisher          = $def.publishingState  # publishing state; publisher name via appDefinitions where present
            DistributionMethod = $dist
            RiskFlag           = switch ($dist) { 'sideloaded' { 'REVIEW-sideloaded' } 'organization' { 'REVIEW-LOB' } default { '' } }
        }
    }
    $uri = $r.'@odata.nextLink'
} while ($uri)

Write-Host ('--- App catalog: {0} apps ---' -f $catalog.Count) -ForegroundColor Cyan
$catalog | Group-Object DistributionMethod | Sort-Object Name |
    Select-Object @{n='DistributionMethod';e={$_.Name}}, Count | Format-Table -AutoSize
$flagged = @($catalog | Where-Object { $_.RiskFlag })
Write-Host ('--- Flagged for review (sideloaded/LOB): {0} ---' -f $flagged.Count) -ForegroundColor Yellow
$flagged | Select-Object DisplayName, DistributionMethod, RiskFlag | Format-Table -AutoSize

# --- Installed apps per team (optional) ---
if ($IncludeInstalled) {
    Write-Host '--- Installed apps per team ---' -ForegroundColor Cyan
    $teams = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=resourceProvisioningOptions/Any(x:x eq 'Team')&`$select=id,displayName&`$top=999").value
    foreach ($t in $teams) {
        $inst = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/teams/{0}/installedApps?`$expand=teamsAppDefinition" -f $t.id)).value
        foreach ($i in $inst) {
            $catalog += [pscustomobject]@{
                AppId              = $i.teamsAppDefinition.teamsAppId
                DisplayName        = $i.teamsAppDefinition.displayName
                Publisher          = ('InstalledIn:{0}' -f $t.displayName)
                DistributionMethod = 'installed'
                RiskFlag           = ''
            }
        }
    }
}

if ($CsvPath) {
    $catalog | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved catalog inventory to {0}" -f $CsvPath) -ForegroundColor Green
}

Disconnect-MgGraph | Out-Null
Disconnect-MicrosoftTeams | Out-Null

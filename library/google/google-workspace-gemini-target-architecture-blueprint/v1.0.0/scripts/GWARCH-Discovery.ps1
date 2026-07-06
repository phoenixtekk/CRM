<#
.SYNOPSIS
    GWARCH-Discovery.ps1 — read-only current-state discovery of the M365/Entra source estate for the target-architecture blueprint.
.DESCRIPTION
    PURPOSE
        Inventories the source Microsoft 365 / Entra ID estate that the Google Workspace + Gemini
        target architecture must be designed against: identity sources and provisioning signals,
        domains and mail routing, groups/OU-equivalent structure, licensing, and governance/hold
        indicators. Output grounds the Assess phase so the architecture is drawn from reality.
        Read-only: it never changes the source tenant. Provide your-tenant-id at the prompt or via
        -TenantId.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWARCH-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\GWARCH-Discovery.ps1 -TenantId your-tenant-id -OutputPath .\gwarch-discovery.json
        Requires: Microsoft.Graph PowerShell SDK. Graph scopes (read-only): Directory.Read.All,
        User.Read.All, Group.Read.All, Organization.Read.All, Domain.Read.All, Policy.Read.All.
    EXPECTED RESULTS
        A console summary plus a JSON report of the current-state source estate (counts, domains,
        licensing, provisioning/hold indicators). No pass/fail — this is factual input to the design.
.NOTES
    White-label — the repeatable way. Read-only where it reads live systems.
#>

[CmdletBinding()]
param(
    [string]$TenantId,
    [string]$OutputPath = ".\gwarch-discovery.json"
)

$ErrorActionPreference = 'Stop'
$readScopes = @(
    'Directory.Read.All','User.Read.All','Group.Read.All',
    'Organization.Read.All','Domain.Read.All','Policy.Read.All'
)

function Connect-Source {
    param([string]$Tenant, [string[]]$Scopes)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft Graph SDK not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $params = @{ Scopes = $Scopes; NoWelcome = $true }
    if ($Tenant) { $params.TenantId = $Tenant }
    Connect-MgGraph @params
}

Write-Host "GWARCH-Discovery — read-only current-state discovery of the M365/Entra source estate" -ForegroundColor Cyan
Connect-Source -Tenant $TenantId -Scopes $readScopes

$report = [ordered]@{
    generatedUtc  = (Get-Date).ToUniversalTime().ToString('o')
    scope         = 'source M365/Entra current-state'
    organization  = $null
    domains       = @()
    counts        = [ordered]@{}
    licensing     = @()
    identity      = [ordered]@{}
    governance    = [ordered]@{}
    notes         = @()
}

try {
    $org = Get-MgOrganization -ErrorAction Stop | Select-Object -First 1
    $report.organization = [ordered]@{
        displayName = $org.DisplayName
        id          = $org.Id
        onPremSync  = [bool]$org.OnPremisesSyncEnabled
    }
    $report.identity.onPremDirSyncEnabled = [bool]$org.OnPremisesSyncEnabled
    if ($org.OnPremisesSyncEnabled) {
        $report.notes += "On-prem directory sync is enabled — likely AD/Entra source of truth (GWARCH-ID-1: confirm the single authoritative source)."
    }
} catch { $report.notes += "Organization read failed: $($_.Exception.Message)" }

try {
    $report.domains = Get-MgDomain -All | ForEach-Object {
        [ordered]@{ id = $_.Id; isVerified = $_.IsVerified; isDefault = $_.IsDefault; authType = $_.AuthenticationType }
    }
} catch { $report.notes += "Domain read failed: $($_.Exception.Message)" }

try { $report.counts.users  = (Get-MgUser -All -Property Id -ConsistencyLevel eventual -CountVariable c | Measure-Object).Count } catch { $report.notes += "User count failed: $($_.Exception.Message)" }
try { $report.counts.groups = (Get-MgGroup -All -Property Id | Measure-Object).Count } catch { $report.notes += "Group count failed: $($_.Exception.Message)" }

try {
    $report.licensing = Get-MgSubscribedSku -All | ForEach-Object {
        [ordered]@{ skuPartNumber = $_.SkuPartNumber; enabled = $_.PrepaidUnits.Enabled; consumed = $_.ConsumedUnits }
    }
} catch { $report.notes += "Licensing read failed: $($_.Exception.Message)" }

# Identity provisioning signal: on-prem synced vs cloud-only users (shadow-source risk indicator)
try {
    $syncedSample = Get-MgUser -Top 200 -Property Id,OnPremisesSyncEnabled -All:$false
    $onPrem = ($syncedSample | Where-Object { $_.OnPremisesSyncEnabled }).Count
    $report.identity.sampledUsers       = $syncedSample.Count
    $report.identity.sampledOnPremSynced = $onPrem
    $report.identity.mixedSourceIndicator = ($onPrem -gt 0 -and $onPrem -lt $syncedSample.Count)
    if ($report.identity.mixedSourceIndicator) {
        $report.notes += "Both on-prem-synced and cloud-only users detected in sample — review for competing identity sources (GWARCH-ID-1)."
    }
} catch { $report.notes += "Identity provisioning sample failed: $($_.Exception.Message)" }

# Governance / hold indicator (informational; Purview hold detail is deferred to the source console)
$report.governance.purviewCoexistenceNote = "Legacy holds/retention on the source are governed in Microsoft Purview; enumerate matters in the source console. GWARCH-GOV-2: each hold needs a Vault-transition sunset owner/date."

Disconnect-MgGraph | Out-Null

$report | ConvertTo-Json -Depth 6 | Out-File -FilePath $OutputPath -Encoding utf8
Write-Host ""
Write-Host "Current-state summary:" -ForegroundColor Green
Write-Host ("  Organization : {0}" -f $report.organization.displayName)
Write-Host ("  Verified domains : {0}" -f ($report.domains | Where-Object { $_.isVerified }).Count)
Write-Host ("  Users  : {0}" -f $report.counts.users)
Write-Host ("  Groups : {0}" -f $report.counts.groups)
Write-Host ("  On-prem dir sync : {0}" -f $report.identity.onPremDirSyncEnabled)
if ($report.notes.Count) { Write-Host "  Notes:"; $report.notes | ForEach-Object { Write-Host "   - $_" -ForegroundColor Yellow } }
Write-Host ""
Write-Host "Full report written to $OutputPath" -ForegroundColor Cyan

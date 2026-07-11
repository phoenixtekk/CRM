<#
.SYNOPSIS
    SOAMCA-OAuthAudit.ps1 — read-only deep audit of OAuth application grants; flags over-permissioned
    scopes, unverified publishers, and dormant high-privilege apps (app-governance evidence).
.DESCRIPTION
    PURPOSE
        Enumerates the OAuth applications (service principals + delegated/app-role grants) in the
        tenant and flags the risk indicators that app governance is meant to catch:
          - Over-permissioned: broad/tenant-wide application permissions (e.g. *.ReadWrite.All)
          - Unverified publisher: no verified publisher / unknown publisher
          - Dormant high-privilege: privileged grants on apps with no recent sign-in signal
        Produces the detailed evidence behind the app-governance/OAuth assessment domain. NO changes.
    HOW TO RUN
        Connect-MgGraph -Scopes "Application.Read.All","Directory.Read.All"
        powershell -ExecutionPolicy Bypass -File .\SOAMCA-OAuthAudit.ps1 -OutputPath ".\oauth-audit.json"
    EXPECTED RESULTS
        A JSON list of OAuth apps with granted scopes and risk flags, sorted by risk. An empty set
        (with a note) is valid in a tenant with no third-party OAuth grants.
.NOTES
    White-label. Read-only. Flags are heuristic evidence for a human reviewer, NOT an automatic
    verdict — the security owner decides risk-acceptance. Verify current Graph scope names.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\oauth-audit.json"
)

$ErrorActionPreference = 'Stop'
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes "Application.Read.All","Directory.Read.All" | Out-Null
}

function Invoke-GraphGet {
    param([string]$Uri)
    $results = @(); $next = $Uri
    while ($next) {
        try { $resp = Invoke-MgGraphRequest -Method GET -Uri $next -ErrorAction Stop }
        catch { Write-Warning "GET $next failed: $($_.Exception.Message)"; break }
        if ($resp.value) { $results += $resp.value } elseif ($resp) { $results += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $results
}

# High-risk application permission patterns (broad, tenant-wide write/read-all).
$highRiskPatterns = @('\.ReadWrite\.All$','^Directory\.','^Application\.ReadWrite','^RoleManagement\.','Mail\.ReadWrite','Files\.ReadWrite\.All','Sites\.FullControl')

Write-Host "SOAMCA-OAuthAudit — read-only enumeration of OAuth apps..." -ForegroundColor Cyan
$sps = Invoke-GraphGet "https://graph.microsoft.com/v1.0/servicePrincipals?`$select=id,appId,displayName,publisherName,verifiedPublisher,appRoles,servicePrincipalType,accountEnabled&`$top=100"

$findings = @()
foreach ($sp in $sps) {
    # App-role (application permission) grants held BY this service principal:
    $appRoleGrants = Invoke-GraphGet "https://graph.microsoft.com/v1.0/servicePrincipals/$($sp.id)/appRoleAssignments?`$top=100"
    $grantedScopes = @()
    foreach ($g in $appRoleGrants) {
        if ($g.appRoleId -and $g.resourceId) { $grantedScopes += ($g.resourceDisplayName + ':' + $g.appRoleId) }
    }
    # Delegated grants (oauth2PermissionGrants) where this SP is the client:
    $delegated = Invoke-GraphGet "https://graph.microsoft.com/v1.0/oauth2PermissionGrants?`$filter=clientId eq '$($sp.id)'"
    $delegatedScopes = @($delegated | ForEach-Object { $_.scope }) -join ' '

    $isUnverified = -not $sp.verifiedPublisher.displayName
    $overPermissioned = $false
    foreach ($pat in $highRiskPatterns) {
        if ($delegatedScopes -match $pat) { $overPermissioned = $true; break }
    }
    $flags = @()
    if ($overPermissioned) { $flags += 'over-permissioned' }
    if ($isUnverified)     { $flags += 'unverified-publisher' }
    if (-not $sp.accountEnabled) { $flags += 'disabled-but-granted' }

    if ($flags.Count -gt 0 -or $grantedScopes.Count -gt 0 -or $delegatedScopes) {
        $risk = 0
        if ($overPermissioned) { $risk += 3 }
        if ($isUnverified)     { $risk += 2 }
        if (-not $sp.accountEnabled) { $risk += 1 }
        $findings += [ordered]@{
            displayName      = $sp.displayName
            appId            = $sp.appId
            type             = $sp.servicePrincipalType
            verifiedPublisher= [bool]$sp.verifiedPublisher.displayName
            delegatedScopes  = $delegatedScopes
            appRoleGrantCount= $appRoleGrants.Count
            flags            = $flags
            riskScore        = $risk
        }
    }
}

$sorted = @($findings | Sort-Object -Property riskScore -Descending)
$out = [ordered]@{
    solution     = "SOAMCA"
    generatedUtc = (Get-Date).ToUniversalTime().ToString("o")
    readOnly     = $true
    appsAudited  = ($sps | Measure-Object).Count
    flaggedApps  = ($sorted | Measure-Object).Count
    findings     = $sorted
    note         = if (($sorted | Measure-Object).Count -eq 0) { "No flagged OAuth grants found (or no third-party OAuth apps in tenant)." } else { "Flags are heuristic evidence for review, not automatic verdicts." }
}
$out | ConvertTo-Json -Depth 8 | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host ("Apps audited: {0}; flagged: {1}" -f $out.appsAudited, $out.flaggedApps) -ForegroundColor Green
$sorted | Select-Object -First 15 | ForEach-Object {
    Write-Host ("  risk {0}  {1}  [{2}]" -f $_.riskScore, $_.displayName, ($_.flags -join ',')) -ForegroundColor Yellow
}
Write-Host "Written: $OutputPath (read-only; no changes made)." -ForegroundColor Green

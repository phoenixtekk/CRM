<#
.SYNOPSIS
    SOAXDR-RBACAudit.ps1 — read-only audit of privileged directory-role assignments relevant to the
    Microsoft Defender suite; flags broad / over-privileged standing access.
.DESCRIPTION
    PURPOSE
        Enumerates directory-role assignments and highlights the security-relevant, high-privilege
        roles that govern who can see and act across the Defender suite (Global Administrator, Security
        Administrator, Security Operator, plus the read roles). Flags excessive Global Admins and
        standing high privilege — the evidence behind the unified-RBAC assessment domain. NO changes.
    HOW TO RUN
        Connect-MgGraph -Scopes "RoleManagement.Read.Directory","Directory.Read.All"
        powershell -ExecutionPolicy Bypass -File .\SOAXDR-RBACAudit.ps1 -OutputPath ".\rbac-audit.json"
    EXPECTED RESULTS
        A JSON list of privileged assignments grouped by role, with flags for over-privilege. An empty
        set (with a note) is valid in a tightly-scoped tenant.
.NOTES
    White-label. Read-only. Flags are heuristic evidence for a human reviewer, NOT an automatic
    verdict — the security owner decides. Consider whether privileged roles are PIM-eligible (just-in-
    time) vs permanently active; permanent activation of high privilege is the higher-risk pattern.
#>
[CmdletBinding()]
param(
    [int]$MaxGlobalAdmins = 5,
    [string]$OutputPath = ".\rbac-audit.json"
)

$ErrorActionPreference = 'Stop'
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes "RoleManagement.Read.Directory","Directory.Read.All" | Out-Null
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

Write-Host "SOAXDR-RBACAudit — read-only enumeration of privileged role assignments..." -ForegroundColor Cyan
$assignments = Invoke-GraphGet "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments?`$top=400&`$expand=roleDefinition"

$highPrivRoles = @('Global Administrator','Privileged Role Administrator','Security Administrator','Exchange Administrator','SharePoint Administrator')
$securityRoles = @('Security Administrator','Security Operator','Security Reader','Global Reader')

$byRole = $assignments | Group-Object { $_.roleDefinition.displayName } | ForEach-Object {
    [ordered]@{
        role         = $_.Name
        count        = $_.Count
        highPrivilege= ($highPrivRoles -contains $_.Name)
        securityRole = ($securityRoles -contains $_.Name)
    }
}

$gaCount = @($assignments | Where-Object { $_.roleDefinition.displayName -eq 'Global Administrator' }).Count
$flags = @()
if ($gaCount -gt $MaxGlobalAdmins) { $flags += "Global Admin count ($gaCount) exceeds recommended max ($MaxGlobalAdmins)" }
$highPrivTotal = @($assignments | Where-Object { $highPrivRoles -contains $_.roleDefinition.displayName }).Count
if ($highPrivTotal -gt ($MaxGlobalAdmins * 3)) { $flags += "High-privilege assignments ($highPrivTotal) are numerous — review for least privilege" }

$out = [ordered]@{
    solution         = "SOAXDR"
    generatedUtc     = (Get-Date).ToUniversalTime().ToString("o")
    readOnly         = $true
    totalAssignments = ($assignments | Measure-Object).Count
    globalAdminCount = $gaCount
    byRole           = @($byRole | Sort-Object -Property count -Descending)
    flags            = $flags
    note             = "Flags are heuristic evidence, not verdicts. Prefer PIM just-in-time activation over permanent high-privilege assignment. Unified RBAC activation is confirmed separately (SOAXDR-Validate -UnifiedRbacActivated)."
}
$out | ConvertTo-Json -Depth 8 | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host ("Assignments: {0}; Global Admins: {1}" -f $out.totalAssignments, $gaCount) -ForegroundColor Green
$flags | ForEach-Object { Write-Host ("  FLAG: {0}" -f $_) -ForegroundColor Yellow }
Write-Host "Written: $OutputPath (read-only; no changes made)." -ForegroundColor Green

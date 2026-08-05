<#
.SYNOPSIS
    AGBINV-Connect-Preflight.ps1 — verify scopes/roles and reachability of the Copilot Package
    Management API, and DECODE the 401/403/404 the customer hits into a named cause.
.DESCRIPTION
    PURPOSE
        Answers "why is my /copilot/admin/catalog/packages request blocked or failed." Signs in,
        reports the scopes and directory roles on the current context, then calls the packages
        endpoint and decodes the HTTP result into a specific, actionable cause (missing scope/consent,
        insufficient role, Agent 365 entitlement, or tenant not rolled out / cloud not supported).
        Read-only; changes nothing.
    HOW TO RUN
        pwsh -File .\AGBINV-Connect-Preflight.ps1 -Environment Global
        Government clouds:  -Environment USGov   (GCC High)   or   -Environment USGovDoD   (DoD)
        Required delegated scope: CopilotPackages.Read.All  (least privilege; read-only)
        Qualifying roles: AI Administrator (preferred), Global Administrator, Cloud Application
        Administrator, Application Administrator, or Copilot Administrator.
    EXPECTED RESULTS
        A printed verdict: signed-in account, scopes, roles, and a decoded HTTP status with the most
        likely cause. 200 = API live and authorized (use Path B). 401 = token. 403 = scope/role/
        entitlement. 404 = not rolled out / cloud unsupported (use Path A — admin center export).
.NOTES
    Copilot Solutions — the repeatable way. Read-only against Microsoft Graph. The Package Management
    API released recently and is documented in both v1.0 and beta; this script uses v1.0 and treats
    availability as tenant-dependent. Verify preview-volatile behavior against current Microsoft docs.
#>

[CmdletBinding()]
param(
    [ValidateSet('Global','USGov','USGovDoD')]
    [string] $Environment = 'Global'
)

$ErrorActionPreference = 'Stop'

$graphEnv = switch ($Environment) {
    'USGov'    { @{ Env = 'USGov';    Base = 'https://graph.microsoft.us' } }
    'USGovDoD' { @{ Env = 'USGovDoD'; Base = 'https://dod-graph.microsoft.us' } }
    default    { @{ Env = 'Global';   Base = 'https://graph.microsoft.com' } }
}
$base = "$($graphEnv.Base)/v1.0"   # prefer v1.0; the beta path returns the same shape

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    throw "Microsoft Graph SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

Write-Host "Connecting to Graph ($($graphEnv.Env)) with CopilotPackages.Read.All ..." -ForegroundColor Cyan
Connect-MgGraph -Environment $graphEnv.Env -Scopes 'CopilotPackages.Read.All' | Out-Null
$ctx = Get-MgContext

Write-Host "`n--- Context ---" -ForegroundColor Cyan
Write-Host ("Account : {0}" -f $ctx.Account)
Write-Host ("Tenant  : {0}" -f $ctx.TenantId)
Write-Host ("Cloud   : {0}" -f $ctx.Environment)
Write-Host ("Scopes  : {0}" -f ($ctx.Scopes -join ', '))
if ($ctx.Scopes -notcontains 'CopilotPackages.Read.All') {
    Write-Host "WARNING: CopilotPackages.Read.All is NOT on the token — admin consent likely missing (see T4)." -ForegroundColor Yellow
}

# Best-effort role read (needs Directory.Read.All / RoleManagement.Read.Directory; non-fatal if absent)
try {
    Connect-MgGraph -Environment $graphEnv.Env -Scopes 'CopilotPackages.Read.All','RoleManagement.Read.Directory' | Out-Null
    $roles = Invoke-MgGraphRequest -Method GET -Uri "$base/me/memberOf/microsoft.graph.directoryRole"
    $roleNames = @($roles.value | ForEach-Object { $_.displayName })
    Write-Host ("Roles   : {0}" -f (($roleNames -join ', ')))
    $qualifying = 'AI Administrator','Global Administrator','Cloud Application Administrator','Application Administrator','Copilot Administrator'
    if (-not ($roleNames | Where-Object { $_ -in $qualifying })) {
        Write-Host "WARNING: none of the qualifying admin roles detected (see R1/T5)." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Roles   : (could not read directory roles — grant RoleManagement.Read.Directory to see this)" -ForegroundColor DarkYellow
}

Write-Host "`n--- Calling the Package Management API ---" -ForegroundColor Cyan
$uri = "$base/copilot/admin/catalog/packages?`$top=1"
Write-Host "GET $uri"
try {
    $resp = Invoke-MgGraphRequest -Method GET -Uri $uri
    Write-Host "`nRESULT: 200 OK — the API is LIVE and your identity is authorized." -ForegroundColor Green
    Write-Host "You can use Path B (the Graph export). Proceed to AGBINV-Export-AgentInventory.ps1." -ForegroundColor Green
}
catch {
    $status = $null
    if ($_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }
    elseif ($_.ErrorDetails.Message -match '"code"\s*:\s*"(\w+)"') { $status = $Matches[1] }
    Write-Host "`nRESULT: request failed. Decoding ..." -ForegroundColor Yellow
    switch -Regex ("$status") {
        '401' {
            Write-Host "401 Unauthorized — TOKEN problem, not permissions (T2)." -ForegroundColor Red
            Write-Host " -> Re-run Connect-MgGraph with the correct -Environment for your tenant; confirm token audience/cloud."
        }
        '403' {
            Write-Host "403 Forbidden — authenticated but not allowed. Most likely cause, in order (T3-T6):" -ForegroundColor Red
            Write-Host "  1) SCOPE/CONSENT: CopilotPackages.Read.All missing from token or not admin-consented (T4)."
            Write-Host "  2) ROLE: signed-in account lacks a qualifying admin role e.g. AI Administrator (T5)."
            Write-Host "  3) ENTITLEMENT: current docs state this API requires Microsoft Agent 365 (T6)."
            Write-Host "  4) ROLLOUT: backend feature not yet enabled for this tenant (T7)."
            Write-Host "  -> If scope+role are confirmed and 403 persists, use Path A (admin center export)."
        }
        '404' {
            Write-Host "404 Not Found — the API is NOT present for this tenant/cloud (T7)." -ForegroundColor Red
            Write-Host "  -> Tenant-by-tenant rollout, OR a Government cloud where the API is unavailable."
            Write-Host "  -> Use Path A (Microsoft 365 admin center Agent Registry -> Export). Re-test Path B after GA."
        }
        default {
            Write-Host "Unrecognized error. Raw message:" -ForegroundColor Red
            Write-Host $_.Exception.Message
            Write-Host "  -> Confirm the URL namespace is exactly /copilot/admin/catalog/packages (T1)."
        }
    }
}

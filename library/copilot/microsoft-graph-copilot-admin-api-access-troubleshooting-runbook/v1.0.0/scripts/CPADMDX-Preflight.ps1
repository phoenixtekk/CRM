<#
.SYNOPSIS
    CPADMDX-Preflight.ps1 - Report the signed-in identity, token scopes, directory roles, and cloud
    used to call the Microsoft Graph Copilot admin (beta) endpoints. READ-ONLY.

.DESCRIPTION
    PURPOSE
      Step 0 of the diagnostic runbook. Establishes the facts you must know before branching:
        - who you are signed in as, and whether the token is DELEGATED or APP-ONLY (Branch B),
        - which permission scopes are actually in the token (Branch C/D),
        - which Entra directory roles the signed-in user holds - e.g. AI Administrator / Global
          Administrator (Branch E),
        - which cloud (Global / USGov / USGovDoD) the token targets (Branch A/F).
      It changes nothing in the tenant.

    HOW TO RUN
      1. Install the Graph SDK if needed:  Install-Module Microsoft.Graph -Scope CurrentUser
      2. Run, choosing your cloud:
           .\CPADMDX-Preflight.ps1 -Environment Global
           .\CPADMDX-Preflight.ps1 -Environment USGov      # GCC High (graph.microsoft.us)
           .\CPADMDX-Preflight.ps1 -Environment USGovDoD    # DoD (dod-graph.microsoft.us)
      3. Sign in interactively as the admin you intend to use. Consent to the requested read scopes.

    EXPECTED RESULTS
      A printed summary and an object with: Account, AuthType (Delegated/AppOnly), Environment,
      GraphHost, Scopes[], DirectoryRoles[]. Use it to fill CPADMDX-Findings.json (via
      CPADMDX-Report-Findings.ps1). If AuthType is AppOnly, go to Branch B. If a required scope is
      missing, Branch C/D. If no admin role is listed, Branch E.

.NOTES
    Copilot category - read-only diagnostics for the Microsoft Graph Copilot admin (beta) API.
    Beta endpoints are subject to change; verify scope/role/cloud facts against current Microsoft
    documentation. Requires the Microsoft.Graph PowerShell SDK.
#>
[CmdletBinding()]
param(
    [ValidateSet('Global','USGov','USGovDoD')]
    [string]$Environment = 'Global',

    # Scopes to request at sign-in (delegated). Defaults cover the package + policy-settings reads.
    [string[]]$Scopes = @('CopilotPackages.Read.All','CopilotPolicySettings.Read'),

    [string]$OutputFolder = '.\CPADMDX-Diagnostics'
)

$ErrorActionPreference = 'Stop'

function Get-GraphHost([string]$env) {
    switch ($env) {
        'USGov'    { 'https://graph.microsoft.us' }
        'USGovDoD' { 'https://dod-graph.microsoft.us' }
        default    { 'https://graph.microsoft.com' }
    }
}

Write-Host "== CPADMDX Preflight ==" -ForegroundColor Cyan
Write-Host "Target cloud: $Environment  ($(Get-GraphHost $Environment))"

# --- Connect (delegated, interactive). Do NOT use app-only for these endpoints. ---
try {
    Connect-MgGraph -Environment $Environment -Scopes $Scopes -NoWelcome -ErrorAction Stop | Out-Null
}
catch {
    Write-Warning "Connect-MgGraph failed: $($_.Exception.Message)"
    Write-Warning "If consent was blocked, a Global Administrator must grant admin consent (Branch D)."
    throw
}

$ctx = Get-MgContext
if (-not $ctx) { throw "No Microsoft Graph context after connect." }

$authType = if ($ctx.AuthType) { $ctx.AuthType } elseif ($ctx.Account) { 'Delegated' } else { 'AppOnly' }

# --- Directory roles of the signed-in user (delegated only) ---
$roles = @()
if ($authType -eq 'Delegated' -and $ctx.Account) {
    try {
        $resp = Invoke-MgGraphRequest -Method GET `
            -Uri "$(Get-GraphHost $Environment)/v1.0/me/memberOf/microsoft.graph.directoryRole?`$select=displayName,roleTemplateId"
        $roles = @($resp.value | ForEach-Object { $_.displayName })
    }
    catch {
        Write-Warning "Could not read directory roles: $($_.Exception.Message)"
    }
}

$result = [pscustomobject]@{
    Timestamp      = (Get-Date).ToString('o')
    Account        = $ctx.Account
    AuthType       = $authType
    Environment    = $Environment
    GraphHost      = (Get-GraphHost $Environment)
    TenantId       = $ctx.TenantId
    Scopes         = @($ctx.Scopes)
    DirectoryRoles = $roles
}

Write-Host ""
Write-Host "Account        : $($result.Account)"
Write-Host "AuthType       : $($result.AuthType)  $(if($result.AuthType -eq 'AppOnly'){'<-- app-only; these endpoints need DELEGATED (Branch B)'})" -ForegroundColor $(if($result.AuthType -eq 'AppOnly'){'Yellow'}else{'Gray'})
Write-Host "TenantId       : $($result.TenantId)"
Write-Host "Scopes         : $($result.Scopes -join ', ')"
Write-Host "DirectoryRoles : $(if($result.DirectoryRoles){$result.DirectoryRoles -join ', '}else{'(none found - see Branch E if you get 403)'})" -ForegroundColor $(if($result.DirectoryRoles){'Gray'}else{'Yellow'})

# Persist a partial finding
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }
$result | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $OutputFolder 'CPADMDX-Preflight.json') -Encoding UTF8
Write-Host ""
Write-Host "Saved: $(Join-Path $OutputFolder 'CPADMDX-Preflight.json')" -ForegroundColor Green

return $result

<#
.SYNOPSIS
    NSCASB-Discovery.ps1 — cloud-app inventory signal and CASB readiness (read-only).
.DESCRIPTION
    PURPOSE
        Builds a starting cloud-app inventory signal by enumerating Entra ID enterprise applications
        (service principals) — a corroborating signal for the sanctioned-app list that Netskope
        discovery refines — and confirms Microsoft Graph connectivity and that scope groups exist.
        The Netskope REST cloud-app discovery pull is flagged and deferred (see the NETSKOPE block).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\NSCASB-Discovery.ps1
        Requires the Microsoft Graph PowerShell SDK and delegated scopes:
        Application.Read.All, Group.Read.All.
    EXPECTED RESULTS
        A list of Entra enterprise applications (cloud apps) and a confirmation that Graph + the
        CASB scope groups are ready. No changes are made (read-only).
.NOTES
    Network / CASB — read-only. Netskope console internals deferred to the official Netskope docs.
#>
[CmdletBinding()] param(
    [string[]] $ScopeGroup = @('CASB Pilot - Pilot users - Pilot','CASB Broad - All users - Expand')
)

Write-Host "`n=== NSCASB Discovery — cloud-app inventory signal (read-only) ===" -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Application.Read.All','Group.Read.All' -NoWelcome

# --- Cloud-app inventory signal: Entra enterprise applications (service principals) ---
Write-Host "`n[Cloud apps — Entra enterprise applications]" -ForegroundColor Cyan
try {
    $apps = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals?`$select=displayName,appId,signInAudience,tags&`$top=999").value
    $apps = $apps | Where-Object { $_.tags -contains 'WindowsAzureActiveDirectoryIntegratedApp' -or $_.signInAudience }
    if ($apps) {
        $apps | Sort-Object displayName | Select-Object -First 200 | ForEach-Object {
            Write-Host ("  {0}  (appId {1})" -f $_.displayName, $_.appId)
        }
        Write-Host ("  Total enterprise applications seen: {0}" -f $apps.Count) -ForegroundColor Green
    } else {
        Write-Host "  No enterprise applications returned." -ForegroundColor Yellow
    }
} catch {
    Write-Host ("  Could not enumerate enterprise applications: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

# --- Scope-group readiness ---
Write-Host "`n[CASB scope groups]" -ForegroundColor Cyan
foreach ($g in $ScopeGroup) {
    try {
        $f = "displayName eq '$($g.Replace("'","''"))'"
        $found = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=$f").value
        if ($found) { Write-Host ("  OK   {0}" -f $g) -ForegroundColor Green }
        else        { Write-Host ("  MISS {0}  (build it with NSCASB-Set-ScopeTargeting.ps1)" -f $g) -ForegroundColor Yellow }
    } catch {
        Write-Host ("  ERR  {0}: {1}" -f $g, $_.Exception.Message) -ForegroundColor Yellow
    }
}

# --- Netskope REST cloud-app discovery (FLAGGED / DEFERRED) ---
Write-Host "`n[Netskope cloud-app discovery — DEFERRED]" -ForegroundColor DarkYellow
Write-Host "  Netskope's own cloud-app discovery and risk scores are the authoritative source." -ForegroundColor DarkYellow
Write-Host "  Pulling them via the Netskope REST API requires a tenant base URL and an API token;" -ForegroundColor DarkYellow
Write-Host "  the exact endpoints/paths are tenant-specific and are deferred to the Netskope docs." -ForegroundColor DarkYellow
# Template (intentionally not invoked — fill in per your Netskope tenant + docs):
# $NetskopeBaseUrl = $env:NETSKOPE_TENANT_URL   # e.g. https://<tenant>.goskope.com
# $NetskopeToken   = $env:NETSKOPE_API_TOKEN
# if ($NetskopeBaseUrl -and $NetskopeToken) {
#     # Invoke-RestMethod -Uri "$NetskopeBaseUrl/<discovery-endpoint-per-Netskope-docs>" `
#     #   -Headers @{ 'Netskope-Api-Token' = $NetskopeToken }
# }

Write-Host "`nReconcile this inventory signal with Netskope discovery into the app risk register." -ForegroundColor Green
Disconnect-MgGraph | Out-Null

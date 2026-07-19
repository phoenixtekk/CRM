<#
.SYNOPSIS
    FIDO2-Discovery.ps1 — tenant authentication-method policy readiness for passwordless/phishing-resistant MFA.
.DESCRIPTION
    PURPOSE
        Reports whether the phishing-resistant methods (FIDO2 security keys, Windows Hello for
        Business, certificate-based authentication) are enabled in the tenant Authentication methods
        policy, and how each is targeted. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\FIDO2-Discovery.ps1
        Requires Microsoft Graph SDK and Policy.Read.All.
    EXPECTED RESULTS
        Per-method enablement state (FIDO2 / WHfB / certificate-based) and the targets configured.
.NOTES
    Entra ID Solutions. Read-only against Graph.
#>
[CmdletBinding()] param()
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Policy.Read.All' -NoWelcome
Write-Host "=== Authentication methods policy ===" -ForegroundColor Cyan
$policy = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/policies/authenticationMethodsPolicy'
$want = @('Fido2','WindowsHelloForBusiness','X509Certificate')
foreach ($cfg in $policy.authenticationMethodConfigurations) {
    if ($want -notcontains $cfg.id) { continue }
    $targets = @()
    if ($cfg.includeTargets) { $targets = $cfg.includeTargets | ForEach-Object { $_.id } }
    Write-Host ("  {0,-24} state: {1,-8} targets: {2}" -f $cfg.id, $cfg.state, ($targets -join ', '))
}
$missing = $want | Where-Object { $id = $_; -not ($policy.authenticationMethodConfigurations | Where-Object { $_.id -eq $id }) }
if ($missing) { Write-Host ("  Not present in policy: {0}" -f ($missing -join ', ')) -ForegroundColor Yellow }
Disconnect-MgGraph | Out-Null

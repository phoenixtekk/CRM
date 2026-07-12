<#
.SYNOPSIS
    ENTVID-Discovery.ps1 — Verified ID posture: service availability, onboarded issuer/authority, credential types.
.DESCRIPTION
    PURPOSE
        Reports the current Entra Verified ID posture: whether the Verifiable Credentials/Verified ID
        admin surface responds for the tenant, the onboarded issuer/authority (DID) if present, and the
        published credential types (contracts). Read-only — it changes nothing. Use it to capture the
        before-state and confirm the service is onboarded before designing credentials.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTVID-Discovery.ps1
        Connects to Microsoft Graph. The Verified ID admin Graph scopes/endpoints can differ by tenant and
        may be preview — VERIFY the exact scope for your tenant. This script requests a read scope and
        degrades gracefully (prints guidance) if the admin surface is not available to it.
    EXPECTED RESULTS
        A summary of tenant context and, where the admin surface is reachable, the issuer authority and
        credential types. Pass = summary prints; a "not available" note means the admin API/scope must be
        verified for your tenant (use the Verified ID blade in the portal to confirm onboarding).
.NOTES
    White-label. Read-only. Verified ID admin API/scopes are VERIFY-flagged (tenant/preview dependent).
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

# NOTE: 'VerifiableCredential.Authority.Read.All' is the documented read scope at time of writing —
# VERIFY the current scope name for your tenant/cloud before relying on it.
try { Connect-MgGraph -Scopes 'VerifiableCredential.Authority.Read.All' -NoWelcome }
catch { Write-Host "Could not consent the Verified ID read scope — VERIFY the current scope for your tenant. Falling back to basic org read." -ForegroundColor Yellow; Connect-MgGraph -Scopes 'Organization.Read.All' -NoWelcome }

$ctx = Get-MgContext
Write-Host "`n=== Entra Verified ID — discovery ===" -ForegroundColor Cyan
Write-Host ("Tenant : {0}" -f $ctx.TenantId)
Write-Host ("Scopes : {0}" -f ($ctx.Scopes -join ', '))

# Try the Verified ID admin authorities endpoint (beta). VERIFY endpoint for your tenant.
$authoritiesUri = '/beta/verifiableCredentials/authorities'
try {
    $auths = @((Invoke-MgGraphRequest -Method GET -Uri $authoritiesUri).value)
    Write-Host ("`n[Issuer authorities]           : {0}" -f $auths.Count) -ForegroundColor Yellow
    foreach ($a in $auths) {
        Write-Host ("  - {0}" -f $a.name)
        Write-Host ("      didModel/DID : {0}" -f ($a.didModel.did))
        Write-Host ("      linkedDomains: {0}" -f (($a.didModel.linkedDomainUrls) -join ', '))
        # Credential contracts (types) for this authority
        try {
            $contracts = @((Invoke-MgGraphRequest -Method GET -Uri "$authoritiesUri/$($a.id)/contracts").value)
            Write-Host ("      credential types: {0}" -f $contracts.Count)
            $contracts | ForEach-Object { Write-Host ("        * {0}" -f $_.name) }
        } catch { Write-Host "      (could not read contracts: $($_.Exception.Message))" -ForegroundColor DarkGray }
    }
    if ($auths.Count -eq 0) { Write-Host "  No issuer authority found — onboard Verified ID in the Entra admin center (Verified ID -> Setup)." -ForegroundColor Yellow }
} catch {
    Write-Host "`n[Issuer authorities] : admin API not available to this session." -ForegroundColor Yellow
    Write-Host "  The Verified ID admin Graph endpoint/scope is tenant- and preview-dependent — VERIFY for your tenant." -ForegroundColor Yellow
    Write-Host "  Confirm onboarding in the portal: Entra admin center -> Verified ID." -ForegroundColor Yellow
}

Write-Host "`nDone. Read-only — no changes were made." -ForegroundColor Green
Disconnect-MgGraph | Out-Null

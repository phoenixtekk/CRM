<#
.SYNOPSIS
    ENTVID-New-IssuanceRequest.ps1 — build (and only on -Submit, POST) a Verified ID issuance request.
.DESCRIPTION
    PURPOSE
        Assembles a Verified ID ISSUANCE request payload for a credential type and, ONLY when -Submit is
        passed, POSTs it to the Verified ID Request Service API to start an issuance (returns a QR/deep
        link for the holder's wallet). By DEFAULT it is BUILD-ONLY: it prints the payload and submits
        nothing, so a dry run never issues a credential. This is the safe preview gate for an operational
        action. Authenticates with the Request Service app's client credentials.
    HOW TO RUN
        Build-only (default): powershell -ExecutionPolicy Bypass -File .\ENTVID-New-IssuanceRequest.ps1 `
                                  -TenantId "<tenant-guid>" -ClientId "<app-guid>" `
                                  -Authority "<issuer-authority>" -CredentialType "VerifiedEmployee" `
                                  -Manifest "https://verifiedid.did.msidentity.com/v1.0/tenants/<t>/verifiableCredentials/contracts/<id>/manifest" `
                                  -CallbackUrl "https://your-app.contoso.com/api/issue/callback"
        Submit:               add -Submit and provide the client secret via the VC_CLIENT_SECRET
                              environment variable (never pass secrets on the command line / in source).
        VERIFY the Request Service API base URL, token scope, and payload schema for your tenant/cloud.
    EXPECTED RESULTS
        Build-only: the JSON issuance request is printed; nothing is sent. -Submit: the Request Service
        response (request id + QR/deep-link URL) is printed. Then complete issuance in Microsoft Authenticator.
.NOTES
    White-label. Operational action GATED behind -Submit (build-only default). Secret read from env, never logged.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$TenantId,
    [Parameter(Mandatory=$true)][string]$ClientId,
    [Parameter(Mandatory=$true)][string]$Authority,
    [string]$CredentialType = 'VerifiedEmployee',
    [Parameter(Mandatory=$true)][string]$Manifest,
    [Parameter(Mandatory=$true)][string]$CallbackUrl,
    [string]$CallbackState = ([guid]::NewGuid().ToString()),
    # VERIFY these for your tenant/cloud before submitting:
    [string]$RequestServiceScope = '3db474b9-6a0c-4840-96ac-1fceb342124f/.default',
    [string]$RequestApiUrl = 'https://verifiedid.did.msidentity.com/v1.0/verifiableCredentials/createIssuanceRequest',
    [switch]$Submit
)

# Assemble the issuance request payload (schema is VERIFY-flagged — confirm against current docs).
$payload = [ordered]@{
    authority     = $Authority
    includeQRCode = $true
    registration  = @{ clientName = 'Issuer/Verifier - Pilot' }
    callback      = @{ url = $CallbackUrl; state = $CallbackState; headers = @{ 'api-key' = '<optional-callback-api-key>' } }
    type          = $CredentialType
    manifest      = $Manifest
    # 'claims' / 'pin' are added per your rules definition when using self-attested / ID-token flows.
}
$json = $payload | ConvertTo-Json -Depth 8

Write-Host "`n=== ENTVID — issuance request (BUILD-ONLY unless -Submit) ===" -ForegroundColor Cyan
Write-Host "Credential type : $CredentialType" -ForegroundColor Yellow
Write-Host "Authority       : $Authority" -ForegroundColor Yellow
Write-Host "Callback        : $CallbackUrl (state $CallbackState)" -ForegroundColor Yellow
Write-Host "`n--- Request payload ---" -ForegroundColor DarkGray
Write-Host $json

if (-not $Submit) {
    Write-Host "`nMODE: BUILD-ONLY. Nothing was submitted and no credential was issued." -ForegroundColor Green
    Write-Host "Review the payload above, then re-run with -Submit (secret via `$env:VC_CLIENT_SECRET) to issue." -ForegroundColor Green
    return
}

# --- Submit path (only reached with -Submit) ---
$secret = $env:VC_CLIENT_SECRET
if ([string]::IsNullOrWhiteSpace($secret)) { Write-Host "ERROR: set the client secret in `$env:VC_CLIENT_SECRET before using -Submit (never pass it on the command line)." -ForegroundColor Red; exit 1 }

Write-Host "`nMODE: SUBMIT — acquiring a Request Service token (client credentials)..." -ForegroundColor Yellow
try {
    $tokenBody = @{ client_id = $ClientId; scope = $RequestServiceScope; client_secret = $secret; grant_type = 'client_credentials' }
    $tok = Invoke-RestMethod -Method POST -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body $tokenBody -ContentType 'application/x-www-form-urlencoded'
    $resp = Invoke-RestMethod -Method POST -Uri $RequestApiUrl -Headers @{ Authorization = "Bearer $($tok.access_token)"; 'Content-Type' = 'application/json' } -Body $json
    Write-Host "Submitted. Request Service response:" -ForegroundColor Green
    $resp | ConvertTo-Json -Depth 8 | Write-Host
    Write-Host "`nOpen the returned QR/deep link in Microsoft Authenticator to complete issuance." -ForegroundColor Green
} catch {
    Write-Host "Submit failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "VERIFY the token scope, Request API URL, and payload schema for your tenant/cloud." -ForegroundColor Yellow
    exit 1
}
finally { $secret = $null; Remove-Variable secret -ErrorAction SilentlyContinue }

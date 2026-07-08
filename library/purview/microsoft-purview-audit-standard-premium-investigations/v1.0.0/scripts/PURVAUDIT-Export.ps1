<#
.SYNOPSIS
    PURVAUDIT-Export.ps1 — Office 365 Management Activity API content subscriptions helper (read-only default).
.DESCRIPTION
    PURPOSE
        Lists, starts, or stops Office 365 Management Activity API content subscriptions so audit data
        can stream to a SIEM. SAFE BY DEFAULT: -Action ListSubscriptions is read-only; StartSubscription
        / StopSubscription only change state with -Commit (otherwise they preview). Authenticates
        app-only with a CERTIFICATE (thumbprint) — never a client secret in code.
    HOW TO RUN
        # List current subscriptions (read-only):
        powershell -File .\PURVAUDIT-Export.ps1 -TenantId <guid> -AppId <guid> -CertificateThumbprint <thumb> -Action ListSubscriptions
        # Start a content type (preview then commit):
        .\PURVAUDIT-Export.ps1 -TenantId <guid> -AppId <guid> -CertificateThumbprint <thumb> `
            -Action StartSubscription -ContentType Audit.AzureActiveDirectory -WhatIf
        .\PURVAUDIT-Export.ps1 ... -Action StartSubscription -ContentType Audit.AzureActiveDirectory -Commit
        Requires an Entra app registration with ActivityFeed.Read (ActivityFeed.ReadDlp for DLP), admin-
        consented, and a certificate uploaded to the app (private key available locally by thumbprint).
        Native SIEM connectors (e.g. Microsoft Sentinel) are a lower-effort alternative to this raw API.
    EXPECTED RESULTS
        ListSubscriptions: the content types currently enabled. Start/Stop under -Commit: the API
        confirms the subscription state; under -WhatIf: the exact call that would be made.
.NOTES
    Purview category — Audit. Certificate app-only auth; NO secrets in code. Management Activity API is
    the manage.office.com resource. Confirm the app permissions/consent and content-type availability
    for your tenant. ContentType one of: Audit.AzureActiveDirectory, Audit.Exchange, Audit.SharePoint,
    Audit.General, DLP.All.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$TenantId,
    [Parameter(Mandatory)] [string]$AppId,
    [Parameter(Mandatory)] [string]$CertificateThumbprint,
    [ValidateSet('ListSubscriptions','StartSubscription','StopSubscription','ListAvailableContent')]
    [string]$Action = 'ListSubscriptions',
    [ValidateSet('Audit.AzureActiveDirectory','Audit.Exchange','Audit.SharePoint','Audit.General','DLP.All')]
    [string]$ContentType,
    [switch]$Commit
)

$ErrorActionPreference = 'Stop'
$apply = $Commit.IsPresent
$resource = 'https://manage.office.com'
$base = "$resource/api/v1.0/$TenantId/activity/feed"

# --- Acquire an app-only token via certificate (client_assertion, no secret) ---
function Get-Cert {
    $c = Get-Item "Cert:\CurrentUser\My\$CertificateThumbprint" -ErrorAction SilentlyContinue
    if (-not $c) { $c = Get-Item "Cert:\LocalMachine\My\$CertificateThumbprint" -ErrorAction SilentlyContinue }
    if (-not $c) { throw "Certificate $CertificateThumbprint not found in CurrentUser/LocalMachine My store (private key required)." }
    return $c
}
function New-JwtAssertion($cert,$aud,$clientId) {
    function B64Url([byte[]]$b){ [Convert]::ToBase64String($b).TrimEnd('=').Replace('+','-').Replace('/','_') }
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $x5t = B64Url ($cert.GetCertHash())
    $header = @{ alg='RS256'; typ='JWT'; x5t=$x5t } | ConvertTo-Json -Compress
    $payload = @{ aud=$aud; iss=$clientId; sub=$clientId; jti=[guid]::NewGuid().ToString(); nbf=$now; exp=($now+600) } | ConvertTo-Json -Compress
    $unsigned = (B64Url ([Text.Encoding]::UTF8.GetBytes($header))) + '.' + (B64Url ([Text.Encoding]::UTF8.GetBytes($payload)))
    $rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
    $sig = $rsa.SignData([Text.Encoding]::UTF8.GetBytes($unsigned), [Security.Cryptography.HashAlgorithmName]::SHA256, [Security.Cryptography.RSASignaturePadding]::Pkcs1)
    return $unsigned + '.' + (B64Url $sig)
}
function Get-Token {
    $cert = Get-Cert
    $tokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    $assertion = New-JwtAssertion $cert $tokenUri $AppId
    $body = @{
        client_id             = $AppId
        scope                 = "$resource/.default"
        grant_type            = 'client_credentials'
        client_assertion_type = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
        client_assertion      = $assertion
    }
    (Invoke-RestMethod -Method POST -Uri $tokenUri -Body $body -ContentType 'application/x-www-form-urlencoded').access_token
}

$token = Get-Token
$headers = @{ Authorization = "Bearer $token" }

switch ($Action) {
    'ListSubscriptions' {
        $subs = Invoke-RestMethod -Method GET -Uri "$base/subscriptions/list" -Headers $headers
        Write-Host "=== Current content subscriptions ===" -ForegroundColor Cyan
        if ($subs) { $subs | Format-Table contentType, status -AutoSize | Out-String | Write-Host }
        else { Write-Host "No subscriptions enabled." -ForegroundColor Yellow }
    }
    'ListAvailableContent' {
        if (-not $ContentType) { Write-Host "Provide -ContentType." -ForegroundColor Red; break }
        $c = Invoke-RestMethod -Method GET -Uri "$base/subscriptions/content?contentType=$ContentType" -Headers $headers
        Write-Host ("Available content blobs for {0}: {1}" -f $ContentType, (@($c).Count)) -ForegroundColor Green
    }
    'StartSubscription' {
        if (-not $ContentType) { Write-Host "Provide -ContentType." -ForegroundColor Red; break }
        if ($apply) {
            $r = Invoke-RestMethod -Method POST -Uri "$base/subscriptions/start?contentType=$ContentType" -Headers $headers
            Write-Host ("[COMMIT] Started subscription: {0} status={1}" -f $ContentType, $r.status) -ForegroundColor Green
        } else { Write-Host ("[WHATIF] Would POST subscriptions/start?contentType={0}" -f $ContentType) -ForegroundColor Yellow }
    }
    'StopSubscription' {
        if (-not $ContentType) { Write-Host "Provide -ContentType." -ForegroundColor Red; break }
        if ($apply) {
            Invoke-RestMethod -Method POST -Uri "$base/subscriptions/stop?contentType=$ContentType" -Headers $headers | Out-Null
            Write-Host ("[COMMIT] Stopped subscription: {0}" -f $ContentType) -ForegroundColor Green
        } else { Write-Host ("[WHATIF] Would POST subscriptions/stop?contentType={0}" -f $ContentType) -ForegroundColor Yellow }
    }
}
if (-not $apply -and $Action -in 'StartSubscription','StopSubscription') { Write-Host "`nNo change made (default). Re-run with -Commit to apply." -ForegroundColor Cyan }

<#
.SYNOPSIS
    AUDSIEM-Configure-Subscription.ps1 — Start/stop Management Activity API content subscriptions, optional webhook (WhatIf default).
.DESCRIPTION
    PURPOSE
        Manages Office 365 Management Activity API content subscriptions so audit data streams to a SIEM.
        SAFE BY DEFAULT: previews the exact API call and makes NO change unless -Commit is passed. Supports
        push delivery by attaching a -WebhookAddress at Start (the API performs a validation handshake against
        that endpoint). Authenticates app-only with a CERTIFICATE (thumbprint) — never a client secret in code.
        This is the ONLY state-changing tool in the set; all others are read-only.
    HOW TO RUN
        # Preview starting the Entra content type (no change):
        powershell -File .\AUDSIEM-Configure-Subscription.ps1 -TenantId <guid> -AppId <guid> `
            -CertificateThumbprint <thumb> -ContentType Audit.AzureActiveDirectory -Action Start -WhatIf
        # Start with a push webhook, then commit:
        .\AUDSIEM-Configure-Subscription.ps1 ... -ContentType Audit.AzureActiveDirectory -Action Start `
            -WebhookAddress https://your-collector.example.com/api/o365feed -Commit
        # Stop (rollback) a content type:
        .\AUDSIEM-Configure-Subscription.ps1 ... -ContentType Audit.Exchange -Action Stop -Commit
        Requires an Entra app with Office 365 Management APIs ActivityFeed.Read (ActivityFeed.ReadDlp for DLP),
        admin-consented, and a certificate uploaded to the app (private key on this host by thumbprint).
        PowerShell 5.1+/7+.
    EXPECTED RESULTS
        Under -WhatIf: prints the exact POST it would make. Under -Commit: the API confirms the subscription
        status (Start => enabled with webhook if supplied; Stop => disabled). Your webhook endpoint must
        answer the validation handshake for a push subscription to enable.
.NOTES
    Purview category — Audit → SIEM integration. Certificate app-only auth; NO secrets in code. Resource is
    https://manage.office.com. Webhook subscriptions EXPIRE and must be renewed (monitor per the Testing
    Guide). Prefer a native connector where available. ContentType: Audit.AzureActiveDirectory, Audit.Exchange,
    Audit.SharePoint, Audit.General, DLP.All. Verify licensing/tenant for API bandwidth/availability.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$TenantId,
    [Parameter(Mandatory)][string]$AppId,
    [Parameter(Mandatory)][string]$CertificateThumbprint,
    [Parameter(Mandatory)]
    [ValidateSet('Audit.AzureActiveDirectory','Audit.Exchange','Audit.SharePoint','Audit.General','DLP.All')]
    [string]$ContentType,
    [ValidateSet('Start','Stop')][string]$Action = 'Start',
    [string]$WebhookAddress,
    [string]$WebhookAuthId = "AUDSIEM-$([guid]::NewGuid().ToString('N').Substring(0,8))",
    [switch]$WhatIf,
    [switch]$Commit
)

$ErrorActionPreference = 'Stop'
$apply = $Commit.IsPresent -and -not $WhatIf.IsPresent
$resource = 'https://manage.office.com'
$base = "$resource/api/v1.0/$TenantId/activity/feed"

function Get-AudSiemToken {
    param([string]$TenantId,[string]$AppId,[string]$CertificateThumbprint,[string]$Resource='https://manage.office.com')
    $cert = Get-Item "Cert:\CurrentUser\My\$CertificateThumbprint" -ErrorAction SilentlyContinue
    if (-not $cert) { $cert = Get-Item "Cert:\LocalMachine\My\$CertificateThumbprint" -ErrorAction SilentlyContinue }
    if (-not $cert) { throw "Certificate $CertificateThumbprint not found in CurrentUser/LocalMachine My store (private key required)." }
    function B64Url([byte[]]$b){ [Convert]::ToBase64String($b).TrimEnd('=').Replace('+','-').Replace('/','_') }
    $tokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $header  = @{ alg='RS256'; typ='JWT'; x5t=(B64Url ($cert.GetCertHash())) } | ConvertTo-Json -Compress
    $payload = @{ aud=$tokenUri; iss=$AppId; sub=$AppId; jti=[guid]::NewGuid().ToString(); nbf=$now; exp=($now+600) } | ConvertTo-Json -Compress
    $unsigned = (B64Url ([Text.Encoding]::UTF8.GetBytes($header))) + '.' + (B64Url ([Text.Encoding]::UTF8.GetBytes($payload)))
    $rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
    $sig = $rsa.SignData([Text.Encoding]::UTF8.GetBytes($unsigned), [Security.Cryptography.HashAlgorithmName]::SHA256, [Security.Cryptography.RSASignaturePadding]::Pkcs1)
    $body = @{ client_id=$AppId; scope="$Resource/.default"; grant_type='client_credentials'
        client_assertion_type='urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
        client_assertion=($unsigned + '.' + (B64Url $sig)) }
    (Invoke-RestMethod -Method POST -Uri $tokenUri -Body $body -ContentType 'application/x-www-form-urlencoded').access_token
}

$token = Get-AudSiemToken -TenantId $TenantId -AppId $AppId -CertificateThumbprint $CertificateThumbprint -Resource $resource
$headers = @{ Authorization = "Bearer $token" }

if ($Action -eq 'Start') {
    $uri = "$base/subscriptions/start?contentType=$ContentType"
    $webhookBody = $null
    if ($WebhookAddress) {
        $webhookBody = @{ webhook = @{ address = $WebhookAddress; authId = $WebhookAuthId; expiration = '' } } | ConvertTo-Json -Compress
        Write-Host ("Push delivery: webhook -> {0} (authId={1})" -f $WebhookAddress, $WebhookAuthId) -ForegroundColor DarkGray
    }
    if ($apply) {
        if ($webhookBody) {
            $r = Invoke-RestMethod -Method POST -Uri $uri -Headers $headers -Body $webhookBody -ContentType 'application/json'
        } else {
            $r = Invoke-RestMethod -Method POST -Uri $uri -Headers $headers
        }
        Write-Host ("[COMMIT] Start {0}: status={1}" -f $ContentType, $r.status) -ForegroundColor Green
    } else {
        Write-Host ("[WHATIF] Would POST {0}" -f $uri) -ForegroundColor Yellow
        if ($webhookBody) { Write-Host ("[WHATIF] With webhook body: {0}" -f $webhookBody) -ForegroundColor Yellow }
    }
}
elseif ($Action -eq 'Stop') {
    $uri = "$base/subscriptions/stop?contentType=$ContentType"
    if ($apply) {
        Invoke-RestMethod -Method POST -Uri $uri -Headers $headers | Out-Null
        Write-Host ("[COMMIT] Stopped {0}" -f $ContentType) -ForegroundColor Green
    } else {
        Write-Host ("[WHATIF] Would POST {0}" -f $uri) -ForegroundColor Yellow
    }
}

if (-not $apply) { Write-Host "`nNo change made (default). Re-run with -Commit (and without -WhatIf) to apply." -ForegroundColor Cyan }

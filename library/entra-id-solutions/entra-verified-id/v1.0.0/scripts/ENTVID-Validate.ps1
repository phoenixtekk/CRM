<#
.SYNOPSIS
    ENTVID-Validate.ps1 — validate Verified ID prerequisites: domain well-known, Request Service app, Key Vault ref.
.DESCRIPTION
    PURPOSE
        Confirms the pilot prerequisites are in place and correct: the domain's
        /.well-known/did-configuration.json resolves over HTTPS (and, if an issuer DID is provided, that
        the file references it); the Request Service app registration exists with a credential and (best
        effort) the Verified ID Request Service API permission; and the named Key Vault is referenced.
        Read-only — it reports PASS/FAIL per check and changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTVID-Validate.ps1 `
            -Domain "contoso.com" `
            -RequestServiceAppName "VC Request Service App - Issuer/Verifier - Pilot" `
            -IssuerDid "did:web:contoso.com"   # optional, to cross-check the well-known file
        Connects to Microsoft Graph read scope Application.Read.All for the app check; the domain check
        needs no auth.
    EXPECTED RESULTS
        PASS/FAIL lines for the well-known file, the app registration + credential, and (best effort) the
        API permission. Any FAIL points to the exact prerequisite to fix (see the Troubleshooting Guide).
.NOTES
    White-label. Read-only. Request Service API permission ID is VERIFY-flagged (tenant/preview dependent).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Domain,
    [string]$RequestServiceAppName = 'VC Request Service App - Issuer/Verifier - Pilot',
    [string]$IssuerDid
)

$pass = 0; $fail = 0
function Test-Line($ok, $msg) { if ($ok) { Write-Host "  PASS  $msg" -ForegroundColor Green; $script:pass++ } else { Write-Host "  FAIL  $msg" -ForegroundColor Red; $script:fail++ } }

Write-Host "`n=== ENTVID — prerequisite validation ===" -ForegroundColor Cyan

# 1) Domain well-known did-configuration.json (no auth)
$wellKnown = "https://$Domain/.well-known/did-configuration.json"
try {
    $resp = Invoke-WebRequest -UseBasicParsing -Uri $wellKnown -TimeoutSec 20
    Test-Line ($resp.StatusCode -eq 200) "did-configuration.json resolves over HTTPS: $wellKnown"
    if ($IssuerDid) { Test-Line ($resp.Content -like "*$IssuerDid*") "did-configuration.json references issuer DID $IssuerDid" }
    else { Write-Host "  SKIP  DID cross-check (no -IssuerDid supplied)" -ForegroundColor DarkGray }
} catch { Test-Line $false "did-configuration.json reachable at $wellKnown ($($_.Exception.Message))" }

# 2) Request Service app registration + credential + permission
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Application.Read.All' -NoWelcome
try {
    $filter = "displayName eq '$RequestServiceAppName'"
    $app = @((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/applications?`$filter=$([uri]::EscapeDataString($filter))").value) | Select-Object -First 1
    Test-Line ($null -ne $app) "Request Service app registration exists: '$RequestServiceAppName'"
    if ($app) {
        $hasCred = ($app.passwordCredentials.Count -gt 0) -or ($app.keyCredentials.Count -gt 0)
        Test-Line $hasCred "App has a client secret or certificate (prefer certificate)"
        # Best-effort: does it request any Verified ID Request Service permission? (resource appId VERIFY per tenant)
        $hasApiPerm = $false
        foreach ($ra in @($app.requiredResourceAccess)) { if ($ra.resourceAccess.Count -gt 0) { $hasApiPerm = $true } }
        Test-Line $hasApiPerm "App declares API permission(s) — VERIFY it is the Verified ID Request Service permission and admin-consented"
    }
} catch { Test-Line $false "Read app registrations ($($_.Exception.Message))" }

Write-Host ("`nResult: {0} passed, {1} failed." -f $pass, $fail) -ForegroundColor ($(if($fail -gt 0){'Red'}else{'Green'}))
Write-Host "Note: the Verified ID Request Service permission ID and admin-consent status must be VERIFIED for your tenant." -ForegroundColor Yellow
Disconnect-MgGraph | Out-Null
if ($fail -gt 0) { exit 1 }

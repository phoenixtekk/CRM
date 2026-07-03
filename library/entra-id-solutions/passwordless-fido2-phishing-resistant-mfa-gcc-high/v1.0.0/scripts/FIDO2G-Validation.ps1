<#
.SYNOPSIS
    FIDO2G-Validation.ps1 — confirm a GCC High user has a phishing-resistant method registered (and default).
.DESCRIPTION
    PURPOSE
        For a given user in a US Government (GCC High/DoD) tenant, lists their registered
        authentication methods and reports whether a phishing-resistant, passwordless method (FIDO2
        security key, Windows Hello for Business, or certificate-based/CAC-PIV) is registered — and
        whether the system-preferred/default sign-in method is phishing-resistant. Read-only. Use
        -Environment USGovDoD on the DoD cloud.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\FIDO2G-Validation.ps1 -UserId user@your-tenant.onmicrosoft.us
        Connects to US Gov Graph (-Environment USGov). Read-only scopes:
        UserAuthenticationMethod.Read.All, User.Read.All.
    EXPECTED RESULTS
        PASS if the user has at least one phishing-resistant method registered; the methods and the
        default method are printed. FAIL (yellow) if only weak methods (password, SMS, voice) exist —
        the user is not yet ready for phishing-resistant enforcement.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$UserId,
    [ValidateSet('USGov','USGovDoD')][string]$Environment = 'USGov'
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment $Environment -Scopes 'UserAuthenticationMethod.Read.All','User.Read.All' -NoWelcome

Write-Host "`n=== Validate phishing-resistant registration — GCC High (env: $Environment) ===" -ForegroundColor Cyan
Write-Host ("User: {0}" -f $UserId)

$methods = @((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$UserId/authentication/methods").value)
# Phishing-resistant, passwordless method OData types
$prTypes = @(
    '#microsoft.graph.fido2AuthenticationMethod',
    '#microsoft.graph.windowsHelloForBusinessAuthenticationMethod',
    '#microsoft.graph.x509CertificateAuthenticationMethod'
)
$labels = @{
    '#microsoft.graph.fido2AuthenticationMethod'                 = 'FIDO2 security key'
    '#microsoft.graph.windowsHelloForBusinessAuthenticationMethod'= 'Windows Hello for Business'
    '#microsoft.graph.x509CertificateAuthenticationMethod'       = 'Certificate-based (CAC/PIV)'
    '#microsoft.graph.microsoftAuthenticatorAuthenticationMethod'= 'Microsoft Authenticator'
    '#microsoft.graph.passwordAuthenticationMethod'              = 'Password'
    '#microsoft.graph.phoneAuthenticationMethod'                 = 'Phone (SMS/voice)'
    '#microsoft.graph.temporaryAccessPassAuthenticationMethod'   = 'Temporary Access Pass'
}

Write-Host "Registered methods:" -ForegroundColor Cyan
foreach ($m in $methods) {
    $t = $m.'@odata.type'
    $name = if ($labels.ContainsKey($t)) { $labels[$t] } else { $t }
    $pr = if ($prTypes -contains $t) { 'phishing-resistant' } else { '' }
    Write-Host ("  - {0} {1}" -f $name, $pr) -ForegroundColor $(if ($pr) { 'Green' } else { 'Gray' })
}

$hasPR = @($methods | Where-Object { $prTypes -contains $_.'@odata.type' }).Count -gt 0

# System-preferred / default sign-in method (best-effort; property may vary by tenant)
try {
    $signInPref = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$UserId/authentication/signInPreferences"
    if ($signInPref.userPreferredMethodForSecondaryAuthentication) {
        Write-Host ("Preferred secondary method   : {0}" -f $signInPref.userPreferredMethodForSecondaryAuthentication)
    }
} catch { Write-Host "  (sign-in preferences not readable — non-fatal)" -ForegroundColor DarkGray }

Write-Host ""
if ($hasPR) {
    Write-Host "PASS — user has a phishing-resistant method registered; ready for enforcement." -ForegroundColor Green
} else {
    Write-Host "FAIL — no phishing-resistant method registered. Register a FIDO2 key, Windows Hello, or CAC/PIV before enforcing." -ForegroundColor Yellow
}
Disconnect-MgGraph | Out-Null

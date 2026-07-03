<#
.SYNOPSIS
    FIDO2G-Discovery.ps1 — GCC High passwordless/phishing-resistant posture: FIDO2, Windows Hello, CBA method policy.
.DESCRIPTION
    PURPOSE
        Reports the current authentication-methods posture in a US Government (GCC High/DoD) tenant:
        whether FIDO2 security keys, Windows Hello for Business, certificate-based authentication, and
        Temporary Access Pass are enabled and who they target, plus which authentication strengths
        exist. Read-only. Use -Environment USGovDoD on the DoD cloud.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\FIDO2G-Discovery.ps1
        Connects to US Gov Graph (-Environment USGov). Read-only scopes:
        Policy.Read.All, Policy.Read.ConditionalAccess.
    EXPECTED RESULTS
        Per-method enabled state and target scope, TAP presence (verify for GCC High), and a list of
        authentication strengths. Pass = posture printed against graph.microsoft.us; fail = a
        connection/redirect error means -Environment was omitted (SDK hit the Commercial endpoint).
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding()] param([ValidateSet('USGov','USGovDoD')][string]$Environment = 'USGov')
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment $Environment -Scopes 'Policy.Read.All','Policy.Read.ConditionalAccess' -NoWelcome

Write-Host "`n=== Passwordless / phishing-resistant posture — GCC High (env: $Environment) ===" -ForegroundColor Cyan

$policy = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/policies/authenticationMethodsPolicy'
$configs = @($policy.authenticationMethodConfigurations)

function Show-Method([string]$id, [string]$label) {
    $m = $configs | Where-Object { $_.id -eq $id } | Select-Object -First 1
    if (-not $m) { Write-Host ("  {0,-28}: not present (verify for GCC High)" -f $label) -ForegroundColor Yellow; return }
    $state = $m.state
    $color = $(if ($state -eq 'enabled') { 'Green' } else { 'Yellow' })
    Write-Host ("  {0,-28}: {1}" -f $label, $state) -ForegroundColor $color
    $inc = @($m.includeTargets)
    if ($inc.Count) { $inc | ForEach-Object { Write-Host ("      target: {0} ({1})" -f $_.id, $_.targetType) } }
}

Write-Host "Authentication methods:" -ForegroundColor Cyan
Show-Method 'Fido2'                       'FIDO2 security key'
Show-Method 'WindowsHelloForBusiness'     'Windows Hello for Business'
Show-Method 'X509Certificate'             'Certificate-based auth (CAC/PIV)'
Show-Method 'TemporaryAccessPass'         'Temporary Access Pass'

# FIDO2 AAGUID restriction detail
$fido = $configs | Where-Object { $_.id -eq 'Fido2' } | Select-Object -First 1
if ($fido) {
    $restricted = $fido.isAttestationEnforced
    Write-Host ("  FIDO2 attestation enforced  : {0}" -f $restricted)
    if ($fido.keyRestrictions) {
        Write-Host ("  FIDO2 key restriction       : enforced={0} type={1} count={2}" -f `
            $fido.keyRestrictions.isEnforced, $fido.keyRestrictions.enforcementType, @($fido.keyRestrictions.aaGuids).Count)
    }
}

# Authentication strengths
Write-Host "`nAuthentication strengths:" -ForegroundColor Cyan
$strengths = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/policies/authenticationStrengthPolicies').value)
Write-Host ("  Total strengths             : {0}" -f $strengths.Count)
$strengths | Select-Object -First 25 | ForEach-Object {
    Write-Host ("  - {0} [{1}] methods: {2}" -f $_.displayName, $_.policyType, ((@($_.allowedCombinations)) -join ', '))
}

Write-Host "`nReminder: FIDO2 / Windows Hello / CBA / Conditional Access are GA in US Gov;" -ForegroundColor DarkCyan
Write-Host "TAP, registration campaign, and Authenticator/synced passkeys are 'verify for GCC High'." -ForegroundColor DarkCyan
Disconnect-MgGraph | Out-Null

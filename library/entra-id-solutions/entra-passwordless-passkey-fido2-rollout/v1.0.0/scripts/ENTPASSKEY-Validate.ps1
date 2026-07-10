<#
.SYNOPSIS
    ENTPASSKEY-Validate.ps1 — confirm the passwordless methods, TAP, and phishing-resistant CA policies.
.DESCRIPTION
    PURPOSE
        Read-only check that the rollout controls are in place: (1) FIDO2 security key and
        Passkey/Microsoft Authenticator are enabled and targeted; (2) Temporary Access Pass is enabled
        (the recovery safety net); (3) at least one Conditional Access policy applies the
        phishing-resistant authentication strength; and (4) the break-glass accounts are excluded from
        those CA policies. Prints PASS/WARN lines.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTPASSKEY-Validate.ps1 -BreakGlassUpn bg1@contoso.onmicrosoft.com,bg2@contoso.onmicrosoft.com
        Consents to Policy.Read.All, User.Read.All (read-only). No changes are made.
    EXPECTED RESULTS
        PASS/WARN for each control and a warning if any phishing-resistant CA policy does NOT exclude a
        named break-glass account. Nothing is modified.
.NOTES
    White-label — Entra ID Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string[]]$BreakGlassUpn
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Policy.Read.All','User.Read.All' -NoWelcome

Write-Host "`n=== Passwordless Rollout Validation — $(Get-Date -Format s) ===" -ForegroundColor Cyan

$amp = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/policies/authenticationMethodsPolicy'
function Get-MethodState($id) { ($amp.authenticationMethodConfigurations | Where-Object { $_.id -eq $id }).state }

# 1. Methods enabled
Write-Host "`n-- Passwordless methods --" -ForegroundColor Cyan
foreach ($m in 'Fido2','MicrosoftAuthenticator','TemporaryAccessPass') {
    $s = Get-MethodState $m
    if ($s -eq 'enabled') { Write-Host ("  PASS: {0} enabled" -f $m) -ForegroundColor Green }
    else { Write-Host ("  WARN: {0} is '{1}' — enable it" -f $m, $s) -ForegroundColor Yellow }
}
Write-Host "  NOTE: confirm the Passkey option under Microsoft Authenticator is enabled (verify preview/availability in your tenant)." -ForegroundColor DarkGray

# 2. Resolve break-glass ids
$bgIds = @()
foreach ($upn in $BreakGlassUpn) {
    $u = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$upn?`$select=id,userPrincipalName" -ErrorAction SilentlyContinue
    if ($u.id) { $bgIds += $u.id }
}

# 3. Phishing-resistant CA policies + break-glass exclusion
Write-Host "`n-- Phishing-resistant Conditional Access --" -ForegroundColor Cyan
$caPolicies = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
$prPolicies = $caPolicies | Where-Object { $_.grantControls.authenticationStrength.id -or ($_.grantControls.builtInControls -contains 'mfa') }
if (-not $prPolicies) { Write-Host "  WARN: no CA policy requires MFA / phishing-resistant strength." -ForegroundColor Yellow }
foreach ($p in $prPolicies) {
    $isStrength = [bool]$p.grantControls.authenticationStrength.id
    $label = if ($isStrength) { "phishing-resistant strength" } else { "builtin mfa (consider upgrading to phishing-resistant strength)" }
    Write-Host ("  • {0}  [state={1}]  {2}" -f $p.displayName, $p.state, $label) -ForegroundColor White
    $excluded = @($p.conditions.users.excludeUsers)
    foreach ($bg in $bgIds) {
        if ($excluded -contains $bg) { Write-Host ("      PASS: break-glass {0} excluded" -f $bg) -ForegroundColor Green }
        else { Write-Host ("      WARN: break-glass {0} NOT excluded from this policy" -f $bg) -ForegroundColor Red }
    }
}

Write-Host "`nProceed to Enforce only when the report-only impact is clean and break-glass is excluded everywhere." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null

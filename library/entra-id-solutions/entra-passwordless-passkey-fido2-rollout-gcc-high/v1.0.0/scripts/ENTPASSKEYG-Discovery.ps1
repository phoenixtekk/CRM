<#
.SYNOPSIS
    ENTPASSKEYG-Discovery.ps1 — inventory the authentication methods policy and passwordless readiness.
.DESCRIPTION
    PURPOSE
        Read-only assessment of the current passwordless posture: which authentication methods are
        enabled and to whom they are targeted (FIDO2 security key, Passkey/Microsoft Authenticator,
        Temporary Access Pass, and the weak methods SMS and Voice), the registration-campaign state,
        and the Conditional Access policies that require MFA. This is your before baseline.
    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        powershell -ExecutionPolicy Bypass -File .\ENTPASSKEYG-Discovery.ps1
        Consents to Policy.Read.All (read-only). No changes are made.
        GCC High / US Gov: Connect-MgGraph uses -Environment USGov (login.microsoftonline.us / graph.microsoft.us).
        For DoD (IL5) use -Environment USGovDoD (dod-graph.microsoft.us). *Verify the correct cloud for your tenant.*
    EXPECTED RESULTS
        A per-method enabled/targeted listing, the registration campaign state, and a list of CA
        policies that apply an MFA / authentication-strength grant. Nothing is modified.
.NOTES
    White-label — Entra ID Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string]$CsvPath
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
# US Government cloud (GCC High). For DoD (IL5) use -Environment USGovDoD (dod-graph.microsoft.us).
Connect-MgGraph -Environment USGov -Scopes 'Policy.Read.All' -NoWelcome

Write-Host "`n=== Passwordless Readiness Discovery — $(Get-Date -Format s) ===" -ForegroundColor Cyan

# --- Authentication methods policy ---
$amp = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/policies/authenticationMethodsPolicy'
$configs = $amp.authenticationMethodConfigurations
$interesting = 'Fido2','MicrosoftAuthenticator','TemporaryAccessPass','Sms','Voice','Email','Software oath'
$rows = @()

Write-Host "`n-- Authentication methods --" -ForegroundColor Cyan
foreach ($c in $configs) {
    $id = $c.id
    $state = $c.state
    $targets = @()
    if ($c.includeTargets) { $targets = @($c.includeTargets | ForEach-Object { $_.id }) }
    $flag = switch ($id) {
        'Fido2'                 { if ($state -eq 'enabled') { 'OK' } else { 'ACTION: enable for passwordless' } }
        'MicrosoftAuthenticator'{ if ($state -eq 'enabled') { 'OK (verify passkey option enabled)' } else { 'ACTION: enable + passkey' } }
        'TemporaryAccessPass'   { if ($state -eq 'enabled') { 'OK (recovery safety net)' } else { 'ACTION: enable BEFORE rollout' } }
        'Sms'                   { if ($state -eq 'enabled') { 'WEAK: retire LAST, after adoption' } else { 'retired' } }
        'Voice'                 { if ($state -eq 'enabled') { 'WEAK: retire LAST, after adoption' } else { 'retired' } }
        default                 { '' }
    }
    $color = if ($flag -like 'ACTION*') { 'Yellow' } elseif ($flag -like 'WEAK*') { 'Magenta' } else { 'Green' }
    Write-Host ("  {0,-24} state={1,-9} targets={2} {3}" -f $id, $state, ($(if($targets){$targets -join ','}else{'<none>'}), $flag)) -ForegroundColor $color
    $rows += [pscustomobject]@{ Method=$id; State=$state; Targets=($targets -join ';'); Note=$flag }
}

# --- Registration campaign (Authenticator) ---
Write-Host "`n-- Registration campaign --" -ForegroundColor Cyan
$auth = $configs | Where-Object { $_.id -eq 'MicrosoftAuthenticator' }
$campaign = $auth.featureSettings.registrationEnforcement ?? $amp.registrationEnforcement
$campState = $amp.registrationEnforcement.authenticationMethodsRegistrationCampaign.state
Write-Host ("  campaign state: {0}" -f ($(if($campState){$campState}else{'<not set>'})))

# --- Conditional Access policies requiring MFA / auth strength ---
Write-Host "`n-- Conditional Access policies with an MFA / auth-strength grant --" -ForegroundColor Cyan
$caPolicies = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
foreach ($p in $caPolicies) {
    $builtIn = @($p.grantControls.builtInControls)
    $strengthId = $p.grantControls.authenticationStrength.id
    if (($builtIn -contains 'mfa') -or $strengthId) {
        $grant = if ($strengthId) { "authStrength=$strengthId" } else { 'builtin mfa' }
        Write-Host ("  • {0}  [state={1}]  {2}" -f $p.displayName, $p.state, $grant) -ForegroundColor White
    }
}

if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host "`nExported to $CsvPath" -ForegroundColor Green }
Write-Host "`nReview: FIDO2 + Passkey enabled/targeted, TAP enabled, SMS/Voice still on until adoption is proven." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null

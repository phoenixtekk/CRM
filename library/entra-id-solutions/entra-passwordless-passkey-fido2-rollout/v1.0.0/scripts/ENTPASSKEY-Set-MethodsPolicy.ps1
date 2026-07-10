<#
.SYNOPSIS
    ENTPASSKEY-Set-MethodsPolicy.ps1 — safely enable FIDO2 + Passkey and target them at rollout groups.
.DESCRIPTION
    PURPOSE
        Enables the passwordless methods for the pilot in the authentication methods policy: FIDO2
        security key and Microsoft Authenticator (passkey), targeted at the named rollout groups, and
        confirms Temporary Access Pass is enabled first. Defaults to -WhatIf, so a plain run only
        PREVIEWS the policy changes and changes nothing. This script does NOT disable SMS or Voice —
        weak-method retirement is a deliberate, adoption-gated portal step done LAST.
    HOW TO RUN
        Preview (default, no changes):
            powershell -ExecutionPolicy Bypass -File .\ENTPASSKEY-Set-MethodsPolicy.ps1 -Fido2GroupId <id> -PasskeyGroupId <id>
        Apply after review:
            powershell -ExecutionPolicy Bypass -File .\ENTPASSKEY-Set-MethodsPolicy.ps1 -Fido2GroupId <id> -PasskeyGroupId <id> -WhatIf:$false
        Consents to Policy.ReadWrite.AuthenticationMethod, Policy.Read.All.
    EXPECTED RESULTS
        In preview: the method enable/target changes that WOULD be made. When applied: FIDO2 and
        Microsoft Authenticator are enabled and targeted at the supplied groups. Reversible in the
        portal (set the method back to Disabled or remove the group from Target).
.NOTES
    White-label — Entra ID Solutions. Write action — preview (-WhatIf) by default. Does not retire weak methods.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)] [string]$Fido2GroupId,
    [Parameter(Mandatory)] [string]$PasskeyGroupId
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Policy.ReadWrite.AuthenticationMethod','Policy.Read.All' -NoWelcome

Write-Host "`n=== Enable Passwordless Methods (pilot) — $(Get-Date -Format s) ===" -ForegroundColor Cyan

# Safety: confirm Temporary Access Pass is enabled first (the recovery net)
$tap = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/TemporaryAccessPass'
if ($tap.state -ne 'enabled') {
    Write-Host "  STOP: Temporary Access Pass is not enabled. Enable TAP before rolling out passwordless (recovery safety net)." -ForegroundColor Red
    Disconnect-MgGraph | Out-Null; return
}
Write-Host "  PASS: Temporary Access Pass is enabled (recovery net in place)." -ForegroundColor Green

function Enable-Method($id, $groupId) {
    $uri = "/v1.0/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/$id"
    $body = @{
        '@odata.type' = "#microsoft.graph.$($id.Substring(0,1).ToLower() + $id.Substring(1))AuthenticationMethodConfiguration"
        id            = $id
        state         = 'enabled'
        includeTargets = @(@{ targetType='group'; id=$groupId; isRegistrationRequired=$false })
    }
    if ($PSCmdlet.ShouldProcess("$id -> enabled, target group $groupId", 'Update authentication method')) {
        Invoke-MgGraphRequest -Method PATCH -Uri $uri -Body ($body | ConvertTo-Json -Depth 6)
        Write-Host ("  ENABLED + targeted: {0} -> {1}" -f $id, $groupId) -ForegroundColor Green
    } else {
        Write-Host ("  [WhatIf] would enable + target: {0} -> {1}" -f $id, $groupId) -ForegroundColor Yellow
    }
}

Enable-Method 'Fido2' $Fido2GroupId
Enable-Method 'MicrosoftAuthenticator' $PasskeyGroupId

Write-Host "`nNOTE: verify the Passkey (device-bound) option under Microsoft Authenticator in the portal — availability/preview varies by tenant." -ForegroundColor DarkGray
Write-Host "Weak methods (SMS/Voice) are intentionally left untouched — retire them last, gated on adoption." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null

<#
.SYNOPSIS
    ENTPASSKEYG-Report.ps1 — passwordless adoption report by user and group.
.DESCRIPTION
    PURPOSE
        Read-only adoption report. For each user it reads the registered authentication methods and
        classifies them as phishing-resistant (FIDO2 security key or passkey in Authenticator) versus
        still relying on password + weak MFA (SMS / voice / phone). Optionally scoped to a rollout
        group so you can gate weak-method retirement on that wave's adoption number.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTPASSKEYG-Report.ps1
        Optional: -GroupId <objectId> to report only that group's members (a rollout wave).
        Optional: -CsvPath .\passkey-adoption.csv to export.
        Consents to UserAuthenticationMethod.Read.All, User.Read.All, GroupMember.Read.All (read-only).
        GCC High / US Gov: Connect-MgGraph uses -Environment USGov (login.microsoftonline.us / graph.microsoft.us).
        For DoD (IL5) use -Environment USGovDoD (dod-graph.microsoft.us). *Verify the correct cloud for your tenant.*
    EXPECTED RESULTS
        Per-user phishing-resistant vs. weak classification and a summary adoption percentage. No
        changes are made.
.NOTES
    White-label — Entra ID Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string]$GroupId,
    [string]$CsvPath
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
# US Government cloud (GCC High). For DoD (IL5) use -Environment USGovDoD (dod-graph.microsoft.us).
Connect-MgGraph -Environment USGov -Scopes 'UserAuthenticationMethod.Read.All','User.Read.All','GroupMember.Read.All' -NoWelcome

Write-Host "`n=== Passwordless Adoption Report — $(Get-Date -Format s) ===" -ForegroundColor Cyan

# Resolve the user set
if ($GroupId) {
    $members = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$GroupId/members?`$select=id,userPrincipalName&`$top=999").value
    $users = $members | Where-Object { $_.userPrincipalName }
    Write-Host ("Scope: group {0} — {1} members`n" -f $GroupId, $users.Count)
} else {
    $users = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/users?$select=id,userPrincipalName&$top=999').value
    Write-Host ("Scope: all users — {0}`n" -f $users.Count)
}

$strong = 0; $weak = 0; $rows = @()
foreach ($u in $users) {
    $methods = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$($u.id)/authentication/methods").value
    $types = @($methods | ForEach-Object { ($_.'@odata.type') -replace '#microsoft.graph.','' })
    $hasFido = $types -contains 'fido2AuthenticationMethod'
    # passkey in Authenticator surfaces as a microsoftAuthenticator or fido2 method depending on tenant/preview
    $hasPasskey = ($types -contains 'fido2AuthenticationMethod') -or ($methods | Where-Object { $_.displayName -match 'passkey' })
    $phishResistant = $hasFido -or $hasPasskey
    if ($phishResistant) { $strong++ } else { $weak++ }
    $rows += [pscustomobject]@{
        UserPrincipalName = $u.userPrincipalName
        PhishingResistant = $phishResistant
        Methods           = ($types -join ';')
    }
    $c = if ($phishResistant) { 'Green' } else { 'Yellow' }
    Write-Host ("  {0,-45} {1}" -f $u.userPrincipalName, ($(if($phishResistant){'PHISHING-RESISTANT'}else{'weak — not yet registered'}))) -ForegroundColor $c
}

$total = $strong + $weak
$pct = if ($total) { [math]::Round(100 * $strong / $total, 1) } else { 0 }
Write-Host ("`nAdoption: {0}/{1} phishing-resistant ({2}%)" -f $strong, $total, $pct) -ForegroundColor Cyan
Write-Host "Only retire SMS/Voice for a group once its adoption is high." -ForegroundColor Cyan

if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host "Exported to $CsvPath" -ForegroundColor Green }
Disconnect-MgGraph | Out-Null

<#
.SYNOPSIS
    FIDO2-Validation.ps1 — confirm a user has a phishing-resistant authentication method registered.
.DESCRIPTION
    PURPOSE
        Lists a user's registered authentication methods and reports whether at least one
        phishing-resistant method (FIDO2 security key, Windows Hello for Business, or
        certificate-based authentication) is present. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\FIDO2-Validation.ps1 -UserId user@contoso.com
        Requires Microsoft Graph SDK and UserAuthenticationMethod.Read.All.
    EXPECTED RESULTS
        "PHISHING-RESISTANT METHOD REGISTERED" when a qualifying method is present; else NOT REGISTERED.
.NOTES
    Entra ID Solutions. Read-only against Graph.
#>
[CmdletBinding()] param([Parameter(Mandatory)][string]$UserId)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'UserAuthenticationMethod.Read.All' -NoWelcome
Write-Host ("=== Authentication methods for {0} ===" -f $UserId) -ForegroundColor Cyan
$methods = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$UserId/authentication/methods").value
$prTypes = @('#microsoft.graph.fido2AuthenticationMethod','#microsoft.graph.windowsHelloForBusinessAuthenticationMethod','#microsoft.graph.x509CertificateAuthenticationMethod')
$pr = $false
foreach ($m in $methods) {
    $type = $m.'@odata.type'
    $isPR = $prTypes -contains $type
    if ($isPR) { $pr = $true }
    Write-Host ("  {0}{1}" -f ($type -replace '#microsoft.graph.',''), ($(if($isPR){'   <-- phishing-resistant'}else{''})))
}
if ($pr) { Write-Host "`nResult: PHISHING-RESISTANT METHOD REGISTERED" -ForegroundColor Green; exit 0 }
else { Write-Host "`nResult: NOT REGISTERED — direct the user to https://aka.ms/mysecurityinfo" -ForegroundColor Yellow; exit 1 }
Disconnect-MgGraph | Out-Null

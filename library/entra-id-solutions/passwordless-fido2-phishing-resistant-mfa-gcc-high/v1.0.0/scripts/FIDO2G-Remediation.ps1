<#
.SYNOPSIS
    FIDO2G-Remediation.ps1 — safely flag/assist GCC High users lacking a phishing-resistant method (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Finds users in a US Government (GCC High/DoD) tenant who lack a phishing-resistant, passwordless
        method and, optionally, adds them to a remediation/registration group so a registration
        campaign or supervised-enrollment drive can target them. Makes NO change in the default
        preview (-WhatIf) mode; add -WhatIf:$false to apply. It never disables a user's existing
        methods and never enforces a policy. Use -Environment USGovDoD on the DoD cloud.
    HOW TO RUN
        Preview (default): powershell -ExecutionPolicy Bypass -File .\FIDO2G-Remediation.ps1 -RemediationGroupName "Phishing-Resistant - Needs Registration - Remediation"
        Apply:            add -WhatIf:$false to the same command after reviewing the preview.
        Connects to US Gov Graph (-Environment USGov). Scopes:
        AuditLog.Read.All, UserAuthenticationMethod.Read.All, Group.ReadWrite.All, User.Read.All.
    EXPECTED RESULTS
        A list of users lacking a phishing-resistant method; in preview it prints what WOULD be added
        to the remediation group; with -WhatIf:$false it adds them and prints the group object ID.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [string]$RemediationGroupName = 'Phishing-Resistant - Needs Registration - Remediation',
    [ValidateSet('USGov','USGovDoD')][string]$Environment = 'USGov'
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment $Environment -Scopes 'AuditLog.Read.All','UserAuthenticationMethod.Read.All','Group.ReadWrite.All','User.Read.All' -NoWelcome

# US Gov vs DoD directoryObjects host for $ref bodies
$graphHost = if ($Environment -eq 'USGovDoD') { 'https://dod-graph.microsoft.us' } else { 'https://graph.microsoft.us' }
Write-Host "`n=== Phishing-resistant remediation — GCC High (env: $Environment) ===" -ForegroundColor Cyan
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { Write-Host "Running in PREVIEW (-WhatIf) mode — no changes will be made. Add -WhatIf:`$false to apply." -ForegroundColor Yellow }

# Identify not-ready users from registration details
$users = New-Object System.Collections.Generic.List[object]
$uri = '/v1.0/reports/authenticationMethods/userRegistrationDetails?$top=999'
do {
    $resp = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($u in $resp.value) { $users.Add($u) }
    $uri = $resp.'@odata.nextLink'
} while ($uri)

$prMethods = @('fido2SecurityKey','windowsHelloForBusiness','x509Certificate','passKeyDeviceBound','passKeyDeviceBoundAuthenticator')
$notReady = @($users | Where-Object {
    $mr = @($_.methodsRegistered)
    -not (($mr | Where-Object { $prMethods -contains $_ }).Count -gt 0 -or $_.isPasswordlessCapable)
})
Write-Host ("Users lacking a phishing-resistant method: {0}" -f $notReady.Count) -ForegroundColor $(if ($notReady.Count) { 'Yellow' } else { 'Green' })
if ($notReady.Count -eq 0) { Disconnect-MgGraph | Out-Null; return }

# Ensure the remediation group exists
$esc = $RemediationGroupName.Replace("'","''")
$group = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$esc'").value | Select-Object -First 1
if (-not $group) {
    if ($PSCmdlet.ShouldProcess($RemediationGroupName, "Create remediation security group")) {
        $mail = ($RemediationGroupName -replace '[^a-zA-Z0-9]','').ToLower()
        $body = @{ displayName=$RemediationGroupName; mailEnabled=$false; mailNickname=$mail; securityEnabled=$true }
        $group = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
        Write-Host ("Created remediation group: {0} ({1})" -f $RemediationGroupName, $group.id) -ForegroundColor Green
    } else {
        Write-Host ("WHATIF would create remediation group: {0}" -f $RemediationGroupName) -ForegroundColor Yellow
    }
}

foreach ($u in $notReady) {
    $upn = $u.userPrincipalName
    if (-not $PSCmdlet.ShouldProcess($upn, "Add to $RemediationGroupName")) {
        Write-Host ("  WHATIF would add: {0}" -f $upn) -ForegroundColor Yellow
        continue
    }
    try {
        $usr = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$upn"
        $ref = @{ '@odata.id' = "$graphHost/v1.0/directoryObjects/$($usr.id)" }
        Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$($group.id)/members/`$ref" -Body ($ref | ConvertTo-Json) | Out-Null
        Write-Host ("  + {0}" -f $upn) -ForegroundColor Green
    } catch { Write-Host ("  ! {0}: {1}" -f $upn, $_.Exception.Message) -ForegroundColor Yellow }
}

if ($group) { Write-Host ("`nRemediation group ID (target a registration campaign / enrollment drive here): {0}" -f $group.id) -ForegroundColor Cyan }
Write-Host "This script never enforces a policy or removes a method — registration must lead enforcement." -ForegroundColor DarkCyan
Disconnect-MgGraph | Out-Null

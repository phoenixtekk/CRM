<#
.SYNOPSIS
    FIDO2-Remediation.ps1 — safely flag (and optionally group) users lacking a phishing-resistant method.
.DESCRIPTION
    PURPOSE
        Finds users who are NOT passwordless/phishing-resistant capable and, when run without
        -WhatIf, adds them to a remediation group you can target with the registration campaign.
        Defaults to -WhatIf so nothing changes until you confirm. It never weakens any setting and
        never deletes credentials.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\FIDO2-Remediation.ps1
        Apply:              powershell -ExecutionPolicy Bypass -File .\FIDO2-Remediation.ps1 -RemediationGroupId <objectId> -WhatIf:$false
        Requires Microsoft Graph SDK; AuditLog.Read.All + GroupMember.ReadWrite.All (to apply).
    EXPECTED RESULTS
        A list of users missing a phishing-resistant method; with -WhatIf:$false they are added to the
        remediation group for the campaign.
.NOTES
    Workplace Marketplace — Entra ID Solutions. Default -WhatIf; additive only.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
param([string]$RemediationGroupId)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = @('AuditLog.Read.All'); if ($RemediationGroupId) { $scopes += 'GroupMember.ReadWrite.All' }
Connect-MgGraph -Scopes $scopes -NoWelcome
$rows = @(); $uri = '/v1.0/reports/authenticationMethods/userRegistrationDetails'
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $rows += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
$weak = $rows | Where-Object { -not $_.isPasswordlessCapable }
Write-Host ("=== Users lacking a phishing-resistant method: {0} ===" -f $weak.Count) -ForegroundColor Cyan
$weak | ForEach-Object { Write-Host ("  {0}" -f $_.userPrincipalName) }
foreach ($u in $weak) {
    if (-not $RemediationGroupId) { continue }
    if ($PSCmdlet.ShouldProcess($u.userPrincipalName, "Add to remediation group $RemediationGroupId")) {
        $body = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($u.id)" }
        try { Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$RemediationGroupId/members/`$ref" -Body $body; Write-Host ("    added {0}" -f $u.userPrincipalName) -ForegroundColor Green }
        catch { Write-Host ("    skip {0}: {1}" -f $u.userPrincipalName, $_.Exception.Message) -ForegroundColor Yellow }
    }
}
if (-not $RemediationGroupId) { Write-Host "`n(Preview only — pass -RemediationGroupId and -WhatIf:`$false to add users to the campaign group.)" -ForegroundColor Yellow }
Disconnect-MgGraph | Out-Null

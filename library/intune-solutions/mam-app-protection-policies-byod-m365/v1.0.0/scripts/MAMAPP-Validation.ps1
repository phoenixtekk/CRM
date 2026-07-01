<#
.SYNOPSIS
    MAMAPP-Validation.ps1 — confirm a user's targeted apps report an App Protection Policy applied.
.DESCRIPTION
    PURPOSE
        Queries the per-user app protection status from Microsoft Graph and confirms the user's
        Microsoft 365 apps have checked in with an App Protection Policy applied on iOS/Android — the
        signal that MAM protection is live for that user.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MAMAPP-Validation.ps1 -UserPrincipalName user@contoso.com
        Requires the Microsoft Graph SDK and scope DeviceManagementApps.Read.All.
    EXPECTED RESULTS
        "PROTECTION APPLIED" with the list of the user's apps reporting a policy, or a warning listing
        apps/platforms with no policy applied.
.NOTES
    Intune Solutions — MAM App Protection Policies for BYOD. Read-only against Graph.
#>
[CmdletBinding()] param([Parameter(Mandatory)][string]$UserPrincipalName)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All' -NoWelcome

Write-Host ("=== App protection status — {0} ===" -f $UserPrincipalName) -ForegroundColor Cyan
$uri = "/beta/deviceAppManagement/managedAppStatuses('userstatus')?userId=$UserPrincipalName"
$applied = @()
try {
    $status = Invoke-MgGraphRequest -Method GET -Uri $uri
    $items = $status.content.userApps
    foreach ($a in $items) {
        $has = $a.appProtectionStatus -eq 'checkedIn' -or $a.policyStatus -eq 'applied' -or $a.appInstanceStatus -eq 'protected'
        Write-Host ("  {0} ({1})  policy: {2}" -f $a.displayName, $a.platform, ($(if($has){'applied'}else{'none'}))) -ForegroundColor ($(if($has){'Green'}else{'Yellow'}))
        if ($has) { $applied += $a.displayName }
    }
} catch { Write-Host ("  Could not read user status: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

if ($applied.Count -gt 0) { Write-Host "`nResult: PROTECTION APPLIED" -ForegroundColor Green; Disconnect-MgGraph | Out-Null; exit 0 }
else { Write-Host "`nResult: NO PROTECTION APPLIED — check group membership, licensing, and Company Portal (Android); run MAMAPP-Remediation.ps1" -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 1 }

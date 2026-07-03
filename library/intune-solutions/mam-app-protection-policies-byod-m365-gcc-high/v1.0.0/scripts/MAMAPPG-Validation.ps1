<#
.SYNOPSIS
    MAMAPPG-Validation.ps1 — confirm a user's targeted apps report an App Protection Policy applied (GCC High).
.DESCRIPTION
    PURPOSE
        Queries the per-user app protection status from Microsoft Graph US Gov and confirms the user's
        Microsoft 365 apps have checked in with an App Protection Policy applied on iOS/Android — the
        signal that MAM protection is live for that user on a GCC High tenant. Pass a real UPN such as
        pilot-user@your-tenant.onmicrosoft.us (no angle brackets).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MAMAPPG-Validation.ps1 -UserPrincipalName pilot-user@your-tenant.onmicrosoft.us
        Connects to US Gov Graph: Connect-MgGraph -Environment USGov -Scopes 'DeviceManagementApps.Read.All'
    EXPECTED RESULTS
        'PROTECTION APPLIED' with the list of the user's apps reporting a policy, or a warning listing
        apps/platforms with no policy applied. PASS = protection applied; FAIL = none applied.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding()] param([Parameter(Mandatory)][string]$UserPrincipalName)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment USGov -Scopes 'DeviceManagementApps.Read.All' -NoWelcome

if ((Get-MgContext).Environment -ne 'USGov') {
    Write-Host "WRONG CLOUD: not USGov (graph.microsoft.us). Reconnect with -Environment USGov." -ForegroundColor Red
    Disconnect-MgGraph | Out-Null
    exit 1
}

Write-Host ("=== App protection status (GCC High) — {0} ===" -f $UserPrincipalName) -ForegroundColor Cyan
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
else { Write-Host "`nResult: NO PROTECTION APPLIED — check group membership, Government licensing, and the MAM broker (Company Portal on Android / Authenticator on iOS); run MAMAPPG-Remediation.ps1" -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 1 }

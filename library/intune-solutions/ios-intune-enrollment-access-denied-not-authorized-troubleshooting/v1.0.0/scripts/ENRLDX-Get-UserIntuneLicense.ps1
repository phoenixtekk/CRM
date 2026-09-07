<#
.SYNOPSIS
    Confirm whether the user has an enabled Intune service plan — the #1 cause of the enrollment
    "Access Denied / not authorized" page.

.DESCRIPTION
    Phase 2A. Reads the user's assigned licenses and reports whether the Intune service plan (INTUNE_A)
    is present and provisioned. A missing/disabled Intune plan blocks enrollment authorization.

.HOW TO RUN
    .\ENRLDX-Get-UserIntuneLicense.ps1 -UserPrincipalName user@contoso.com
    Sovereign cloud: add  -Environment USGov.

.EXPECTED RESULT
    The user's licenses and a clear YES/NO on an enabled Intune service plan.

.NOTES
    Intune Solutions — read-only diagnostic (Microsoft Graph). Scope: User.Read.All / Directory.Read.All.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$UserPrincipalName,
    [string]$Environment = "Global"
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'User.Read.All','Directory.Read.All' -Environment $Environment -NoWelcome

$u = Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'" -Property "id,displayName,accountEnabled,userType" -ErrorAction Stop
Write-Host "User: $($u.DisplayName)  <$UserPrincipalName>  Enabled=$($u.AccountEnabled)  Type=$($u.UserType)" -ForegroundColor Cyan
if ($u.UserType -eq 'Guest') { Write-Host "NOTE: this is a GUEST account — guests cannot enroll (Phase 2E)." -ForegroundColor Yellow }

$intunePlans = @('INTUNE_A','INTUNE_A_VL','INTUNE_EDU','INTUNE_A_D')
$lic = Get-MgUserLicenseDetail -UserId $u.Id -ErrorAction SilentlyContinue
$hasIntune = $false
foreach ($l in $lic) {
    $plan = $l.ServicePlans | Where-Object { $_.ServicePlanName -in $intunePlans }
    foreach ($p in $plan) {
        Write-Host ("  {0}: {1} = {2}" -f $l.SkuPartNumber, $p.ServicePlanName, $p.ProvisioningStatus) -ForegroundColor $(if($p.ProvisioningStatus -eq 'Success'){'Green'}else{'Yellow'})
        if ($p.ProvisioningStatus -eq 'Success') { $hasIntune = $true }
    }
}
if ($hasIntune) {
    Write-Host "`nIntune service plan: ENABLED — licensing is not the cause; check MDM scope (2B), restrictions (2C), CA (2D)." -ForegroundColor Green
} else {
    Write-Host "`nIntune service plan: NOT ENABLED — assign an Intune-bearing license (M365 admin center > user > Licenses). This is the most likely cause." -ForegroundColor Yellow
    Write-Host "  User's SKUs: $(( $lic.SkuPartNumber) -join ', ')"
}

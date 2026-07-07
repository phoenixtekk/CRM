<#
.SYNOPSIS
  SPOEXT-Validation.ps1 — read-only PASS/FAIL check of the sharing baseline against the expected policy. Makes NO changes.
.DESCRIPTION
  Validation for Stage 3. Compares the live tenant settings and each in-scope site's SharingCapability
  against the expected "Tenant Sharing Baseline - SPO - Prod" values you pass in, and prints PASS/FAIL
  per check. Read-only. Run after Configure and after every Expand tranche.
.EXAMPLE
  .\SPOEXT-Validation.ps1 -ExpectSharingCapability ExternalUserSharingOnly -ExpectDefaultLinkType Direct -ExpectDefaultLinkPermission View -ExpectDomainMode AllowList
  # Validate the tenant baseline only.
.EXAMPLE
  .\SPOEXT-Validation.ps1 -SiteScope (Get-Content .\pilot-sites.txt) -ExpectSharingCapability ExternalUserSharingOnly -ExpectSiteSharingCapability ExistingExternalUserSharingOnly
  # Validate the tenant baseline plus the tightened pilot sites.
  # (PowerShell 5.1+/7+, Microsoft.Online.SharePoint.PowerShell; connect with Connect-SPOService.)
.NOTES
  Expected results: every check prints PASS. Any FAIL blocks Expand until remediated or rolled back.
  Exit code 1 if any check fails. SharePoint — External Sharing & Access Governance.
#>
[CmdletBinding()]
param(
    [string]$ExpectSharingCapability,
    [string]$ExpectOneDriveSharingCapability,
    [string]$ExpectDefaultLinkType,
    [string]$ExpectDefaultLinkPermission,
    [string]$ExpectDomainMode,
    [switch]$ExpectGuestExpiration,
    [string[]]$SiteScope,
    [string]$ExpectSiteSharingCapability
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Online.SharePoint.PowerShell)) {
    Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser -Force
}
Import-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction Stop
try { $t = Get-SPOTenant -ErrorAction Stop }
catch {
    Write-Warning 'Not connected. Run: Connect-SPOService -Url https://<tenant>-admin.sharepoint.com (Government: your .us admin host).'
    return
}

$fails = 0
function Test-Value {
    param($Name, $Actual, $Expected)
    if ([string]::IsNullOrEmpty($Expected)) { return }   # skip checks not requested
    if ("$Actual" -eq "$Expected") {
        Write-Host ("  PASS  {0} = {1}" -f $Name, $Actual) -ForegroundColor Green
    } else {
        Write-Host ("  FAIL  {0} = {1} (expected {2})" -f $Name, $Actual, $Expected) -ForegroundColor Red
        $script:fails++
    }
}

Write-Host '=== Tenant baseline validation ===' -ForegroundColor Cyan
Test-Value 'SharingCapability'         $t.SharingCapability         $ExpectSharingCapability
Test-Value 'OneDriveSharingCapability' $t.OneDriveSharingCapability $ExpectOneDriveSharingCapability
Test-Value 'DefaultSharingLinkType'    $t.DefaultSharingLinkType    $ExpectDefaultLinkType
Test-Value 'DefaultLinkPermission'     $t.DefaultLinkPermission     $ExpectDefaultLinkPermission
Test-Value 'SharingDomainRestrictionMode' $t.SharingDomainRestrictionMode $ExpectDomainMode

# OneDrive must not be looser than tenant (ordinal of the enum)
$order = @{ Disabled=0; ExistingExternalUserSharingOnly=1; ExternalUserSharingOnly=2; ExternalUserAndGuestSharing=3 }
if ($order[$t.OneDriveSharingCapability] -le $order[$t.SharingCapability]) {
    Write-Host ("  PASS  OneDrive ({0}) is not looser than tenant ({1})" -f $t.OneDriveSharingCapability, $t.SharingCapability) -ForegroundColor Green
} else {
    Write-Host ("  FAIL  OneDrive ({0}) is LOOSER than tenant ({1})" -f $t.OneDriveSharingCapability, $t.SharingCapability) -ForegroundColor Red
    $fails++
}

if ($ExpectGuestExpiration) {
    if ($t.ExternalUserExpirationRequired) {
        Write-Host ("  PASS  Guest expiration required ({0} days)" -f $t.ExternalUserExpireInDays) -ForegroundColor Green
    } else {
        Write-Host '  FAIL  Guest expiration is NOT required' -ForegroundColor Red
        $fails++
    }
}

if ($SiteScope -and $ExpectSiteSharingCapability) {
    Write-Host '=== Per-site validation ===' -ForegroundColor Cyan
    foreach ($url in $SiteScope) {
        $s = try { Get-SPOSite -Identity $url -ErrorAction Stop } catch { Write-Host ("  FAIL  cannot read {0}: {1}" -f $url, $_.Exception.Message) -ForegroundColor Red; $fails++; continue }
        Test-Value ("Site {0}" -f $url) $s.SharingCapability $ExpectSiteSharingCapability
    }
}

Write-Host ''
if ($fails -eq 0) {
    Write-Host 'ALL CHECKS PASSED — baseline matches policy.' -ForegroundColor Green
} else {
    Write-Host ("{0} CHECK(S) FAILED — remediate or roll back before Expand." -f $fails) -ForegroundColor Red
    exit 1
}

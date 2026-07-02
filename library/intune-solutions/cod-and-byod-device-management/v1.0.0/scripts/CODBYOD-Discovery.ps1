<#
.SYNOPSIS
    CODBYOD-Discovery.ps1 — tenant readiness check for COD + BYOD device management.

.DESCRIPTION
    PURPOSE
        Confirms the building blocks of the one-identity / two-ownership model exist: enrollment
        restrictions, a compliance policy (for COD), App Protection policies (for BYOD), the
        Corporate/Personal device filters, Company Portal, and a Conditional Access policy.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\CODBYOD-Discovery.ps1
        Reads only — makes no changes.

    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall verdict. A READY tenant has compliance + app
        protection policies, both ownership filters, Company Portal, and at least one CA policy.

.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementApps.Read.All','DeviceManagementServiceConfig.Read.All','Policy.Read.All' | Out-Null

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}
function Count($uri) { try { @((Invoke-MgGraphRequest -Method GET -Uri $uri).value).Count } catch { -1 } }

$results = New-Object System.Collections.Generic.List[object]

# Compliance policies (COD)
$comp = Count 'https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies'
$results.Add( (R 'Compliance policy exists (COD)' ($comp -gt 0) "$comp policy(ies)") )

# App Protection policies (BYOD)
$ios = Count 'https://graph.microsoft.com/v1.0/deviceAppManagement/iosManagedAppProtections'
$and = Count 'https://graph.microsoft.com/v1.0/deviceAppManagement/androidManagedAppProtections'
$results.Add( (R 'App Protection policy exists (BYOD)' (($ios + $and) -gt 0) "iOS=$ios, Android=$and") )

# Ownership filters
$corp = $false; $pers = $false
try {
    $filters = (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/deviceManagement/assignmentFilters').value
    foreach ($f in $filters) {
        if ($f.rule -match 'deviceOwnership.*Corporate') { $corp = $true }
        if ($f.rule -match 'deviceOwnership.*Personal')  { $pers = $true }
    }
} catch {}
$results.Add( (R 'Corporate device filter exists' $corp 'rule on device.deviceOwnership = Corporate') )
$results.Add( (R 'Personal device filter exists'  $pers 'rule on device.deviceOwnership = Personal') )

# Enrollment restrictions present
$enr = Count 'https://graph.microsoft.com/v1.0/deviceManagement/deviceEnrollmentConfigurations'
$results.Add( (R 'Enrollment restrictions configured' ($enr -gt 0) "$enr configuration(s)") )

# Company Portal
try {
    $apps = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps?`$filter=contains(displayName,'Company Portal')").value
    $results.Add( (R 'Company Portal added' (@($apps).Count -gt 0) "$(@($apps).Count) match(es)") )
} catch { $results.Add( (R 'Company Portal added' $false $_.Exception.Message) ) }

# Conditional Access
$ca = Count 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies'
$results.Add( (R 'Conditional Access policy present' ($ca -gt 0) "$ca policy(ies)") )

$results | Format-Table -AutoSize
$fail = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: READY — tenant has the COD + BYOD building blocks.' -ForegroundColor Green }
else { Write-Host "OVERALL: NOT READY — $fail check(s) failed. Resolve before piloting." -ForegroundColor Yellow }

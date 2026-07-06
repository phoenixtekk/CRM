<#
.SYNOPSIS
    MACBYOD-Discovery.ps1 — BYOD-readiness check for macOS account-driven user enrollment + Conditional Access.
.DESCRIPTION
    PURPOSE
        Confirms the Intune/Entra tenant is ready to onboard personal Macs with the lightest footprint
        and gate them with Conditional Access. Checks: macOS enrollment allowed, a macOS BYOD compliance
        policy present, and whether a Conditional Access policy requires a compliant/enrolled Mac.
        Reads only — makes no changes. Use 'your-tenant-id' style values, never real secrets in scripts.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MACBYOD-Discovery.ps1
        Requires the Microsoft Graph PowerShell SDK. Graph scopes (read-only):
        DeviceManagementServiceConfig.Read.All, DeviceManagementConfiguration.Read.All,
        Policy.Read.All.
    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall verdict. A READY tenant shows macOS enrollment allowed,
        a macOS BYOD compliance policy present, and a require-compliant-Mac Conditional Access policy
        found (report-only or enforced).
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.Read.All','DeviceManagementConfiguration.Read.All','Policy.Read.All' -NoWelcome

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}

$results = New-Object System.Collections.Generic.List[object]

# 1) macOS enrollment allowed (platform restrictions)
try {
    $restr = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/deviceManagement/deviceEnrollmentConfigurations'
    $macBlocked = $false; $detail = 'no platform-restriction blocking macOS found'
    foreach ($c in @($restr.value | Where-Object { "$($_.'@odata.type')" -match 'PlatformRestrictions' })) {
        $mac = $c.macOSRestriction
        if ($mac -and $mac.platformBlocked -eq $true) { $macBlocked = $true; $detail = "Blocked by '$($c.displayName)'" }
    }
    $results.Add( (R 'macOS personally-owned enrollment allowed' (-not $macBlocked) $detail) )
} catch { $results.Add( (R 'macOS personally-owned enrollment allowed' $false "Could not read enrollment restrictions: $($_.Exception.Message)") ) }

# 2) macOS BYOD compliance policy present
$macCompliance = 0; $compNames = @()
try {
    $pols = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies'
    foreach ($p in $pols.value) {
        if ("$($p.'@odata.type')" -match 'macOS') { $macCompliance++; $compNames += $p.displayName }
    }
    $results.Add( (R 'macOS compliance policy exists' ($macCompliance -gt 0) "$macCompliance macOS policy(ies): $([string]::Join(', ', $compNames))") )
} catch { $results.Add( (R 'macOS compliance policy exists' $false "Could not read compliance policies: $($_.Exception.Message)") ) }

# 3) Conditional Access policy requiring compliant device, scoped to macOS
$caFound = $false; $caDetail = 'no require-compliant CA policy targeting macOS found'
try {
    $ca = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies'
    foreach ($pol in $ca.value) {
        $grants    = @($pol.grantControls.builtInControls)
        $platforms = @($pol.conditions.platforms.includePlatforms)
        $reqCompliant = $grants -contains 'compliantDevice'
        $macScoped    = ($platforms -contains 'macOS') -or ($platforms -contains 'all')
        if ($reqCompliant -and $macScoped) {
            $caFound = $true
            $state = switch ($pol.state) { 'enabled' {'enforced'} 'enabledForReportingButNotEnforced' {'report-only'} default { $pol.state } }
            $caDetail = "'$($pol.displayName)' [$state]"
            break
        }
    }
    $results.Add( (R 'CA requires compliant Mac' $caFound $caDetail) )
} catch { $results.Add( (R 'CA requires compliant Mac' $false "Could not read CA policies: $($_.Exception.Message)") ) }

$results | Format-Table -AutoSize
$fail = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: READY — tenant is prepared for macOS BYOD user enrollment + Conditional Access.' -ForegroundColor Green }
else { Write-Host "OVERALL: NOT READY — $fail check(s) failed. Resolve before onboarding personal Macs." -ForegroundColor Yellow }
Disconnect-MgGraph | Out-Null

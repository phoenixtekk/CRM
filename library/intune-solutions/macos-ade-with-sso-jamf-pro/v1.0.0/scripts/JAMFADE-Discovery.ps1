<#
.SYNOPSIS
    JAMFADE-Discovery.ps1 — Intune/Entra readiness check for Jamf-managed macOS with enforced SSO.

.DESCRIPTION
    PURPOSE
        Confirms the Microsoft side is ready to treat Jamf-managed Macs as registered, compliant,
        Conditional-Access-gated devices:
          - the Jamf device-compliance PARTNER is Active for macOS,
          - at least one macOS COMPLIANCE policy exists,
          - a CONDITIONAL ACCESS policy targets macOS,
          - the macOS Company Portal app is available.
        This is the Intune/Entra counterpart to JAMFADE-JamfReadiness.ps1 (which checks the Jamf MDM
        side). Jamf — not Intune — is the MDM, so APNs/ADE tokens live in Jamf and are checked there.

    HOW TO RUN
        Install the SDK once:  Install-Module Microsoft.Graph -Scope CurrentUser
        Then:                  .\JAMFADE-Discovery.ps1
        Reads only — makes no changes.

    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall verdict. A READY tenant shows Jamf as an Active
        compliance partner for macOS, a macOS compliance policy, a macOS Conditional Access policy,
        and the Company Portal app present.

.NOTES
    White-label — Intune Solutions. Read-only. Jamf Pro is the MDM; this script
    validates the Microsoft Entra/Intune partner-compliance + Conditional Access layer.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementApps.Read.All','DeviceManagementServiceConfig.Read.All','Policy.Read.All' | Out-Null

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}

$results = New-Object System.Collections.Generic.List[object]

# 1) Jamf compliance/device-management partner active for macOS
try {
    $cmp = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/deviceManagement/complianceManagementPartners'
    $jamf = @($cmp.value | Where-Object { "$($_.displayName)" -match 'Jamf' })
    $active = @($jamf | Where-Object { "$($_.partnerState)" -match 'enabled|available' -and ($_.macOsEnrollment -eq $true -or "$($_.macOsOnboarded)" -eq 'True') })
    $detail = if ($jamf.Count) { ($jamf | ForEach-Object { "$($_.displayName)=$($_.partnerState); macOS=$($_.macOsEnrollment)" }) -join '; ' } else { 'no compliance partner named Jamf' }
    $results.Add( (R 'Jamf device-compliance partner active (macOS)' ($active.Count -gt 0) $detail) )
} catch { $results.Add( (R 'Jamf device-compliance partner active (macOS)' $false "Could not read complianceManagementPartners: $($_.Exception.Message)") ) }

# 2) macOS compliance policy
try {
    $pols = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies'
    $mac = @($pols.value | Where-Object { "$($_.'@odata.type')" -match 'macOS' })
    $results.Add( (R 'macOS compliance policy exists' ($mac.Count -gt 0) "$($mac.Count) macOS compliance policy(ies)") )
} catch { $results.Add( (R 'macOS compliance policy exists' $false $_.Exception.Message) ) }

# 3) Conditional Access policy targeting macOS
try {
    $ca = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies'
    $macCa = @($ca.value | Where-Object {
        $p = $_.conditions.platforms
        $p -and ((@($p.includePlatforms) -contains 'macOS') -or (@($p.includePlatforms) -contains 'all'))
    })
    $results.Add( (R 'Conditional Access policy targets macOS' ($macCa.Count -gt 0) "$($macCa.Count) policy(ies); enforce 'Require compliant device'") )
} catch { $results.Add( (R 'Conditional Access policy targets macOS' $false "Could not read CA policies (need Policy.Read.All): $($_.Exception.Message)") ) }

# 4) Company Portal app for macOS
try {
    $apps = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps?`$filter=contains(displayName,'Company Portal')"
    $cp = @($apps.value | Where-Object { $_.displayName -match 'Company Portal' })
    $results.Add( (R 'Company Portal (macOS) available' ($cp.Count -gt 0) "$($cp.Count) match(es) — deploy via Jamf to register devices") )
} catch { $results.Add( (R 'Company Portal (macOS) available' $false $_.Exception.Message) ) }

$results | Format-Table -AutoSize
$fail = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: READY — Entra/Intune is prepared to enforce SSO on Jamf-managed Macs.' -ForegroundColor Green }
else { Write-Host "OVERALL: NOT READY — $fail check(s) failed. Resolve before enforcing Conditional Access." -ForegroundColor Yellow }
Write-Host 'Reminder: also run JAMFADE-JamfReadiness.ps1 to validate the Jamf MDM side.' -ForegroundColor Cyan

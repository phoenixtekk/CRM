<#
.SYNOPSIS
    Report which Apple serials are assigned to the Intune ADE (enrollment program) token, so you can
    see what still needs re-assigning from Jamf in ABM.

.DESCRIPTION
    Phase 1/3. Reads the imported Apple device identities under each Intune DEP onboarding setting
    (ADE token) and lists the serials Intune knows about, with their enrollment profile. Serials NOT
    listed here are still assigned to another MDM (Jamf) in ABM and must be re-assigned.

.HOW TO RUN
    .\JAMFMIG-Get-ABMAssignments.ps1
    Sovereign cloud: add  -Environment USGov.

.EXPECTED RESULT
    CSV of serials known to Intune's ADE token(s) + assigned enrollment profile. Compare against the
    Jamf inventory to find devices still on Jamf's MDM server in ABM.

.NOTES
    Migrations — read-only (Microsoft Graph). Uses the beta imported-device-identity endpoint.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".",
    [string]$Environment = "Global"
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.Read.All' -Environment $Environment -NoWelcome
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$base = if ($Environment -match 'USGov') { 'https://graph.microsoft.us' } else { 'https://graph.microsoft.com' }

$rows = @()
$dep = Get-MgDeviceManagementDepOnboardingSetting -All -ErrorAction Stop
foreach ($d in $dep) {
    Write-Host "ADE token: $($d.TokenName)" -ForegroundColor Cyan
    $uri = "$base/beta/deviceManagement/depOnboardingSettings/$($d.Id)/importedAppleDeviceIdentities?`$top=200"
    do {
        try { $resp = Invoke-MgGraphRequest -Method GET -Uri $uri } catch { Write-Warning "  read failed: $($_.Exception.Message)"; break }
        foreach ($x in $resp.value) {
            $rows += [pscustomobject]@{
                Token           = $d.TokenName
                Serial          = $x.serialNumber
                Model           = $x.model
                Platform        = $x.platform
                EnrollmentState = $x.enrollmentState
                Profile         = $x.requestedEnrollmentProfileId
                DiscoverySource = $x.discoverySource
            }
        }
        $uri = $resp.'@odata.nextLink'
    } while ($uri)
}

$out = Join-Path $OutputPath "JAMFMIG-ABMAssignments-$stamp.csv"
$rows | Export-Csv $out -NoTypeInformation -Encoding UTF8
Write-Host "`nSerials known to Intune ADE token(s): $($rows.Count)" -ForegroundColor Green
Write-Host "Exported: $out" -ForegroundColor Green
Write-Host "Serials in the Jamf inventory but NOT here are still assigned to Jamf in ABM — re-assign them to the Intune MDM server." -ForegroundColor Yellow

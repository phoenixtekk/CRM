<#
.SYNOPSIS
    MDE-ConnectorCheck.ps1 — confirm the Intune ↔ Defender for Endpoint connector is active (Graph).
.DESCRIPTION
    PURPOSE
        Reads the Intune Microsoft Defender for Endpoint connector state so you can confirm the
        service-to-service connection is enabled before expecting onboarding/risk to flow.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDE-ConnectorCheck.ps1
        Requires Microsoft Graph SDK and DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        Connector state (e.g. "enabled" / "available") and last-sync time.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only against Graph.
#>
[CmdletBinding()] param()
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' -NoWelcome
try {
    $c = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/deviceManagement/mobileThreatDefenseConnectors'
    $mde = $c.value | Where-Object { $_.id -or $_.partnerState }
    if (-not $mde) { $mde = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/mobileThreatDefenseConnectors').value }
} catch { $mde = $null }
# Also check the dedicated MDE connector endpoint
try { $atp = Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/microsoftDefenderAdvancedThreatProtectionConfiguration' } catch { $atp = $null }
if ($atp) {
    Write-Host ("Defender connector state : {0}" -f $atp.advancedThreatProtectionOnboardingState) -ForegroundColor Cyan
    Write-Host ("Last sync                : {0}" -f $atp.lastHeartbeatDateTime)
} elseif ($mde) {
    $mde | ForEach-Object { Write-Host ("Connector {0} : {1}" -f $_.id, $_.partnerState) }
} else {
    Write-Host "Could not read the Defender connector via Graph — confirm in Intune > Endpoint security > Microsoft Defender for Endpoint." -ForegroundColor Yellow
}
Disconnect-MgGraph | Out-Null

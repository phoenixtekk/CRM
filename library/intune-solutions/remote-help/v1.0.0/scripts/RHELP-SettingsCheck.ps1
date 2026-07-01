<#
.SYNOPSIS
    RHELP-SettingsCheck.ps1 — confirm Remote Help is enabled tenant-wide with chosen options (Graph).
.DESCRIPTION
    PURPOSE
        Reads the Intune Remote Help (remote assistance) tenant settings so you can confirm Remote
        Help is enabled and review the remote-control and unenrolled-device options.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\RHELP-SettingsCheck.ps1
        Requires Microsoft Graph SDK and DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        The Remote Help enablement state and key options.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only against Graph.
#>
[CmdletBinding()] param()
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' -NoWelcome
try {
    $s = Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/remoteAssistanceSettings'
    Write-Host "=== Remote Help (Remote Assistance) settings ===" -ForegroundColor Cyan
    Write-Host ("State                         : {0}" -f $s.remoteAssistanceState) -ForegroundColor ($(if($s.remoteAssistanceState -eq 'enabled'){'Green'}else{'Yellow'}))
    Write-Host ("Allow session to unenrolled   : {0}" -f $s.allowSessionsToUnenrolledDevices)
    Write-Host ("Block chat                    : {0}" -f $s.blockChat)
} catch {
    Write-Host "Could not read remoteAssistanceSettings via Graph. Confirm in Intune > Tenant administration > Remote Help." -ForegroundColor Yellow
}
Disconnect-MgGraph | Out-Null

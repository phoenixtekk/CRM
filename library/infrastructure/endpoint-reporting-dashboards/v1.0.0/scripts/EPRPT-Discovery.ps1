<#
.SYNOPSIS
    EPRPT-Discovery.ps1 — reporting-readiness check for endpoint reporting & dashboards.
.DESCRIPTION
    PURPOSE
        Confirms the data sources and permissions needed for endpoint reporting are reachable:
        signs in to Microsoft Graph and reads managed devices, compliance, device configuration,
        and apps, reporting a count for each so you know the reporting layer can be built.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\EPRPT-Discovery.ps1
        Requires the Microsoft Graph PowerShell SDK and read scopes:
        DeviceManagementManagedDevices.Read.All, DeviceManagementConfiguration.Read.All,
        DeviceManagementApps.Read.All, Group.Read.All.
    EXPECTED RESULTS
        A line per data source with a count, and an overall READY / NOT READY result.
.NOTES
    Workplace Marketplace — Infrastructure. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param()
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementConfiguration.Read.All','DeviceManagementApps.Read.All','Group.Read.All' -NoWelcome

Write-Host "`n=== Endpoint Reporting — readiness ===" -ForegroundColor Cyan
$ok = $true
function Probe($label,$uri){
    try {
        $r = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
        $count = if ($null -ne $r.value) { @($r.value).Count } else { 1 }
        Write-Host ("  {0,-26}: OK (sample {1})" -f $label,$count) -ForegroundColor Green
    } catch {
        Write-Host ("  {0,-26}: FAILED — {1}" -f $label,$_.Exception.Message) -ForegroundColor Yellow
        $script:ok = $false
    }
}
Probe 'Managed devices'        "/v1.0/deviceManagement/managedDevices?`$top=1"
Probe 'Compliance policies'    "/v1.0/deviceManagement/deviceCompliancePolicies?`$top=1"
Probe 'Device configurations'  "/beta/deviceManagement/deviceConfigurations?`$top=1"
Probe 'Mobile apps'            "/v1.0/deviceAppManagement/mobileApps?`$top=1"
Probe 'Groups'                 "/v1.0/groups?`$top=1"

if ($ok) { Write-Host "`nResult: READY — all reporting data sources are readable." -ForegroundColor Green; exit 0 }
else     { Write-Host "`nResult: NOT READY — grant the missing read scope(s) and re-run." -ForegroundColor Yellow; exit 1 }
Disconnect-MgGraph | Out-Null

<#
.SYNOPSIS
    MAMAPP-Discovery.ps1 — inventory App Protection / App Configuration policies and the CA app-protection grant.
.DESCRIPTION
    PURPOSE
        Enumerates the tenant's iOS and Android App Protection Policies, managed-app App Configuration
        policies, and any Conditional Access policy that grants "Require app protection policy" — so you
        can see what MAM protection already exists before you configure the BYOD solution.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MAMAPP-Discovery.ps1
        Requires the Microsoft Graph SDK and scopes:
        DeviceManagementApps.Read.All and Policy.Read.All.
    EXPECTED RESULTS
        A list of iOS/Android App Protection Policies, App Configuration policies, and any CA policy
        whose grant includes an approved-app / app-protection control.
.NOTES
    Intune Solutions — MAM App Protection Policies for BYOD. Read-only against Graph.
#>
[CmdletBinding()] param()
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All','Policy.Read.All' -NoWelcome

Write-Host "`n=== iOS App Protection Policies ===" -ForegroundColor Cyan
$ios = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceAppManagement/iosManagedAppProtections').value
if ($ios) { foreach ($p in $ios) { Write-Host ("  {0}" -f $p.displayName) } } else { Write-Host "  none" -ForegroundColor Yellow }

Write-Host "=== Android App Protection Policies ===" -ForegroundColor Cyan
$and = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceAppManagement/androidManagedAppProtections').value
if ($and) { foreach ($p in $and) { Write-Host ("  {0}" -f $p.displayName) } } else { Write-Host "  none" -ForegroundColor Yellow }

Write-Host "=== App Configuration Policies (managed apps) ===" -ForegroundColor Cyan
$cfg = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceAppManagement/targetedManagedAppConfigurations').value
if ($cfg) { foreach ($c in $cfg) { Write-Host ("  {0}" -f $c.displayName) } } else { Write-Host "  none" -ForegroundColor Yellow }

Write-Host "=== Conditional Access — Require app protection policy ===" -ForegroundColor Cyan
$ca = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
$appCa = $ca | Where-Object { $_.grantControls -and ($_.grantControls.builtInControls -contains 'compliantApplication' -or $_.grantControls.builtInControls -contains 'approvedApplication') }
if ($appCa) { foreach ($c in $appCa) { Write-Host ("  {0}  [state: {1}]" -f $c.displayName, $c.state) } } else { Write-Host "  no CA policy requires app protection / approved app" -ForegroundColor Yellow }

Disconnect-MgGraph | Out-Null

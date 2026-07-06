<#
.SYNOPSIS
    MACCA-Discovery.ps1 — inventory enrolled Macs, macOS compliance policies, and CA policies (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Read-only baseline for the macOS Zero-Trust gate. Lists Intune-enrolled Macs with their
        compliance state and OS version, the macOS compliance policies in the tenant, and the
        Conditional Access policies that require a compliant device. Use it to size the pilot,
        pick a reachable minimum-OS floor, and see what already exists before you build.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MACCA-Discovery.ps1 -CsvPath C:\Temp\macca-macs.csv
        Requires Microsoft Graph SDK and scopes: DeviceManagementManagedDevices.Read.All,
        DeviceManagementConfiguration.Read.All, Policy.Read.All.
    EXPECTED RESULTS
        A table of Macs (name, OS version, compliance state), a list of macOS compliance policies,
        and a list of CA policies using the compliant-device control. Optional CSV of the Macs.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param([string]$CsvPath)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementConfiguration.Read.All','Policy.Read.All' -NoWelcome

# --- Enrolled Macs ---
Write-Host "=== Enrolled Macs (Intune) ===" -ForegroundColor Cyan
$uri = "/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'macOS'&`$select=deviceName,osVersion,complianceState,userPrincipalName,azureADRegistered"
$macs = @()
do {
    $resp = Invoke-MgGraphRequest -Method GET -Uri $uri
    $macs += $resp.value
    $uri = $resp.'@odata.nextLink'
} while ($uri)

$macReport = $macs | ForEach-Object {
    [pscustomobject]@{
        Device      = $_.deviceName
        OSVersion   = $_.osVersion
        Compliance  = $_.complianceState
        EntraReg    = $_.azureADRegistered
        User        = $_.userPrincipalName
    }
}
if ($macReport) { $macReport | Sort-Object Compliance, Device | Format-Table -AutoSize }
else { Write-Host "  (no macOS devices found)" -ForegroundColor Yellow }

$compliant = ($macReport | Where-Object Compliance -eq 'compliant').Count
Write-Host ("Macs total: {0} | Compliant: {1} | Other: {2}" -f $macReport.Count, $compliant, ($macReport.Count - $compliant)) -ForegroundColor Cyan

# --- macOS compliance policies ---
Write-Host "`n=== macOS compliance policies ===" -ForegroundColor Cyan
$cps = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/deviceManagement/deviceCompliancePolicies').value
$macCps = $cps | Where-Object { $_.'@odata.type' -match 'macOS' }
if ($macCps) { $macCps | ForEach-Object { Write-Host ("  {0}" -f $_.displayName) } }
else { Write-Host "  (none — build 'macOS - Zero-Trust Compliance' per the guide)" -ForegroundColor Yellow }

# --- CA policies requiring a compliant device ---
Write-Host "`n=== Conditional Access policies requiring a compliant device ===" -ForegroundColor Cyan
$pols = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
$compPols = $pols | Where-Object { $_.grantControls.builtInControls -contains 'compliantDevice' }
if ($compPols) {
    $compPols | ForEach-Object {
        $plat = ($_.conditions.platforms.includePlatforms -join ',')
        Write-Host ("  {0}  [state: {1}]  [platforms: {2}]" -f $_.displayName, $_.state, ($(if($plat){$plat}else{'all'})))
    }
} else { Write-Host "  (none — build 'CA - macOS - Require Compliant Device' per the guide)" -ForegroundColor Yellow }

if ($CsvPath -and $macReport) { $macReport | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "`nSaved $CsvPath" -ForegroundColor Green }
Disconnect-MgGraph | Out-Null

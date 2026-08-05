<#
.SYNOPSIS
    INTBASE-Validate-Enrollment.ps1 — confirm a Windows device enrolled and is compliant.

.DESCRIPTION
    PURPOSE
        Read-only validation for a single Windows device. Confirms the device is present in Intune,
        managed (MDM), Microsoft Entra joined, and reporting compliant — the exit criterion for both the
        user-driven and Autopilot enrollment paths.

    HOW TO RUN
        Connect-MgGraph -Environment Global -Scopes "DeviceManagementManagedDevices.Read.All","Device.Read.All"
        # Government: Connect-MgGraph -Environment USGov   (or USGovDoD)
        .\INTBASE-Validate-Enrollment.ps1 -DeviceName "PILOT-PC-01"

    EXPECTED RESULTS
        A PASS/FAIL table for the named device and an overall verdict. All PASS = the device is managed,
        Entra joined, and compliant. Read-only — makes no changes.

.NOTES
    Intune Solutions — read-only. Requires the Microsoft.Graph PowerShell module.
#>
[CmdletBinding()]
param([Parameter(Mandatory)][string]$DeviceName)

function R($n, $p, $d) { [pscustomobject]@{ Check = $n; Result = $(if ($p) { 'PASS' } else { 'FAIL' }); Detail = $d } }
$res = New-Object System.Collections.Generic.List[object]

if (-not (Get-MgContext)) { Write-Host "Not connected. Run Connect-MgGraph first." -ForegroundColor Red; exit 1 }

try {
    $flt = "deviceName eq '{0}'" -f ($DeviceName -replace "'", "''")
    $md = Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/deviceManagement/managedDevices?`$filter={0}" -f [uri]::EscapeDataString($flt))
    $dev = $md.value | Select-Object -First 1
} catch { Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 }

if (-not $dev) {
    Write-Host "Device '$DeviceName' not found in Intune managed devices." -ForegroundColor Yellow
    exit 2
}

$res.Add((R 'Present in Intune (managed device)' $true ("id=" + $dev.id)))
$res.Add((R 'Managed by Intune (MDM)' ($dev.managementAgent -match 'mdm') ("agent=" + $dev.managementAgent)))
$res.Add((R 'Microsoft Entra joined' ($dev.joinType -match 'azureADJoined' -or $dev.deviceEnrollmentType -match 'azureADJoined|windowsAutoEnrollment|windowsAzureADJoin') ("joinType=" + $dev.joinType + "; enrollType=" + $dev.deviceEnrollmentType)))
$res.Add((R 'Compliant' ($dev.complianceState -eq 'compliant') ("state=" + $dev.complianceState)))
$res.Add((R 'Windows platform' ($dev.operatingSystem -match 'Windows') ("os=" + $dev.operatingSystem + " " + $dev.osVersion)))

Write-Host "`n=== INTBASE Validate — $DeviceName ===" -ForegroundColor Cyan
$res | Format-Table -AutoSize
$overall = if ($res | Where-Object { $_.Result -eq 'FAIL' }) { 'FAIL' } else { 'PASS' }
Write-Host "Overall: $overall" -ForegroundColor $(if ($overall -eq 'PASS') { 'Green' } else { 'Yellow' })

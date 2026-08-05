<#
.SYNOPSIS
    INTBASE-Report-Enrollment.ps1 — list enrolled Windows devices and how each was enrolled.

.DESCRIPTION
    PURPOSE
        Read-only inventory of enrolled Windows devices with their enrollment method (user-driven Entra
        join vs Windows Autopilot), ownership, management state, and compliance — the evidence that both
        first-time enrollment paths landed devices under management.

    HOW TO RUN
        Connect-MgGraph -Environment Global -Scopes "DeviceManagementManagedDevices.Read.All"
        # Government: Connect-MgGraph -Environment USGov   (or USGovDoD)
        .\INTBASE-Report-Enrollment.ps1 -CsvPath .\INTBASE-Enrollment-Report.csv

    EXPECTED RESULTS
        A table (and optional CSV) of Windows managed devices with Method, Ownership, Compliance, and last
        check-in. Read-only — makes no changes.

.NOTES
    Intune Solutions — read-only. Requires the Microsoft.Graph PowerShell module.
#>
[CmdletBinding()]
param([string]$CsvPath)

if (-not (Get-MgContext)) { Write-Host "Not connected. Run Connect-MgGraph first." -ForegroundColor Red; exit 1 }

function Get-Method($d) {
    switch -Regex ($d.deviceEnrollmentType) {
        'windowsAutoEnrollment|windowsCoManagement' { 'Autopilot / Auto-enroll' ; break }
        'windowsAzureADJoin'                        { 'User-driven (Entra join)'; break }
        'windowsBulkAzureDomainJoin'                { 'Bulk / provisioning'      ; break }
        default                                     { $d.deviceEnrollmentType }
    }
}

$all = @()
$uri = "/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'Windows'&`$top=100"
do {
    $page = Invoke-MgGraphRequest -Method GET -Uri $uri
    $all += $page.value
    $uri = $page.'@odata.nextLink'
} while ($uri)

$rows = $all | ForEach-Object {
    [pscustomobject]@{
        DeviceName   = $_.deviceName
        Method       = Get-Method $_
        Ownership    = $_.managedDeviceOwnerType
        Managed      = $_.managementAgent
        Compliance   = $_.complianceState
        OS           = ("{0} {1}" -f $_.operatingSystem, $_.osVersion)
        User         = $_.userPrincipalName
        LastCheckIn  = $_.lastSyncDateTime
    }
}

Write-Host "`n=== INTBASE Windows Enrollment Report ($($rows.Count) device(s)) ===" -ForegroundColor Cyan
$rows | Sort-Object Method, DeviceName | Format-Table -AutoSize

$byMethod = $rows | Group-Object Method | Select-Object Name, Count
Write-Host "`nBy enrollment method:" -ForegroundColor Cyan
$byMethod | Format-Table -AutoSize

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "Saved report to $CsvPath" -ForegroundColor Green
}

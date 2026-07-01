<#
.SYNOPSIS
    CLINDEV-Report.ps1 — Fleet report for shared clinical Windows devices managed by Microsoft
    Intune, exported to CSV.

    PURPOSE
        Read-only fleet-level reporting: counts of shared clinical devices broken down by device
        type (WOW / Kiosk / Tablet / Nurse-Station, inferred from the device-name prefix),
        configuration profile applied, and compliance state. Run on a schedule and after each
        Expand wave to track coverage and drift across the fleet.

    HOW TO RUN
        1. Install-Module Microsoft.Graph -Scope CurrentUser   (if needed)
        2. Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All","DeviceManagementConfiguration.Read.All","Group.Read.All","Directory.Read.All"
        3. .\CLINDEV-Report.ps1
           .\CLINDEV-Report.ps1 -CsvPath .\clindev-fleet-report.csv

    EXPECTED RESULTS
        Console summary tables (counts by device type, by compliance, by Shared-PC-profile applied)
        and a per-device CSV with DeviceName, DeviceType, EnrollmentType, SharedProfileApplied,
        Compliance, and PrimaryUser. Use the counts to confirm full, correct coverage of the
        'Clinical - Shared Devices' fleet.

.NOTES
    Healthcare Solutions — read-only.
#>

[CmdletBinding()]
param(
    [string] $GroupName         = "Clinical - Shared Devices",
    [string] $SharedProfileName = "Clinical Shared - Shared PC Mode - Standardize",
    [string] $CsvPath           = ".\clindev-fleet-report.csv"
)

function Assert-Graph {
    if (-not (Get-MgContext)) {
        throw "Not connected to Microsoft Graph. Run Connect-MgGraph with read scopes first (see .SYNOPSIS)."
    }
}
function Get-DeviceType([string]$name) {
    switch -Regex ($name) {
        '^WOW'             { 'WOW (Workstation-on-Wheels)'; break }
        '^KIOSK'           { 'Kiosk'; break }
        '^(TAB|TABLET)'    { 'Clinical Tablet'; break }
        '^(NS|NURSE)'      { 'Nurse-Station PC'; break }
        default            { 'Unclassified' }
    }
}

try {
    Assert-Graph

    $group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction SilentlyContinue | Select-Object -First 1
    $memberDeviceIds = @()
    if ($group) {
        $memberDeviceIds = (Get-MgGroupMember -GroupId $group.Id -All) |
            ForEach-Object { $_.AdditionalProperties.deviceId } | Where-Object { $_ }
    } else {
        Write-Warning "Group '$GroupName' not found — reporting across all Windows devices instead."
    }

    $devices = Get-MgDeviceManagementManagedDevice -All -Filter "operatingSystem eq 'Windows'" -ErrorAction Stop
    if ($group) {
        $devices = $devices | Where-Object { $memberDeviceIds -contains $_.AzureAdDeviceId }
    }

    $rows = foreach ($d in $devices) {
        $profileApplied = $false
        try {
            $states = Get-MgDeviceManagementManagedDeviceDeviceConfigurationState -ManagedDeviceId $d.Id -ErrorAction Stop
            $profileApplied = [bool]($states | Where-Object { $_.DisplayName -eq $SharedProfileName -and $_.State -eq 'compliant' })
        } catch { $profileApplied = $false }

        [pscustomobject]@{
            DeviceName           = $d.DeviceName
            DeviceType           = Get-DeviceType $d.DeviceName
            EnrollmentType       = $d.DeviceEnrollmentType
            SharedProfileApplied = $profileApplied
            Compliance           = $d.ComplianceState
            PrimaryUser          = if ([string]::IsNullOrWhiteSpace($d.UserPrincipalName)) { "<none>" } else { $d.UserPrincipalName }
        }
    }

    Write-Host "=== Count by device type ===" -ForegroundColor Cyan
    $rows | Group-Object DeviceType | Select-Object Name, Count | Format-Table -AutoSize

    Write-Host "=== Count by compliance ===" -ForegroundColor Cyan
    $rows | Group-Object Compliance | Select-Object Name, Count | Format-Table -AutoSize

    Write-Host "=== Shared PC profile applied ===" -ForegroundColor Cyan
    $rows | Group-Object SharedProfileApplied | Select-Object @{n='ProfileApplied';e={$_.Name}}, Count | Format-Table -AutoSize

    $rows | Sort-Object DeviceType, DeviceName | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Total shared clinical devices: {0}. Exported to {1}" -f $rows.Count, $CsvPath) -ForegroundColor Green
}
catch {
    Write-Error "CLINDEV-Report failed: $($_.Exception.Message)"
    exit 1
}

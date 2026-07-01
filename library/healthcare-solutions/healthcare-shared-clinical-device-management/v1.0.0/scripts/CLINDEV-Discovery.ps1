<#
.SYNOPSIS
    CLINDEV-Discovery.ps1 — Inventory shared clinical Windows devices (WOWs, kiosks, nurse-station
    PCs, tablets) managed by Microsoft Intune.

    PURPOSE
        Read-only discovery of candidate shared clinical devices: enrollment type, Shared PC mode
        state, membership in the 'Clinical - Shared Devices' group, and primary user (which on a
        true shared device should be NONE). Use this first, during the Assess phase, to size the
        fleet and spot devices that are mis-modeled (e.g. a personal primary user on a cart).

    HOW TO RUN
        1. Install the Microsoft Graph PowerShell SDK if needed:
               Install-Module Microsoft.Graph -Scope CurrentUser
        2. Connect with read-only scopes:
               Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All","Group.Read.All","Directory.Read.All"
        3. Run:
               .\CLINDEV-Discovery.ps1
               .\CLINDEV-Discovery.ps1 -GroupName "Clinical - Shared Devices" -CsvPath .\clindev-discovery.csv

    EXPECTED RESULTS
        A table (and optional CSV) of shared clinical devices with: DeviceName, OS/Version,
        EnrollmentType, ManagementState, InSharedDeviceGroup (True/False), PrimaryUser (should be
        '<none>'), and Compliance. Devices with a non-empty PrimaryUser are flagged as candidates
        for remediation (see CLINDEV-Remediation.ps1).

.NOTES
    Healthcare Solutions — read-only.
#>

[CmdletBinding()]
param(
    [string] $GroupName = "Clinical - Shared Devices",
    [string] $CsvPath
)

function Assert-Graph {
    if (-not (Get-MgContext)) {
        throw "Not connected to Microsoft Graph. Run Connect-MgGraph with read scopes first (see .SYNOPSIS)."
    }
}

try {
    Assert-Graph

    Write-Host "Resolving shared-device group '$GroupName'..." -ForegroundColor Cyan
    $group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction SilentlyContinue | Select-Object -First 1
    $memberDeviceIds = @()
    if ($group) {
        $members = Get-MgGroupMember -GroupId $group.Id -All -ErrorAction SilentlyContinue
        $memberDeviceIds = $members | ForEach-Object { $_.AdditionalProperties.deviceId } | Where-Object { $_ }
    } else {
        Write-Warning "Group '$GroupName' not found. InSharedDeviceGroup will report False for all devices."
    }

    Write-Host "Enumerating Windows managed devices..." -ForegroundColor Cyan
    $devices = Get-MgDeviceManagementManagedDevice -All -Filter "operatingSystem eq 'Windows'" -ErrorAction Stop

    $rows = foreach ($d in $devices) {
        $primary = if ([string]::IsNullOrWhiteSpace($d.UserPrincipalName)) { "<none>" } else { $d.UserPrincipalName }
        [pscustomobject]@{
            DeviceName          = $d.DeviceName
            OS                  = $d.OperatingSystem
            OSVersion           = $d.OsVersion
            EnrollmentType      = $d.DeviceEnrollmentType
            ManagementState     = $d.ManagementState
            InSharedDeviceGroup = [bool]($memberDeviceIds -contains $d.AzureAdDeviceId)
            PrimaryUser         = $primary
            Compliance          = $d.ComplianceState
            SerialNumber        = $d.SerialNumber
        }
    }

    $rows | Sort-Object DeviceName | Format-Table -AutoSize

    $withOwner = $rows | Where-Object { $_.PrimaryUser -ne "<none>" }
    Write-Host ""
    Write-Host ("Total Windows devices: {0} | In '{1}': {2} | With a (stray) primary user: {3}" -f `
        $rows.Count, $GroupName, ($rows | Where-Object InSharedDeviceGroup).Count, $withOwner.Count) -ForegroundColor Yellow
    if ($withOwner.Count -gt 0) {
        Write-Warning "Devices with a primary user should be reviewed — shared clinical devices should have PrimaryUser = <none>. See CLINDEV-Remediation.ps1."
    }

    if ($CsvPath) {
        $rows | Sort-Object DeviceName | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
        Write-Host "Exported to $CsvPath" -ForegroundColor Green
    }
}
catch {
    Write-Error "CLINDEV-Discovery failed: $($_.Exception.Message)"
    exit 1
}

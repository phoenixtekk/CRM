<#
.SYNOPSIS
    CLINDEV-Validation.ps1 — Per-device PASS/FAIL validation for shared clinical Windows devices in
    Microsoft Intune.

    PURPOSE
        Read-only validation that each shared clinical device meets the standard model:
          1. Enrolled and managed in Intune.
          2. Member of the 'Clinical - Shared Devices' group.
          3. The Shared PC mode (and, where applicable, kiosk) configuration profile is applied.
          4. The clinical app baseline is installed.
          5. No personal primary user (owner-less).
        Each device gets a PASS/FAIL per check and an overall result. Run during Pilot and after
        each Expand wave; use before declaring the acceptance gate (see 05-testing.md) met.

    HOW TO RUN
        1. Install-Module Microsoft.Graph -Scope CurrentUser   (if needed)
        2. Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All","DeviceManagementConfiguration.Read.All","DeviceManagementApps.Read.All","Group.Read.All","Directory.Read.All"
        3. .\CLINDEV-Validation.ps1
           .\CLINDEV-Validation.ps1 -SharedProfileName "Clinical Shared - Shared PC Mode - Standardize" `
                                    -RequiredApps "Epic Hyperdrive","Microsoft Edge" -CsvPath .\clindev-validation.csv

    EXPECTED RESULTS
        A per-device table with Enrolled / InGroup / SharedProfileApplied / AppsInstalled /
        NoPrimaryUser columns (PASS/FAIL) and an Overall result, plus a summary count of devices
        passing all checks. FAIL rows indicate exactly which check to remediate.

.NOTES
    Healthcare Solutions — read-only.
#>

[CmdletBinding()]
param(
    [string]   $GroupName          = "Clinical - Shared Devices",
    [string]   $SharedProfileName  = "Clinical Shared - Shared PC Mode - Standardize",
    [string]   $KioskProfileName   = "Clinical Shared - Kiosk Assigned Access - Lock-down",
    [string[]] $RequiredApps       = @("Epic Hyperdrive"),
    [string]   $CsvPath
)

function Assert-Graph {
    if (-not (Get-MgContext)) {
        throw "Not connected to Microsoft Graph. Run Connect-MgGraph with read scopes first (see .SYNOPSIS)."
    }
}
function PF([bool]$b) { if ($b) { "PASS" } else { "FAIL" } }

try {
    Assert-Graph

    $group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction SilentlyContinue | Select-Object -First 1
    $memberDeviceIds = @()
    if ($group) {
        $memberDeviceIds = (Get-MgGroupMember -GroupId $group.Id -All) |
            ForEach-Object { $_.AdditionalProperties.deviceId } | Where-Object { $_ }
    } else {
        Write-Warning "Group '$GroupName' not found — InGroup will FAIL for all devices."
    }

    $devices = Get-MgDeviceManagementManagedDevice -All -Filter "operatingSystem eq 'Windows'" -ErrorAction Stop

    $rows = foreach ($d in $devices) {
        $enrolled  = ($d.ManagementState -eq 'managed') -and ($d.DeviceEnrollmentType -ne 'unknown')
        $inGroup   = [bool]($memberDeviceIds -contains $d.AzureAdDeviceId)
        $noOwner   = [string]::IsNullOrWhiteSpace($d.UserPrincipalName)

        # Configuration profile state (Shared PC / kiosk) via device config states
        $profileApplied = $false
        try {
            $states = Get-MgDeviceManagementManagedDeviceDeviceConfigurationState -ManagedDeviceId $d.Id -ErrorAction Stop
            $profileApplied = [bool]($states | Where-Object {
                ($_.DisplayName -eq $SharedProfileName -or $_.DisplayName -eq $KioskProfileName) -and $_.State -eq 'compliant'
            })
        } catch { $profileApplied = $false }

        # App baseline presence
        $appsOk = $true
        try {
            $appStates = Get-MgDeviceManagementManagedDeviceDetectedApp -ManagedDeviceId $d.Id -All -ErrorAction Stop
            $detected  = $appStates.DisplayName
            foreach ($app in $RequiredApps) {
                if (-not ($detected | Where-Object { $_ -like "*$app*" })) { $appsOk = $false }
            }
        } catch { $appsOk = $false }

        $overall = $enrolled -and $inGroup -and $profileApplied -and $appsOk -and $noOwner

        [pscustomobject]@{
            DeviceName           = $d.DeviceName
            Enrolled             = PF $enrolled
            InGroup              = PF $inGroup
            SharedProfileApplied = PF $profileApplied
            AppsInstalled        = PF $appsOk
            NoPrimaryUser        = PF $noOwner
            Overall              = PF $overall
        }
    }

    $rows | Sort-Object DeviceName | Format-Table -AutoSize
    $pass = ($rows | Where-Object { $_.Overall -eq 'PASS' }).Count
    Write-Host ""
    Write-Host ("Devices passing ALL checks: {0} / {1}" -f $pass, $rows.Count) -ForegroundColor Yellow

    if ($CsvPath) {
        $rows | Sort-Object DeviceName | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
        Write-Host "Exported to $CsvPath" -ForegroundColor Green
    }
}
catch {
    Write-Error "CLINDEV-Validation failed: $($_.Exception.Message)"
    exit 1
}

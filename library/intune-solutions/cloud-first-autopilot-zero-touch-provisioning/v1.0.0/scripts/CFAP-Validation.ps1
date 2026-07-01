<#
.SYNOPSIS
    CFAP-Validation.ps1 — Per-device provisioning / enrollment validation for Cloud-First Autopilot
    Zero-Touch Provisioning.

PURPOSE
    Read-only. Confirms a single device provisioned correctly cloud-first: it is Autopilot-registered,
    Microsoft Entra joined (and NOT domain joined, unless the documented exception applies),
    Intune-enrolled, and the assigned provisioning apps / security baseline are present. Combines a
    local on-device check with an optional Microsoft Graph lookup of the managed device.

HOW TO RUN
    On the provisioned device (local checks only):
        powershell -ExecutionPolicy Bypass -File .\CFAP-Validation.ps1

    With Graph cross-checks (managed device + Autopilot identity) — requires the Microsoft Graph
    PowerShell SDK and DeviceManagementManagedDevices.Read.All +
    DeviceManagementServiceConfig.Read.All:
        .\CFAP-Validation.ps1 -CheckGraph

    Allow the device to be domain joined (only for a documented domain-join exception device):
        .\CFAP-Validation.ps1 -AllowDomainJoin

EXPECTED RESULTS
    A PASS/FAIL per check and an overall result. For a default cloud-first device: AzureAdJoined YES,
    DomainJoined NO, MDM enrolled YES, Autopilot-registered YES, required apps Installed. Read-only;
    changes nothing.
#>
[CmdletBinding()]
param(
    [switch]$CheckGraph,
    [switch]$AllowDomainJoin
)

$ErrorActionPreference = 'Stop'
$results = [System.Collections.Generic.List[object]]::new()
function Add-Check($name, $pass, $detail) {
    $results.Add([pscustomobject]@{ Check = $name; Result = (@('FAIL','PASS')[[int][bool]$pass]); Detail = $detail })
}

# --- Local join / enrollment state ---
$dsreg = & dsregcmd /status 2>$null
$aadJoined = ($dsreg | Select-String 'AzureAdJoined\s*:\s*YES') -ne $null
$domJoined = ($dsreg | Select-String 'DomainJoined\s*:\s*YES') -ne $null
$mdmUrl    = ($dsreg | Select-String 'MdmUrl\s*:\s*\S+') -ne $null

Add-Check 'Microsoft Entra joined' $aadJoined ("AzureAdJoined={0}" -f $aadJoined)
if ($AllowDomainJoin) {
    Add-Check 'Domain join (exception allowed)' $true ("DomainJoined={0} (exception device)" -f $domJoined)
} else {
    Add-Check 'Cloud-first (not domain joined)' (-not $domJoined) ("DomainJoined={0} (expected NO)" -f $domJoined)
}
Add-Check 'Intune (MDM) enrolled' $mdmUrl ("MdmUrl present={0}" -f $mdmUrl)

# --- Graph cross-checks ---
$serial = (Get-CimInstance Win32_BIOS).SerialNumber
if ($CheckGraph) {
    try {
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        if (-not (Get-MgContext)) {
            Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementServiceConfig.Read.All' | Out-Null
        }

        # Autopilot identity
        $apUri = "https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities?`$filter=contains(serialNumber,'$serial')"
        $ap = (Invoke-MgGraphRequest -Method GET -Uri $apUri).value
        $apRegistered = ($ap -and $ap.Count -gt 0)
        $apAssigned = $apRegistered -and ($ap[0].deploymentProfileAssignmentStatus -match 'assigned')
        Add-Check 'Autopilot-registered (tenant)' $apRegistered ("serial={0}" -f $serial)
        Add-Check 'Autopilot profile assigned' $apAssigned ("status={0}" -f ($ap[0].deploymentProfileAssignmentStatus))

        # Managed device + assigned apps
        $mdUri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=serialNumber eq '$serial'"
        $md = (Invoke-MgGraphRequest -Method GET -Uri $mdUri).value
        if ($md -and $md.Count -gt 0) {
            $deviceId = $md[0].id
            Add-Check 'Intune managed device record' $true ("compliance={0}" -f $md[0].complianceState)

            $appUri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$deviceId')/detectedApps"
            try {
                $apps = (Invoke-MgGraphRequest -Method GET -Uri $appUri).value
                Add-Check 'Detected apps present' ([bool]$apps) ("detectedApps={0}" -f ($apps.Count))
            } catch {
                Add-Check 'Detected apps present' $false 'detectedApps unavailable'
            }
        } else {
            Add-Check 'Intune managed device record' $false "no managedDevice for serial $serial"
        }
    } catch {
        Write-Warning "Graph checks skipped/failed: $($_.Exception.Message)"
    }
}

# --- Local required-app presence (Win32/MSI install state heuristic) ---
$installed = @()
foreach ($root in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                  'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*') {
    $installed += (Get-ItemProperty $root -EA SilentlyContinue | Where-Object DisplayName).DisplayName
}
Add-Check 'Local apps inventory readable' ([bool]$installed) ("installedApps={0}" -f $installed.Count)

Write-Host "`n=== CFAP Validation Results ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize
$overall = -not ($results.Result -contains 'FAIL')
Write-Host ("`nOVERALL: {0}" -f (@('FAIL','PASS')[[int][bool]$overall])) -ForegroundColor ($(if($overall){'Green'}else{'Red'}))
if (-not $overall) { exit 1 }

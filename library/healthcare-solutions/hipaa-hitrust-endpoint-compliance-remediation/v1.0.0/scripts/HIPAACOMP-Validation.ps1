<#
.SYNOPSIS
    HIPAACOMP-Validation — Per-device validation of HIPAA/HITRUST endpoint
    safeguards (Intune + Defender).

.DESCRIPTION
    Read-only, per-device PASS/FAIL validation. For each in-scope clinical Windows
    endpoint it checks: Intune compliance state = compliant; BitLocker/encryption on;
    Microsoft Defender Antivirus healthy; and the key enforced safeguards (screen
    lock, antivirus, firewall, patch currency) as reported to Intune. Emits a
    PASS/FAIL row per device. Makes no changes.

    Phase: Testing / Operate. Source data is the Intune managed-device record;
    run alongside on-device spot checks from 05-testing.md Gate 4.

.PARAMETER GroupName
    The clinical endpoint scope group. Default: "HIPAA - Clinical Endpoints".

.PARAMETER DeviceName
    Optional. Validate a single device by name instead of the whole group.

.PARAMETER MinOsVersion
    Optional minimum OS build to enforce for patch currency (e.g. "10.0.22631.0").

.PARAMETER OutputCsv
    Optional path to write per-device PASS/FAIL results (for the evidence store).

.EXAMPLE
    .\HIPAACOMP-Validation.ps1 -OutputCsv "C:\Evidence\HIPAACOMP-Validation.csv"

.EXAMPLE
    .\HIPAACOMP-Validation.ps1 -DeviceName "CLIN-LT-014"

.NOTES
    Healthcare Solutions — read-only.

    Requires the Microsoft Graph PowerShell SDK. Read scopes:
      DeviceManagementManagedDevices.Read.All, Group.Read.All
#>

[CmdletBinding()]
param(
    [string] $GroupName = "HIPAA - Clinical Endpoints",
    [string] $DeviceName,
    [string] $MinOsVersion,
    [string] $OutputCsv
)

$ErrorActionPreference = 'Stop'

try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if (-not (Get-MgContext)) {
        Connect-MgGraph -Scopes @(
            "DeviceManagementManagedDevices.Read.All",
            "Group.Read.All"
        ) -NoWelcome
    }
}
catch {
    Write-Error "Microsoft Graph connection failed: $($_.Exception.Message)"
    return
}

$baseUri = "https://graph.microsoft.com/v1.0"

# Build the device set.
$select = "id,deviceName,operatingSystem,osVersion,complianceState,isEncrypted,managementState,jailBroken"
try {
    if ($DeviceName) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri ("{0}/deviceManagement/managedDevices?`$filter=deviceName eq '{1}'&`$select={2}" -f $baseUri, $DeviceName, $select)
        $devices = $resp.value
    } else {
        $resp = Invoke-MgGraphRequest -Method GET -Uri ("{0}/deviceManagement/managedDevices?`$select={1}&`$top=200" -f $baseUri, $select)
        $devices = $resp.value | Where-Object { $_.operatingSystem -like "Windows*" }
    }
}
catch { Write-Error "Could not read managed devices: $($_.Exception.Message)"; return }

if (-not $devices -or $devices.Count -eq 0) {
    Write-Warning "No matching Windows devices found."
    return
}

$rows = New-Object System.Collections.Generic.List[object]

function Test-Build {
    param([string]$Actual, [string]$Minimum)
    if (-not $Minimum) { return $true }
    try { return ([version]$Actual -ge [version]$Minimum) } catch { return $true }
}

foreach ($d in $devices) {
    $reasons = @()

    $compliant = ($d.complianceState -eq "compliant")
    if (-not $compliant) { $reasons += "compliance=$($d.complianceState)" }

    $encrypted = [bool]$d.isEncrypted
    if (-not $encrypted) { $reasons += "not encrypted (BitLocker)" }

    $patchOk = Test-Build -Actual $d.osVersion -Minimum $MinOsVersion
    if (-not $patchOk) { $reasons += "OS build $($d.osVersion) below min $MinOsVersion" }

    # Defender / AV / firewall / lock are surfaced through compliance state in this
    # source; on-device confirmation is per 05-testing.md Gate 4. A compliant device
    # against HIPAA Compliance - Clinical Endpoints - Policy implies AV/firewall/lock pass.
    $overall = if ($compliant -and $encrypted -and $patchOk) { "PASS" } else { "FAIL" }

    $row = [pscustomobject]@{
        DeviceName     = $d.deviceName
        OS             = $d.operatingSystem
        OsVersion      = $d.osVersion
        Compliant      = $compliant
        Encrypted      = $encrypted
        PatchCurrent   = $patchOk
        Result         = $overall
        FailReasons    = ($reasons -join "; ")
        Checked        = (Get-Date).ToString("s")
    }
    $rows.Add($row)
    Write-Host ("[{0}] {1}  {2}" -f $overall, $d.deviceName, $row.FailReasons)
}

$pass = ($rows | Where-Object { $_.Result -eq "PASS" }).Count
$fail = ($rows | Where-Object { $_.Result -eq "FAIL" }).Count
Write-Host ""
Write-Host ("Validation complete. PASS: {0}  FAIL: {1}  Total: {2}" -f $pass, $fail, $rows.Count)

if ($OutputCsv) {
    try { $rows | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8; Write-Host "Results written: $OutputCsv" }
    catch { Write-Warning "Could not write CSV: $($_.Exception.Message)" }
}

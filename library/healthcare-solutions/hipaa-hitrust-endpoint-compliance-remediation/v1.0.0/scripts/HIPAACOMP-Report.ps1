<#
.SYNOPSIS
    HIPAACOMP-Report — Audit-ready compliance + vulnerability exposure evidence
    report (Intune + Defender) to CSV.

.DESCRIPTION
    Read-only. Produces a consolidated, date-stamped evidence report for the
    HIPAA/HITRUST endpoint control set: per-device Intune compliance state and key
    safeguard status, plus Microsoft Defender Vulnerability Management exposure
    context. Output is written as CSV to the evidence repository. Captures
    configuration/compliance metadata only — never ePHI. Makes no changes.

    Phase: Evidence/Report. Schedule on a cadence (Operate phase).

.PARAMETER GroupName
    The clinical endpoint scope group. Default: "HIPAA - Clinical Endpoints".

.PARAMETER OutputCsv
    Path to write the evidence report. Default: a date-stamped file in the current
    directory. Point this at the secured evidence repository (Requirement R11).

.EXAMPLE
    .\HIPAACOMP-Report.ps1 -OutputCsv "\\evidence\HIPAA\HIPAACOMP-Report.csv"

.NOTES
    Healthcare Solutions — read-only.

    Requires the Microsoft Graph PowerShell SDK. Read scopes:
      DeviceManagementManagedDevices.Read.All,
      DeviceManagementConfiguration.Read.All, Group.Read.All
    Defender exposure score is read from the Defender portal / Security Graph where
    entitled; when not available via Graph, the report notes it for manual capture
    from security.microsoft.com > Vulnerability management > Dashboard.
#>

[CmdletBinding()]
param(
    [string] $GroupName = "HIPAA - Clinical Endpoints",
    [string] $OutputCsv = ("HIPAACOMP-Report-{0}.csv" -f (Get-Date -Format "yyyyMMdd"))
)

$ErrorActionPreference = 'Stop'

try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if (-not (Get-MgContext)) {
        Connect-MgGraph -Scopes @(
            "DeviceManagementManagedDevices.Read.All",
            "DeviceManagementConfiguration.Read.All",
            "Group.Read.All"
        ) -NoWelcome
    }
}
catch {
    Write-Error "Microsoft Graph connection failed: $($_.Exception.Message)"
    return
}

$baseUri = "https://graph.microsoft.com/v1.0"
$reportDate = (Get-Date).ToString("s")

# --- Per-device compliance + safeguard metadata ---
$select = "deviceName,operatingSystem,osVersion,complianceState,isEncrypted,managementState,lastSyncDateTime"
$rows = New-Object System.Collections.Generic.List[object]
try {
    $resp = Invoke-MgGraphRequest -Method GET -Uri ("{0}/deviceManagement/managedDevices?`$select={1}&`$top=500" -f $baseUri, $select)
    $devices = $resp.value | Where-Object { $_.operatingSystem -like "Windows*" }
    foreach ($d in $devices) {
        $rows.Add([pscustomobject]@{
            ReportDate      = $reportDate
            ScopeGroup      = $GroupName
            DeviceName      = $d.deviceName
            OS              = $d.operatingSystem
            OsVersion       = $d.osVersion
            ComplianceState = $d.complianceState
            Encrypted       = [bool]$d.isEncrypted
            ManagementState = $d.managementState
            LastSync        = $d.lastSyncDateTime
            ExposureNote    = "See Defender dashboard for device exposure level"
        })
    }
}
catch { Write-Warning "Could not read managed devices: $($_.Exception.Message)" }

# --- Tenant-level exposure context (best-effort via Graph security; else note) ---
$exposureSummary = "Capture Exposure score + Secure Score for Devices from security.microsoft.com > Vulnerability management > Dashboard (compare to baseline per Implementation Step 10)."
try {
    $secScore = Invoke-MgGraphRequest -Method GET -Uri ("{0}/security/secureScores?`$top=1" -f $baseUri)
    if ($secScore.value.Count -ge 1) {
        $s = $secScore.value[0]
        $exposureSummary = ("Tenant Secure Score {0}/{1} as of {2}. Confirm device-level exposure in Defender dashboard." -f $s.currentScore, $s.maxScore, $s.createdDateTime)
    }
}
catch { Write-Verbose "Secure Score not available via Graph: $($_.Exception.Message)" }

# --- Summary counts ---
$total      = $rows.Count
$compliant  = ($rows | Where-Object { $_.ComplianceState -eq "compliant" }).Count
$encrypted  = ($rows | Where-Object { $_.Encrypted }).Count

Write-Host ("HIPAACOMP evidence report - {0}" -f $reportDate)
Write-Host ("Windows devices: {0} | Compliant: {1} | Encrypted: {2}" -f $total, $compliant, $encrypted)
Write-Host $exposureSummary

# --- Write CSV evidence ---
try {
    $rows | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
    # Append a summary footer line as a second small file for the evidence set.
    $summaryPath = [System.IO.Path]::ChangeExtension($OutputCsv, $null) + "summary.csv"
    [pscustomobject]@{
        ReportDate     = $reportDate
        ScopeGroup     = $GroupName
        WindowsDevices = $total
        Compliant      = $compliant
        Encrypted      = $encrypted
        ExposureNote   = $exposureSummary
    } | Export-Csv -Path $summaryPath -NoTypeInformation -Encoding UTF8
    Write-Host "Evidence written: $OutputCsv"
    Write-Host "Summary written:  $summaryPath"
    Write-Host "Store in the secured, retained evidence repository (Requirement R11). Metadata only - no ePHI."
}
catch { Write-Error "Could not write report: $($_.Exception.Message)" }

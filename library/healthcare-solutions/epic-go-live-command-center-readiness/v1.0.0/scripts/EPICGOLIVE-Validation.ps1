<#
.SYNOPSIS
    EPICGOLIVE-Validation — per-device go/no-go validation for an Epic go-live.

.DESCRIPTION
    Evaluates each in-scope clinical endpoint against the readiness standard
    ("Endpoint Readiness Checklist - Clinical Fleet - Pre-Go-Live") and returns a
    PASS / FAIL per device with the failing check(s). Read-only: it inspects device,
    compliance, and detected-app state from Microsoft Intune / Microsoft Entra via
    Microsoft Graph and computes PASS/FAIL — it changes nothing.

    Checks evaluated per device:
      1. Enrolled            (device enrolled in Intune)
      2. Compliant           (compliance state = compliant)
      3. EpicVersion         (detected Epic client version equals the target string)
      4. ImprivataPresent    (Imprivata agent detected — for classes requiring tap)
      5. CheckedInRecently   (last sync within the freshness window)

    Printing, peripheral-enumeration, and login-time checks require device-side / functional
    confirmation during the sweep; this script surfaces the data points it can read and marks
    the human-confirmed checks as 'Manual' so the validator records them on the checklist.

.PARAMETER GroupId
    Object ID of the "Readiness Device Group - Clinical Fleet - Validation".

.PARAMETER TargetEpicVersion
    The exact Epic client version string designated for this go-live (from the readiness checklist).

.PARAMETER EpicAppNameLike
    Display-name match used to detect the Epic client (e.g. 'Hyperdrive').

.PARAMETER ImprivataAppNameLike
    Display-name match used to detect the Imprivata agent (e.g. 'Imprivata').

.PARAMETER RequireImprivata
    Switch — when set, ImprivataPresent is a graded check (FAIL if absent). Omit for device
    classes that do not use tap-and-go.

.PARAMETER MaxSyncAgeHours
    Freshness window for the check-in test. Default 24.

.PARAMETER OutputPath
    Optional path to write the per-device validation results CSV.

.EXAMPLE
    Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','Group.Read.All'
    .\EPICGOLIVE-Validation.ps1 -GroupId <guid> -TargetEpicVersion '10.x.x' -RequireImprivata

.NOTES
    Healthcare Solutions — read-only.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $GroupId,
    [Parameter(Mandatory)] [string] $TargetEpicVersion,
    [string] $EpicAppNameLike = 'Hyperdrive',
    [string] $ImprivataAppNameLike = 'Imprivata',
    [switch] $RequireImprivata,
    [int]    $MaxSyncAgeHours = 24,
    [string] $OutputPath
)

function Assert-Graph {
    if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue)) {
        throw "Microsoft.Graph PowerShell SDK not found. Install-Module Microsoft.Graph, then Connect-MgGraph."
    }
    if (-not (Get-MgContext)) {
        throw "Not connected to Microsoft Graph. Run Connect-MgGraph with read scopes."
    }
}
Assert-Graph

function Get-DetectedAppVersion {
    param([string] $ManagedDeviceId, [string] $NameLike)
    try {
        $apps = Get-MgDeviceManagementManagedDeviceDetectedApp -ManagedDeviceId $ManagedDeviceId -All -ErrorAction Stop
        $match = $apps | Where-Object { $_.DisplayName -like "*$NameLike*" } |
            Sort-Object Version -Descending | Select-Object -First 1
        if ($match) { return $match.Version }
    } catch { }
    return $null
}

Write-Host "EPICGOLIVE-Validation — evaluating readiness (read-only)..." -ForegroundColor Cyan

# Resolve in-scope managed devices via the readiness group.
$members   = Get-MgGroupMember -GroupId $GroupId -All
$deviceIds = $members | Where-Object { $_.AdditionalProperties.'@odata.type' -match 'device' } |
    ForEach-Object { $_.AdditionalProperties.deviceId }
$devices = Get-MgDeviceManagementManagedDevice -All |
    Where-Object { $deviceIds -contains $_.AzureAdDeviceId }

$now = Get-Date

$results = foreach ($d in $devices) {
    $epicVer      = Get-DetectedAppVersion -ManagedDeviceId $d.Id -NameLike $EpicAppNameLike
    $imprivataVer = Get-DetectedAppVersion -ManagedDeviceId $d.Id -NameLike $ImprivataAppNameLike

    $checkEnrolled  = [bool]$d.EnrolledDateTime
    $checkCompliant = ($d.ComplianceState -eq 'compliant')
    $checkEpic      = ($epicVer -eq $TargetEpicVersion)
    $checkImprivata = if ($RequireImprivata) { [bool]$imprivataVer } else { $true }
    $checkFresh     = if ($d.LastSyncDateTime) {
        (($now - [datetime]$d.LastSyncDateTime).TotalHours -le $MaxSyncAgeHours)
    } else { $false }

    $failed = @()
    if (-not $checkEnrolled)  { $failed += 'NotEnrolled' }
    if (-not $checkCompliant) { $failed += 'NonCompliant' }
    if (-not $checkEpic)      { $failed += "EpicVersion(found='$epicVer' want='$TargetEpicVersion')" }
    if (-not $checkImprivata) { $failed += 'ImprivataMissing' }
    if (-not $checkFresh)     { $failed += 'StaleCheckIn' }

    [pscustomobject]@{
        DeviceName        = $d.DeviceName
        ManagedDeviceId   = $d.Id
        Result            = if ($failed.Count -eq 0) { 'PASS' } else { 'FAIL' }
        FailedChecks      = ($failed -join '; ')
        Enrolled          = $checkEnrolled
        Compliant         = $checkCompliant
        EpicVersionOK     = $checkEpic
        EpicVersionFound  = $epicVer
        ImprivataOK       = $checkImprivata
        CheckedInRecently = $checkFresh
        Printing          = 'Manual'   # confirm functional test on the checklist
        Peripherals       = 'Manual'   # confirm enumeration/function on the checklist
        LoginTime         = 'Manual'   # confirm measured time vs class target
    }
}

$pass = ($results | Where-Object Result -eq 'PASS' | Measure-Object).Count
$fail = ($results | Where-Object Result -eq 'FAIL' | Measure-Object).Count
Write-Host ("Validation complete — PASS: {0}  FAIL: {1}" -f $pass, $fail) -ForegroundColor Green

if ($OutputPath) {
    $results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "Results written to $OutputPath" -ForegroundColor Green
} else {
    $results
}

Write-Host "No changes were made (read-only)." -ForegroundColor Green

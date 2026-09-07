<#
.SYNOPSIS
    Validate that migrated Apple devices are enrolled in Intune, compliant, and managed — by platform.

.DESCRIPTION
    Phase 3/4 validation. Reports Intune-managed macOS, iPadOS, and iOS devices with their management
    state, compliance, ownership, and last check-in, so you can confirm a wave landed correctly before
    moving on.

.HOW TO RUN
    .\JAMFMIG-Validate-Migration.ps1 [-SerialsCsv .\wave1-serials.csv]
    Sovereign cloud: add  -Environment USGov.

.EXPECTED RESULT
    CSV + per-platform counts of Intune-managed Apple devices and their compliance. If -SerialsCsv is
    given (a column 'Serial'), only those devices are reported — use it to validate a specific wave.

.NOTES
    Migrations — read-only (Microsoft Graph).
#>
[CmdletBinding()]
param(
    [string]$SerialsCsv,
    [string]$OutputPath = ".",
    [string]$Environment = "Global"
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -Environment $Environment -NoWelcome
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

$wave = $null
if ($SerialsCsv -and (Test-Path $SerialsCsv)) {
    $wave = (Import-Csv $SerialsCsv).Serial | Where-Object { $_ } | ForEach-Object { $_.Trim().ToUpper() }
    Write-Host "Filtering to $($wave.Count) wave serial(s)." -ForegroundColor Cyan
}

$apple = Get-MgDeviceManagementManagedDevice -Filter "operatingSystem eq 'macOS' or operatingSystem eq 'iOS'" -All -ErrorAction Stop
$rows = foreach ($d in $apple) {
    if ($wave -and ($d.SerialNumber.ToUpper() -notin $wave)) { continue }
    [pscustomobject]@{
        Device        = $d.DeviceName
        Platform      = $d.OperatingSystem            # macOS / iOS (iPadOS reports as iOS)
        OSVersion     = $d.OsVersion
        Serial        = $d.SerialNumber
        User          = $d.UserPrincipalName
        ManagementState = $d.ManagementState
        Compliance    = $d.ComplianceState
        Ownership     = $d.ManagedDeviceOwnerType
        Enrolled      = $d.EnrolledDateTime
        LastCheckIn   = $d.LastSyncDateTime
    }
}

$out = Join-Path $OutputPath "JAMFMIG-Validation-$stamp.csv"
$rows | Export-Csv $out -NoTypeInformation -Encoding UTF8
Write-Host "`nIntune-managed Apple devices:" -ForegroundColor Cyan
$rows | Group-Object Platform | Format-Table Name,Count -AutoSize
$noncompliant = $rows | Where-Object Compliance -ne 'compliant'
Write-Host "Compliant: $(($rows | Where-Object Compliance -eq 'compliant').Count) / $($rows.Count)  |  Non-compliant: $($noncompliant.Count)" -ForegroundColor $(if($noncompliant){'Yellow'}else{'Green'})
Write-Host "Exported: $out" -ForegroundColor Green

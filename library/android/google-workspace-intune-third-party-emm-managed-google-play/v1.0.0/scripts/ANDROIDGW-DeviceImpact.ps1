<#
.SYNOPSIS
    ANDROIDGW-DeviceImpact.ps1 — read-only existing-Android-device impact / enrollment-state report for the re-enrollment assessment.
.DESCRIPTION
    PURPOSE
        Inventories every existing managed Android device with the fields that reveal re-enrollment: the
        enrollment type, ownership, management state, compliance, and enrolled / last-check-in dates. Run
        it BEFORE the Google Admin console change to capture a baseline, then AGAIN after the binding is
        in place and diff (-BaselineCsv) to detect any device that re-enrolled or fell out of management.
        Read-only — makes NO changes. Writes "Device Impact - Android - Assess".
    HOW TO RUN
        Baseline (before change):
          powershell -ExecutionPolicy Bypass -File .\ANDROIDGW-DeviceImpact.ps1 -CsvPath C:\Temp\ANDROIDGW-Impact-baseline.csv
        After change, diff against the baseline:
          powershell -ExecutionPolicy Bypass -File .\ANDROIDGW-DeviceImpact.ps1 -CsvPath C:\Temp\ANDROIDGW-Impact-after.csv -BaselineCsv C:\Temp\ANDROIDGW-Impact-baseline.csv
        Requires the Microsoft Graph PowerShell SDK and (read-only) scope:
        DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        Baseline: a per-device inventory saved for later comparison. Diff: a per-device change list
        (enrolled-date changed, enrollment type changed, dropped/added). Interpret ANY change against
        current Microsoft/Google guidance and your tenant — do NOT assume it is expected or unexpected.
.NOTES
    Android — Google Workspace <-> Intune Third-Party EMM. Read-only. This script MEASURES re-enrollment
    impact; it does NOT predict or assert it. The re-enrollment question is answered by piloting +
    verifying against current guidance, never from memory.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [string]$BaselineCsv,
    [string]$ReportName = 'Device Impact - Android - Assess'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -NoWelcome

Write-Host ("=== {0} ===" -f $ReportName) -ForegroundColor Cyan

# --- Current Android device inventory (impact-relevant fields) ---
$rows = @()
$uri = "/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'Android'&`$select=id,deviceName,managedDeviceOwnerType,deviceEnrollmentType,managementState,complianceState,enrolledDateTime,lastSyncDateTime,azureADDeviceId,manufacturer,model,osVersion,userPrincipalName&`$top=200"
do {
    $r = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($d in $r.value) {
        $rows += [pscustomobject]@{
            DeviceId        = $d.id
            DeviceName      = $d.deviceName
            User            = $d.userPrincipalName
            OwnerType       = $d.managedDeviceOwnerType
            EnrollmentType  = $d.deviceEnrollmentType
            ManagementState = $d.managementState
            ComplianceState = $d.complianceState
            EnrolledDate    = $d.enrolledDateTime
            LastSync        = $d.lastSyncDateTime
            Manufacturer    = $d.manufacturer
            Model           = $d.model
            OSVersion       = $d.osVersion
        }
    }
    $uri = $r.'@odata.nextLink'
} while ($uri)

Write-Host ('--- Android devices: {0} total ---' -f $rows.Count) -ForegroundColor Cyan
$rows | Group-Object EnrollmentType | Sort-Object Name | Select-Object @{n='EnrollmentType';e={$_.Name}}, Count | Format-Table -AutoSize
$rows | Group-Object ManagementState | Sort-Object Name | Select-Object @{n='ManagementState';e={$_.Name}}, Count | Format-Table -AutoSize

# --- Optional diff against a pre-change baseline ---
if ($BaselineCsv) {
    if (-not (Test-Path $BaselineCsv)) {
        Write-Warning ("Baseline CSV not found: {0}" -f $BaselineCsv)
    } else {
        $base = Import-Csv -Path $BaselineCsv
        $baseById = @{}; foreach ($b in $base) { if ($b.DeviceId) { $baseById[$b.DeviceId] = $b } }
        $nowById  = @{}; foreach ($n in $rows) { $nowById[$n.DeviceId] = $n }

        Write-Host '--- Re-enrollment / impact diff vs baseline ---' -ForegroundColor Cyan
        $changes = @()
        foreach ($id in $baseById.Keys) {
            if (-not $nowById.ContainsKey($id)) {
                $changes += [pscustomobject]@{ DeviceName=$baseById[$id].DeviceName; Change='DROPPED (no longer present)'; From=$baseById[$id].EnrollmentType; To='(gone)' }
                continue
            }
            $b = $baseById[$id]; $n = $nowById[$id]
            if ($b.EnrolledDate -ne $n.EnrolledDate) {
                $changes += [pscustomobject]@{ DeviceName=$n.DeviceName; Change='ENROLLED-DATE CHANGED (possible re-enrollment)'; From=$b.EnrolledDate; To=$n.EnrolledDate }
            }
            if ($b.EnrollmentType -ne $n.EnrollmentType) {
                $changes += [pscustomobject]@{ DeviceName=$n.DeviceName; Change='ENROLLMENT-TYPE CHANGED'; From=$b.EnrollmentType; To=$n.EnrollmentType }
            }
            if ($b.ManagementState -ne $n.ManagementState) {
                $changes += [pscustomobject]@{ DeviceName=$n.DeviceName; Change='MANAGEMENT-STATE CHANGED'; From=$b.ManagementState; To=$n.ManagementState }
            }
        }
        foreach ($id in $nowById.Keys) {
            if (-not $baseById.ContainsKey($id)) {
                $changes += [pscustomobject]@{ DeviceName=$nowById[$id].DeviceName; Change='NEW (not in baseline)'; From='(none)'; To=$nowById[$id].EnrollmentType }
            }
        }

        if ($changes.Count -eq 0) {
            Write-Host 'No per-device changes detected vs baseline.' -ForegroundColor Green
        } else {
            $changes | Format-Table -AutoSize
            Write-Host ("{0} device change(s) detected." -f $changes.Count) -ForegroundColor Yellow
        }
        Write-Host "⚠ Interpret EVERY change against CURRENT Microsoft/Google guidance and your tenant." -ForegroundColor Yellow
        Write-Host "  A changed enrolled-date does NOT automatically mean the integration caused a re-enrollment —" -ForegroundColor Yellow
        Write-Host "  correlate with the change window and confirm expected behavior. Do NOT assert from this alone." -ForegroundColor Yellow
    }
}

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved '{0}' to {1}" -f $ReportName, $CsvPath) -ForegroundColor Green
    if (-not $BaselineCsv) { Write-Host "Keep this as your PRE-CHANGE baseline; re-run with -BaselineCsv after the cutover." -ForegroundColor DarkCyan }
}

Disconnect-MgGraph | Out-Null

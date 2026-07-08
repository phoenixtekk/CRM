<#
.SYNOPSIS
    ANDROIDENT-Report.ps1 — Android Enterprise readiness + per-model enrollment coverage (read-only).
.DESCRIPTION
    PURPOSE
        Produces a rollup of the Android Enterprise foundation: the managed Google Play binding state and
        last app sync, the corporate-owned enrollment profiles, and the enrolled Android device inventory
        broken down by ownership (corporate/personal) and management model, so you can confirm each
        in-scope enrollment model has enrolled at least one pilot device and no device enrolled via a
        blocked model. Read-only against Microsoft Graph. Optional -Csv export.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ANDROIDENT-Report.ps1
        CSV export:  ... -Csv .\androident-report.csv
        Requires the Microsoft Graph PowerShell SDK and delegated scopes:
        DeviceManagementServiceConfig.Read.All, DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        PASS = binding bound + recent SUCCESS app sync; the FM/COPE/COSU profiles present; each in-scope
        model shows >=1 enrolled Android device. Investigate any device enrolled via an unexpected model.
.NOTES
    Android category — Android Enterprise connection & managed Google Play setup. Read-only.
    AMAPI note: enrollment behavior is evolving — verify against current Microsoft guidance / your tenant.
#>
[CmdletBinding()]
param(
    [string]$Csv
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome

Write-Host "`n=== Android Enterprise foundation report ===" -ForegroundColor Cyan

# 1) Binding
try {
    $mgp = Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/androidManagedStoreAccountEnterpriseSettings"
    if ($mgp -and $mgp.bindStatus) {
        $col = if ($mgp.bindStatus -eq 'bound') { 'Green' } else { 'Yellow' }
        Write-Host ("Managed Play     : {0}  owner={1}  lastSync={2}/{3}" -f $mgp.bindStatus, $mgp.ownerUserPrincipalName, $mgp.lastAppSyncStatus, $mgp.lastAppSyncDateTime) -ForegroundColor $col
    } else { Write-Host "Managed Play     : NOT bound." -ForegroundColor Yellow }
} catch { Write-Host "Managed Play     : NOT configured." -ForegroundColor Yellow }

# 2) Enrollment profiles
try {
    $profs = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/androidDeviceOwnerEnrollmentProfiles?`$top=100").value
    Write-Host ("Enroll profiles  : {0} corporate-owned profile(s)" -f ($profs.Count))
    foreach ($p in $profs) { Write-Host ("   - {0}  ({1})" -f $p.displayName, $p.enrollmentMode) -ForegroundColor DarkGray }
} catch { Write-Host "Enroll profiles  : (unable to read)." -ForegroundColor Yellow }

# 3) Enrolled Android device inventory by ownership + management model
Write-Host "`n-- Enrolled Android devices by model --" -ForegroundColor Cyan
$rows = @()
try {
    $uri = "/beta/deviceManagement/managedDevices?`$filter=operatingSystem eq 'Android'&`$select=deviceName,managedDeviceOwnerType,managementAgent,ownerType,deviceEnrollmentType,joinType&`$top=200"
    do {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $uri
        foreach ($d in $resp.value) {
            $rows += [pscustomobject]@{
                DeviceName     = $d.deviceName
                Ownership      = $d.managedDeviceOwnerType
                EnrollmentType = $d.deviceEnrollmentType
                Agent          = $d.managementAgent
            }
        }
        $uri = $resp.'@odata.nextLink'
    } while ($uri)
} catch { Write-Host "   (unable to read managedDevices — check DeviceManagementManagedDevices.Read.All scope)." -ForegroundColor Yellow }

if ($rows.Count -eq 0) {
    Write-Host "   No enrolled Android devices found yet (enrol one per model in the pilot — Implementation Step 9)." -ForegroundColor Yellow
} else {
    $rows | Group-Object EnrollmentType | Sort-Object Name | ForEach-Object {
        Write-Host ("   {0,-40} : {1} device(s)" -f $_.Name, $_.Count)
    }
    Write-Host ("`n   Total enrolled Android devices : {0}" -f $rows.Count) -ForegroundColor Green
    Write-Host  "   (Map enrollment types to models: work profile = BYOD; device owner fully-managed/dedicated/COPE = corporate-owned.)" -ForegroundColor DarkGray
}

if ($Csv -and $rows.Count -gt 0) {
    $rows | Export-Csv -Path $Csv -NoTypeInformation -Encoding UTF8
    Write-Host ("`nCSV written: {0}" -f $Csv) -ForegroundColor Green
}

Write-Host "`nAMAPI transition / enrollment-type naming is evolving — verify model mapping against current Microsoft guidance / your tenant." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null

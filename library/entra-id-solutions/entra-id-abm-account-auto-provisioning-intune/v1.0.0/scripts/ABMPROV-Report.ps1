<#
.SYNOPSIS
    ABMPROV-Report.ps1 — fleet Managed Apple ID provisioning coverage + COD/BYOD/Shared breakdown (read-only).
.DESCRIPTION
    PURPOSE
        Produces a fleet report: provisioning scope coverage (how many users are in the provisioning
        scope groups and whether the SCIM job is active), plus a breakdown of managed iOS devices by
        enrollment model — Corporate-Owned (COD), BYOD, and Shared — so you can audit that every
        iPhone enrolled the intended way on the federated identity. Read-only against Microsoft Graph.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ABMPROV-Report.ps1
        Requires the Microsoft Graph PowerShell SDK and delegated scopes:
        Application.Read.All, Synchronization.Read.All, Group.Read.All,
        DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        Provisioning coverage (scope-group member counts + job status) and a COD / BYOD / Shared device
        count breakdown with a per-device list. ABM-side provisioned-account state is deferred to Apple.
.NOTES
    Entra ID Solutions — Entra ID + ABM federation & auto-provisioning. Read-only. ABM state deferred.
#>
[CmdletBinding()]
param(
    [string]$AppDisplayName = 'Apple Business Manager - Federation - Prod',
    [string[]]$ScopeGroups  = @('Managed Apple ID Provisioning - Pilot - Stage','Managed Apple ID Provisioning - Corp - Prod')
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Application.Read.All','Synchronization.Read.All','Group.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome

Write-Host "`n=== Managed Apple ID provisioning coverage ===" -ForegroundColor Cyan
$escaped = $AppDisplayName.Replace("'","''")
$sp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals?`$filter=displayName eq '$escaped'").value | Select-Object -First 1
if (-not $sp) {
    Write-Host ("Provisioning app : NOT FOUND ('{0}')" -f $AppDisplayName) -ForegroundColor Yellow
} else {
    $jobLine = 'none'
    try {
        $jobs = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals/$($sp.id)/synchronization/jobs").value
        if ($jobs.Count -gt 0) { $jobLine = ($jobs | ForEach-Object { "$($_.templateId)=$($_.status.code)" }) -join ', ' }
    } catch {}
    Write-Host ("Provisioning app : {0}" -f $sp.displayName) -ForegroundColor Green
    Write-Host ("SCIM job(s)      : {0}" -f $jobLine)
}

$totalScope = 0
foreach ($g in $ScopeGroups) {
    $ge = $g.Replace("'","''")
    $grp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$ge'").value | Select-Object -First 1
    if (-not $grp) { Write-Host ("  scope group '{0}' : MISSING" -f $g) -ForegroundColor Yellow; continue }
    $count = 0
    try { $count = ((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$($grp.id)/members?`$select=id").value).Count } catch {}
    Write-Host ("  scope group '{0}' : {1} user(s)" -f $g, $count) -ForegroundColor Green
    $totalScope += $count
}
Write-Host ("Total in provisioning scope : {0}" -f $totalScope)

# Device breakdown by model
Write-Host "`n=== iOS device enrollment-model breakdown ===" -ForegroundColor Cyan
$uri = "/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'iOS'&`$select=deviceName,deviceEnrollmentType,userId,userPrincipalName"
$devices = @()
try { $devices = (Invoke-MgGraphRequest -Method GET -Uri $uri).value } catch { Write-Host "  (unable to read managed devices)" -ForegroundColor Yellow }

$cod=0;$byod=0;$shared=0;$other=0
$rows = @()
foreach ($d in $devices) {
    $pt = "$($d.deviceEnrollmentType)"
    $model = 'Other'
    if ($pt -like '*UserEnrollment*') { $model='BYOD'; $byod++ }
    elseif ($pt -like '*Shared*' -or (($pt -like '*Dep*' -or $pt -like '*AutomatedDevice*' -or $pt -like '*DeviceEnrollment*') -and -not $d.userId)) { $model='Shared'; $shared++ }
    elseif (($pt -like '*Dep*' -or $pt -like '*AutomatedDevice*' -or $pt -like '*DeviceEnrollment*') -and $d.userId) { $model='COD'; $cod++ }
    else { $model="Other ($pt)"; $other++ }
    $rows += [pscustomobject]@{ Device=$d.deviceName; Model=$model; User=$d.userPrincipalName }
}

Write-Host ("COD (Corporate-Owned) : {0}" -f $cod)   -ForegroundColor Green
Write-Host ("BYOD (User Enrollment): {0}" -f $byod)  -ForegroundColor Green
Write-Host ("Shared (no affinity)  : {0}" -f $shared) -ForegroundColor Green
Write-Host ("Other / legacy        : {0}" -f $other) -ForegroundColor $(if ($other -gt 0) {'Yellow'} else {'Green'})
Write-Host ("Total iOS devices     : {0}" -f $devices.Count)

if ($rows.Count -gt 0) {
    Write-Host "`n-- Per-device --" -ForegroundColor Cyan
    $rows | Sort-Object Model, Device | Format-Table -AutoSize | Out-String | Write-Host
}

Write-Host "ABM-side provisioned Managed Apple ID accounts are deferred to Apple's documentation/console." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null

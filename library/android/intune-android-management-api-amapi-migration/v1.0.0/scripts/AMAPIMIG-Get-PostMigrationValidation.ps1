<#
.SYNOPSIS
    AMAPIMIG-Get-PostMigrationValidation.ps1 — post-migration validation report for a wave cohort: devices check in, compliant, apps deliver, account/ownership signals (read-only).
.DESCRIPTION
    For a wave group (or all Android devices), reports whether devices are present and checking in,
    their compliance state, ownership/account signals, and managed-app install status for a named
    managed Google Play app — the evidence that a migrated cohort 'manages under AMAPI, accounts
    add, apps deliver.' Read-only against Microsoft Graph; makes no changes.
.EXAMPLE
    .\AMAPIMIG-Get-PostMigrationValidation.ps1 -GroupName "AMAPIMIG - WorkProfile - Pilot" -AppDisplayName "Microsoft Authenticator"
    (PowerShell 5.1+/7+, Microsoft.Graph SDK; connect with Connect-MgGraph)
.NOTES
    Expected results: a per-device table (CheckIn/Compliance/Ownership) + app install summary. Pass =
    devices checking in, compliant, and the required app installed. The AMAPI-managed state itself is
    confirmed in the admin center / current Microsoft guidance. White-label. Read-only. No secrets.
#>

[CmdletBinding()]
param(
    [string]$GroupName,
    [string]$AppDisplayName,
    [int]$StaleHours = 24,
    [string]$ExportCsv
)

$ErrorActionPreference = 'Stop'

function Connect-AmapiGraph {
    param([string[]]$Scopes)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph PowerShell SDK not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = Get-MgContext
    if (-not $ctx -or ($Scopes | Where-Object { $ctx.Scopes -notcontains $_ })) {
        Connect-MgGraph -Scopes $Scopes | Out-Null
    }
    Write-Host "Connected to tenant: $((Get-MgContext).TenantId)" -ForegroundColor Green
}

function Invoke-AmapiGraphGetAll {
    param([Parameter(Mandatory)][string]$Uri)
    $results = @(); $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($null -ne $resp.value) { $results += $resp.value } else { $results += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $results
}

Connect-AmapiGraph -Scopes @('DeviceManagementManagedDevices.Read.All','DeviceManagementApps.Read.All','Group.Read.All')

# Resolve the cohort: members of the wave group, else all Android devices.
$targetDeviceNames = $null
if ($GroupName) {
    $grp = Invoke-AmapiGraphGetAll -Uri ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f ($GroupName -replace "'","''"))
    if (-not $grp) { throw "Group '$GroupName' not found." }
    $members = Invoke-AmapiGraphGetAll -Uri "https://graph.microsoft.com/v1.0/groups/$($grp[0].id)/members?`$select=id,deviceId,displayName"
    $targetDeviceNames = $members | Where-Object { $_.'@odata.type' -match 'device' } | Select-Object -ExpandProperty displayName
    Write-Host "Cohort '$GroupName': $(@($targetDeviceNames).Count) device member(s)." -ForegroundColor Green
}

$select = 'id,deviceName,deviceEnrollmentType,managedDeviceOwnerType,complianceState,lastSyncDateTime,userPrincipalName,azureADDeviceId'
$devices = Invoke-AmapiGraphGetAll -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'Android'&`$select=$select"
if ($targetDeviceNames) { $devices = $devices | Where-Object { $targetDeviceNames -contains $_.deviceName } }

$now = Get-Date
$rows = foreach ($d in $devices) {
    $last = if ($d.lastSyncDateTime) { [datetime]$d.lastSyncDateTime } else { $null }
    $checkIn = if ($last) { ($now - $last).TotalHours -le $StaleHours } else { $false }
    [pscustomobject]@{
        DeviceName     = $d.deviceName
        EnrollmentType = $d.deviceEnrollmentType
        Ownership      = $d.managedDeviceOwnerType
        Compliance     = $d.complianceState
        LastSync       = $last
        CheckInOk      = $checkIn
        User           = $d.userPrincipalName
    }
}

Write-Host "`n=== Post-migration validation: devices ===" -ForegroundColor Cyan
$rows | Sort-Object DeviceName | Format-Table DeviceName, EnrollmentType, Ownership, Compliance, CheckInOk, LastSync -AutoSize

$total = @($rows).Count
$checkingIn = @($rows | Where-Object { $_.CheckInOk }).Count
$compliant  = @($rows | Where-Object { $_.Compliance -eq 'compliant' }).Count
Write-Host ("Checking in (<= $StaleHours h): {0}/{1}   Compliant: {2}/{1}" -f $checkingIn, $total, $compliant) -ForegroundColor $(if ($checkingIn -eq $total -and $compliant -eq $total) { 'Green' } else { 'Yellow' })

# App delivery check.
if ($AppDisplayName) {
    Write-Host "`n=== App delivery: '$AppDisplayName' ===" -ForegroundColor Cyan
    try {
        $apps = Invoke-AmapiGraphGetAll -Uri ("https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps?`$filter=displayName eq '{0}'" -f ($AppDisplayName -replace "'","''"))
        $app = $apps | Where-Object { $_.'@odata.type' -match 'androidManagedStoreApp|androidStoreApp|androidManagedStore' } | Select-Object -First 1
        if (-not $app) { $app = $apps | Select-Object -First 1 }
        if (-not $app) {
            Write-Host "App '$AppDisplayName' not found in the tenant." -ForegroundColor Yellow
        } else {
            $states = Invoke-AmapiGraphGetAll -Uri "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($app.id)/deviceStatuses?`$select=deviceName,installState,userPrincipalName"
            if ($targetDeviceNames) { $states = $states | Where-Object { $targetDeviceNames -contains $_.deviceName } }
            $installed = @($states | Where-Object { $_.installState -eq 'installed' }).Count
            Write-Host ("Installed: {0}/{1} reporting device(s)" -f $installed, @($states).Count) -ForegroundColor $(if (@($states).Count -and $installed -eq @($states).Count) { 'Green' } else { 'Yellow' })
            $states | Select-Object deviceName, installState, userPrincipalName | Format-Table -AutoSize
        }
    } catch {
        Write-Warning "App status read failed (schema/scope): $($_.Exception.Message)"
    }
}

if ($ExportCsv) {
    $rows | Sort-Object DeviceName | Export-Csv -Path $ExportCsv -NoTypeInformation -Encoding UTF8
    Write-Host "Device validation detail written to $ExportCsv" -ForegroundColor Green
}

Write-Host "`nPASS when: devices check in + compliant, the required app is installed, and the admin" -ForegroundColor DarkYellow
Write-Host "center confirms the AMAPI-managed state per current Microsoft guidance. 'Can't add a Google" -ForegroundColor DarkYellow
Write-Host "account' or missing apps -> see 06-troubleshooting and the enrollment-troubleshooting solution." -ForegroundColor DarkYellow

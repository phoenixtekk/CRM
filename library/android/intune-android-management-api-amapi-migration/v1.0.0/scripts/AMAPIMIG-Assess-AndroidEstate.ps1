<#
.SYNOPSIS
    AMAPIMIG-Assess-AndroidEstate.ps1 — inventory the Intune Android estate by enrollment model for AMAPI migration planning (read-only).
.DESCRIPTION
    Enumerates enrolled Android devices via Microsoft Graph and reports a breakdown by enrollment
    model (work profile / fully managed / corporate-owned work profile / dedicated-COSU),
    management agent, ownership, OS version, OEM, compliance, and last check-in — with a stale-device
    list. Read-only; makes no changes. Use its output to build the migration wave plan.
.EXAMPLE
    .\AMAPIMIG-Assess-AndroidEstate.ps1 -StaleDays 30 -ExportCsv .\AMAPIMIG-Estate.csv
    (PowerShell 5.1+/7+, Microsoft.Graph SDK; connect with Connect-MgGraph)
.NOTES
    Expected results: a per-enrollment-model count table plus an optional per-device CSV. There is
    NO single Graph property that labels a device 'AMAPI-managed' vs 'legacy Play EMM' — verify the
    authoritative migration status in the Intune admin center / current Microsoft guidance.
    White-label. Read-only. No secrets.
#>

[CmdletBinding()]
param(
    [int]$StaleDays = 30,
    [string]$ExportCsv
)

$ErrorActionPreference = 'Stop'

$enrollmentTypeMap = @{
    'androidEnterpriseDedicatedDevice'      = 'Dedicated'
    'androidEnterpriseFullyManaged'         = 'FullyManaged'
    'androidEnterpriseCorporateWorkProfile' = 'CorpWorkProfile'
    'androidWorkProfile'                    = 'WorkProfile'
}

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

Connect-AmapiGraph -Scopes @('DeviceManagementManagedDevices.Read.All')

$select = 'id,deviceName,operatingSystem,osVersion,manufacturer,model,deviceEnrollmentType,managementAgent,managedDeviceOwnerType,complianceState,lastSyncDateTime,userPrincipalName'
$uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'Android'&`$select=$select"
Write-Host "Querying Android managed devices..." -ForegroundColor Cyan
$devices = Invoke-AmapiGraphGetAll -Uri $uri
Write-Host "Retrieved $($devices.Count) Android device(s)." -ForegroundColor Green

$now = Get-Date
$rows = foreach ($d in $devices) {
    $model = if ($enrollmentTypeMap.ContainsKey([string]$d.deviceEnrollmentType)) { $enrollmentTypeMap[[string]$d.deviceEnrollmentType] } else { "Other:$($d.deviceEnrollmentType)" }
    $last  = if ($d.lastSyncDateTime) { [datetime]$d.lastSyncDateTime } else { $null }
    $stale = if ($last) { ($now - $last).TotalDays -gt $StaleDays } else { $true }
    [pscustomobject]@{
        DeviceName      = $d.deviceName
        Model           = $model
        EnrollmentType  = $d.deviceEnrollmentType
        MgmtAgent       = $d.managementAgent
        Ownership       = $d.managedDeviceOwnerType
        OsVersion       = $d.osVersion
        Manufacturer    = $d.manufacturer
        HwModel         = $d.model
        Compliance      = $d.complianceState
        LastSync        = $last
        Stale           = $stale
        User            = $d.userPrincipalName
    }
}

Write-Host "`n=== Android estate by enrollment model ===" -ForegroundColor Cyan
$rows | Group-Object Model | Sort-Object Name | ForEach-Object {
    [pscustomobject]@{
        Model         = $_.Name
        Devices       = $_.Count
        Compliant     = ($_.Group | Where-Object { $_.Compliance -eq 'compliant' }).Count
        StaleOver     = ($_.Group | Where-Object { $_.Stale }).Count
    }
} | Format-Table -AutoSize

Write-Host "`n=== By OEM (manufacturer) ===" -ForegroundColor Cyan
$rows | Group-Object Manufacturer | Sort-Object Count -Descending |
    Select-Object @{n='Manufacturer';e={$_.Name}}, Count | Format-Table -AutoSize

$staleList = $rows | Where-Object { $_.Stale }
Write-Host "`nStale devices (no check-in > $StaleDays days, or never): $($staleList.Count)" -ForegroundColor Yellow

if ($ExportCsv) {
    $rows | Sort-Object Model, DeviceName | Export-Csv -Path $ExportCsv -NoTypeInformation -Encoding UTF8
    Write-Host "Per-device inventory written to $ExportCsv" -ForegroundColor Green
}

Write-Host "`nNOTE: Legacy-Play-EMM vs AMAPI is NOT a single device property here. Confirm the" -ForegroundColor DarkYellow
Write-Host "authoritative migration status in the Intune admin center / current Microsoft guidance." -ForegroundColor DarkYellow

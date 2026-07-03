<#
.SYNOPSIS
    INTCOMPDXG-Report.ps1 — tenant/group compliance rollup on GCC High (US Gov).
.DESCRIPTION
    PURPOSE
        Read-only. Produces a compliance rollup (compliant / noncompliant / inGracePeriod /
        notEvaluated / error / conflict) across the whole tenant or a named group, so you can see
        whether a failure is one device or a pattern and confirm the numbers match the portal.
        Optionally writes a CSV. Pass -GroupName 'your-group-name' to scope, or omit for tenant-wide.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\INTCOMPDXG-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\INTCOMPDXG-Report.ps1 -GroupName your-group-name -CsvPath .\compliance-report.csv
        (Graph scopes: DeviceManagementManagedDevices.Read.All; connects with -Environment USGov.
         For DoD tenants pass -CloudEnvironment USGovDoD.)
    EXPECTED RESULTS
        A count by compliance state plus a per-device table. Counts should match Devices > Compliance
        in intune.microsoft.us. If they don't, confirm the environment (USGov) and the group scope.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding()]
param(
    [string]$GroupName,
    [string]$CsvPath,
    [ValidateSet('USGov','USGovDoD')][string]$CloudEnvironment = 'USGov'
)

$ErrorActionPreference = 'Stop'
$scopes = @('DeviceManagementManagedDevices.Read.All','Group.Read.All')

function Connect-UsGovGraph {
    param([string]$Env,[string[]]$Scopes)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph modules not found. Install: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = Get-MgContext
    if (-not $ctx -or $ctx.Environment -ne $Env) {
        Write-Host "Connecting to Microsoft Graph ($Env) ..." -ForegroundColor Cyan
        Connect-MgGraph -Environment $Env -Scopes $Scopes | Out-Null
    }
    $ctx = Get-MgContext
    if ($ctx.Environment -ne $Env) {
        throw "Connected environment is '$($ctx.Environment)', expected '$Env'. On GCC High use -Environment USGov (or USGovDoD)."
    }
    Write-Host ("Connected: tenant={0} environment={1}" -f $ctx.TenantId,$ctx.Environment) -ForegroundColor Green
}

function Invoke-GraphPaged {
    param([string]$Uri)
    $items = New-Object System.Collections.Generic.List[object]
    $next = $Uri
    while ($next) {
        $page = Invoke-MgGraphRequest -Method GET -Uri $next -OutputType PSObject
        foreach ($v in $page.value) { $items.Add($v) }
        $next = $page.'@odata.nextLink'
    }
    return $items
}

Connect-UsGovGraph -Env $CloudEnvironment -Scopes $scopes

# Build the device set: whole tenant, or restricted to a group's member device names.
$select = 'deviceName,operatingSystem,osVersion,complianceState,managedDeviceOwnerType,lastSyncDateTime'
if ($GroupName) {
    $genc = [uri]::EscapeDataString($GroupName)
    $gid = @((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$genc'" -OutputType PSObject).value)[0].id
    if (-not $gid) { throw "Group '$GroupName' not found." }
    $memberNames = (Invoke-GraphPaged "/v1.0/groups/$gid/members?`$select=displayName").displayName
    $all = Invoke-GraphPaged "/beta/deviceManagement/managedDevices?`$select=$select"
    $devices = @($all | Where-Object { $memberNames -contains $_.deviceName })
    Write-Host "Scoped to group '$GroupName' ($($devices.Count) device(s))." -ForegroundColor Cyan
}
else {
    $devices = @(Invoke-GraphPaged "/beta/deviceManagement/managedDevices?`$select=$select")
    Write-Host "Tenant-wide ($($devices.Count) device(s))." -ForegroundColor Cyan
}

Write-Host "`n=== Compliance Report ($CloudEnvironment) ===" -ForegroundColor Cyan
$byState = $devices | Group-Object complianceState | Sort-Object Count -Descending
$byState | Select-Object @{n='ComplianceState';e={$_.Name}}, Count | Format-Table -AutoSize

$table = $devices | Select-Object deviceName,
    @{n='OS';e={"$($_.operatingSystem) $($_.osVersion)"}},
    @{n='Ownership';e={$_.managedDeviceOwnerType}},
    @{n='Compliance';e={$_.complianceState}},
    @{n='LastCheckIn';e={$_.lastSyncDateTime}}
$table | Sort-Object Compliance,deviceName | Format-Table -AutoSize

if ($CsvPath) {
    $table | Sort-Object Compliance,deviceName | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "CSV written: $CsvPath" -ForegroundColor Green
}

$nonCompliant = @($devices | Where-Object { $_.complianceState -ne 'compliant' }).Count
Write-Host ("`n{0} of {1} device(s) are NOT compliant." -f $nonCompliant,$devices.Count) -ForegroundColor ($(if($nonCompliant -eq 0){'Green'}else{'Yellow'}))
Write-Host "Cross-check against Devices > Compliance in intune.microsoft.us (not .com)." -ForegroundColor DarkCyan

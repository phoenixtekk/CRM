<#
.SYNOPSIS
    AMAPIMIG-New-MigrationWavePlan.ps1 — bucket the Android estate into migration waves and (optionally) create the wave groups (safe: read-only unless -CreateGroups -Commit).
.DESCRIPTION
    Reads the Android estate via Graph, assigns each device to a Pilot/Wave1/Wave2/Prod cohort per
    enrollment model (lowest-visibility first), and writes a wave-plan CSV. With -CreateGroups it
    previews the Assigned security groups to create per model/stage; nothing is created until you add
    -Commit. Read-only by default; group creation is gated behind -Commit.
.EXAMPLE
    .\AMAPIMIG-New-MigrationWavePlan.ps1 -PilotPerModel 3 -ExportCsv .\AMAPIMIG-WavePlan.csv
    .\AMAPIMIG-New-MigrationWavePlan.ps1 -CreateGroups            # preview groups (WhatIf)
    .\AMAPIMIG-New-MigrationWavePlan.ps1 -CreateGroups -Commit    # actually create the wave groups
    (PowerShell 5.1+/7+, Microsoft.Graph SDK; connect with Connect-MgGraph)
.NOTES
    Expected results: AMAPIMIG-WavePlan.csv with a Wave column per device; optional wave groups.
    Pass = a plan exists with sensible cohorts. Sequence/enrollment-path per model must be confirmed
    against current Microsoft guidance before executing. White-label. Safe-by-default. No secrets.
#>

[CmdletBinding()]
param(
    [int]$PilotPerModel = 3,
    [int]$Wave1Fraction = 25,   # percent of the remainder placed in Wave1 (rest split Wave2/Prod)
    [string]$ExportCsv = ".\AMAPIMIG-WavePlan.csv",
    [switch]$CreateGroups,
    [switch]$Commit,
    [string]$GroupNamePrefix = 'AMAPIMIG'
)

$ErrorActionPreference = 'Stop'

$enrollmentTypeMap = @{
    'androidEnterpriseDedicatedDevice'      = 'Dedicated'
    'androidEnterpriseFullyManaged'         = 'FullyManaged'
    'androidEnterpriseCorporateWorkProfile' = 'CorpWorkProfile'
    'androidWorkProfile'                    = 'WorkProfile'
}
# Migration order: lowest user-visibility first. Verify appropriateness for your org.
$modelOrder = @('FullyManaged','CorpWorkProfile','WorkProfile','Dedicated')

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

$writeNeeded = ($CreateGroups -and $Commit)
$scopes = if ($writeNeeded) { @('DeviceManagementManagedDevices.Read.All','Group.ReadWrite.All') }
          else              { @('DeviceManagementManagedDevices.Read.All') }
Connect-AmapiGraph -Scopes $scopes

$select = 'id,deviceName,deviceEnrollmentType,managedDeviceOwnerType,complianceState,lastSyncDateTime,userPrincipalName'
$devices = Invoke-AmapiGraphGetAll -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'Android'&`$select=$select"
Write-Host "Retrieved $($devices.Count) Android device(s)." -ForegroundColor Green

# Assign waves per model.
$plan = New-Object System.Collections.Generic.List[object]
foreach ($model in $modelOrder) {
    $set = @($devices | Where-Object { $enrollmentTypeMap[[string]$_.deviceEnrollmentType] -eq $model } | Sort-Object deviceName)
    if (-not $set) { continue }
    for ($i = 0; $i -lt $set.Count; $i++) {
        $d = $set[$i]
        if ($i -lt $PilotPerModel) {
            $wave = 'Pilot'
        } else {
            $rank = ($i - $PilotPerModel) / [math]::Max(1, ($set.Count - $PilotPerModel))
            $wave = if ($rank -lt ($Wave1Fraction / 100.0)) { 'Wave1' }
                    elseif ($rank -lt 0.66) { 'Wave2' } else { 'Prod' }
        }
        $plan.Add([pscustomobject]@{
            DeviceName = $d.deviceName
            Model      = $model
            Wave       = $wave
            WaveGroup  = "$GroupNamePrefix - $model - $wave"
            Ownership  = $d.managedDeviceOwnerType
            Compliance = $d.complianceState
            User       = $d.userPrincipalName
        })
    }
}

Write-Host "`n=== Migration wave plan (order: $($modelOrder -join ' -> ')) ===" -ForegroundColor Cyan
$plan | Group-Object Model, Wave | Sort-Object Name |
    Select-Object @{n='Model/Wave';e={$_.Name}}, Count | Format-Table -AutoSize

$plan | Export-Csv -Path $ExportCsv -NoTypeInformation -Encoding UTF8
Write-Host "Wave plan written to $ExportCsv" -ForegroundColor Green

if ($CreateGroups) {
    $groups = $plan | Select-Object -ExpandProperty WaveGroup -Unique | Sort-Object
    Write-Host "`n=== Wave groups (Assigned security groups) ===" -ForegroundColor Cyan
    foreach ($gname in $groups) {
        $exists = Invoke-AmapiGraphGetAll -Uri ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f ($gname -replace "'","''"))
        if ($exists) { Write-Host "EXISTS  $gname" -ForegroundColor DarkGray; continue }
        if (-not $Commit) {
            Write-Host "WHATIF  would create Assigned security group: $gname" -ForegroundColor Yellow
        } else {
            $body = @{
                displayName     = $gname
                mailEnabled     = $false
                mailNickname    = ($gname -replace '[^a-zA-Z0-9]', '').ToLower()
                securityEnabled = $true
                groupTypes      = @()
                description     = "AMAPI migration wave cohort (Assigned). Created by AMAPIMIG-New-MigrationWavePlan.ps1."
            } | ConvertTo-Json
            $new = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/groups' -Body $body -ContentType 'application/json'
            Write-Host "CREATED $gname (id $($new.id))" -ForegroundColor Green
        }
    }
    if (-not $Commit) { Write-Host "`nPreview only. Re-run with -Commit to create the groups." -ForegroundColor Yellow }
}

Write-Host "`nNOTE: Confirm the migration SEQUENCE and enrollment PATH per model against current" -ForegroundColor DarkYellow
Write-Host "Microsoft guidance before executing any wave. Re-enrollment/impact is verified in Pilot." -ForegroundColor DarkYellow

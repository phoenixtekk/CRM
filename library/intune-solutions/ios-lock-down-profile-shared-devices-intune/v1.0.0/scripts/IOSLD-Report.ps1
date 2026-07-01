<#
.SYNOPSIS
    IOSLD-Report.ps1 — fleet shared-vs-corporate posture report for managed iPhones.

.DESCRIPTION
    PURPOSE
        Classifies every iOS managed device as SHARED (no primary user) or CORPORATE (has a primary
        user), and reports supervision, compliance, OS version, enrolled-by account, and last check-in.
        Flags posture problems: shared phones that are unsupervised (lock-down won't hold) and phones
        whose group membership does not match their model (mismatch).

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\IOSLD-Report.ps1
        .\IOSLD-Report.ps1 -CsvPath C:\Temp\ios-posture.csv
        Reads only — makes no changes.

    EXPECTED RESULTS
        A summary (shared vs corporate counts, supervised, compliant), a CSV per device, and printed
        lists of any unsupervised shared phones and any model/group mismatches to review.

.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string]$CsvPath = "$PSScriptRoot\ios-posture-report.csv",
    [string]$SharedGroupName    = 'iOS – Shared Devices',
    [string]$CorporateGroupName = 'iOS – Corporate Devices'
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','Group.Read.All' | Out-Null

# Resolve group object ids and member device ids (for mismatch detection)
function GroupMemberDeviceIds($name) {
    $g = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'&`$select=id" -f $name.Replace("'","''"))).value | Select-Object -First 1
    if (-not $g) { return @() }
    $ids = @(); $uri = "https://graph.microsoft.com/v1.0/groups/$($g.id)/members?`$select=deviceId"
    do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $ids += ($r.value | ForEach-Object { $_.deviceId } | Where-Object { $_ }); $uri = $r.'@odata.nextLink' } while ($uri)
    return $ids
}
$sharedIds = GroupMemberDeviceIds $SharedGroupName
$corpIds   = GroupMemberDeviceIds $CorporateGroupName

# Pull all iOS managed devices (page through)
$uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'iOS'&`$select=deviceName,serialNumber,operatingSystem,osVersion,isSupervised,userId,userPrincipalName,complianceState,azureADDeviceId,enrolledDateTime,lastSyncDateTime"
$devices = @()
do { $resp = Invoke-MgGraphRequest -Method GET -Uri $uri; $devices += $resp.value; $uri = $resp.'@odata.nextLink' } while ($uri)

$rows = $devices | ForEach-Object {
    $isShared = [string]::IsNullOrEmpty($_.userId)
    $model = if ($isShared) { 'Shared' } else { 'Corporate' }
    $inShared = $sharedIds -contains $_.azureADDeviceId
    $inCorp   = $corpIds   -contains $_.azureADDeviceId
    $mismatch = ($model -eq 'Shared' -and $inCorp) -or ($model -eq 'Corporate' -and $inShared) -or `
                ($model -eq 'Shared' -and -not $inShared -and $inCorp) -or ($model -eq 'Corporate' -and -not $inCorp -and $inShared)
    [pscustomobject]@{
        DeviceName = $_.deviceName
        Serial     = $_.serialNumber
        Model      = $model
        OS         = "$($_.operatingSystem) $($_.osVersion)"
        Supervised = [bool]$_.isSupervised
        InSharedGrp= $inShared
        InCorpGrp  = $inCorp
        Mismatch   = [bool]$mismatch
        EnrolledBy = $_.userPrincipalName
        Compliance = $_.complianceState
        LastSync   = $_.lastSyncDateTime
    }
}

$rows | Sort-Object Model, DeviceName | Export-Csv -NoTypeInformation -Path $CsvPath
Write-Host "CSV written: $CsvPath" -ForegroundColor Cyan
Write-Host ''
Write-Host ("Total iOS devices       : {0}" -f $rows.Count)
Write-Host ("Shared (no user)        : {0}" -f ($rows | Where-Object Model -eq 'Shared').Count)
Write-Host ("Corporate (has user)    : {0}" -f ($rows | Where-Object Model -eq 'Corporate').Count)
Write-Host ("Supervised              : {0}" -f ($rows | Where-Object Supervised).Count)
Write-Host ("Compliant               : {0}" -f ($rows | Where-Object { $_.Compliance -eq 'compliant' }).Count)

$unsupShared = $rows | Where-Object { $_.Model -eq 'Shared' -and -not $_.Supervised }
if ($unsupShared) {
    Write-Host ''
    Write-Host 'SHARED phones NOT supervised (lock-down will not hold):' -ForegroundColor Yellow
    $unsupShared | Format-Table DeviceName, Serial -AutoSize
}
$mismatches = $rows | Where-Object Mismatch
if ($mismatches) {
    Write-Host ''
    Write-Host 'Model / group MISMATCHES (review group membership):' -ForegroundColor Yellow
    $mismatches | Format-Table DeviceName, Serial, Model, InSharedGrp, InCorpGrp -AutoSize
}
Disconnect-MgGraph | Out-Null

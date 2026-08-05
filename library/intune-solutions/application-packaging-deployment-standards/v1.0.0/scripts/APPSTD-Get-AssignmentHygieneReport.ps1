<#
.SYNOPSIS
    APPSTD-Get-AssignmentHygieneReport.ps1 — reports assignment-hygiene violations across the app
    catalog: unassigned apps, All Devices/All Users targeting, duplicate same-intent assignments,
    Required+Uninstall conflicts, and missing exclusion group.
.DESCRIPTION
    PURPOSE
        Read-only. Enumerates every managed Windows app and its assignments and applies the standard's
        ring/assignment hygiene rules (Implementation Step 9f):
          - H1  Assigned to All Devices or All Users (virtual groups)          -> violation.
          - H2  Required AND Uninstall intent for overlapping targets          -> conflict.
          - H3  Two or more assignments with the same intent (duplicate)       -> ambiguity.
          - H4  Required assignment missing the 'APP – Exclusions – Do Not Deploy' exclusion.
          - H5  No assignments at all (orphan) — flagged, with age if available.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\APPSTD-Get-AssignmentHygieneReport.ps1
        powershell -ExecutionPolicy Bypass -File .\APPSTD-Get-AssignmentHygieneReport.ps1 -CsvPath C:\Temp\assignments.csv
        powershell -ExecutionPolicy Bypass -File .\APPSTD-Get-AssignmentHygieneReport.ps1 -ExclusionGroupName "APP – Exclusions – Do Not Deploy"
        Requires the Microsoft Graph PowerShell SDK, DeviceManagementApps.Read.All and Group.Read.All.
    EXPECTED RESULTS
        A per-app hygiene report and a summary count per rule. Nothing is changed — read-only.
.NOTES
    Intune Solutions — read-only against Microsoft Graph. No changes are made to the tenant.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [string]$ExclusionGroupName = 'APP – Exclusions – Do Not Deploy'
)

function Connect-Graph {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Write-Host 'Installing Microsoft.Graph (CurrentUser)...' -ForegroundColor Yellow
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All','Group.Read.All' -NoWelcome
}

Connect-Graph

# Resolve the exclusion group id (best-effort; report still runs if not found).
$exclId = $null
try {
    $enc = [uri]::EscapeDataString($ExclusionGroupName)
    $g   = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$enc'"
    if ($g.value) { $exclId = $g.value[0].id }
} catch { }
if (-not $exclId) { Write-Host ("Note: exclusion group '{0}' not found; H4 will report as missing everywhere." -f $ExclusionGroupName) -ForegroundColor Yellow }

$apps = @(); $uri = '/v1.0/deviceAppManagement/mobileApps?$top=100&$expand=assignments'
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $apps += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)

$wanted = @('win32','winGet','windowsMsi','StoreForBusiness','UniversalAppX','MobileMSI')
$apps = $apps | Where-Object { $t = $_.'@odata.type'; $wanted | Where-Object { $t -like "*$_*" } }
if (-not $apps) { Write-Host 'No matching Windows apps found.' -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

$rows = foreach ($a in $apps) {
    $asn      = @($a.assignments)
    $requires = @($asn | Where-Object { $_.intent -eq 'required' })
    $avail    = @($asn | Where-Object { $_.intent -eq 'available' })
    $uninst   = @($asn | Where-Object { $_.intent -eq 'uninstall' })
    $viol = @()

    # Target group ids referenced (include) and excluded.
    $incl = $asn | Where-Object { $_.target.'@odata.type' -notlike '*exclusionGroupAssignmentTarget*' }
    $excl = $asn | Where-Object { $_.target.'@odata.type' -like  '*exclusionGroupAssignmentTarget*' }

    # H1 — All Devices / All Users virtual targets.
    $allTarget = $incl | Where-Object {
        $_.target.'@odata.type' -like '*allDevicesAssignmentTarget*' -or
        $_.target.'@odata.type' -like '*allLicensedUsersAssignmentTarget*'
    }
    if ($allTarget) { $viol += 'H1(all-devices/all-users)' }

    # H2 — Required and Uninstall both present.
    if ($requires.Count -gt 0 -and $uninst.Count -gt 0) { $viol += 'H2(required+uninstall)' }

    # H3 — duplicate same-intent group targets.
    foreach ($grp in @($requires, $avail, $uninst)) {
        $ids = $grp | ForEach-Object { $_.target.groupId } | Where-Object { $_ }
        $dup = $ids | Group-Object | Where-Object { $_.Count -gt 1 }
        if ($dup) { $viol += 'H3(duplicate-intent-target)' }
    }

    # H4 — Required assignment without the standard exclusion group.
    if ($requires.Count -gt 0) {
        $hasExcl = $false
        if ($exclId) { $hasExcl = [bool]($excl | Where-Object { $_.target.groupId -eq $exclId }) }
        if (-not $hasExcl) { $viol += 'H4(missing-standard-exclusion)' }
    }

    # H5 — orphan (no assignments).
    if ($asn.Count -eq 0) { $viol += 'H5(unassigned-orphan)' }

    $viol = $viol | Select-Object -Unique
    [pscustomobject]@{
        App             = $a.displayName
        Created         = $a.createdDateTime
        Required        = $requires.Count
        Available       = $avail.Count
        Uninstall       = $uninst.Count
        Excluded        = $excl.Count
        Clean           = if ($viol.Count -eq 0) {'YES'} else {'NO'}
        Violations      = ($viol -join '; ')
    }
}

Write-Host ''
Write-Host '=== Assignment Hygiene ===' -ForegroundColor Cyan
Write-Host ("  Apps checked : {0}" -f $rows.Count)
Write-Host ("  Clean        : {0}" -f ($rows | Where-Object Clean -eq 'YES').Count) -ForegroundColor Green
Write-Host ("  With issues  : {0}" -f ($rows | Where-Object Clean -eq 'NO').Count)  -ForegroundColor Yellow
Write-Host ''
Write-Host '  Violations by rule:' -ForegroundColor Cyan
$rows | Where-Object Clean -eq 'NO' | ForEach-Object { $_.Violations -split '; ' } |
    Where-Object { $_ } | Group-Object | Sort-Object Count -Descending |
    ForEach-Object { Write-Host ("    {0,-34} {1}" -f $_.Name, $_.Count) }
Write-Host ''
$rows | Where-Object Clean -eq 'NO' | Sort-Object App | Format-Table App, Required, Uninstall, Excluded, Violations -AutoSize

if ($CsvPath) {
    $rows | Sort-Object Clean, App | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Saved: {0}" -f $CsvPath) -ForegroundColor Green
}

Disconnect-MgGraph | Out-Null

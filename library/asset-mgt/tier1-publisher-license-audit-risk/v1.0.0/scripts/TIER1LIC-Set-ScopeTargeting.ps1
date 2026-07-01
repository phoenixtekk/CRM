<#
.SYNOPSIS
    TIER1LIC-Set-ScopeTargeting.ps1 — build the publisher-scope group from the inventory.
.DESCRIPTION
    PURPOSE
        Derives the set of hosts and users in scope for one tier-1 publisher from the inventory
        export, so the rest of the process (discovery, mapping, position, remediation) operates on a
        well-defined, repeatable scope. Produces the publisher-scope group artifact. By default it
        only WRITES A LOCAL SCOPE FILE (it does not touch any directory or group system); pass
        -GroupExportPath to also emit a membership CSV your group/CMDB tooling can import.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TIER1LIC-Set-ScopeTargeting.ps1 `
            -InventoryCsv .\inventory.csv -Publisher Oracle `
            [-ScopeFile .\scope-Oracle.json] [-GroupExportPath .\scope-group-Oracle.csv]
        Inventory columns used: Host, Publisher, Product, AuthorizedUsers
    EXPECTED RESULTS
        The in-scope host list (and named users where present) for the publisher, saved as the
        scope group artifact; optionally a membership CSV for import into your group tooling.
.NOTES
    White-label SAM tooling — Asset Mgt. Writes scope artifacts only; performs no changes against
    any directory, group, or device. Scope decisions are governed by your contracts and topology.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string] $InventoryCsv,
    [Parameter(Mandatory)] [ValidateSet('Oracle','IBM','SAP')] [string] $Publisher,
    [string] $ScopeFile,
    [string] $GroupExportPath
)

if (-not (Test-Path $InventoryCsv)) { Write-Error "Inventory CSV not found: $InventoryCsv"; return }
$rows = Import-Csv -Path $InventoryCsv | Where-Object { $_.Publisher.Trim().ToLower() -eq $Publisher.ToLower() }
if (-not $rows) { Write-Host "No rows for publisher '$Publisher'." -ForegroundColor Yellow; return }

Write-Host "`n=== Publisher-scope group — $Publisher ===" -ForegroundColor Cyan

$hosts = $rows | Select-Object -ExpandProperty Host | Where-Object { $_ } | Sort-Object -Unique
$users = $rows | ForEach-Object { if ($_.AuthorizedUsers) { $_.AuthorizedUsers } } |
         Where-Object { $_ -and -not ($_ -match '^\d+$') } | Sort-Object -Unique   # skip pure counts

$scope = [pscustomobject]@{
    Publisher = $Publisher
    Generated = (Get-Date).ToString('s')
    HostCount = $hosts.Count
    Hosts     = $hosts
    Users     = $users
}

Write-Host ("In-scope hosts : {0}" -f $hosts.Count) -ForegroundColor Green
$hosts | ForEach-Object { Write-Host "   $_" }
if ($users.Count) { Write-Host ("Named users    : {0}" -f $users.Count) -ForegroundColor Green }

if (-not $ScopeFile) { $ScopeFile = ".\scope-$Publisher.json" }
if ($PSCmdlet.ShouldProcess($ScopeFile, "Write scope group artifact")) {
    $scope | ConvertTo-Json -Depth 4 | Set-Content -Path $ScopeFile -Encoding UTF8
    Write-Host "Scope group written: $ScopeFile" -ForegroundColor Green
}

if ($GroupExportPath) {
    $membership = $hosts | ForEach-Object { [pscustomobject]@{ Publisher = $Publisher; MemberType = 'Host'; Member = $_ } }
    $membership += $users | ForEach-Object { [pscustomobject]@{ Publisher = $Publisher; MemberType = 'User'; Member = $_ } }
    if ($PSCmdlet.ShouldProcess($GroupExportPath, "Write group membership CSV")) {
        $membership | Export-Csv -Path $GroupExportPath -NoTypeInformation -Encoding UTF8
        Write-Host "Group membership written: $GroupExportPath" -ForegroundColor Green
    }
}

<#
.SYNOPSIS
    GWDRIVE-Report.ps1 — coverage and exception report for a Drive migration wave.
.DESCRIPTION
    PURPOSE
        Renders migration coverage and an itemized exception list for the wave's scopes: source
        item/folder counts per scope, the count of distinct permission principals, and the sharing in
        place — so you can reconcile what the migration should move and see the exceptions (unmapped
        principals, over-broad sharing, empty scopes) before passing the wave. Read-only against
        Microsoft Graph; it moves nothing and changes nothing. Placeholders use plain text such as
        your-tenant-id, not angle brackets.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWDRIVE-Report.ps1 -ScopeCsv .\wave.csv
        Optional: -IdentityMapCsv .\identity-map.csv to flag principals with no Google mapping.
        Optional: -CsvPath .\gwdrive-coverage.csv to export the per-scope coverage table.
        ScopeCsv columns: Kind (SharePoint|OneDrive), Scope, DriveId. Requires the Microsoft Graph
        PowerShell SDK; consent to Sites.Read.All, Files.Read.All, User.Read.All, Group.Read.All.
    EXPECTED RESULTS
        A per-scope coverage table (files, folders, principals, shared items) and an exception list.
        The wave is ready to pass when coverage reconciles and the exception list is empty.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ScopeCsv,
    [string]$IdentityMapCsv,
    [string]$CsvPath
)

if (-not (Test-Path $ScopeCsv)) { Write-Host "ScopeCsv not found: $ScopeCsv" -ForegroundColor Red; return }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Sites.Read.All','Files.Read.All','User.Read.All','Group.Read.All' -NoWelcome

Write-Host "`n=== Drive migration — coverage & exception report ===" -ForegroundColor Cyan

$idMap = @{}
if ($IdentityMapCsv -and (Test-Path $IdentityMapCsv)) {
    Import-Csv $IdentityMapCsv | ForEach-Object { if ($_.Source) { $idMap[$_.Source.Trim().ToLower()] = $true } }
}

$rows = New-Object System.Collections.Generic.List[object]
$exceptions = New-Object System.Collections.Generic.List[string]

foreach ($scope in (Import-Csv $ScopeCsv)) {
    if (-not $scope.DriveId) { continue }
    $files = 0; $folders = 0; $anyLink = 0
    $prin = New-Object System.Collections.Generic.HashSet[string]
    try {
        $stack = New-Object System.Collections.Generic.Stack[string]
        $root = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/drives/$($scope.DriveId)/root/children?`$top=200")
        foreach ($c in $root.value) { $stack.Push($c.id) }
        while ($stack.Count -gt 0) {
            $id = $stack.Pop()
            $node = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/drives/$($scope.DriveId)/items/$id"
            if ($node.folder) {
                $folders++
                $sub = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/drives/$($scope.DriveId)/items/$id/children?`$top=200")
                foreach ($s in $sub.value) { $stack.Push($s.id) }
            } else { $files++ }
            try {
                $perms = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/drives/$($scope.DriveId)/items/$id/permissions").value
                foreach ($p in $perms) {
                    if ($p.link -and $p.link.scope -eq 'anonymous') { $anyLink++ }
                    $who = $null
                    if ($p.grantedToV2.user.email) { $who = $p.grantedToV2.user.email }
                    elseif ($p.grantedToV2.siteGroup.displayName) { $who = 'group:' + $p.grantedToV2.siteGroup.displayName }
                    elseif ($p.grantedTo.user.email) { $who = $p.grantedTo.user.email }
                    if ($who) {
                        [void]$prin.Add($who)
                        if ($idMap.Count -gt 0 -and -not $idMap.ContainsKey($who.Trim().ToLower())) {
                            $exceptions.Add(("Unmapped principal '{0}' in scope '{1}' (permission would be dropped)" -f $who, $scope.Scope))
                        }
                    }
                }
            } catch {}
        }
    } catch {
        $exceptions.Add(("Scope '{0}' ({1}) not readable: {2}" -f $scope.Scope, $scope.DriveId, $_.Exception.Message))
        continue
    }
    if (($files + $folders) -eq 0) { $exceptions.Add(("Scope '{0}' is empty — confirm it is in scope" -f $scope.Scope)) }
    if ($anyLink -gt 0) { $exceptions.Add(("Scope '{0}' has {1} anyone-with-the-link share(s) — confirm sharing rule before migrating" -f $scope.Scope, $anyLink)) }
    Write-Host ("  {0,-10} {1,-38} files={2,-6} folders={3,-5} principals={4,-4} anyLink={5}" -f $scope.Kind, $scope.Scope, $files, $folders, $prin.Count, $anyLink)
    $rows.Add([pscustomobject]@{ Kind=$scope.Kind; Scope=$scope.Scope; DriveId=$scope.DriveId; Files=$files; Folders=$folders; Principals=$prin.Count; AnyoneLinks=$anyLink })
}

$totItems = ($rows | Measure-Object -Property Files -Sum).Sum + ($rows | Measure-Object -Property Folders -Sum).Sum
Write-Host ""
Write-Host ("Scopes reported : {0}" -f $rows.Count)
Write-Host ("Total items     : {0}" -f $totItems)
Write-Host ("Exceptions      : {0}" -f $exceptions.Count) -ForegroundColor ($(if($exceptions.Count -eq 0){'Green'}else{'Yellow'}))
if ($exceptions.Count -gt 0) {
    Write-Host "`nException list (resolve before passing the wave):" -ForegroundColor Yellow
    $exceptions | ForEach-Object { Write-Host ("  - {0}" -f $_) }
} else {
    Write-Host "`nNo exceptions — coverage reconciles. Wave is ready for its pass/fail gate." -ForegroundColor Green
}

if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host ("Saved {0}" -f $CsvPath) }

Disconnect-MgGraph | Out-Null

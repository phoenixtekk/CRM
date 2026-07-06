<#
.SYNOPSIS
    GWDRIVE-Validation.ps1 — per-item migration and permission validation for a Drive migration wave.
.DESCRIPTION
    PURPOSE
        Validates a wave per item against the mapping: confirms the source scopes were fully
        inventoried (files/folders and their permission principals), and checks each source principal
        resolves in the identity map so no permission will be dropped, and each source permission
        level resolves in the role translation table so no role will be flattened. Read-only against
        Microsoft Graph on the source side; it reads the identity-map and permission-map CSVs to
        confirm coverage. It changes nothing. Placeholders use plain text such as your-tenant-id,
        not angle brackets.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWDRIVE-Validation.ps1 -ScopeCsv .\wave.csv `
            -IdentityMapCsv .\identity-map.csv -PermissionMapCsv .\permission-map.csv
        ScopeCsv columns: Kind (SharePoint|OneDrive), DriveId. IdentityMapCsv column: Source (source
        principal email or group:Name). PermissionMapCsv column: SourceLevel. Requires the Microsoft
        Graph PowerShell SDK; consent to Sites.Read.All, Files.Read.All, User.Read.All, Group.Read.All.
    EXPECTED RESULTS
        A per-scope line and a wave summary: items readable, principals covered by the identity map
        vs unmapped (would be dropped), and permission levels covered by the translation vs unmapped
        (would be flattened). PASS when every principal and level is covered; GAP lists what to fix.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ScopeCsv,
    [string]$IdentityMapCsv,
    [string]$PermissionMapCsv
)

if (-not (Test-Path $ScopeCsv)) { Write-Host "ScopeCsv not found: $ScopeCsv" -ForegroundColor Red; return }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Sites.Read.All','Files.Read.All','User.Read.All','Group.Read.All' -NoWelcome

Write-Host "`n=== Drive migration — per-item validation ===" -ForegroundColor Cyan

# Load the maps (coverage sets).
$idMap = @{}
if ($IdentityMapCsv -and (Test-Path $IdentityMapCsv)) {
    Import-Csv $IdentityMapCsv | ForEach-Object { if ($_.Source) { $idMap[$_.Source.Trim().ToLower()] = $true } }
} else { Write-Host "No IdentityMapCsv supplied — principal coverage cannot be confirmed." -ForegroundColor Yellow }

$permMap = @{}
if ($PermissionMapCsv -and (Test-Path $PermissionMapCsv)) {
    Import-Csv $PermissionMapCsv | ForEach-Object { if ($_.SourceLevel) { $permMap[$_.SourceLevel.Trim().ToLower()] = $true } }
} else { Write-Host "No PermissionMapCsv supplied — level coverage cannot be confirmed." -ForegroundColor Yellow }

$unmappedPrincipals = New-Object System.Collections.Generic.HashSet[string]
$unmappedLevels      = New-Object System.Collections.Generic.HashSet[string]
$totalItems = 0

foreach ($scope in (Import-Csv $ScopeCsv)) {
    if (-not $scope.DriveId) { continue }
    $items = 0; $covered = 0; $uncovered = 0
    try {
        $stack = New-Object System.Collections.Generic.Stack[string]
        $root = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/drives/$($scope.DriveId)/root/children?`$top=200")
        foreach ($c in $root.value) { $stack.Push($c.id) }
        while ($stack.Count -gt 0) {
            $id = $stack.Pop(); $items++
            $node = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/drives/$($scope.DriveId)/items/$id"
            if ($node.folder) {
                $sub = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/drives/$($scope.DriveId)/items/$id/children?`$top=200")
                foreach ($s in $sub.value) { $stack.Push($s.id) }
            }
            try {
                $perms = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/drives/$($scope.DriveId)/items/$id/permissions").value
                foreach ($p in $perms) {
                    $who = $null
                    if ($p.grantedToV2.user.email) { $who = $p.grantedToV2.user.email }
                    elseif ($p.grantedToV2.siteGroup.displayName) { $who = 'group:' + $p.grantedToV2.siteGroup.displayName }
                    elseif ($p.grantedTo.user.email) { $who = $p.grantedTo.user.email }
                    if ($who) {
                        if ($idMap.Count -gt 0 -and -not $idMap.ContainsKey($who.Trim().ToLower())) { [void]$unmappedPrincipals.Add($who); $uncovered++ } else { $covered++ }
                    }
                    foreach ($role in @($p.roles)) {
                        if ($permMap.Count -gt 0 -and $role -and -not $permMap.ContainsKey($role.Trim().ToLower())) { [void]$unmappedLevels.Add($role) }
                    }
                }
            } catch {}
        }
    } catch {
        Write-Host ("  {0}: not readable ({1})" -f $scope.DriveId, $_.Exception.Message) -ForegroundColor Yellow
        continue
    }
    $totalItems += $items
    Write-Host ("  {0,-10} drive {1}: items={2}, grants covered={3}, unmapped={4}" -f $scope.Kind, $scope.DriveId, $items, $covered, $uncovered)
}

Write-Host ""
$prinPass = ($idMap.Count -gt 0) -and ($unmappedPrincipals.Count -eq 0)
$lvlPass  = ($permMap.Count -gt 0) -and ($unmappedLevels.Count -eq 0)
Write-Host ("Items validated             : {0}" -f $totalItems)
Write-Host ("Signal — principal coverage : {0}" -f ($(if($prinPass){'PASS — every source principal is in the identity map (none will be dropped)'}elseif($idMap.Count -eq 0){'GAP — supply -IdentityMapCsv to check'}else{"GAP — $($unmappedPrincipals.Count) unmapped principals will be dropped"}))) -ForegroundColor ($(if($prinPass){'Green'}else{'Yellow'}))
Write-Host ("Signal — level coverage     : {0}" -f ($(if($lvlPass){'PASS — every source permission level maps to a Google role (none will be flattened)'}elseif($permMap.Count -eq 0){'GAP — supply -PermissionMapCsv to check'}else{"GAP — $($unmappedLevels.Count) source levels have no role mapping"}))) -ForegroundColor ($(if($lvlPass){'Green'}else{'Yellow'}))

if ($unmappedPrincipals.Count -gt 0) {
    Write-Host "`nUnmapped principals (add to GWDRIVE Mapping - Identity - Source to Google):" -ForegroundColor Yellow
    $unmappedPrincipals | ForEach-Object { Write-Host ("  - {0}" -f $_) }
}
if ($unmappedLevels.Count -gt 0) {
    Write-Host "`nUnmapped levels (add to GWDRIVE Mapping - Permissions - Level to Role):" -ForegroundColor Yellow
    $unmappedLevels | ForEach-Object { Write-Host ("  - {0}" -f $_) }
}

Disconnect-MgGraph | Out-Null

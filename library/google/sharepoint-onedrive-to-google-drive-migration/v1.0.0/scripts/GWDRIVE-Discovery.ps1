<#
.SYNOPSIS
    GWDRIVE-Discovery.ps1 — inventory source SharePoint Online & OneDrive content, structure, permissions, and sharing for a Drive migration.
.DESCRIPTION
    PURPOSE
        Reads the in-scope SharePoint Online sites/document libraries and OneDrive for Business
        drives through Microsoft Graph and reports item/folder counts, the distinct permission
        principals (users, groups) and the sharing in place. Read-only — it supports the Assess step,
        moves no content, and changes no permissions. Its principal list is the input to the identity
        mapping table (map every principal to a Google identity before migrating, or its permission
        is dropped). Placeholders use plain text such as your-tenant-id, not angle brackets.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWDRIVE-Discovery.ps1
        Optional: -SiteIds site-id-1,site-id-2 to scope to named sites (default: all sites).
        Optional: -CsvPath .\gwdrive-discovery.csv to export the per-scope summary.
        Requires the Microsoft Graph PowerShell SDK. On first run, consent to the read scopes:
        Sites.Read.All, Files.Read.All, User.Read.All, Group.Read.All.
    EXPECTED RESULTS
        A per-scope summary (site/library and OneDrive): item and folder counts, distinct permission
        principals, and shared-item counts, plus a PASS/GAP line per signal you record against the
        Requirements checklist and use to build the mapping artifacts.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string[]]$SiteIds,
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Sites.Read.All','Files.Read.All','User.Read.All','Group.Read.All' -NoWelcome

Write-Host "`n=== Drive migration — source content, permission & sharing discovery ===" -ForegroundColor Cyan

$rows = New-Object System.Collections.Generic.List[object]
$principals = New-Object System.Collections.Generic.HashSet[string]

function Get-GraphPaged {
    param([string]$Uri)
    $items = New-Object System.Collections.Generic.List[object]
    $next = $Uri
    do {
        $r = Invoke-MgGraphRequest -Method GET -Uri $next
        foreach ($v in $r.value) { $items.Add($v) }
        $next = $r.'@odata.nextLink'
    } while ($next)
    return $items
}

# Walk a drive's items, counting files/folders and collecting permission principals + sharing.
function Measure-Drive {
    param([string]$DriveId, [string]$Label, [string]$Kind)
    $files = 0; $folders = 0; $shared = 0
    $local = New-Object System.Collections.Generic.HashSet[string]
    try {
        $children = Get-GraphPaged "/v1.0/drives/$DriveId/root/children?`$top=200"
        $stack = New-Object System.Collections.Generic.Stack[object]
        foreach ($c in $children) { $stack.Push($c) }
        while ($stack.Count -gt 0) {
            $item = $stack.Pop()
            if ($item.folder) {
                $folders++
                try {
                    $sub = Get-GraphPaged "/v1.0/drives/$DriveId/items/$($item.id)/children?`$top=200"
                    foreach ($s in $sub) { $stack.Push($s) }
                } catch {}
            } else { $files++ }
            # Permissions on this item (principals + sharing signals)
            try {
                $perms = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/drives/$DriveId/items/$($item.id)/permissions").value
                foreach ($p in $perms) {
                    if ($p.link) { $shared++ }
                    $who = $null
                    if ($p.grantedToV2.user.email) { $who = $p.grantedToV2.user.email }
                    elseif ($p.grantedToV2.siteGroup.displayName) { $who = 'group:' + $p.grantedToV2.siteGroup.displayName }
                    elseif ($p.grantedTo.user.email) { $who = $p.grantedTo.user.email }
                    if ($who) { [void]$local.Add($who); [void]$principals.Add($who) }
                }
            } catch {}
        }
    } catch {
        Write-Host ("  {0}: not readable ({1})" -f $Label, $_.Exception.Message) -ForegroundColor Yellow
    }
    Write-Host ("  {0,-40} files={1,-6} folders={2,-5} principals={3,-4} shared={4}" -f $Label, $files, $folders, $local.Count, $shared)
    $rows.Add([pscustomobject]@{
        Kind = $Kind; Scope = $Label; DriveId = $DriveId
        Files = $files; Folders = $folders; Principals = $local.Count; SharedItems = $shared
    })
}

# --- SharePoint sites / document libraries ---
Write-Host "`nSharePoint sites / document libraries:" -ForegroundColor Cyan
$sites = @()
try {
    if ($SiteIds) {
        foreach ($id in $SiteIds) { $sites += (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/sites/$id") }
    } else {
        $sites = Get-GraphPaged "/v1.0/sites?search=*"
    }
} catch { Write-Host ("  sites not reachable ({0})" -f $_.Exception.Message) -ForegroundColor Yellow }

foreach ($site in $sites) {
    try {
        $drives = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/sites/$($site.id)/drives").value
        foreach ($d in $drives) { Measure-Drive -DriveId $d.id -Label ("{0} / {1}" -f $site.displayName, $d.name) -Kind 'SharePoint' }
    } catch { Write-Host ("  {0}: drives not readable" -f $site.displayName) -ForegroundColor Yellow }
}

# --- OneDrive for Business ---
Write-Host "`nOneDrive for Business:" -ForegroundColor Cyan
try {
    $users = Get-GraphPaged "/v1.0/users?`$select=id,userPrincipalName&`$top=200"
    foreach ($u in $users) {
        try {
            $od = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$($u.id)/drive?`$select=id"
            if ($od.id) { Measure-Drive -DriveId $od.id -Label ("OneDrive: {0}" -f $u.userPrincipalName) -Kind 'OneDrive' }
        } catch {}
    }
} catch { Write-Host ("  users not reachable ({0})" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Signals ---
$scopeOk = $rows.Count -gt 0
$prinOk  = $principals.Count -gt 0
Write-Host ""
Write-Host ("Signal — scopes discovered  : {0}" -f ($(if($scopeOk){"PASS — $($rows.Count) scopes readable for mapping"}else{'GAP — confirm source access / scope'}))) -ForegroundColor ($(if($scopeOk){'Green'}else{'Yellow'}))
Write-Host ("Signal — permission principals: {0}" -f ($(if($prinOk){"PASS — $($principals.Count) distinct principals (build the identity map from these)"}else{'GAP — no principals read; check Files.Read.All consent'}))) -ForegroundColor ($(if($prinOk){'Green'}else{'Yellow'}))

Write-Host "`nMap EVERY principal above to a Google identity in GWDRIVE Mapping - Identity - Source to Google" -ForegroundColor Cyan
Write-Host "before migrating — an unmapped principal has its permission silently dropped." -ForegroundColor Cyan

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation
    $prinPath = [System.IO.Path]::ChangeExtension($CsvPath, $null).TrimEnd('.') + '-principals.csv'
    $principals | ForEach-Object { [pscustomobject]@{ Principal = $_ } } | Export-Csv -Path $prinPath -NoTypeInformation
    Write-Host ("Saved {0} and {1}" -f $CsvPath, $prinPath)
}

Disconnect-MgGraph | Out-Null

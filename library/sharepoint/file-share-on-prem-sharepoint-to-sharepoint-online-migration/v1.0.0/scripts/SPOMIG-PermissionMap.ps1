<#
.SYNOPSIS
    SPOMIG-PermissionMap.ps1 — read-only permission-mapping helper (source principals -> SPO/M365/Entra groups).
.DESCRIPTION
    Enumerates the explicit (non-inherited) NTFS principals on a source file share, then proposes a
    target mapping to a SharePoint Online group / Microsoft 365 group / Entra security group and a
    permission level. Where a source principal cannot be resolved to an Entra ID object it is FLAGGED
    "Unmatched" for a human decision — never guessed. Read-only planning: makes no permission changes
    in the source or the target. Emits "Permission Map - Source->SPO - Design".
.EXAMPLE
    .\SPOMIG-PermissionMap.ps1 -Path \\fs01\Finance -CsvPath .\PermissionMap.csv
    # PowerShell 5.1+/7+. Optional -ResolveEntra uses Microsoft Graph (Connect-MgGraph) to check that
    # each principal exists in Entra ID; without it, matching is left blank for you to complete.
.NOTES
    Expected results: one row per distinct source principal with a proposed target group + level and an
    Unmatched flag. The wave gate requires ZERO unmatched principals. Nothing is written to any system.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Path,
    [string]$CsvPath,
    [switch]$ResolveEntra   # when set, verifies each principal exists in Entra ID via Graph (read-only)
)

if (-not (Test-Path -LiteralPath $Path)) { throw "Source path not found or not accessible: $Path" }

# Map NTFS rights to an SPO permission level (coarse, review each row).
function Get-SpoLevel([string]$rights) {
    if ($rights -match 'FullControl|Modify|Write') { return 'Edit' }
    if ($rights -match 'ReadAndExecute|Read')       { return 'Read' }
    return 'Read'
}

if ($ResolveEntra) {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Write-Warning 'Microsoft.Graph not installed; install it or run without -ResolveEntra.'
    } else {
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        Connect-MgGraph -Scopes 'Directory.Read.All','Group.Read.All' -NoWelcome
    }
}

Write-Host '=== Permission Map - Source->SPO - Design ===' -ForegroundColor Cyan

# Collect distinct explicit principals and the broadest right each holds anywhere in the tree.
$principals = @{}
Get-ChildItem -LiteralPath $Path -Recurse -Force -Directory -ErrorAction SilentlyContinue |
    ForEach-Object { $_.FullName } |
    ForEach-Object {
        try {
            (Get-Acl -LiteralPath $_ -ErrorAction Stop).Access |
                Where-Object { -not $_.IsInherited } |
                ForEach-Object {
                    $id = $_.IdentityReference.Value
                    $r  = $_.FileSystemRights.ToString()
                    if (-not $principals.ContainsKey($id)) { $principals[$id] = $r } else { $principals[$id] = "$($principals[$id]),$r" }
                }
        } catch { }
    }

$rows = foreach ($id in ($principals.Keys | Sort-Object)) {
    $level    = Get-SpoLevel $principals[$id]
    $leaf     = ($id -split '\\')[-1]
    $unmatched = $true
    if ($ResolveEntra -and (Get-MgContext)) {
        $hit = $null
        try { $hit = Get-MgGroup -Filter "displayName eq '$leaf'" -Top 1 -ErrorAction SilentlyContinue } catch {}
        if (-not $hit) { try { $hit = Get-MgUser -Filter "mailNickname eq '$leaf'" -Top 1 -ErrorAction SilentlyContinue } catch {} }
        if ($hit) { $unmatched = $false }
    }
    [pscustomobject]@{
        SourcePrincipal   = $id
        NtfsRights        = $principals[$id]
        ProposedTargetGroup = "SPO Group - $leaf - Target"   # prefer a group; review/rename per your IA
        ProposedLevel     = $level
        Unmatched         = $unmatched
    }
}

$unmatchedCount = @($rows | Where-Object Unmatched).Count
Write-Host ("--- {0} distinct principals; {1} unmatched ---" -f @($rows).Count, $unmatchedCount) -ForegroundColor Cyan
$rows | Format-Table SourcePrincipal, ProposedTargetGroup, ProposedLevel, Unmatched -AutoSize

if ($CsvPath) {
    $rows | Export-Csv -LiteralPath $CsvPath -NoTypeInformation
    Write-Host ("Saved 'Permission Map - Source->SPO - Design' to {0}" -f $CsvPath) -ForegroundColor Green
}
if ($unmatchedCount -gt 0) {
    Write-Host ("RESOLVE {0} unmatched principal(s) before migrating — do not guess." -f $unmatchedCount) -ForegroundColor Yellow
} else {
    Write-Host 'All principals mapped — permission map ready.' -ForegroundColor Green
}
if ($ResolveEntra -and (Get-MgContext)) { Disconnect-MgGraph | Out-Null }

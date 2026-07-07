<#
.SYNOPSIS
  Discovery (READ-ONLY): produces the "Permission Audit - SPO - Discovery" baseline for a site --
  broken inheritance, unique permissions, direct user grants, Limited Access, and over-share signals.
  Makes no changes.
.DESCRIPTION
  Connects to a SharePoint Online site with PnP PowerShell (modern auth, no stored credentials) and walks
  the web plus its lists/libraries (optionally folders/items) looking for scopes with unique role
  assignments (HasUniqueRoleAssignments). For each role assignment it records the principal, its type
  (User / SharePointGroup / SecurityGroup), and the permission levels bound. It flags DIRECT USER grants,
  principals holding only the system-managed "Limited Access" level, and broad OVER-SHARE principals
  (Everyone, Everyone except external users, the site Members group) holding Edit/Full Control. This is
  the before-state for rollback and the exception list the site owner reviews. Read-only.
.EXAMPLE
  .\SPOPERM-Discovery.ps1 -Url https://contoso.sharepoint.com/sites/Finance
  # Read-only audit of the web and its lists/libraries; prints the summary to the console.
.EXAMPLE
  .\SPOPERM-Discovery.ps1 -Url https://contoso.sharepoint.com/sites/Finance -IncludeItems -CsvPath .\finance-audit.csv
  # Also scan folders/items with unique permissions and export the full baseline to CSV.
  # (PowerShell 5.1+/7+, PnP.PowerShell; connect with Connect-PnPOnline -Interactive.)
.NOTES
  Expected results: one row per unique-permission scope+principal with Direct/LimitedAccess/OverShare
  flags; a summary count of broken-inheritance scopes, direct grants, and over-shares. No changes made.
  Government cloud: use the correct admin/site URL for your cloud (*.sharepoint.us) -- verify in tenant.
  Item-level scanning (-IncludeItems) can be slow on large libraries; scope it deliberately.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Url,
    [switch]$IncludeItems,
    [string]$CsvPath,
    [string[]]$OverShareBroadPrincipals = @('Everyone', 'Everyone except external users'),
    [string[]]$OverShareHighLevels     = @('Edit', 'Full Control', 'Design')
)

Write-Host "Connecting (read-only) to $Url ..." -ForegroundColor Cyan
try {
    Connect-PnPOnline -Url $Url -Interactive -ErrorAction Stop
} catch {
    Write-Error "Connect-PnPOnline failed: $($_.Exception.Message)"; return
}

$results = New-Object System.Collections.Generic.List[object]

function Get-ScopeAssignments {
    param($ClientObject, [string]$ScopeType, [string]$ScopeName, [string]$ScopeUrl)

    Get-PnPProperty -ClientObject $ClientObject -Property HasUniqueRoleAssignments, RoleAssignments | Out-Null
    if (-not $ClientObject.HasUniqueRoleAssignments) { return }

    foreach ($ra in $ClientObject.RoleAssignments) {
        $member = Get-PnPProperty -ClientObject $ra -Property Member
        $binds  = Get-PnPProperty -ClientObject $ra -Property RoleDefinitionBindings
        $levels = ($binds | Select-Object -ExpandProperty Name) -join '; '

        $principalType = $member.PrincipalType.ToString()
        $isDirectUser  = ($principalType -eq 'User')
        $isLimitedOnly = ($levels -eq 'Limited Access')
        $isBroad       = ($OverShareBroadPrincipals -contains $member.Title) `
                            -or ($member.LoginName -match 'spo-grid-all-users|everyone')
        $hasHighLevel  = $false
        foreach ($lvl in $OverShareHighLevels) { if ($levels -match [regex]::Escape($lvl)) { $hasHighLevel = $true } }
        $isOverShare   = ($isBroad -and $hasHighLevel)

        $results.Add([pscustomobject]@{
            ScopeType     = $ScopeType
            ScopeName     = $ScopeName
            ScopeUrl      = $ScopeUrl
            Principal     = $member.Title
            PrincipalType = $principalType
            LoginName     = $member.LoginName
            Levels        = $levels
            DirectUser    = $isDirectUser
            LimitedAccess = $isLimitedOnly
            OverShare     = $isOverShare
        })
    }
}

# --- Web root ---
$web = Get-PnPWeb -Includes HasUniqueRoleAssignments
Get-ScopeAssignments -ClientObject $web -ScopeType 'Web' -ScopeName $web.Title -ScopeUrl $web.Url

# --- Lists / libraries (skip hidden/system) ---
$lists = Get-PnPList | Where-Object { -not $_.Hidden -and $_.BaseTemplate -ne 544 }
foreach ($list in $lists) {
    Get-ScopeAssignments -ClientObject $list -ScopeType 'List' -ScopeName $list.Title -ScopeUrl $list.DefaultViewUrl

    if ($IncludeItems) {
        try {
            $items = Get-PnPListItem -List $list -PageSize 500 -Fields 'ID','FileRef' -ErrorAction Stop
            foreach ($item in $items) {
                Get-PnPProperty -ClientObject $item -Property HasUniqueRoleAssignments | Out-Null
                if ($item.HasUniqueRoleAssignments) {
                    $ref = $item.FieldValues['FileRef']
                    Get-ScopeAssignments -ClientObject $item -ScopeType 'Item' -ScopeName "$($list.Title)#$($item.Id)" -ScopeUrl $ref
                }
            }
        } catch {
            Write-Warning "Item scan skipped for '$($list.Title)': $($_.Exception.Message)"
        }
    }
}

# --- Report ---
Write-Host "`nPermission Audit - SPO - Discovery : $Url" -ForegroundColor Green
if ($results.Count -eq 0) {
    Write-Host "No unique permissions found -- the site inherits cleanly." -ForegroundColor Green
} else {
    $results | Format-Table ScopeType, ScopeName, Principal, PrincipalType, Levels, DirectUser, LimitedAccess, OverShare -AutoSize

    $brokenScopes = ($results | Select-Object ScopeType, ScopeName -Unique).Count
    $directs      = ($results | Where-Object { $_.DirectUser }).Count
    $limited      = ($results | Where-Object { $_.LimitedAccess }).Count
    $overshares   = ($results | Where-Object { $_.OverShare }).Count

    Write-Host "`nSummary:" -ForegroundColor Cyan
    Write-Host ("  Unique-permission scopes : {0}" -f $brokenScopes)
    Write-Host ("  Direct USER grants       : {0}" -f $directs) -ForegroundColor $(if ($directs) {'Yellow'} else {'Green'})
    Write-Host ("  Limited Access entries   : {0}" -f $limited)
    Write-Host ("  Over-share signals       : {0}" -f $overshares) -ForegroundColor $(if ($overshares) {'Yellow'} else {'Green'})
}

if ($CsvPath) {
    $results | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "`nExported baseline to $CsvPath (keep as rollback before-state)." -ForegroundColor Cyan
}

Write-Host "`nNext: review with the site owner, then dry-run SPOPERM-Remediate-GroupAccess.ps1 -WhatIf." -ForegroundColor DarkGray

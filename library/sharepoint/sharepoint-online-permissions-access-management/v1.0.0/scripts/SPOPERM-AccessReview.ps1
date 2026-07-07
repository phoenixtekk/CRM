<#
.SYNOPSIS
  Reporting / access review (READ-ONLY): produces "Access Report - SPO - Report" -- a who-has-access
  export for a site with SharePoint groups expanded to their members (incl. Entra/M365 group members via
  Graph). Makes no changes.
.DESCRIPTION
  Connects with PnP PowerShell (modern auth, no stored credentials). For the web root (and optionally each
  list/library with unique permissions) it enumerates the role assignments, and for each SharePoint group
  it expands the membership -- including nested Entra ID security / Microsoft 365 groups, resolved through
  Microsoft Graph (Connect-MgGraph, read-only Group.Read.All/Directory.Read.All) when -ExpandEntraGroups
  is set. The result is a per-principal list of effective access (who, via which group, at what level, on
  what scope) suitable for owner attestation. This is the recurring evidence used when Entra ID P2 Access
  Reviews or SharePoint Advanced Management site-access review are not licensed. Read-only.
.EXAMPLE
  .\SPOPERM-AccessReview.ps1 -Url https://contoso.sharepoint.com/sites/Finance -Report
  # Print the who-has-access report for the site to the console.
.EXAMPLE
  .\SPOPERM-AccessReview.ps1 -Url https://contoso.sharepoint.com/sites/Finance -Report -ExpandEntraGroups -CsvPath .\finance-access.csv
  # Expand nested Entra/M365 groups via Graph and export the attestation report to CSV.
  # (PowerShell 5.1+/7+, PnP.PowerShell + Microsoft.Graph; connect with Connect-PnPOnline / Connect-MgGraph.)
.NOTES
  Expected results: one row per (principal, group, level, scope). Route the export to the site owner for
  recurring attestation (Access Review - <Site> - Prod). -ExpandEntraGroups requires delegated
  Group.Read.All / Directory.Read.All. Government cloud: connect Graph with the correct environment
  (Connect-MgGraph -Environment USGov / USGovDoD) and the correct site URL -- verify in tenant.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Url,
    [switch]$Report,
    [switch]$IncludeLists,
    [switch]$ExpandEntraGroups,
    [string]$CsvPath
)

Write-Host "Connecting (read-only) to $Url ..." -ForegroundColor Cyan
try {
    Connect-PnPOnline -Url $Url -Interactive -ErrorAction Stop
} catch {
    Write-Error "Connect-PnPOnline failed: $($_.Exception.Message)"; return
}

if ($ExpandEntraGroups) {
    try {
        Connect-MgGraph -Scopes 'Group.Read.All','Directory.Read.All' -ErrorAction Stop | Out-Null
        Write-Host "Connected to Microsoft Graph (read-only) for Entra/M365 group expansion." -ForegroundColor Cyan
    } catch {
        Write-Warning "Connect-MgGraph failed; nested Entra/M365 groups will not be expanded: $($_.Exception.Message)"
        $ExpandEntraGroups = $false
    }
}

$rows = New-Object System.Collections.Generic.List[object]

function Expand-EntraMembers {
    param([string]$LoginName, [string]$GroupTitle)
    # SharePoint stores Entra groups as ...|federateddirectoryclaimprovider|<objectId>
    if ($LoginName -match '([0-9a-fA-F-]{36})') {
        $objectId = $Matches[1]
        try {
            $members = Get-MgGroupMember -GroupId $objectId -All -ErrorAction Stop
            foreach ($m in $members) {
                $disp = $m.AdditionalProperties['displayName']
                $upn  = $m.AdditionalProperties['userPrincipalName']
                [pscustomobject]@{ Member = $disp; Upn = $upn; Via = "Entra group: $GroupTitle" }
            }
        } catch {
            Write-Verbose "Could not expand Entra group $GroupTitle ($objectId): $($_.Exception.Message)"
        }
    }
}

function Add-ScopeReport {
    param($ClientObject, [string]$ScopeName, [string]$ScopeUrl)

    Get-PnPProperty -ClientObject $ClientObject -Property RoleAssignments | Out-Null
    foreach ($ra in $ClientObject.RoleAssignments) {
        $member = Get-PnPProperty -ClientObject $ra -Property Member
        $levels = ((Get-PnPProperty -ClientObject $ra -Property RoleDefinitionBindings) | Select-Object -ExpandProperty Name) -join '; '
        $pType  = $member.PrincipalType.ToString()

        if ($pType -eq 'SharePointGroup') {
            $spMembers = Get-PnPGroupMember -Identity $member.Title -ErrorAction SilentlyContinue
            foreach ($sm in $spMembers) {
                if ($ExpandEntraGroups -and $sm.PrincipalType -match 'SecurityGroup') {
                    foreach ($em in (Expand-EntraMembers -LoginName $sm.LoginName -GroupTitle $sm.Title)) {
                        $rows.Add([pscustomobject]@{ Scope=$ScopeName; ScopeUrl=$ScopeUrl; Group=$member.Title; Member=$em.Member; Upn=$em.Upn; Via=$em.Via; Level=$levels })
                    }
                } else {
                    $rows.Add([pscustomobject]@{ Scope=$ScopeName; ScopeUrl=$ScopeUrl; Group=$member.Title; Member=$sm.Title; Upn=$sm.LoginName; Via='SharePoint group'; Level=$levels })
                }
            }
        }
        elseif ($ExpandEntraGroups -and $pType -eq 'SecurityGroup') {
            foreach ($em in (Expand-EntraMembers -LoginName $member.LoginName -GroupTitle $member.Title)) {
                $rows.Add([pscustomobject]@{ Scope=$ScopeName; ScopeUrl=$ScopeUrl; Group=$member.Title; Member=$em.Member; Upn=$em.Upn; Via=$em.Via; Level=$levels })
            }
        }
        else {
            # Direct user (should be none after remediation) -- report so it's caught.
            $rows.Add([pscustomobject]@{ Scope=$ScopeName; ScopeUrl=$ScopeUrl; Group='(direct grant)'; Member=$member.Title; Upn=$member.LoginName; Via='DIRECT'; Level=$levels })
        }
    }
}

$web = Get-PnPWeb
Add-ScopeReport -ClientObject $web -ScopeName $web.Title -ScopeUrl $web.Url

if ($IncludeLists) {
    $lists = Get-PnPList | Where-Object { -not $_.Hidden -and $_.BaseTemplate -ne 544 }
    foreach ($list in $lists) {
        Get-PnPProperty -ClientObject $list -Property HasUniqueRoleAssignments | Out-Null
        if ($list.HasUniqueRoleAssignments) {
            Add-ScopeReport -ClientObject $list -ScopeName $list.Title -ScopeUrl $list.DefaultViewUrl
        }
    }
}

Write-Host "`nAccess Report - SPO - Report : $Url" -ForegroundColor Green
if ($Report) {
    $rows | Format-Table Scope, Group, Member, Via, Level -AutoSize
}

$directLeftovers = ($rows | Where-Object { $_.Via -eq 'DIRECT' }).Count
Write-Host ("`nPrincipals reported: {0}  |  direct-grant leftovers: {1}" -f $rows.Count, $directLeftovers) `
    -ForegroundColor $(if ($directLeftovers) {'Yellow'} else {'Green'})
if ($directLeftovers) {
    Write-Host "Direct grants remain -- run SPOPERM-Remediate-GroupAccess.ps1 -ConvertDirectGrants." -ForegroundColor Yellow
}

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "Exported attestation report to $CsvPath (route to the site owner: Access Review - <Site> - Prod)." -ForegroundColor Cyan
}

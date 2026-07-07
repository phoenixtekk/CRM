<#
.SYNOPSIS
  Remediation (SAFE BY DEFAULT / -WhatIf): moves a site to GROUP-BASED access -- ensures the standard
  SharePoint groups + levels exist, and converts DIRECT USER grants at the web root into group membership.
  Dry-run unless -Commit.
.DESCRIPTION
  Connects with PnP PowerShell (modern auth, no stored credentials). With -EnsureGroups it verifies the
  three standard SharePoint groups (Owners=Full Control, Members=Edit, Visitors=Read) exist with the
  correct permission levels, creating/binding any that are missing. With -ConvertDirectGrants it reads the
  web-root role assignments, and for each principal that is a DIRECT USER it proposes the target group
  based on the granted level (Full Control->Owners, Edit/Contribute->Members, Read->Visitors), then adds
  the user to that group and removes the direct grant. Records the change as
  "Group Access Remediation - <Site> - Remediation". SAFE BY DEFAULT: reports the plan only; nothing is
  written unless -Commit is supplied. Supports -WhatIf.
.EXAMPLE
  .\SPOPERM-Remediate-GroupAccess.ps1 -Url https://contoso.sharepoint.com/sites/Finance -EnsureGroups -WhatIf
  # Show what standard groups/levels would be created or corrected. No changes.
.EXAMPLE
  .\SPOPERM-Remediate-GroupAccess.ps1 -Url https://contoso.sharepoint.com/sites/Finance -ConvertDirectGrants -Commit
  # Convert each direct user grant at the root into the matching group membership and remove the direct grant.
  # (PowerShell 5.1+/7+, PnP.PowerShell; connect with Connect-PnPOnline -Interactive.)
.NOTES
  Expected results: a per-user plan (user -> target group; direct grant removed). With -Commit the users
  are added to the standard groups and their direct web-root grants removed; re-run SPOPERM-Discovery.ps1
  to confirm no direct USER grants remain at the root. Requires Site Collection Admin on the target site.
  Government cloud: use the correct site URL (*.sharepoint.us) -- verify in tenant.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)][string]$Url,
    [switch]$EnsureGroups,
    [switch]$ConvertDirectGrants,
    [string]$OwnersGroup   = 'Owners',
    [string]$MembersGroup  = 'Members',
    [string]$VisitorsGroup = 'Visitors',
    [switch]$Commit
)

$doWrite = $Commit -and $PSCmdlet.ShouldProcess($Url, 'Apply group-based access remediation')

Write-Host "Connecting to $Url ..." -ForegroundColor Cyan
try {
    Connect-PnPOnline -Url $Url -Interactive -ErrorAction Stop
} catch {
    Write-Error "Connect-PnPOnline failed: $($_.Exception.Message)"; return
}

$web = Get-PnPWeb
# Resolve the site's associated group titles where present (Team/comm sites prefix with the site title).
$assoc = @{
    Owners   = (Get-PnPProperty -ClientObject $web -Property AssociatedOwnerGroup).Title
    Members  = (Get-PnPProperty -ClientObject $web -Property AssociatedMemberGroup).Title
    Visitors = (Get-PnPProperty -ClientObject $web -Property AssociatedVisitorGroup).Title
}
$targetLevel = @{ Owners = 'Full Control'; Members = 'Edit'; Visitors = 'Read' }

if (-not $doWrite) {
    Write-Host "`n*** DRY-RUN (report only) -- pass -Commit to apply changes ***`n" -ForegroundColor Yellow
}

# --- EnsureGroups: standard groups exist with the standard levels ---
if ($EnsureGroups) {
    Write-Host "Group Access Remediation - $($web.Title) - Remediation : ensuring standard groups/levels" -ForegroundColor Green
    foreach ($role in 'Owners','Members','Visitors') {
        $groupTitle = $assoc[$role]
        $level      = $targetLevel[$role]
        $existing   = if ($groupTitle) { Get-PnPGroup -Identity $groupTitle -ErrorAction SilentlyContinue } else { $null }

        if ($existing) {
            $perms = (Get-PnPGroupPermissions -Identity $groupTitle -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name) -join '; '
            if ($perms -match [regex]::Escape($level)) {
                Write-Host ("  OK   {0,-9} '{1}' has '{2}'" -f $role, $groupTitle, $level) -ForegroundColor Green
            } else {
                Write-Host ("  FIX  {0,-9} '{1}' should have '{2}' (has: {3})" -f $role, $groupTitle, $level, $perms) -ForegroundColor Yellow
                if ($doWrite) { Set-PnPGroupPermissions -Identity $groupTitle -AddRole $level }
            }
        } else {
            Write-Host ("  MISS {0,-9} no associated group -- would create '{1} {2}' with '{3}'" -f $role, $web.Title, $role, $targetLevel[$role]) -ForegroundColor Yellow
            if ($doWrite) {
                $new = New-PnPGroup -Title "$($web.Title) $role"
                Set-PnPGroupPermissions -Identity $new.Title -AddRole $level
                $assoc[$role] = $new.Title
            }
        }
    }
}

# --- ConvertDirectGrants: direct USER grants at the root -> group membership ---
if ($ConvertDirectGrants) {
    Write-Host "`nGroup Access Remediation - $($web.Title) - Remediation : converting direct user grants" -ForegroundColor Green
    Get-PnPProperty -ClientObject $web -Property RoleAssignments | Out-Null

    foreach ($ra in $web.RoleAssignments) {
        $member = Get-PnPProperty -ClientObject $ra -Property Member
        if ($member.PrincipalType.ToString() -ne 'User') { continue }
        if ($member.LoginName -match 'app@sharepoint|system|SHAREPOINT\\system') { continue }

        $binds  = (Get-PnPProperty -ClientObject $ra -Property RoleDefinitionBindings | Select-Object -ExpandProperty Name)
        $levels = $binds -join '; '
        $target =
            if     ($levels -match 'Full Control') { $assoc.Owners }
            elseif ($levels -match 'Edit|Contribute|Design') { $assoc.Members }
            elseif ($levels -match 'Read') { $assoc.Visitors }
            else   { $null }

        if (-not $target) {
            Write-Host ("  SKIP  {0} has '{1}' -- no standard group maps; owner must decide" -f $member.Title, $levels) -ForegroundColor Yellow
            continue
        }

        Write-Host ("  PLAN  {0}  ->  add to '{1}'  (remove direct '{2}')" -f $member.Title, $target, $levels)
        if ($doWrite) {
            try {
                Add-PnPGroupMember -LoginName $member.LoginName -Identity $target -ErrorAction Stop
                Set-PnPWebPermission -User $member.LoginName -RemoveRole $binds -ErrorAction Stop
                Write-Host ("  DONE  {0} converted to '{1}'" -f $member.Title, $target) -ForegroundColor Green
            } catch {
                Write-Warning "  Could not convert $($member.Title): $($_.Exception.Message)"
            }
        }
    }
}

if (-not $doWrite) {
    Write-Host "`nDry-run complete. Re-run with -Commit after owner approval." -ForegroundColor Yellow
} else {
    Write-Host "`nCommit complete. Verify with SPOPERM-Discovery.ps1 and SPOPERM-AccessReview.ps1 -Report." -ForegroundColor Cyan
}

<#
.SYNOPSIS
    SPMAM-Report.ps1 — coverage report: which target users have an App Protection Policy AND are in
    scope of the SharePoint Online CA app-protection grant (Microsoft Graph). Read-only.
.DESCRIPTION
    PURPOSE
        For a target group (the mobile-access population), reports per user whether an App Protection
        Policy applies and whether an enabled Office 365 CA app-protection grant includes them, so
        you can see coverage and gaps at a glance before enforcing or expanding.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SPMAM-Report.ps1 -TargetGroup "SPO Mobile - Users - Prod" -CsvPath C:\Temp\spmam.csv
        Requires the Microsoft Graph PowerShell SDK. Consented scopes (read-only):
        DeviceManagementApps.Read.All, Policy.Read.All, Group.Read.All, User.Read.All.
    EXPECTED RESULTS
        A per-user table (APP applied? / CA effective? / ready?) and a summary count of ready vs
        gapped users; optional CSV export.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only against Graph.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory=$true)][string]$TargetGroup,
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All','Policy.Read.All','Group.Read.All','User.Read.All' -NoWelcome

# Resolve target group + members
$grp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$TargetGroup'&`$select=id,displayName").value | Select-Object -First 1
if (-not $grp) { Write-Host "Group not found: $TargetGroup" -ForegroundColor Red; Disconnect-MgGraph | Out-Null; exit 1 }
$members = @()
$uri = "/v1.0/groups/$($grp.id)/transitiveMembers/microsoft.graph.user?`$select=id,userPrincipalName"
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $members += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)

# Pre-load APP assignment group IDs and enabled O365 app-protection CA policies
$appGroupIds = @()
foreach ($seg in 'iosManagedAppProtections','androidManagedAppProtections') {
    try { $appGroupIds += ((Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceAppManagement/$seg`?`$expand=assignments").value | ForEach-Object { $_.assignments } | ForEach-Object { $_.target.groupId }) } catch {}
}
$appGroupIds = $appGroupIds | Where-Object { $_ } | Select-Object -Unique

$caPolicies = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value | Where-Object {
    $_.state -eq 'enabled' -and (($_.grantControls.builtInControls -contains 'compliantApplication') -or ($_.grantControls.builtInControls -contains 'approvedApplication')) -and
    ((@($_.conditions.applications.includeApplications) -contains 'Office365') -or (@($_.conditions.applications.includeApplications) -contains 'All') -or (@($_.conditions.applications.includeApplications) -contains '00000003-0000-0ff1-ce00-000000000000'))
}

$rows = foreach ($u in $members) {
    $mids = @()
    $muri = "/v1.0/users/$($u.id)/transitiveMemberOf?`$select=id"
    do { $mr = Invoke-MgGraphRequest -Method GET -Uri $muri; $mids += ($mr.value | ForEach-Object { $_.id }); $muri = $mr.'@odata.nextLink' } while ($muri)

    $appOk = [bool]($appGroupIds | Where-Object { $mids -contains $_ })
    $caOk = $false
    foreach ($c in $caPolicies) {
        $incAll = $c.conditions.users.includeUsers -contains 'All'
        $inc = $incAll -or ($c.conditions.users.includeGroups | Where-Object { $mids -contains $_ }) -or ($c.conditions.users.includeUsers -contains $u.id)
        $exc = ($c.conditions.users.excludeGroups | Where-Object { $mids -contains $_ }) -or ($c.conditions.users.excludeUsers -contains $u.id)
        if ($inc -and -not $exc) { $caOk = $true }
    }
    [pscustomobject]@{ User=$u.userPrincipalName; AppProtection=$appOk; CAGrant=$caOk; Ready=($appOk -and $caOk) }
}

Write-Host "=== SharePoint Online mobile-access coverage — $TargetGroup ===" -ForegroundColor Cyan
$rows | Sort-Object Ready | Format-Table -AutoSize
$ready = ($rows | Where-Object Ready).Count
Write-Host ("Ready: {0} / {1}   (gaps: {2})" -f $ready, $rows.Count, ($rows.Count - $ready)) -ForegroundColor Cyan
if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }

Disconnect-MgGraph | Out-Null

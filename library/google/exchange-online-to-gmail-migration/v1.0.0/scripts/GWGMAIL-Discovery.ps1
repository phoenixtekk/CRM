<#
.SYNOPSIS
    GWGMAIL-Discovery.ps1 — baseline the Exchange Online / M365 source estate for mail migration.
.DESCRIPTION
    PURPOSE
        Captures the source-mailbox baseline the migration is planned from: total and licensed user
        counts, resource/room mailboxes, and group/distribution-list counts read from the Microsoft
        365 / Entra source through Microsoft Graph. Read-only — it supports the Assess step, moves no
        mail, and changes no mail flow. Per-mailbox data volumes, contact counts, and mail-touching
        integrations the API cannot read are recorded by hand into the baseline artifact.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWGMAIL-Discovery.ps1
        Optional: -CsvPath .\gwgmail-baseline.csv to export the summary.
        Requires the Microsoft Graph PowerShell SDK. On first run, consent to the read scopes:
        User.Read.All, Organization.Read.All, Group.Read.All.
    EXPECTED RESULTS
        A baseline summary: total users, licensed users, resource/room mailboxes, and group count,
        with a PASS/GAP line per signal you record against the Requirements checklist as
        GWGMAIL Discovery - Source Mailboxes - Baseline.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'User.Read.All','Organization.Read.All','Group.Read.All' -NoWelcome

Write-Host "`n=== Exchange Online to Gmail — source-mailbox discovery ===" -ForegroundColor Cyan

function Get-GraphCount {
    param([string]$Uri)
    $total = 0
    $next = $Uri
    do {
        $r = Invoke-MgGraphRequest -Method GET -Uri $next
        $total += @($r.value).Count
        $next = $r.'@odata.nextLink'
    } while ($next)
    return $total
}

# Total users
$totalUsers = 0
try {
    $totalUsers = Get-GraphCount "/v1.0/users?`$select=id"
    Write-Host ("Total users            : {0}" -f $totalUsers)
} catch {
    Write-Host ("Total users            : not reachable ({0})" -f $_.Exception.Message) -ForegroundColor Yellow
}

# Licensed users (proxy: users with assignedLicenses = mailbox-bearing candidates)
$licensedUsers = 0
try {
    $uri = "/v1.0/users?`$select=id,assignedLicenses&`$top=999"
    $next = $uri
    do {
        $r = Invoke-MgGraphRequest -Method GET -Uri $next
        foreach ($u in $r.value) { if (@($u.assignedLicenses).Count -gt 0) { $licensedUsers++ } }
        $next = $r.'@odata.nextLink'
    } while ($next)
    Write-Host ("Licensed users         : {0}" -f $licensedUsers)
} catch {
    Write-Host ("Licensed users         : not reachable ({0})" -f $_.Exception.Message) -ForegroundColor Yellow
}

# Resource/room mailboxes (for calendar mapping planning)
$resourceMailboxes = 0
try {
    $rooms = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/places/microsoft.graph.room?`$select=id"
    $resourceMailboxes = @($rooms.value).Count
    Write-Host ("Resource/room mailboxes: {0}" -f $resourceMailboxes)
} catch {
    Write-Host ("Resource/room mailboxes: not readable via Graph places (record manually)") -ForegroundColor Yellow
}
Write-Host ("Shared mailboxes       : record manually from Exchange admin (not exposed uniformly via Graph)") -ForegroundColor Yellow

# Groups / distribution lists
$groups = 0
try {
    $groups = Get-GraphCount "/v1.0/groups?`$select=id"
    Write-Host ("Groups / dist. lists   : {0}" -f $groups)
} catch {
    Write-Host ("Groups / dist. lists   : not reachable ({0})" -f $_.Exception.Message) -ForegroundColor Yellow
}

# Signals
$usersOk = $totalUsers -gt 0
$licOk   = $licensedUsers -gt 0
$grpOk   = $groups -gt 0
Write-Host ""
Write-Host ("Signal — user baseline : {0}" -f ($(if($usersOk){'PASS — user counts readable for batch sizing'}else{'GAP — confirm source tenant access'}))) -ForegroundColor ($(if($usersOk){'Green'}else{'Yellow'}))
Write-Host ("Signal — mail licensing: {0}" -f ($(if($licOk){'PASS — licensed/mailbox population visible'}else{'GAP — confirm license read access'}))) -ForegroundColor ($(if($licOk){'Green'}else{'Yellow'}))
Write-Host ("Signal — groups        : {0}" -f ($(if($grpOk){'PASS — group/DL counts readable'}else{'GAP — confirm group read access'}))) -ForegroundColor ($(if($grpOk){'Green'}else{'Yellow'}))

Write-Host "`nRecord these counts in GWGMAIL Discovery - Source Mailboxes - Baseline, then add per-mailbox" -ForegroundColor Cyan
Write-Host "data volumes, contact counts, resource-calendar mappings, and mail-touching integrations by hand." -ForegroundColor Cyan

if ($CsvPath) {
    [pscustomobject]@{
        TotalUsers        = $totalUsers
        LicensedUsers     = $licensedUsers
        ResourceMailboxes = $resourceMailboxes
        Groups            = $groups
    } | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved {0}" -f $CsvPath)
}

Disconnect-MgGraph | Out-Null

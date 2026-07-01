<#
.SYNOPSIS
    HYBID-Set-SyncScopeHelper.ps1 — review and stage organizational-unit sync-scope changes.
.DESCRIPTION
    PURPOSE
        Helps you plan the Microsoft Entra Connect domain/OU sync scope. It lists candidate OUs with
        the count of users and computers each contains, so you can decide what to include, and it
        previews how many objects a proposed set of OUs would bring into scope BEFORE you set the
        filter in the wizard. It does NOT change the Connect filter itself (OU/domain filtering is set
        in the Microsoft Entra Connect wizard); it produces the object list and counts to drive that
        decision safely.
    HOW TO RUN
        Inventory candidate OUs (read-only):
            powershell -ExecutionPolicy Bypass -File .\HYBID-Set-SyncScopeHelper.ps1
        Preview a proposed scope (read-only):
            powershell -ExecutionPolicy Bypass -File .\HYBID-Set-SyncScopeHelper.ps1 ^
                -IncludeOU "OU=Hybrid Pilot Sync Scope - Pilot - Pilot,DC=corp,DC=example,DC=com"
        Requires the ActiveDirectory module (RSAT AD tools).
    EXPECTED RESULTS
        A table of OUs with user/computer counts, or — when -IncludeOU is supplied — the total users
        and computers the proposed scope would synchronize. No directory or sync changes are made.
.NOTES
    Workplace Marketplace — Entra ID Solutions. Read-only (planning helper).
#>
[CmdletBinding()]
param(
    [string[]]$IncludeOU
)

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Host "ActiveDirectory module required (RSAT AD tools)." -ForegroundColor Yellow
    return
}
Import-Module ActiveDirectory -ErrorAction Stop

function Get-ScopeCounts([string]$ou) {
    $u = (Get-ADUser -Filter * -SearchBase $ou -ErrorAction SilentlyContinue | Measure-Object).Count
    $c = (Get-ADComputer -Filter * -SearchBase $ou -ErrorAction SilentlyContinue | Measure-Object).Count
    [pscustomobject]@{ OU = $ou; Users = $u; Computers = $c }
}

if ($IncludeOU) {
    Write-Host "`n=== Proposed sync scope preview ===" -ForegroundColor Cyan
    $totalU = 0; $totalC = 0
    foreach ($ou in $IncludeOU) {
        $r = Get-ScopeCounts $ou
        Write-Host ("  {0}`n    users {1}, computers {2}" -f $r.OU, $r.Users, $r.Computers)
        $totalU += $r.Users; $totalC += $r.Computers
    }
    Write-Host ("`nTotal in proposed scope: {0} users, {1} computers." -f $totalU, $totalC) -ForegroundColor Green
    Write-Host "Set these OUs in the Microsoft Entra Connect wizard -> Domain and OU filtering." -ForegroundColor Cyan
} else {
    Write-Host "`n=== Candidate OUs (top level) ===" -ForegroundColor Cyan
    $base = (Get-ADDomain).DistinguishedName
    Get-ADOrganizationalUnit -Filter * -SearchBase $base -SearchScope OneLevel |
        ForEach-Object { Get-ScopeCounts $_.DistinguishedName } |
        Sort-Object Users -Descending |
        Format-Table OU, Users, Computers -AutoSize
    Write-Host "Re-run with -IncludeOU '<DN>' [,'<DN>'...] to preview a proposed scope." -ForegroundColor Cyan
}

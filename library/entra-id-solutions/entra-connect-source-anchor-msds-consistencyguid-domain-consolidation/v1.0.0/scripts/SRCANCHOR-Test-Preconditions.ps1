<#
.SYNOPSIS
    SRCANCHOR-Test-Preconditions.ps1 — list in-scope objects that already have mS-DS-ConsistencyGuid set.
.DESCRIPTION
    PURPOSE
        Read-only precondition test for the source-anchor switch. The Microsoft Entra Connect wizard only
        seeds mS-DS-ConsistencyGuid where it is EMPTY; if ANY in-scope object already has a value, the
        wizard refuses by default. This script enumerates the supplied in-scope OUs and reports, per OU
        and in total, any objects whose mS-DS-ConsistencyGuid is already populated — the blocker — with a
        count and a sample of distinguishedNames so you can investigate what set it. Makes no changes.
    HOW TO RUN
        On the Microsoft Entra Connect server (or any host with RSAT AD tools), elevated:
            powershell -ExecutionPolicy Bypass -File .\SRCANCHOR-Test-Preconditions.ps1 ^
                -IncludeOU "OU=Source Anchor - In-Scope OUs,DC=corp,DC=example,DC=com"
        Pass one or more OU distinguishedNames via -IncludeOU. Requires the ActiveDirectory module.
    EXPECTED RESULTS
        Per-OU and total count of objects with mS-DS-ConsistencyGuid already set (expect 0), plus a
        sample of distinguishedNames for any that are. PASS when the total is 0; BLOCKED otherwise. No
        changes are made.
.NOTES
    White-label — the repeatable way. Read-only; the anchor change itself is done in the Microsoft Entra
    Connect wizard, never scripted. Vendor internals (Quest On Demand Migration) deferred to vendor docs.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$IncludeOU,

    [int]$SampleSize = 10
)

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Host "ActiveDirectory module required (RSAT AD tools)." -ForegroundColor Yellow
    return
}
Import-Module ActiveDirectory -ErrorAction Stop

Write-Host "`n=== Source Anchor Precondition Test ===" -ForegroundColor Cyan
$total = 0
$sample = New-Object System.Collections.ArrayList

foreach ($ou in $IncludeOU) {
    $hits = @(Get-ADObject -LDAPFilter '(mS-DS-ConsistencyGuid=*)' -SearchBase $ou -Properties distinguishedName -ErrorAction SilentlyContinue)
    Write-Host ("  {0}`n    already populated: {1}" -f $ou, $hits.Count) -ForegroundColor ($(if ($hits.Count -gt 0) { 'Yellow' } else { 'Green' }))
    $total += $hits.Count
    foreach ($h in $hits) { if ($sample.Count -lt $SampleSize) { [void]$sample.Add($h.DistinguishedName) } }
}

if ($total -gt 0) {
    Write-Host ("`nSample of already-populated objects (up to {0}):" -f $SampleSize) -ForegroundColor Yellow
    $sample | ForEach-Object { Write-Host ("  {0}" -f $_) }
    Write-Host ("`nResult: BLOCKED — {0} in-scope object(s) already have mS-DS-ConsistencyGuid set." -f $total) -ForegroundColor Yellow
    Write-Host "Investigate what populated the attribute; clear it (only after confirming it is safe) or exclude those objects from scope, until the count is 0." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "`nResult: PASS — no in-scope object has mS-DS-ConsistencyGuid set. The wizard can seed all objects." -ForegroundColor Green
    exit 0
}

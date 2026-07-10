<#
.SYNOPSIS
    SRCANCHOR-Report.ps1 — coverage and duplicate-risk report for the source-anchor migration.
.DESCRIPTION
    PURPOSE
        Read-only run/coverage report. Summarizes the in-scope object count, how many carry
        mS-DS-ConsistencyGuid (seeded coverage), recent Microsoft Entra Connect sync run results/errors
        (best-effort via Get-ADSyncRunProfileResult), and a duplicate-risk check that flags any in-scope
        objects still missing mS-DS-ConsistencyGuid (which would migrate as new/duplicate identities).
        Optionally writes the per-object coverage to CSV. Makes no changes.
    HOW TO RUN
        On the Microsoft Entra Connect server, elevated:
            powershell -ExecutionPolicy Bypass -File .\SRCANCHOR-Report.ps1 ^
                -IncludeOU "OU=Source Anchor - In-Scope OUs,DC=corp,DC=example,DC=com" ^
                -CsvPath .\SourceAnchor-Coverage.csv
        Requires the ActiveDirectory module; the sync-run section requires the ADSync (Connect) role.
    EXPECTED RESULTS
        In-scope object count, populated (seeded) count, populated %, recent run results with any error
        counts, and a duplicate-risk verdict (0 unseeded in-scope objects = low risk). Optional CSV. No
        changes are made.
.NOTES
    White-label — the repeatable way. Read-only; the anchor change itself is done in the Microsoft Entra
    Connect wizard, never scripted. Vendor internals (Quest On Demand Migration) deferred to vendor docs.
#>
[CmdletBinding()]
param(
    [string[]]$IncludeOU,
    [string]$CsvPath
)

Write-Host "`n=== Source Anchor Report — $(Get-Date -Format s) ===" -ForegroundColor Cyan

$rows = New-Object System.Collections.ArrayList
$inScope = 0; $populated = 0

if (Get-Module -ListAvailable -Name ActiveDirectory) {
    Import-Module ActiveDirectory -ErrorAction Stop
    $scopes = if ($IncludeOU) { $IncludeOU } else { @((Get-ADDomain).DistinguishedName) }
    foreach ($ou in $scopes) {
        $objs = Get-ADUser -Filter * -SearchBase $ou -Properties 'mS-DS-ConsistencyGuid', UserPrincipalName -ErrorAction SilentlyContinue
        foreach ($o in $objs) {
            $inScope++
            $has = [bool]$o.'mS-DS-ConsistencyGuid'
            if ($has) { $populated++ }
            [void]$rows.Add([pscustomobject]@{
                    UserPrincipalName = $o.UserPrincipalName
                    OU                = $ou
                    ConsistencyGuidSet = $has
                })
        }
    }
    $pct = if ($inScope -gt 0) { [math]::Round(100.0 * $populated / $inScope, 1) } else { 0 }
    Write-Host "`n-- Coverage --" -ForegroundColor Cyan
    Write-Host ("  In-scope objects              : {0}" -f $inScope)
    Write-Host ("  mS-DS-ConsistencyGuid populated: {0} ({1}%)" -f $populated, $pct) -ForegroundColor ($(if ($populated -eq $inScope -and $inScope -gt 0) { 'Green' } else { 'Yellow' }))
} else {
    Write-Host "ActiveDirectory module not found — install RSAT AD tools for coverage." -ForegroundColor Yellow
}

# Recent ADSync run results (best-effort)
Write-Host "`n-- Recent sync run results --" -ForegroundColor Cyan
if (Get-Module -ListAvailable -Name ADSync) {
    Import-Module ADSync -ErrorAction Stop
    $runs = Get-ADSyncRunProfileResult -NumberRequested 10 -ErrorAction SilentlyContinue
    if ($runs) {
        foreach ($r in $runs) {
            $color = $(if ($r.Result -eq 'success') { 'Green' } else { 'Yellow' })
            Write-Host ("  {0,-22} {1,-26} {2}" -f $r.ConnectorName, $r.RunProfileName, $r.Result) -ForegroundColor $color
        }
    } else { Write-Host "  No run results found." -ForegroundColor Yellow }
} else {
    Write-Host "  ADSync module not found — run on the Connect server for run results." -ForegroundColor Yellow
}

# Duplicate-risk check
$unseeded = $inScope - $populated
Write-Host "`n-- Duplicate-risk check --" -ForegroundColor Cyan
if ($inScope -gt 0 -and $unseeded -eq 0) {
    Write-Host "  LOW RISK — every in-scope object carries mS-DS-ConsistencyGuid; migrations can hard-match." -ForegroundColor Green
} else {
    Write-Host ("  RISK — {0} in-scope object(s) have NO mS-DS-ConsistencyGuid; migrating them now would create duplicates. Seed/verify before migrating." -f $unseeded) -ForegroundColor Yellow
}

if ($CsvPath -and $rows.Count -gt 0) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`nPer-object coverage written to {0}" -f $CsvPath) -ForegroundColor Cyan
}

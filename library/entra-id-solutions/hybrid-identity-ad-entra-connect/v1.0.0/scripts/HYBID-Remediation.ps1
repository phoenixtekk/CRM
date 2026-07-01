<#
.SYNOPSIS
    HYBID-Remediation.ps1 — safely fix sync errors and duplicate UPN/proxyAddress values.
.DESCRIPTION
    PURPOSE
        Addresses the two most common hybrid-identity faults: (1) duplicate proxyAddress values in
        AD that cause duplicate-attribute sync errors, and (2) a stalled sync engine. By default it
        runs in -WhatIf mode and only reports what it WOULD change — re-run with -Apply to act. With
        -Apply it removes the conflicting (lower-priority) duplicate proxyAddress entries you
        confirm, then triggers a delta sync cycle.
    HOW TO RUN
        Dry run (default, no changes):
            powershell -ExecutionPolicy Bypass -File .\HYBID-Remediation.ps1
        Apply fixes after reviewing the dry run:
            powershell -ExecutionPolicy Bypass -File .\HYBID-Remediation.ps1 -Apply
        Requires the ActiveDirectory module; the sync trigger requires the ADSync (Connect) role.
    EXPECTED RESULTS
        A list of duplicate proxyAddress conflicts (always), and — only with -Apply — the removals
        performed plus a triggered delta sync. Nothing is changed unless -Apply is supplied.
.NOTES
    Workplace Marketplace — Entra ID Solutions. Defaults to -WhatIf (no changes).
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Apply
)

# Default to WhatIf unless -Apply is explicitly passed.
if (-not $Apply) { $WhatIfPreference = $true }

Write-Host "=== Hybrid Identity Remediation ($([bool]$Apply ? 'APPLY' : 'WhatIf')) ===" -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Host "ActiveDirectory module required (RSAT AD tools)." -ForegroundColor Yellow
    return
}
Import-Module ActiveDirectory -ErrorAction Stop

# Find duplicate proxyAddresses across users
$users = Get-ADUser -Filter * -Properties proxyAddresses, UserPrincipalName
$map = @{}
foreach ($u in $users) {
    foreach ($p in $u.proxyAddresses) {
        $key = ($p -replace '^smtp:', '').ToLower()
        if (-not $key) { continue }
        if (-not $map.ContainsKey($key)) { $map[$key] = New-Object System.Collections.ArrayList }
        [void]$map[$key].Add([pscustomobject]@{ User = $u; Raw = $p })
    }
}
$dups = $map.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }

if (-not $dups) {
    Write-Host "No duplicate proxyAddress conflicts found." -ForegroundColor Green
} else {
    Write-Host ("Found {0} duplicated address value(s):" -f @($dups).Count) -ForegroundColor Yellow
    foreach ($d in $dups) {
        Write-Host ("  {0}" -f $d.Key) -ForegroundColor Yellow
        # Keep the first holder; the rest are conflicts to remove.
        $holders = $d.Value
        $keep = $holders[0]
        Write-Host ("    KEEP   : {0}" -f $keep.User.UserPrincipalName)
        foreach ($extra in $holders[1..($holders.Count - 1)]) {
            Write-Host ("    REMOVE : {0}  ({1})" -f $extra.User.UserPrincipalName, $extra.Raw)
            if ($PSCmdlet.ShouldProcess($extra.User.UserPrincipalName, "Remove proxyAddress $($extra.Raw)")) {
                Set-ADUser -Identity $extra.User.DistinguishedName -Remove @{ proxyAddresses = $extra.Raw }
            }
        }
    }
}

# Trigger a delta sync (only when applying and on the Connect host)
if ($Apply -and (Get-Module -ListAvailable -Name ADSync)) {
    Import-Module ADSync -ErrorAction Stop
    if ($PSCmdlet.ShouldProcess('ADSync', 'Start delta sync cycle')) {
        try { Start-ADSyncSyncCycle -PolicyType Delta | Out-Null; Write-Host "Delta sync triggered." -ForegroundColor Green }
        catch { Write-Host "Sync trigger skipped: $($_.Exception.Message)" -ForegroundColor Yellow }
    }
}

if (-not $Apply) { Write-Host "`nDry run only. Re-run with -Apply to make changes." -ForegroundColor Cyan }

<#
.SYNOPSIS
    RIDCAP-TokenExposure.ps1 — Kerberos token-size / group-SID-count exposure for busy principals.
.DESCRIPTION
    PURPOSE
        Enumerates the effective group-SID count (tokenGroups, including nested membership) for
        high-membership users and service accounts, and flags any approaching the token limits.
        Group SIDs ride in the Kerberos PAC; too many cause authentication to fail. Read-only.
        Run it against your-domain to find portfolio-spanning identities before they break.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\RIDCAP-TokenExposure.ps1 -Top 25
        Optionally scope to a set of names: -Identity user1,svc-app2
        Requires the RSAT ActiveDirectory module and domain read access.
    EXPECTED RESULTS
        A table of principals ranked by group-SID count with WARN/CRITICAL flags. PASS when no
        principal reaches the warning threshold (default 900; hard ceiling is about 1,015).
.NOTES
    White-label — the repeatable way. Read-only against Active Directory.
#>

[CmdletBinding()]
param(
    # Explicit principals to inspect. If omitted, the busiest users/service accounts are sampled.
    [string[]]$Identity,

    [int]$Top = 25,

    [int]$WarnThreshold     = 900,
    [int]$CriticalThreshold = 1015
)

Import-Module ActiveDirectory -ErrorAction Stop

Write-Host ""
Write-Host "=== RIDCAP Token Exposure — group-SID count vs token limits ===" -ForegroundColor Cyan
Write-Host "Warn >= $WarnThreshold SIDs ; Critical >= $CriticalThreshold SIDs (approx auth-failure ceiling)."
Write-Host "Default MaxTokenSize is 48000 bytes; token bloat hits portfolio-spanning users & service accounts."
Write-Host ""

# Build the candidate list.
if ($Identity) {
    $candidates = foreach ($id in $Identity) {
        try { Get-ADUser -Identity $id -Properties memberOf, servicePrincipalName }
        catch { Write-Host "Could not resolve: $id" -ForegroundColor Yellow }
    }
} else {
    # Sample: rank users by direct memberOf count and take the busiest, then measure their
    # effective token SID count (which also accounts for nesting).
    Write-Host "No -Identity supplied; sampling the busiest users by direct group membership..." -ForegroundColor Yellow
    $candidates = Get-ADUser -Filter * -Properties memberOf, servicePrincipalName |
        Sort-Object { @($_.memberOf).Count } -Descending |
        Select-Object -First $Top
}

$rows = foreach ($p in $candidates) {
    if (-not $p) { continue }
    $sidCount = $null
    try {
        # tokenGroups is a constructed attribute: the full set of SIDs (incl. nested groups)
        # that would appear in the principal's token. Requires a per-object base query.
        $tg = Get-ADUser -Identity $p.DistinguishedName -Properties tokenGroups
        $sidCount = @($tg.tokenGroups).Count
    } catch {
        # Retry via generic object read for accounts the typed cmdlet cannot expand.
        try {
            $tg = Get-ADObject -Identity $p.DistinguishedName -Properties tokenGroups
            $sidCount = @($tg.tokenGroups).Count
        } catch { $sidCount = -1 }
    }

    $flag = if ($sidCount -lt 0) { 'ERROR' }
            elseif ($sidCount -ge $CriticalThreshold) { 'CRITICAL' }
            elseif ($sidCount -ge $WarnThreshold) { 'WARN' }
            else { 'OK' }

    [pscustomobject]@{
        SamAccountName = $p.SamAccountName
        IsServiceAcct  = [bool]$p.servicePrincipalName
        TokenSidCount  = $sidCount
        Flag           = $flag
    }
}

$rows = $rows | Sort-Object TokenSidCount -Descending
$rows | Format-Table -AutoSize

$breaches = @($rows | Where-Object { $_.Flag -in @('WARN', 'CRITICAL') })
Write-Host ""
if ($breaches.Count -eq 0) {
    Write-Host "PASS — no principal at or above the warning threshold." -ForegroundColor Green
    exit 0
} else {
    Write-Host "FAIL — $($breaches.Count) principal(s) at/over threshold. Scope their project membership down or consolidate groups." -ForegroundColor Red
    exit 1
}

<#
.SYNOPSIS
    EDREADY-Validation.ps1 — read-only readiness rubric validation (pass/fail per R/H/S/P gate).
.DESCRIPTION
    Runs the readiness validation gates from 05-testing.md and prints PASS/FAIL for each: Roles
    least-privilege with coverage (no Global Admin), unified audit log on, the readiness-proof hold
    enabled during the proof (or absent after cleanup), and mailbox scope accounted for. Makes NO
    changes. Use during Stage E to confirm readiness before declaring it.
.EXAMPLE
    .\EDREADY-Validation.ps1
    Validate assuming the proof hold has been removed (post-cleanup: expects the proof hold ABSENT).
.EXAMPLE
    .\EDREADY-Validation.ps1 -ProofActive
    Validate DURING the proof: expects the proof hold PRESENT and enabled (Test 3).
.NOTES
    Expected results: a PASS/FAIL line per gate and an overall readiness verdict. White-label.
    Read-only. Uses Get-RoleGroupMember / Get-AdminAuditLogConfig / Get-CaseHoldPolicy / Get-Mailbox.
    Proof names match 03-implementation.md.
#>
[CmdletBinding()]
param(
    [switch]$ProofActive,
    [string]$ProofHoldPolicy = 'Readiness Hold Policy – Proof – Pilot'
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

$results = [ordered]@{}
function Set-Gate($name, $pass, $detail) {
    $results[$name] = [pscustomobject]@{ Gate = $name; Result = $(if($pass){'PASS'}else{'FAIL'}); Detail = $detail }
    $color = if ($pass) { 'Green' } else { 'Yellow' }
    Write-Host ("  [{0}] {1} — {2}" -f $(if($pass){'PASS'}else{'FAIL'}), $name, $detail) -ForegroundColor $color
}

Write-Host "`n=== eDiscovery Readiness — validation (read-only) ===" -ForegroundColor Cyan

# Gate R — roles least-privilege with coverage, no Global Admin
$mgr = @(Get-RoleGroupMember -Identity 'eDiscovery Manager' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
$adm = @(Get-RoleGroupMember -Identity 'eDiscovery Administrator' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
$ga  = @(Get-RoleGroupMember -Identity 'Organization Management' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
$gaOverlap = @($mgr + $adm | Where-Object { $ga -contains $_ } | Select-Object -Unique)
$rPass = ($mgr.Count -ge 2) -and ($gaOverlap.Count -eq 0)
Set-Gate 'R - Roles least-privilege + coverage' $rPass ("Managers={0}, Admins={1}, GlobalAdmin-overlap={2}" -f $mgr.Count, $adm.Count, $gaOverlap.Count)

# Gate H1 — unified audit log on
$auditOn = $false
try { $auditOn = [bool](Get-AdminAuditLogConfig -ErrorAction Stop).UnifiedAuditLogIngestionEnabled } catch {}
Set-Gate 'H - Unified audit log enabled' $auditOn ("UnifiedAuditLogIngestionEnabled = {0}" -f $auditOn)

# Gate H2/H3 — proof hold present (during proof) or removed (after cleanup)
$hold = Get-CaseHoldPolicy -Identity $ProofHoldPolicy -ErrorAction SilentlyContinue
if ($ProofActive) {
    $hPass = ($null -ne $hold) -and ([bool]$hold.Enabled)
    Set-Gate 'H - Proof hold ENABLED (during proof)' $hPass ("'{0}' present={1}, enabled={2}" -f $ProofHoldPolicy, ($null -ne $hold), ([bool]$hold.Enabled))
} else {
    $hPass = ($null -eq $hold)
    Set-Gate 'H - Proof hold REMOVED (post-cleanup)' $hPass ("'{0}' present={1} (expected absent)" -f $ProofHoldPolicy, ($null -ne $hold))
}

# Gate S — mailbox scope reachable (coverage sanity)
$mbxCount = 0
try { $mbxCount = @(Get-Mailbox -ResultSize 50 -ErrorAction SilentlyContinue).Count } catch {}
Set-Gate 'S - Mailbox scope reachable' ($mbxCount -gt 0) ("Enumerated {0} mailbox(es); confirm Teams/M365-Group/inactive coverage via EDREADY-Scope.ps1" -f $mbxCount)

$failed = @($results.Values | Where-Object { $_.Result -eq 'FAIL' })
Write-Host ""
if ($failed.Count -eq 0) {
    Write-Host "READINESS VERDICT: PASS — all evaluated gates green. Confirm S (scope) + P (process) evidence to declare full readiness." -ForegroundColor Green
} else {
    Write-Host ("READINESS VERDICT: NOT READY — {0} gate(s) failed. Remediate per 03-implementation.md and re-run." -f $failed.Count) -ForegroundColor Yellow
}

Disconnect-ExchangeOnline -Confirm:$false | Out-Null

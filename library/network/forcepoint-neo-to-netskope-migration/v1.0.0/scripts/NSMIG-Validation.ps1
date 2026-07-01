<#
.SYNOPSIS
    NSMIG-Validation.ps1 — confirm coexistence/cutover state on this device (read-only).
.DESCRIPTION
    PURPOSE
        Verifies the migration state of a device: which agents are present (Forcepoint Neo, Netskope)
        and whether the device is safely in one of the expected stages — passive coexistence
        (Forcepoint present and running, Netskope present but not enforcing) or cut over (Netskope
        present and running, Forcepoint removed/stopped). Flags the dangerous dual-enforcement state.
        Steering ownership confirmation in the consoles is deferred to Netskope/Forcepoint docs; this
        checks locally observable agent/service state.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\NSMIG-Validation.ps1
    EXPECTED RESULTS
        A stage verdict — "PASSIVE COEXISTENCE", "CUT OVER TO NETSKOPE", or a warning
        ("DUAL ENFORCEMENT RISK" / "UNPROTECTED"). Read-only; exit 0 on a clean stage, 1 otherwise.
.NOTES
    Network Solutions. Read-only. Netskope/Forcepoint console steering specifics deferred to vendor docs.
#>
[CmdletBinding()] param()
Write-Host "=== NSMIG Validation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan

$fpSvc = Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'Forcepoint' -or $_.Name -match 'Forcepoint' }
$nsSvc = Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'Netskope' -or $_.Name -match 'stagent|Netskope' }
$fpRunning = [bool]($fpSvc | Where-Object { $_.Status -eq 'Running' })
$nsRunning = [bool]($nsSvc | Where-Object { $_.Status -eq 'Running' })
$fpPresent = [bool]$fpSvc
$nsPresent = [bool]$nsSvc

Write-Host ("Forcepoint Neo : present={0}  running={1}" -f $fpPresent, $fpRunning)
Write-Host ("Netskope client: present={0}  running={1}" -f $nsPresent, $nsRunning)

$exit = 1
if ($fpRunning -and $nsRunning) {
    Write-Host "`nResult: DUAL ENFORCEMENT RISK — both agents running. Set Netskope passive or stop Forcepoint steering." -ForegroundColor Red
}
elseif ($fpRunning -and $nsPresent -and -not $nsRunning) {
    Write-Host "`nResult: PASSIVE COEXISTENCE — Forcepoint steering, Netskope present but not enforcing." -ForegroundColor Green; $exit = 0
}
elseif ($nsRunning -and -not $fpPresent) {
    Write-Host "`nResult: CUT OVER TO NETSKOPE — Netskope sole agent, Forcepoint removed." -ForegroundColor Green; $exit = 0
}
elseif ($nsRunning -and $fpPresent -and -not $fpRunning) {
    Write-Host "`nResult: CUT OVER (legacy not yet removed) — Netskope enforcing, Forcepoint stopped. Remove the legacy agent after parity passes (NSMIG-Remediation.ps1)." -ForegroundColor Yellow; $exit = 0
}
elseif (-not $fpRunning -and -not $nsRunning) {
    Write-Host "`nResult: UNPROTECTED — no web-filtering agent is enforcing. Investigate before leaving the device in this state." -ForegroundColor Red
}
else {
    Write-Host "`nResult: UNDETERMINED — review agent state above." -ForegroundColor Yellow
}
exit $exit

<#
.SYNOPSIS
    GWCHAT-Validation.ps1 — confirm per-team migration and coexistence readiness before a cutover.
.DESCRIPTION
    PURPOSE
        Validates that a migration wave is ready to cut over from Teams to Chat and Meet: the wave's
        users (from a members CSV) exist in the Microsoft Teams / Microsoft 365 source, are licensed,
        and the wave's channel-to-space mapping, meeting-coexistence, and adoption signals are asserted.
        This is the readiness gate for the per-wave cutover runbook. Read-only against Microsoft Graph —
        it changes nothing on either platform.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWCHAT-Validation.ps1 -Wave "Wave 1" `
            -MembersCsv .\wave1-users.csv -MappingReady -InteropLive -AdoptionReady
        -MembersCsv is a CSV with a 'Upn' column listing the wave's users. -MappingReady asserts the
        channel->space mapping is frozen for the wave; -InteropLive asserts Meet<->Teams / calendar-sync
        interop is live; -AdoptionReady asserts comms/training are delivered. Requires the Microsoft
        Graph PowerShell SDK and User.Read.All.
    EXPECTED RESULTS
        "WAVE READY" when every listed user resolves and is licensed and the mapping, interop, and
        adoption signals are asserted; otherwise a per-signal GAP list and a non-zero exit code.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$Wave = 'Wave 0',
    [Parameter(Mandatory)][string]$MembersCsv,
    [switch]$MappingReady,
    [switch]$InteropLive,
    [switch]$AdoptionReady
)

Write-Host "=== Teams -> Chat/Meet migration — wave readiness validation ($Wave) ===" -ForegroundColor Cyan
$gaps = @()

if (-not (Test-Path $MembersCsv)) { throw "Members CSV not found: $MembersCsv" }
$members = @(Import-Csv -Path $MembersCsv | Where-Object { $_.Upn })
Write-Host ("Wave members listed    : {0}" -f $members.Count)
if ($members.Count -eq 0) { $gaps += "members CSV empty or missing a 'Upn' column" }

# Resolve each member and check licensing against the source tenant.
$resolved = 0
$licensed = 0
if ($members.Count -gt 0) {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'User.Read.All' -NoWelcome
    foreach ($m in $members) {
        try {
            $u = Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/users/{0}?`$select=id,assignedLicenses" -f $m.Upn)
            if ($u) {
                $resolved++
                if (@($u.assignedLicenses).Count -gt 0) { $licensed++ }
            }
        } catch {
            Write-Host ("  unresolved: {0}" -f $m.Upn) -ForegroundColor Yellow
        }
    }
    Disconnect-MgGraph | Out-Null
}
$resolveOk = ($members.Count -gt 0 -and $resolved -eq $members.Count)
$licenseOk = ($members.Count -gt 0 -and $licensed -eq $members.Count)
Write-Host ("Users resolved         : {0} of {1}" -f $resolved, $members.Count) -ForegroundColor ($(if($resolveOk){'Green'}else{'Yellow'}))
Write-Host ("Users licensed         : {0} of {1}" -f $licensed, $members.Count) -ForegroundColor ($(if($licenseOk){'Green'}else{'Yellow'}))
if (-not $resolveOk) { $gaps += "not all wave members resolve in the source tenant" }
if (-not $licenseOk) { $gaps += "not all wave members are licensed (confirm Chat/Meet enabled in Google Admin)" }

# Mapping, interop, and adoption readiness signals (asserted by the operator per the runbook).
Write-Host ("Channel->space mapping : {0}" -f ($(if($MappingReady){'asserted frozen'}else{'not asserted'}))) -ForegroundColor ($(if($MappingReady){'Green'}else{'Yellow'}))
if (-not $MappingReady) { $gaps += "channel->space mapping not asserted frozen (GWCHAT Mapping - Channels to Spaces - Program)" }
Write-Host ("Meeting interop        : {0}" -f ($(if($InteropLive){'asserted live'}else{'not asserted'}))) -ForegroundColor ($(if($InteropLive){'Green'}else{'Yellow'}))
if (-not $InteropLive) { $gaps += "Meet<->Teams / calendar-sync interop not asserted live (GWCHAT Meetings - Teams to Meet - Transition)" }
Write-Host ("Adoption / comms       : {0}" -f ($(if($AdoptionReady){'asserted delivered'}else{'not asserted'}))) -ForegroundColor ($(if($AdoptionReady){'Green'}else{'Yellow'}))
if (-not $AdoptionReady) { $gaps += "adoption comms/training not asserted delivered (GWCHAT Adoption - Change & Comms - Program)" }

if ($gaps.Count -eq 0) {
    Write-Host "`nResult: WAVE READY" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nResult: WAVE NOT READY" -ForegroundColor Yellow
    $gaps | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    exit 1
}

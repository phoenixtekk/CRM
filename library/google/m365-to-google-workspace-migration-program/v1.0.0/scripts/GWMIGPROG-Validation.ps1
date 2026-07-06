<#
.SYNOPSIS
    GWMIGPROG-Validation.ps1 — confirm per-wave readiness before a migration cutover.
.DESCRIPTION
    PURPOSE
        Validates that a migration wave is ready to cut over: the wave's users (from a members CSV)
        exist in the Microsoft 365 / Entra source, are licensed, and the wave's target-group and
        coexistence signals are asserted. This is the readiness gate for the per-wave cutover runbook.
        Read-only against Microsoft Graph — it changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWMIGPROG-Validation.ps1 -Wave "Wave 1" `
            -MembersCsv .\wave1-users.csv -CoexistenceLive -TargetGroupReady
        -MembersCsv is a CSV with a 'Upn' column listing the wave's users. -CoexistenceLive asserts
        mail routing/calendar interop is live; -TargetGroupReady asserts the wave's Google target
        group is provisioned. Requires the Microsoft Graph PowerShell SDK and User.Read.All.
    EXPECTED RESULTS
        "WAVE READY" when every listed user resolves and is licensed and both coexistence and
        target-group signals are asserted; otherwise a per-signal GAP list and a non-zero exit code.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$Wave = 'Wave 0',
    [Parameter(Mandatory)][string]$MembersCsv,
    [switch]$CoexistenceLive,
    [switch]$TargetGroupReady
)

Write-Host "=== Migration program — wave readiness validation ($Wave) ===" -ForegroundColor Cyan
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
if (-not $licenseOk) { $gaps += "not all wave members are licensed" }

# Coexistence and target-group readiness signals (asserted by the operator per the runbook).
Write-Host ("Coexistence routing    : {0}" -f ($(if($CoexistenceLive){'asserted live'}else{'not asserted'}))) -ForegroundColor ($(if($CoexistenceLive){'Green'}else{'Yellow'}))
if (-not $CoexistenceLive) { $gaps += "coexistence not asserted live (GWMIGPROG Coexistence - Mail & Calendar - Transition)" }
Write-Host ("Target group ready     : {0}" -f ($(if($TargetGroupReady){'asserted ready'}else{'not asserted'}))) -ForegroundColor ($(if($TargetGroupReady){'Green'}else{'Yellow'}))
if (-not $TargetGroupReady) { $gaps += "Google target group not asserted ready (GWMIGPROG-Set-ScopeTargeting.ps1)" }

if ($gaps.Count -eq 0) {
    Write-Host "`nResult: WAVE READY" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nResult: WAVE NOT READY" -ForegroundColor Yellow
    $gaps | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    exit 1
}

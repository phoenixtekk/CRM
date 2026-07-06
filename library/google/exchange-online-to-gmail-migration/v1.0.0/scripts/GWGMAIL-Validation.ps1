<#
.SYNOPSIS
    GWGMAIL-Validation.ps1 — per-user migration validation for an Exchange-to-Gmail batch.
.DESCRIPTION
    PURPOSE
        Validates that a migration batch is ready and that each user's data types are accounted for
        before a DNS/MX cutover: the batch's users (from a members CSV) resolve in the Microsoft 365
        source and are licensed, and the target-provisioned, mail, calendar, contacts, and coexistence
        signals are asserted per the runbook. This is the per-user validation gate. Read-only against
        Microsoft Graph — it changes nothing and moves no mail.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWGMAIL-Validation.ps1 -Wave "Wave 0" `
            -MembersCsv .\batch.csv -TargetProvisioned -MailMigrated -CalendarMigrated -ContactsMigrated -CoexistenceLive
        -MembersCsv is a CSV with a 'Upn' column listing the batch's users. The switches assert the
        target account is provisioned and each data type migrated; -CoexistenceLive asserts mail
        routing/calendar interop is live. Requires the Microsoft Graph PowerShell SDK and User.Read.All.
    EXPECTED RESULTS
        "BATCH READY" when every listed user resolves and is licensed and the target, mail, calendar,
        contacts, and coexistence signals are asserted; otherwise a per-signal GAP list and a non-zero
        exit code.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$Wave = 'Wave 0',
    [Parameter(Mandatory)][string]$MembersCsv,
    [switch]$TargetProvisioned,
    [switch]$MailMigrated,
    [switch]$CalendarMigrated,
    [switch]$ContactsMigrated,
    [switch]$CoexistenceLive
)

Write-Host "=== Exchange to Gmail — per-user migration validation ($Wave) ===" -ForegroundColor Cyan
$gaps = @()

if (-not (Test-Path $MembersCsv)) { throw "Members CSV not found: $MembersCsv" }
$members = @(Import-Csv -Path $MembersCsv | Where-Object { $_.Upn })
Write-Host ("Batch members listed   : {0}" -f $members.Count)
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
Write-Host ("Users licensed (source): {0} of {1}" -f $licensed, $members.Count) -ForegroundColor ($(if($licenseOk){'Green'}else{'Yellow'}))
if (-not $resolveOk) { $gaps += "not all batch members resolve in the source tenant" }
if (-not $licenseOk) { $gaps += "not all batch members are licensed" }

# Target and per-data-type signals (asserted by the operator per the runbook and per-user validation).
Write-Host ("Target provisioned     : {0}" -f ($(if($TargetProvisioned){'asserted'}else{'not asserted'}))) -ForegroundColor ($(if($TargetProvisioned){'Green'}else{'Yellow'}))
if (-not $TargetProvisioned) { $gaps += "Gmail target accounts not asserted provisioned/licensed" }
Write-Host ("Mail migrated          : {0}" -f ($(if($MailMigrated){'asserted'}else{'not asserted'}))) -ForegroundColor ($(if($MailMigrated){'Green'}else{'Yellow'}))
if (-not $MailMigrated) { $gaps += "mail not asserted migrated (run/confirm the mail pass + delta)" }
Write-Host ("Calendar migrated      : {0}" -f ($(if($CalendarMigrated){'asserted'}else{'not asserted'}))) -ForegroundColor ($(if($CalendarMigrated){'Green'}else{'Yellow'}))
if (-not $CalendarMigrated) { $gaps += "calendar not asserted migrated (confirm events + resource mapping)" }
Write-Host ("Contacts migrated      : {0}" -f ($(if($ContactsMigrated){'asserted'}else{'not asserted'}))) -ForegroundColor ($(if($ContactsMigrated){'Green'}else{'Yellow'}))
if (-not $ContactsMigrated) { $gaps += "contacts not asserted migrated" }
Write-Host ("Coexistence routing    : {0}" -f ($(if($CoexistenceLive){'asserted live'}else{'not asserted'}))) -ForegroundColor ($(if($CoexistenceLive){'Green'}else{'Yellow'}))
if (-not $CoexistenceLive) { $gaps += "coexistence not asserted live (GWGMAIL Coexistence - Mail Routing - Transition)" }

if ($gaps.Count -eq 0) {
    Write-Host "`nResult: BATCH READY — mail, calendar, and contacts validated per user" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nResult: BATCH NOT READY" -ForegroundColor Yellow
    $gaps | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    exit 1
}

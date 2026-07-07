<#
.SYNOPSIS
    MSEDISC-Discovery.ps1 — read-only eDiscovery posture, readiness, and role check.
.DESCRIPTION
    Connects to Security & Compliance PowerShell and reports whether the tenant/operator is ready to
    run eDiscovery: eDiscovery role-group membership (eDiscovery Manager / eDiscovery Administrator),
    existing compliance cases, Content Searches, and case-hold policies, and whether the unified
    audit log is enabled. Makes NO changes — this is the "what exists / am I ready" assessment used
    before running a matter.
.EXAMPLE
    .\MSEDISC-Discovery.ps1
    (PowerShell 5.1+/7+, ExchangeOnlineManagement; connect with Connect-IPPSSession)
.NOTES
    Expected results: role-group membership, counts of cases/searches/holds, and audit status.
    White-label — Security Solutions. Read-only. Uses Get-RoleGroupMember / Get-ComplianceCase /
    Get-ComplianceSearch / Get-CaseHoldPolicy / Get-AdminAuditLogConfig.
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host "`n=== Microsoft Purview eDiscovery — readiness discovery ===" -ForegroundColor Cyan

Write-Host "`n--- eDiscovery role groups (least privilege) ---" -ForegroundColor Cyan
foreach ($rg in 'eDiscovery Manager','eDiscovery Administrator') {
    $members = Get-RoleGroupMember -Identity $rg -ErrorAction SilentlyContinue
    if ($members) {
        Write-Host ("  {0}:" -f $rg) -ForegroundColor Green
        $members | Select-Object -ExpandProperty Name | ForEach-Object { Write-Host "     $_" }
    } else {
        Write-Host ("  {0}: (no members or not visible)" -f $rg) -ForegroundColor Yellow
    }
}

Write-Host "`n--- Compliance / eDiscovery cases ---" -ForegroundColor Cyan
$cases = Get-ComplianceCase -ErrorAction SilentlyContinue
if ($cases) { $cases | Select-Object Name, CaseType, Status | Format-Table -AutoSize }
else { Write-Host "  No compliance cases found." -ForegroundColor Yellow }

Write-Host "`n--- Content Searches ---" -ForegroundColor Cyan
$searches = Get-ComplianceSearch -ErrorAction SilentlyContinue
if ($searches) {
    $searches | Select-Object Name, Status,
        @{n='Items';e={$_.Items}}, @{n='Size';e={$_.Size}} | Format-Table -AutoSize
    Write-Host ("  Total searches: {0}" -f @($searches).Count)
} else { Write-Host "  No Content Searches found." -ForegroundColor Yellow }

Write-Host "`n--- Case-hold policies ---" -ForegroundColor Cyan
$holds = Get-CaseHoldPolicy -ErrorAction SilentlyContinue
if ($holds) { $holds | Select-Object Name, Enabled, Mode | Format-Table -AutoSize }
else { Write-Host "  No case-hold policies found." -ForegroundColor Yellow }

Write-Host "`n--- Unified audit log status ---" -ForegroundColor Cyan
try {
    $audit = Get-AdminAuditLogConfig -ErrorAction Stop
    $on = [bool]$audit.UnifiedAuditLogIngestionEnabled
    Write-Host ("  UnifiedAuditLogIngestionEnabled = {0}" -f $on) -ForegroundColor ($(if($on){'Green'}else{'Yellow'}))
    if (-not $on) { Write-Host "  NOTE: enable auditing (Requirement 2.3) — the audit trail is your defensibility evidence." -ForegroundColor Yellow }
} catch { Write-Host "  Could not read audit config (insufficient role?)." -ForegroundColor Yellow }

Write-Host "`nDiscovery complete. Premium (custodians/review sets/analytics/export) is gated by E5 — verify in your tenant." -ForegroundColor Green
Disconnect-ExchangeOnline -Confirm:$false | Out-Null

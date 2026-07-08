<#
.SYNOPSIS
    EDREADY-Discovery.ps1 — read-only eDiscovery current-state inventory (Roles + Holds evidence).
.DESCRIPTION
    Connects to Security & Compliance PowerShell and inventories the current eDiscovery posture:
    eDiscovery role-group membership (eDiscovery Manager / eDiscovery Administrator, and whether a
    Global Administrator appears), existing compliance cases, Content Searches, and case-hold
    policies, plus unified-audit-log status. Makes NO changes — this is the current-state evidence
    for the Roles (R) and Holds (H) domains of the readiness scorecard.
.EXAMPLE
    .\EDREADY-Discovery.ps1
    (PowerShell 5.1+/7+, ExchangeOnlineManagement; connect with Connect-IPPSSession)
.NOTES
    Expected results: role-group membership + Global-Admin flag, counts of cases/searches/holds, and
    audit status. White-label. Read-only. Uses Get-RoleGroupMember / Get-ComplianceCase /
    Get-ComplianceSearch / Get-CaseHoldPolicy / Get-AdminAuditLogConfig. Premium tier is E5-gated —
    verify in your tenant.
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host "`n=== eDiscovery Readiness — current-state discovery (read-only) ===" -ForegroundColor Cyan

# --- Roles (R): role-group membership + Global Admin detection ---
$globalAdmins = @()
try {
    $globalAdmins = (Get-RoleGroupMember -Identity 'Organization Management' -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty Name)
} catch { }

Write-Host "`n--- eDiscovery role groups (least privilege) ---" -ForegroundColor Cyan
foreach ($rg in 'eDiscovery Manager','eDiscovery Administrator') {
    $members = @(Get-RoleGroupMember -Identity $rg -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
    if ($members.Count -gt 0) {
        Write-Host ("  {0} ({1} member(s)):" -f $rg, $members.Count) -ForegroundColor Green
        $members | ForEach-Object { Write-Host "     $_" }
        $overlap = $members | Where-Object { $globalAdmins -contains $_ }
        if ($overlap) {
            Write-Host ("     WARNING: also a Global Admin -> {0}  (over-privileged; grant via role group only)" -f ($overlap -join ', ')) -ForegroundColor Yellow
        }
    } else {
        Write-Host ("  {0}: (no members or not visible) — READINESS GAP (R)" -f $rg) -ForegroundColor Yellow
    }
}
$mgrCount = @(Get-RoleGroupMember -Identity 'eDiscovery Manager' -ErrorAction SilentlyContinue).Count
if ($mgrCount -lt 2) {
    Write-Host ("  COVERAGE GAP (R): only {0} eDiscovery Manager member — no single-point-of-failure requires >= 2." -f $mgrCount) -ForegroundColor Yellow
}

# --- Holds (H): unified audit log ---
Write-Host "`n--- Unified audit log status (defensibility evidence) ---" -ForegroundColor Cyan
try {
    $audit = Get-AdminAuditLogConfig -ErrorAction Stop
    $on = [bool]$audit.UnifiedAuditLogIngestionEnabled
    Write-Host ("  UnifiedAuditLogIngestionEnabled = {0}" -f $on) -ForegroundColor ($(if($on){'Green'}else{'Yellow'}))
    if (-not $on) { Write-Host "  HIGH-SEVERITY GAP (H): auditing OFF — enable via EDREADY-Remediation.ps1 -Commit (Requirement 2.3)." -ForegroundColor Yellow }
} catch { Write-Host "  Could not read audit config (insufficient role?)." -ForegroundColor Yellow }

# --- Existing cases / searches / holds (tier signals) ---
Write-Host "`n--- Compliance / eDiscovery cases ---" -ForegroundColor Cyan
$cases = @(Get-ComplianceCase -ErrorAction SilentlyContinue)
if ($cases.Count -gt 0) { $cases | Select-Object Name, CaseType, Status | Format-Table -AutoSize }
else { Write-Host "  No compliance cases found." -ForegroundColor Yellow }

Write-Host "`n--- Content Searches ---" -ForegroundColor Cyan
$searches = @(Get-ComplianceSearch -ErrorAction SilentlyContinue)
if ($searches.Count -gt 0) {
    $searches | Select-Object Name, Status, @{n='Items';e={$_.Items}}, @{n='Size';e={$_.Size}} | Format-Table -AutoSize
    Write-Host ("  Total searches: {0}" -f $searches.Count)
} else { Write-Host "  No Content Searches found." -ForegroundColor Yellow }

Write-Host "`n--- Case-hold policies ---" -ForegroundColor Cyan
$holds = @(Get-CaseHoldPolicy -ErrorAction SilentlyContinue)
if ($holds.Count -gt 0) { $holds | Select-Object Name, Enabled, Mode | Format-Table -AutoSize }
else { Write-Host "  No case-hold policies found." -ForegroundColor Yellow }

Write-Host "`nDiscovery complete. Premium (custodians/review sets/analytics/export) is gated by E5 — verify your licensing/tenant." -ForegroundColor Green
Write-Host "Next: EDREADY-Scope.ps1 (S evidence), then score R/H/S/P and run EDREADY-Reporting.ps1." -ForegroundColor Green
Disconnect-ExchangeOnline -Confirm:$false | Out-Null

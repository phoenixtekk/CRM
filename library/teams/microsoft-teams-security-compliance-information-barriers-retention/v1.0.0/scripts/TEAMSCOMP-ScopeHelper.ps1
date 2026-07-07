<#
.SYNOPSIS
  Scope / health helper (read-only): previews IB segment scope and checks IB prerequisites before application.
.DESCRIPTION
  Verifies who a barrier will actually apply to and whether the IB prerequisites are met — so scope is
  confirmed before the tenant-wide application run. For each sample user it reports
  Get-InformationBarrierRecipientStatus (the segment(s) and policy that resolve), and it checks the IB
  prerequisites: no conflicting Exchange address book policies, and a reminder to confirm scoped
  directory search in the Teams admin center. Read-only — changes nothing.
.EXAMPLE
  .\TEAMSCOMP-ScopeHelper.ps1 -SampleUsers "groupa-user@contoso.com","groupb-user@contoso.com"
  # read-only; prints each user's resolved IB segment/policy + prerequisite checks
  (PowerShell 5.1+/7+, ExchangeOnlineManagement [+ optional ExchangeOnline for ABP check]; connect via Connect-IPPSSession)
.NOTES
  Expected results: per-user recipient status (segment + policy, or "no segment"), an ABP-conflict
  check, and a scoped-directory-search reminder. Use before Start-InformationBarrierPoliciesApplication.
  White-label. Read-only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$SampleUsers
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false -ErrorAction Stop

Write-Host "`n=== IB scope / health helper (read-only) ===" -ForegroundColor Cyan

# --- Per-user recipient status -------------------------------------------------
Write-Host "`n--- Resolved IB recipient status per sample user ---" -ForegroundColor Cyan
foreach ($u in $SampleUsers) {
    try {
        $st = Get-InformationBarrierRecipientStatus -Identity $u -ErrorAction Stop
        if ($st) {
            Write-Host ("  {0}" -f $u) -ForegroundColor Gray
            $st | Format-List
        } else {
            Write-Host ("  {0} — no recipient status (user may carry NO segment attribute → governed by no barrier)" -f $u) -ForegroundColor Yellow
        }
    } catch {
        Write-Host ("  {0} — could not resolve status ({1})" -f $u, $_.Exception.Message) -ForegroundColor Yellow
    }
}

# --- Prerequisite: no conflicting address book policies ------------------------
Write-Host "`n--- IB prerequisite: conflicting address book policies ---" -ForegroundColor Cyan
try {
    if (Get-Command Get-AddressBookPolicy -ErrorAction SilentlyContinue) {
        $abps = Get-AddressBookPolicy -ErrorAction SilentlyContinue
        if ($abps) {
            Write-Host "  ADDRESS BOOK POLICIES FOUND — IB is incompatible with ABP-based address segregation. Review:" -ForegroundColor Yellow
            $abps | Select-Object Name | Format-Table -AutoSize
        } else { Write-Host "  No address book policies found (OK for IB)." -ForegroundColor Green }
    } else {
        Write-Host "  Get-AddressBookPolicy not available in this session — check via Exchange Online PowerShell (Connect-ExchangeOnline)." -ForegroundColor Gray
    }
} catch {
    Write-Host "  Could not enumerate address book policies — verify manually in Exchange Online." -ForegroundColor Yellow
}

# --- Prerequisite: scoped directory search reminder ---------------------------
Write-Host "`n--- IB prerequisite: scoped directory search ---" -ForegroundColor Cyan
Write-Host "  Confirm scoped directory search is ENABLED in the Teams admin center (Org-wide settings)" -ForegroundColor Gray
Write-Host "  before running Start-InformationBarrierPoliciesApplication. This is tenant-wide." -ForegroundColor Gray

Write-Host "`nScope check complete. If every in-scope user resolves the expected segment and prerequisites pass, proceed to application." -ForegroundColor Green
Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

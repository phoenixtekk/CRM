<#
.SYNOPSIS
    EDREADY-Scope.ps1 — read-only scope/health helper (Scope/coverage evidence).
.DESCRIPTION
    Reports data-source coverage for the readiness Scope (S) domain: mailbox count and per-mailbox
    litigation-hold state, inactive/legacy mailboxes, and existing retention holds, plus a printed
    workload checklist (Exchange incl. Teams chat which lives in mailboxes, SharePoint, OneDrive,
    Teams/M365 Group sites) to confirm nothing is missed. Makes NO changes.
.EXAMPLE
    .\EDREADY-Scope.ps1
    (PowerShell 5.1+/7+, ExchangeOnlineManagement; connect with Connect-ExchangeOnline and Connect-IPPSSession)
.EXAMPLE
    .\EDREADY-Scope.ps1 -Csv .\edready-scope.csv
    Also writes the mailbox coverage table to CSV for the evidence pack.
.NOTES
    Expected results: mailbox/inactive-mailbox coverage, litigation-hold flags, retention holds, and a
    workload checklist. White-label. Read-only. Uses Get-Mailbox / Get-Mailbox -InactiveMailboxOnly /
    Get-RetentionCompliancePolicy. SharePoint/OneDrive/Teams sites are confirmed in the portal — verify
    in your tenant.
#>
[CmdletBinding()]
param(
    [string]$Csv
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop

# Exchange Online for mailbox coverage; S&C for retention holds.
Connect-ExchangeOnline -ShowBanner:$false
Connect-IPPSSession -ShowBanner:$false

Write-Host "`n=== eDiscovery Readiness — scope / coverage (read-only) ===" -ForegroundColor Cyan

# --- Active mailboxes + litigation-hold state ---
Write-Host "`n--- Mailbox coverage & litigation-hold state ---" -ForegroundColor Cyan
$mbx = @(Get-Mailbox -ResultSize Unlimited -ErrorAction SilentlyContinue |
    Select-Object DisplayName, PrimarySmtpAddress,
        @{n='LitigationHold';e={$_.LitigationHoldEnabled}},
        @{n='RecipientType';e={$_.RecipientTypeDetails}})
if ($mbx.Count -gt 0) {
    Write-Host ("  Active mailboxes: {0}" -f $mbx.Count) -ForegroundColor Green
    $onHold = @($mbx | Where-Object { $_.LitigationHold }).Count
    Write-Host ("  With litigation hold enabled: {0}" -f $onHold)
    $mbx | Select-Object -First 25 | Format-Table -AutoSize
    if ($mbx.Count -gt 25) { Write-Host ("  ... ({0} more; use -Csv to export all)" -f ($mbx.Count - 25)) -ForegroundColor DarkGray }
    if ($Csv) { $mbx | Export-Csv -NoTypeInformation -Path $Csv; Write-Host ("  Wrote coverage CSV: {0}" -f $Csv) -ForegroundColor Green }
} else { Write-Host "  No mailboxes returned (insufficient role?)." -ForegroundColor Yellow }

# --- Inactive / legacy mailboxes (classic coverage blind spot) ---
Write-Host "`n--- Inactive / legacy mailboxes (easy-to-miss preservation) ---" -ForegroundColor Cyan
try {
    $inactive = @(Get-Mailbox -InactiveMailboxOnly -ResultSize Unlimited -ErrorAction Stop |
        Select-Object DisplayName, PrimarySmtpAddress, @{n='LitigationHold';e={$_.LitigationHoldEnabled}})
    if ($inactive.Count -gt 0) {
        Write-Host ("  Inactive mailboxes: {0} — confirm each is covered by a hold if in scope (Scope GAP risk)." -f $inactive.Count) -ForegroundColor Yellow
        $inactive | Format-Table -AutoSize
    } else { Write-Host "  No inactive mailboxes found." -ForegroundColor Green }
} catch { Write-Host "  Could not enumerate inactive mailboxes (insufficient role or not available)." -ForegroundColor Yellow }

# --- Existing retention holds (retention-vs-hold interplay) ---
Write-Host "`n--- Retention hold policies (interplay with legal holds) ---" -ForegroundColor Cyan
$ret = @(Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue | Select-Object Name, Enabled, Mode)
if ($ret.Count -gt 0) { $ret | Format-Table -AutoSize }
else { Write-Host "  No retention policies found (or not visible)." -ForegroundColor Yellow }

# --- Workload checklist (confirm in portal) ---
Write-Host "`n--- Workload coverage checklist (confirm each is in the scope note) ---" -ForegroundColor Cyan
@(
    'Exchange Online mailboxes (incl. Teams CHAT — stored in mailboxes)',
    'SharePoint Online sites',
    'OneDrive for Business accounts',
    'Teams / M365 Group team sites and files (SharePoint/OneDrive-backed)',
    'Inactive / legacy mailboxes (above)',
    'Third-party / imported data (if any)',
    'Unindexed / partially-indexed items (handled per matter)'
) | ForEach-Object { Write-Host "   [ ] $_" }

Write-Host "`nScope review complete. SharePoint/OneDrive/Teams sites are confirmed in the Purview portal — verify in your tenant." -ForegroundColor Green
Disconnect-ExchangeOnline -Confirm:$false | Out-Null

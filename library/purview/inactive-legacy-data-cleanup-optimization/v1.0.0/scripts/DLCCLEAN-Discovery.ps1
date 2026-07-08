<#
.SYNOPSIS
    DLCCLEAN-Discovery.ps1 — read-only storage/ROT & stale-data posture: retention, holds, inactive mailboxes, storage signals (safe: read-only).
.DESCRIPTION
    PURPOSE
        Builds the data-lifecycle baseline before any cleanup: every existing RETENTION policy / label / label
        policy and its scope; ALL HOLDS in force (litigation holds, eDiscovery case holds, and retain-action
        retention policies) — the safety inventory that must be respected before any deletion; the INACTIVE
        MAILBOX inventory (Get-Mailbox -InactiveMailboxOnly); and mailbox/site/OneDrive last-activity + storage
        signals from Microsoft Graph usage reports. Read-only — makes NO changes and deletes nothing. Use it to
        see what already exists, what is protected by a hold, and where the ROT is, before you design cleanup.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLCCLEAN-Discovery.ps1 -CsvPath .\DLCCLEAN-Posture.csv
        Requires Security & Compliance PowerShell (Connect-IPPSSession) and Exchange Online (Connect-ExchangeOnline).
        Storage signals additionally require Microsoft Graph (Connect-MgGraph -Scopes 'Reports.Read.All').
.EXAMPLE
    .\DLCCLEAN-Discovery.ps1 -CsvPath .\DLCCLEAN-Posture.csv
    Prints retention policies/labels, the full hold inventory, inactive mailboxes, and storage signals; exports the retention inventory CSV.
.NOTES
    Purview — Inactive & Legacy Data Cleanup. Read-only across S&C PowerShell / Exchange Online / Graph.
    Expected results: a complete hold inventory + sized stale-data candidates. PASS = holds enumerated and ROT identified before any policy is built.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [int]$StaleDays = 365,
    [string]$UserPrincipalName
)

# --- Connect (modern auth / MFA). Reuses existing sessions if present. ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}
if (-not (Get-Command Get-Mailbox -ErrorAction SilentlyContinue)) {
    try {
        if ($UserPrincipalName) { Connect-ExchangeOnline -UserPrincipalName $UserPrincipalName -ShowBanner:$false -ErrorAction Stop }
        else { Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop }
    } catch { Write-Host 'Exchange Online sign-in skipped — inactive-mailbox / litigation-hold sections will degrade gracefully.' -ForegroundColor Yellow }
}
# (Connect-ExchangeOnline is optional; inactive-mailbox / hold sections degrade gracefully if absent.)

Write-Host '=== Data Lifecycle / ROT Posture Assessment (read-only) ===' -ForegroundColor Cyan

# --- 1. Existing retention policies / labels / label policies and their scope ---
Write-Host '--- Retention policies & label policies ---' -ForegroundColor Cyan
$retPolicies = Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue
$rows = foreach ($p in $retPolicies) {
    $locs = @()
    foreach ($loc in 'ExchangeLocation','SharePointLocation','OneDriveLocation','ModernGroupLocation','TeamsChatLocation','TeamsChannelLocation','AdaptiveScopeLocation') {
        $val = $p.$loc
        if ($val -and $val.Count -gt 0) { $locs += ("{0}={1}" -f $loc.Replace('Location',''), ($val -join '|')) }
    }
    [pscustomobject]@{
        Name          = $p.Name
        Type          = if ($p.RetentionRuleTypes) { 'LabelPolicy/Retention' } else { 'Retention' }
        Enabled       = $p.Enabled
        Mode          = $p.Mode
        IsHold        = ($p.RestrictiveRetention -eq $true)   # preservation-lock style
        Scope         = ($locs -join '; ')
    }
}
if ($rows) { $rows | Sort-Object Name | Format-Table -AutoSize } else { Write-Host 'No retention policies found.' -ForegroundColor Yellow }

Write-Host '--- Retention labels (ComplianceTag) ---' -ForegroundColor Cyan
$tags = Get-ComplianceTag -ErrorAction SilentlyContinue
if ($tags) {
    $tags | Select-Object Name,
        @{n='Action';e={$_.RetentionAction}},
        @{n='Days';e={$_.RetentionDuration}},
        @{n='IsRecord';e={$_.IsRecordLabel}},
        @{n='DispositionReview';e={[bool]$_.ReviewerEmail}} | Format-Table -AutoSize
} else { Write-Host 'No retention labels found (or insufficient role).' -ForegroundColor Yellow }

# --- 2. HOLD INVENTORY (the safety gate) ---
Write-Host '--- HOLD INVENTORY (must be respected before any deletion) ---' -ForegroundColor Cyan
$holdCount = 0

# 2a. eDiscovery / In-Place case holds
$caseHolds = @()
if (Get-Command Get-CaseHoldPolicy -ErrorAction SilentlyContinue) {
    $caseHolds = @(Get-CaseHoldPolicy -ErrorAction SilentlyContinue)
    Write-Host ("eDiscovery case holds: {0}" -f $caseHolds.Count) -ForegroundColor $(if($caseHolds.Count){'Yellow'}else{'Green'})
    $caseHolds | Select-Object Name, Enabled | Format-Table -AutoSize
    $holdCount += $caseHolds.Count
}

# 2b. Retain-action retention policies act as holds
$retainHolds = @($retPolicies | Where-Object { $_.RestrictiveRetention -eq $true -or $_.Mode -eq 'Enable' })
Write-Host ("Retain-action retention policies (protect content): {0}" -f $retainHolds.Count)

# 2c. Litigation holds on mailboxes (Exchange Online)
if (Get-Command Get-Mailbox -ErrorAction SilentlyContinue) {
    try {
        $litHold = @(Get-Mailbox -ResultSize Unlimited -Filter 'LitigationHoldEnabled -eq $true' -ErrorAction SilentlyContinue |
                     Select-Object DisplayName, PrimarySmtpAddress, LitigationHoldDuration)
        Write-Host ("Mailboxes on litigation hold: {0}" -f $litHold.Count) -ForegroundColor $(if($litHold.Count){'Yellow'}else{'Green'})
        if ($litHold.Count) { $litHold | Format-Table -AutoSize }
        $holdCount += $litHold.Count
    } catch { Write-Host 'Could not enumerate litigation holds (connect Exchange Online / check role).' -ForegroundColor Yellow }
} else {
    Write-Host 'Exchange Online not connected — litigation-hold enumeration skipped (Connect-ExchangeOnline to include).' -ForegroundColor Yellow
}
Write-Host ("TOTAL discrete holds discovered (excl. retain policies): {0}" -f $holdCount) -ForegroundColor Cyan

# --- 3. Inactive mailboxes (retained after the user was deleted) ---
Write-Host '--- Inactive mailboxes ---' -ForegroundColor Cyan
if (Get-Command Get-Mailbox -ErrorAction SilentlyContinue) {
    try {
        $inactive = @(Get-Mailbox -InactiveMailboxOnly -ResultSize Unlimited -ErrorAction SilentlyContinue |
                      Select-Object DisplayName, PrimarySmtpAddress, WhenSoftDeleted)
        Write-Host ("Inactive mailboxes: {0} (retained by a hold; candidates for records-approved disposition)" -f $inactive.Count)
        if ($inactive.Count) { $inactive | Sort-Object WhenSoftDeleted | Format-Table -AutoSize }
    } catch { Write-Host 'Could not enumerate inactive mailboxes (check role/connection).' -ForegroundColor Yellow }
}

# --- 4. Storage / last-activity signals (Microsoft Graph usage reports) ---
Write-Host '--- Storage / last-activity signals (Graph usage reports) ---' -ForegroundColor Cyan
if (Get-Command Invoke-MgGraphRequest -ErrorAction SilentlyContinue) {
    try {
        # 7-day usage detail; returns CSV. See Report.ps1 for full sized ROT candidate extraction.
        $spo = Invoke-MgGraphRequest -Method GET -OutputType HttpResponseMessage `
                 -Uri "https://graph.microsoft.com/v1.0/reports/getSharePointSiteUsageDetail(period='D7')" -ErrorAction SilentlyContinue
        if ($spo) { Write-Host ("SharePoint site usage report available — use DLCCLEAN-Report.ps1 -StaleDays {0} for the sized candidate list." -f $StaleDays) -ForegroundColor Green }
    } catch { Write-Host 'Graph usage reports not reachable (Connect-MgGraph -Scopes Reports.Read.All).' -ForegroundColor Yellow }
} else {
    Write-Host 'Microsoft Graph not connected — run DLCCLEAN-Report.ps1 with Graph for sized storage/stale-data candidates.' -ForegroundColor Yellow
}

if ($CsvPath -and $rows) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Retention inventory exported to {0}" -f $CsvPath) -ForegroundColor Green
}

Write-Host 'Done. Baseline + hold inventory captured — design labels/scopes (Implementation Phase 1) and size ROT with DLCCLEAN-Report.ps1.' -ForegroundColor Cyan

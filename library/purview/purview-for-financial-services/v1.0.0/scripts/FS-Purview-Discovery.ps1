<#
.SYNOPSIS
    FS-Purview-Discovery.ps1 — inventory FS-relevant Purview config (labels, DLP, retention+lock, comms). Read-only.
.DESCRIPTION
    PURPOSE
        Connects to Security & Compliance PowerShell and reports the tenant's current Microsoft Purview
        posture for a Financial Services program: sensitivity labels and label policies, DLP policies
        (with mode: test/audit vs enforce), retention labels/policies (including Preservation Lock
        state), and communication-compliance supervision policies. This is the "what exists today" read
        used to plan the FS taxonomy, the DLP audit gate, the records schedule, and supervision.
    HOW TO RUN
        Install-Module ExchangeOnlineManagement -Scope CurrentUser
        powershell -ExecutionPolicy Bypass -File .\FS-Purview-Discovery.ps1
        Sign in as a Compliance Administrator (or Information Protection + DLP + Records + Communication
        Compliance roles) when prompted. Features are E5 / E5 Compliance-gated — verify your tenant.
    EXPECTED RESULTS
        Lists of sensitivity labels (name, priority, encryption), label policies, DLP policies (MODE —
        flags any already enforcing), retention labels, retention policies (with LOCKED flag), and
        communication-compliance policies. Absent cmdlets/nodes usually indicate licensing.
.NOTES
    White-label — Purview / Financial Services. Read-only.
    Uses Get-Label / Get-LabelPolicy / Get-DlpCompliancePolicy / Get-ComplianceTag /
    Get-RetentionCompliancePolicy / Get-SupervisoryReviewPolicyV2.
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host "`n=== Microsoft Purview (Financial Services) — configuration discovery ===" -ForegroundColor Cyan

Write-Host "`n--- Sensitivity labels ---" -ForegroundColor Cyan
$labels = Get-Label -ErrorAction SilentlyContinue
if ($labels) {
    $labels | Sort-Object Priority | Select-Object DisplayName, Priority,
        @{n='Encrypted';e={[bool]$_.EncryptionEnabled}}, ContentType | Format-Table -AutoSize
} else { Write-Host "  No sensitivity labels found." -ForegroundColor Yellow }

Write-Host "`n--- Label policies ---" -ForegroundColor Cyan
$labelPols = Get-LabelPolicy -ErrorAction SilentlyContinue
if ($labelPols) { $labelPols | Select-Object Name, Enabled | Format-Table -AutoSize }
else { Write-Host "  No label policies found." -ForegroundColor Yellow }

Write-Host "`n--- DLP policies (mode: test/audit vs enforce) ---" -ForegroundColor Cyan
$dlp = Get-DlpCompliancePolicy -ErrorAction SilentlyContinue
if ($dlp) {
    $dlp | Select-Object Name, Mode, Enabled | Sort-Object Mode | Format-Table -AutoSize
    $enforcing = @($dlp | Where-Object { $_.Mode -match 'Enable' })
    if ($enforcing) { Write-Host ("  NOTE: {0} DLP policy(ies) already enforcing." -f $enforcing.Count) -ForegroundColor Yellow }
} else { Write-Host "  No DLP policies found." -ForegroundColor Yellow }

Write-Host "`n--- Retention labels (regulatory-record capable) ---" -ForegroundColor Cyan
$retLabels = Get-ComplianceTag -ErrorAction SilentlyContinue
if ($retLabels) {
    $retLabels | Select-Object Name, RetentionDuration, RetentionAction,
        @{n='RegulatoryRecord';e={[bool]$_.IsRecordLabel -and $_.ComplianceTagType -eq 'Regulatory'}} | Format-Table -AutoSize
} else { Write-Host "  No retention labels found." -ForegroundColor Yellow }

Write-Host "`n--- Retention policies (Preservation Lock state) ---" -ForegroundColor Cyan
$retPols = Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue
if ($retPols) {
    $retPols | Select-Object Name, Enabled, Mode,
        @{n='Locked (Preservation Lock)';e={[bool]$_.RestrictiveRetention}} | Format-Table -AutoSize
    $locked = @($retPols | Where-Object { $_.RestrictiveRetention })
    if ($locked) { Write-Host ("  NOTE: {0} retention policy(ies) are LOCKED (immutable — no rollback)." -f $locked.Count) -ForegroundColor Yellow }
} else { Write-Host "  No retention policies found." -ForegroundColor Yellow }

Write-Host "`n--- Communication-compliance (supervision) policies ---" -ForegroundColor Cyan
try {
    $srp = Get-SupervisoryReviewPolicyV2 -ErrorAction Stop
    if ($srp) { $srp | Select-Object Name, Enabled | Format-Table -AutoSize }
    else { Write-Host "  No communication-compliance policies found." -ForegroundColor Yellow }
} catch {
    Write-Host ("  Communication-compliance cmdlet unavailable: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "  This is E5/E5-Compliance-gated and role-scoped — verify licensing and Communication Compliance roles." -ForegroundColor Yellow
}

Write-Host "`nDiscovery complete. Use FS-Purview-Validation.ps1 to check the expected named objects." -ForegroundColor Green
Disconnect-ExchangeOnline -Confirm:$false | Out-Null

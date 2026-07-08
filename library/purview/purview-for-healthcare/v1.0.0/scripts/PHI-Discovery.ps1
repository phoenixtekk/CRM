<#
.SYNOPSIS
    PHI-Discovery.ps1 — inventory sensitivity labels, DLP policies, and retention config for a PHI estate (read-only).
.DESCRIPTION
    PURPOSE
        Connects to Security & Compliance PowerShell and reports the tenant's current Microsoft
        Purview information-protection posture relevant to PHI: sensitivity labels and label policies,
        DLP policies (with mode: test/audit vs enforce, and whether the HIPAA/health template is in
        use), and retention labels/policies. This is the "what exists today" read used to plan the
        PHI taxonomy, the DLP audit gate, and the retention schedule.
    HOW TO RUN
        Install-Module ExchangeOnlineManagement -Scope CurrentUser
        powershell -ExecutionPolicy Bypass -File .\PHI-Discovery.ps1
        Sign in as a Compliance Administrator (or Information Protection + DLP roles) when prompted.
.EXAMPLE
    .\PHI-Discovery.ps1
    Lists sensitivity labels, label policies, DLP policies (flagging any already enforcing), and
    retention labels/policies. PowerShell 5.1+/7+; uses Connect-IPPSSession.
.NOTES
    Expected results: read-only inventory printed to the console; any DLP policy already in Enforce is
    flagged. No changes are made. White-label — no credentials in code. Purview is licensing-dependent
    and evolving — verify your licensing/tenant.
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host "`n=== Microsoft Purview for Healthcare — configuration discovery (read-only) ===" -ForegroundColor Cyan

Write-Host "`n--- Sensitivity labels ---" -ForegroundColor Cyan
$labels = Get-Label -ErrorAction SilentlyContinue
if ($labels) {
    $labels | Sort-Object Priority | Select-Object DisplayName, Priority,
        @{n='Encrypted';e={[bool]$_.EncryptionEnabled}}, ContentType | Format-Table -AutoSize
    $phi = @($labels | Where-Object { $_.DisplayName -match 'PHI' })
    Write-Host ("  PHI-named labels present: {0}" -f $phi.Count) -ForegroundColor ($(if($phi.Count){'Green'}else{'Yellow'}))
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
    $phiDlp = @($dlp | Where-Object { $_.Name -match 'PHI|HIPAA|Health' })
    Write-Host ("  PHI/HIPAA-named DLP policies: {0}" -f $phiDlp.Count) -ForegroundColor ($(if($phiDlp.Count){'Green'}else{'Yellow'}))
} else { Write-Host "  No DLP policies found." -ForegroundColor Yellow }

Write-Host "`n--- Retention labels ---" -ForegroundColor Cyan
$retLabels = Get-ComplianceTag -ErrorAction SilentlyContinue
if ($retLabels) { $retLabels | Select-Object Name, RetentionDuration, RetentionAction | Format-Table -AutoSize }
else { Write-Host "  No retention labels found." -ForegroundColor Yellow }

Write-Host "`n--- Retention policies ---" -ForegroundColor Cyan
$retPols = Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue
if ($retPols) { $retPols | Select-Object Name, Enabled, Mode | Format-Table -AutoSize }
else { Write-Host "  No retention policies found." -ForegroundColor Yellow }

Write-Host "`nDiscovery complete. Use PHI-Validation.ps1 to check the expected named objects." -ForegroundColor Green
Disconnect-ExchangeOnline -Confirm:$false | Out-Null

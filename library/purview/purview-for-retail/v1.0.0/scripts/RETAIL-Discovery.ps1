<#
.SYNOPSIS
    RETAIL-Discovery.ps1 — inventory the tenant's retail-relevant Purview posture (read-only).
.DESCRIPTION
    PURPOSE
        Connects to Security & Compliance PowerShell and reports the Microsoft Purview configuration a
        retail/PCI program cares about: sensitivity labels and label policies, DLP policies (with
        mode: test/audit vs enforce) and whether they cover the Credit Card Number / PII sensitive-
        information types, retention labels/policies, and the presence of the built-in Credit Card
        Number SIT. This is the "what exists today" read used to plan the taxonomy, the DLP audit
        gate, and retention scope.
    HOW TO RUN
        Install-Module ExchangeOnlineManagement -Scope CurrentUser
        powershell -ExecutionPolicy Bypass -File .\RETAIL-Discovery.ps1
        Sign in as a Compliance Administrator (or Information Protection + DLP roles) when prompted.
    EXPECTED RESULTS
        Lists of sensitivity labels (name, priority, encryption), label policies, DLP policies (name,
        MODE — flags any already enforcing), retention labels/policies, and a check that the built-in
        Credit Card Number sensitive-info type is present. Nothing is changed.
.NOTES
    White-label — Purview / Retail. Read-only.
    PowerShell 5.1+/7+. Uses Get-Label / Get-LabelPolicy / Get-DlpCompliancePolicy /
    Get-RetentionCompliancePolicy / Get-ComplianceTag / Get-DlpSensitiveInformationType.
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host "`n=== Microsoft Purview for Retail — configuration discovery ===" -ForegroundColor Cyan

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
    $pciLike = @($dlp | Where-Object { $_.Name -match 'PCI|Cardholder|PII|Customer' })
    Write-Host ("  Retail/PCI-named DLP policies: {0}" -f $pciLike.Count) -ForegroundColor Cyan
} else { Write-Host "  No DLP policies found." -ForegroundColor Yellow }

Write-Host "`n--- Retention labels ---" -ForegroundColor Cyan
$retLabels = Get-ComplianceTag -ErrorAction SilentlyContinue
if ($retLabels) { $retLabels | Select-Object Name, RetentionDuration, RetentionAction | Format-Table -AutoSize }
else { Write-Host "  No retention labels found." -ForegroundColor Yellow }

Write-Host "`n--- Retention policies ---" -ForegroundColor Cyan
$retPols = Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue
if ($retPols) { $retPols | Select-Object Name, Enabled, Mode | Format-Table -AutoSize }
else { Write-Host "  No retention policies found." -ForegroundColor Yellow }

Write-Host "`n--- Sensitive-info types for PAN (PCI) ---" -ForegroundColor Cyan
try {
    $cc = Get-DlpSensitiveInformationType -ErrorAction Stop | Where-Object { $_.Name -match 'Credit Card' }
    if ($cc) { $cc | Select-Object Name, Publisher | Format-Table -AutoSize }
    else { Write-Host "  Credit Card Number SIT not found (verify tenant)." -ForegroundColor Yellow }
} catch { Write-Host ("  Could not enumerate sensitive-info types: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

Write-Host "`nDiscovery complete. Use RETAIL-Validation.ps1 to check the expected named objects." -ForegroundColor Green
Disconnect-ExchangeOnline -Confirm:$false | Out-Null

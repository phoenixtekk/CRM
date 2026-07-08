<#
.SYNOPSIS
    PURVIEW-MFG-Discovery.ps1 — inventory the Manufacturing Purview posture (read-only).
.DESCRIPTION
    PURPOSE
        Connects to Security & Compliance PowerShell and reports the tenant's current Microsoft
        Purview information-protection posture for a Manufacturing IP + CUI program: sensitivity
        labels and label policies, the custom part/drawing-number sensitive-info type, DLP policies
        (with mode: test/audit vs enforce), and retention labels/policies. This is the "what exists
        today" read used to plan the taxonomy, the DLP audit gate, and retention scope.
    HOW TO RUN
        Install-Module ExchangeOnlineManagement -Scope CurrentUser
        powershell -ExecutionPolicy Bypass -File .\PURVIEW-MFG-Discovery.ps1
        Sign in as a Compliance Administrator (or Information Protection + DLP roles) when prompted.
    EXAMPLE
        .\PURVIEW-MFG-Discovery.ps1
    EXPECTED RESULTS
        Lists of sensitivity labels (name, priority, encryption), label policies, the custom SIT
        'SIT - MFG Part/Drawing Number' (present/absent), DLP policies (name, MODE — flags any
        already in Enforce), and retention labels/policies. Read-only; no changes made.
.NOTES
    White-label — Purview Solutions. Read-only. PowerShell 5.1+/7+.
    Uses Get-Label / Get-LabelPolicy / Get-DlpSensitiveInformationType / Get-DlpCompliancePolicy /
    Get-ComplianceTag / Get-RetentionCompliancePolicy. Availability is licensing-/cloud-dependent.
#>
[CmdletBinding()] param(
    [string]$SitName = 'SIT - MFG Part/Drawing Number'
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host "`n=== Microsoft Purview for Manufacturing — configuration discovery ===" -ForegroundColor Cyan

Write-Host "`n--- Sensitivity labels ---" -ForegroundColor Cyan
$labels = Get-Label -ErrorAction SilentlyContinue
if ($labels) {
    $labels | Sort-Object Priority | Select-Object DisplayName, Priority,
        @{n='Encrypted';e={[bool]$_.EncryptionEnabled}}, ContentType | Format-Table -AutoSize
    $mfg = @($labels | Where-Object { $_.DisplayName -like '*MFG-*' })
    Write-Host ("  Manufacturing (MFG-*) labels found: {0}" -f $mfg.Count) -ForegroundColor $(if($mfg.Count -ge 1){'Green'}else{'Yellow'})
} else { Write-Host "  No sensitivity labels found." -ForegroundColor Yellow }

Write-Host "`n--- Label policies ---" -ForegroundColor Cyan
$labelPols = Get-LabelPolicy -ErrorAction SilentlyContinue
if ($labelPols) { $labelPols | Select-Object Name, Enabled | Format-Table -AutoSize }
else { Write-Host "  No label policies found." -ForegroundColor Yellow }

Write-Host "`n--- Custom sensitive info type (IP part/drawing numbers) ---" -ForegroundColor Cyan
$sit = Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $SitName }
if ($sit) { Write-Host ("  Present: '{0}' (Publisher: {1})" -f $sit.Name, $sit.Publisher) -ForegroundColor Green }
else { Write-Host ("  Missing: '{0}' — create it (Implementation Step 4)." -f $SitName) -ForegroundColor Yellow }

Write-Host "`n--- DLP policies (mode: test/audit vs enforce) ---" -ForegroundColor Cyan
$dlp = Get-DlpCompliancePolicy -ErrorAction SilentlyContinue
if ($dlp) {
    $dlp | Select-Object Name, Mode, Enabled | Sort-Object Mode | Format-Table -AutoSize
    $enforcing = @($dlp | Where-Object { $_.Mode -match 'Enable' })
    if ($enforcing) { Write-Host ("  NOTE: {0} DLP policy(ies) already enforcing." -f $enforcing.Count) -ForegroundColor Yellow }
} else { Write-Host "  No DLP policies found." -ForegroundColor Yellow }

Write-Host "`n--- Retention labels ---" -ForegroundColor Cyan
$retLabels = Get-ComplianceTag -ErrorAction SilentlyContinue
if ($retLabels) { $retLabels | Select-Object Name, RetentionDuration, RetentionAction | Format-Table -AutoSize }
else { Write-Host "  No retention labels found." -ForegroundColor Yellow }

Write-Host "`n--- Retention policies ---" -ForegroundColor Cyan
$retPols = Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue
if ($retPols) { $retPols | Select-Object Name, Enabled, Mode | Format-Table -AutoSize }
else { Write-Host "  No retention policies found." -ForegroundColor Yellow }

Write-Host "`nDiscovery complete. Use PURVIEW-MFG-Validation.ps1 to check the expected named objects." -ForegroundColor Green
Write-Host "NOTE: feature availability is licensing-/cloud-dependent (E5 / E5 Compliance; GCC/GCC High for CUI) — verify your tenant." -ForegroundColor DarkGray
Disconnect-ExchangeOnline -Confirm:$false | Out-Null

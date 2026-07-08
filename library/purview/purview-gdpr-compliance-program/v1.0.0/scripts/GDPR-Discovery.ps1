<#
.SYNOPSIS
    GDPR-Discovery.ps1 — inventory the tenant's GDPR-relevant Purview posture (read-only).
.DESCRIPTION
    PURPOSE
        Connects to Security & Compliance PowerShell and reports the "what exists today" baseline for
        the GDPR program: sensitivity labels and label policies, DLP policies (with mode: test/audit
        vs enforce), retention labels/policies, the EU personal-data sensitive-information types
        available in the tenant, and the Purview role groups + members (role-separation readiness).
        Compliance Manager assessments are portal-driven and are NOT created here.
    HOW TO RUN
        Install-Module ExchangeOnlineManagement -Scope CurrentUser
        powershell -ExecutionPolicy Bypass -File .\GDPR-Discovery.ps1
        Sign in as a least-privilege Compliance Administrator / Compliance Data Administrator.
    EXPECTED RESULTS
        Lists of labels (name, priority, encryption), label policies, DLP policies (name + MODE —
        flags any already enforcing), retention labels/policies, matching EU personal-data SITs, and
        Purview role groups with member counts. Read-only — makes no changes.
.NOTES
    White-label — Purview Solutions. Read-only.
    Uses Get-Label / Get-LabelPolicy / Get-DlpCompliancePolicy / Get-RetentionCompliancePolicy /
    Get-ComplianceTag / Get-DlpSensitiveInformationType / Get-RoleGroup / Get-RoleGroupMember.
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host "`n=== Microsoft Purview GDPR — posture discovery ===" -ForegroundColor Cyan

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

Write-Host "`n--- Retention labels ---" -ForegroundColor Cyan
$retLabels = Get-ComplianceTag -ErrorAction SilentlyContinue
if ($retLabels) { $retLabels | Select-Object Name, RetentionDuration, RetentionAction | Format-Table -AutoSize }
else { Write-Host "  No retention labels found." -ForegroundColor Yellow }

Write-Host "`n--- Retention policies ---" -ForegroundColor Cyan
$retPols = Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue
if ($retPols) { $retPols | Select-Object Name, Enabled, Mode | Format-Table -AutoSize }
else { Write-Host "  No retention policies found." -ForegroundColor Yellow }

Write-Host "`n--- EU personal-data sensitive-information types (available in tenant) ---" -ForegroundColor Cyan
$euSits = Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^EU ' -or $_.Name -match 'EU ' }
if ($euSits) { $euSits | Sort-Object Name | Select-Object Name, Publisher | Format-Table -AutoSize }
else { Write-Host "  No EU personal-data SITs matched (verify licensing/tenant)." -ForegroundColor Yellow }

Write-Host "`n--- Purview role groups (role-separation readiness) ---" -ForegroundColor Cyan
$rg = Get-RoleGroup -ErrorAction SilentlyContinue
if ($rg) {
    foreach ($g in ($rg | Sort-Object Name)) {
        $members = @(Get-RoleGroupMember -Identity $g.Name -ErrorAction SilentlyContinue)
        Write-Host ("  {0,-45} members: {1}" -f $g.Name, $members.Count)
    }
    Write-Host "  Review that Insider Risk / Communication Compliance roles are held by SEPARATE owners." -ForegroundColor Yellow
} else { Write-Host "  Could not enumerate role groups (permission?)." -ForegroundColor Yellow }

Write-Host "`nDiscovery complete. Compliance Manager assessments are portal-driven (not created here)." -ForegroundColor Green
Write-Host "Next: GDPR-Validation.ps1 to check the expected named objects." -ForegroundColor Green
Disconnect-ExchangeOnline -Confirm:$false | Out-Null

<#
.SYNOPSIS
    ISO27701-Discovery.ps1 — inventory the tenant's ISO 27701 (PIMS) Purview posture (read-only).
.DESCRIPTION
    PURPOSE
        Connects to Security & Compliance PowerShell and reports the "what exists today" baseline for the
        ISO 27701 PIMS program: sensitivity labels and label policies, DLP policies (with mode: test/audit
        vs enforce), retention labels/policies, the PII sensitive-information types available in the
        tenant, and the Purview role groups + members (role-separation readiness). Compliance Manager
        assessments (ISO 27701 / any existing ISO 27001 for reuse) are portal-driven and NOT created here.
    HOW TO RUN
        Install-Module ExchangeOnlineManagement -Scope CurrentUser
        powershell -ExecutionPolicy Bypass -File .\ISO27701-Discovery.ps1
        Sign in as a least-privilege Compliance Administrator / Compliance Data Administrator.
    EXPECTED RESULTS
        Lists of labels (name, priority, encryption), label policies, DLP policies (name + MODE — flags
        any already enforcing), retention labels/policies, matching PII SITs, and Purview role groups with
        member counts. Read-only — makes no changes.
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

Write-Host "`n=== Microsoft Purview ISO 27701 (PIMS) — posture discovery ===" -ForegroundColor Cyan

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

Write-Host "`n--- PII sensitive-information types (available in tenant) ---" -ForegroundColor Cyan
$piiSits = Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match 'National|Passport|Tax|Identification|Health|Social Security|Driver|SSN|EU ' }
if ($piiSits) { $piiSits | Sort-Object Name | Select-Object Name, Publisher | Format-Table -AutoSize }
else { Write-Host "  No PII SITs matched the heuristic (verify licensing/tenant)." -ForegroundColor Yellow }

Write-Host "`n--- Purview role groups (role-separation readiness) ---" -ForegroundColor Cyan
$rg = Get-RoleGroup -ErrorAction SilentlyContinue
if ($rg) {
    foreach ($g in ($rg | Sort-Object Name)) {
        $members = @(Get-RoleGroupMember -Identity $g.Name -ErrorAction SilentlyContinue)
        Write-Host ("  {0,-45} members: {1}" -f $g.Name, $members.Count)
    }
    Write-Host "  Review that Insider Risk / Communication Compliance / Priva roles are held by SEPARATE owners." -ForegroundColor Yellow
} else { Write-Host "  Could not enumerate role groups (permission?)." -ForegroundColor Yellow }

Write-Host "`nDiscovery complete. Compliance Manager assessments (ISO 27701 / existing ISO 27001 for reuse) are portal-driven." -ForegroundColor Green
Write-Host "Next: ISO27701-Validation.ps1 to check the expected named objects." -ForegroundColor Green
Disconnect-ExchangeOnline -Confirm:$false | Out-Null

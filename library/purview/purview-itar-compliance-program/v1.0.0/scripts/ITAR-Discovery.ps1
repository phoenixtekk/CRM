<#
.SYNOPSIS
    ITAR-Discovery.ps1 — inventory the tenant's ITAR/export-control Purview posture (read-only).
.DESCRIPTION
    PURPOSE
        Connects to Security & Compliance PowerShell and reports the "what exists today" baseline for the
        ITAR program: sensitivity labels and label policies, DLP policies (with mode: test/audit vs
        enforce), retention labels/policies, the custom ITAR/USML sensitive-info type and any export-
        control SITs, and the Purview role groups + members (role-separation readiness). Compliance
        Manager assessments (export-control / NIST 800-171) are portal-driven and NOT created here.
    HOW TO RUN
        Install-Module ExchangeOnlineManagement -Scope CurrentUser
        powershell -ExecutionPolicy Bypass -File .\ITAR-Discovery.ps1
        Sign in as a least-privilege Compliance Administrator (an authorized U.S. person for ITAR data).
    EXPECTED RESULTS
        Lists of labels (name, priority, encryption), label policies, DLP policies (name + MODE — flags
        any already enforcing), retention labels/policies, the custom SIT 'SIT - ITAR/USML Markers'
        (present/absent), export-control SITs, and Purview role groups with member counts. Read-only.
.NOTES
    White-label — Purview Solutions. Read-only. Verify licensing/tenant (advanced features need E5 / E5
    Compliance; ITAR data generally needs GCC High).
    Uses Get-Label / Get-LabelPolicy / Get-DlpCompliancePolicy / Get-RetentionCompliancePolicy /
    Get-ComplianceTag / Get-DlpSensitiveInformationType / Get-RoleGroup / Get-RoleGroupMember.
#>
[CmdletBinding()] param(
    [string]$SitName = 'SIT - ITAR/USML Markers'
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host "`n=== Microsoft Purview ITAR / export-control — posture discovery ===" -ForegroundColor Cyan

Write-Host "`n--- Sensitivity labels ---" -ForegroundColor Cyan
$labels = Get-Label -ErrorAction SilentlyContinue
if ($labels) {
    $labels | Sort-Object Priority | Select-Object DisplayName, Priority,
        @{n='Encrypted';e={[bool]$_.EncryptionEnabled}}, ContentType | Format-Table -AutoSize
    $itar = @($labels | Where-Object { $_.DisplayName -like '*ITAR*' })
    Write-Host ("  ITAR labels found: {0}" -f $itar.Count) -ForegroundColor $(if($itar.Count -ge 1){'Green'}else{'Yellow'})
} else { Write-Host "  No sensitivity labels found." -ForegroundColor Yellow }

Write-Host "`n--- Label policies ---" -ForegroundColor Cyan
$labelPols = Get-LabelPolicy -ErrorAction SilentlyContinue
if ($labelPols) { $labelPols | Select-Object Name, Enabled | Format-Table -AutoSize }
else { Write-Host "  No label policies found." -ForegroundColor Yellow }

Write-Host "`n--- Custom sensitive info type (ITAR/USML markers) ---" -ForegroundColor Cyan
$sit = Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $SitName }
if ($sit) { Write-Host ("  Present: '{0}' (Publisher: {1})" -f $sit.Name, $sit.Publisher) -ForegroundColor Green }
else { Write-Host ("  Missing: '{0}' — create it (Implementation Step 5)." -f $SitName) -ForegroundColor Yellow }

Write-Host "`n--- Export-control sensitive-information types (available in tenant) ---" -ForegroundColor Cyan
$ecSits = Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match 'Export|ITAR|EAR|Munitions|USML' }
if ($ecSits) { $ecSits | Sort-Object Name | Select-Object Name, Publisher | Format-Table -AutoSize }
else { Write-Host "  No export-control SITs matched (verify licensing/tenant)." -ForegroundColor Yellow }

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

Write-Host "`n--- Purview role groups (role-separation readiness) ---" -ForegroundColor Cyan
$rg = Get-RoleGroup -ErrorAction SilentlyContinue
if ($rg) {
    foreach ($g in ($rg | Sort-Object Name)) {
        $members = @(Get-RoleGroupMember -Identity $g.Name -ErrorAction SilentlyContinue)
        Write-Host ("  {0,-45} members: {1}" -f $g.Name, $members.Count)
    }
    Write-Host "  Confirm roles that can access technical data are held by AUTHORIZED U.S. PERSONS (export-control/HR determination)." -ForegroundColor Yellow
} else { Write-Host "  Could not enumerate role groups (permission?)." -ForegroundColor Yellow }

Write-Host "`nDiscovery complete. Confirm the sovereign cloud (GCC High) with export-control/legal before placing ITAR data." -ForegroundColor Green
Write-Host "Next: ITAR-Validation.ps1 to check the expected named objects." -ForegroundColor Green
Disconnect-ExchangeOnline -Confirm:$false | Out-Null

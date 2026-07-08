<#
.SYNOPSIS
    CMPCJIS-Discovery.ps1 - assess CJI-control licensing, current state, and audit-logging status (read-only).
.DESCRIPTION
    PURPOSE
        Read-only baseline for a CJIS-aligned Purview program. Connects to Security & Compliance PowerShell,
        Exchange Online, and Microsoft Graph and reports: which CJI-control capabilities are licensed
        (sensitivity labels/encryption, DLP, retention, Audit Premium, Insider Risk via Graph
        subscribedSkus); the existing CJI-relevant labels/DLP/retention objects; whether UNIFIED AUDIT
        LOGGING is enabled; and an INDICATIVE environment hint. It CANNOT attest CJIS authorization
        (GCC High / Azure Government) - that is your CSA's determination. Changes nothing.
    HOW TO RUN
        powershell -File .\CMPCJIS-Discovery.ps1 -CsvPath .\CJIS-Discovery-Baseline.csv
        Requires ExchangeOnlineManagement (Connect-IPPSSession + Connect-ExchangeOnline) and, for licensing,
        Microsoft.Graph. Interactive modern-auth; no secrets in code.
    EXPECTED RESULTS
        A per-item table (Item / State / Detail) and a licensing summary. "CHECK" means verify your
        licensing/tenant/cloud, not a defect. Feeds "CJIS Control Map - Purview - Baseline".
.NOTES
    Purview category - CJIS Compliance Program. Read-only. CJIS is generally satisfied only in GCC High /
    Azure Government under a signed CJIS agreement - commercial M365 is generally NOT CJIS-authorized;
    this script cannot attest that. No client names; no secrets.
#>
[CmdletBinding()]
param(
    [string]$UserPrincipalName,
    [string]$CsvPath,
    [switch]$SkipGraphLicensing
)

$ErrorActionPreference = 'Stop'
$rows = New-Object System.Collections.Generic.List[object]
function Add-Row($item,$state,$detail){ $rows.Add([pscustomobject]@{ Item=$item; State=$state; Detail=$detail }) }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser" -ForegroundColor Red; return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$cp = @{}; if ($UserPrincipalName) { $cp['UserPrincipalName'] = $UserPrincipalName }

# --- Unified audit logging (Exchange Online) ---
try {
    Connect-ExchangeOnline @cp -ShowBanner:$false -ErrorAction Stop | Out-Null
    $cfg = Get-AdminAuditLogConfig -ErrorAction Stop
    $on = [bool]$cfg.UnifiedAuditLogIngestionEnabled
    Add-Row 'Unified audit logging' ($(if($on){'ON'}else{'OFF'})) ("UnifiedAuditLogIngestionEnabled={0} (CJIS Auditing & Accountability)" -f $on)
} catch { Add-Row 'Unified audit logging' 'CHECK' ("Get-AdminAuditLogConfig failed: {0}" -f $_.Exception.Message) }

# --- Security & Compliance PowerShell (CJI-relevant objects) ---
try {
    Connect-IPPSSession @cp -ErrorAction Stop | Out-Null

    try { $labels = @(Get-Label -ErrorAction Stop)
          $cji = @($labels | Where-Object { $_.DisplayName -match '(?i)cji|criminal|chri' })
          Add-Row 'Sensitivity labels' 'REACHABLE' ("{0} label(s); {1} CJI-named" -f $labels.Count, $cji.Count) }
    catch { Add-Row 'Sensitivity labels' 'CHECK' $_.Exception.Message }

    try { $dlp = @(Get-DlpCompliancePolicy -ErrorAction Stop)
          $cjiDlp = @($dlp | Where-Object { $_.Name -match '(?i)cji|criminal' })
          Add-Row 'DLP policies' 'REACHABLE' ("{0} DLP policy(ies); {1} CJI-named" -f $dlp.Count, $cjiDlp.Count) }
    catch { Add-Row 'DLP policies' 'CHECK' $_.Exception.Message }

    try { $ret = @(Get-RetentionCompliancePolicy -ErrorAction Stop)
          Add-Row 'Retention policies' 'REACHABLE' ("{0} retention policy(ies)" -f $ret.Count) }
    catch { Add-Row 'Retention policies' 'CHECK' $_.Exception.Message }

    # Custom Sensitive Information Types (candidate CJI identifiers - agency-defined)
    try { $sit = @(Get-DlpSensitiveInformationType -ErrorAction Stop | Where-Object { $_.Publisher -ne 'Microsoft Corporation' })
          Add-Row 'Custom Sensitive Info Types' 'REACHABLE' ("{0} custom SIT(s) - CJI identifiers come from the agency" -f $sit.Count) }
    catch { Add-Row 'Custom Sensitive Info Types' 'CHECK' $_.Exception.Message }
}
catch { Add-Row 'Security & Compliance PowerShell' 'CHECK' ("Connect-IPPSSession failed: {0}" -f $_.Exception.Message) }

# Compliance Manager assessment template (portal-primary; availability differs by cloud)
Add-Row 'CJIS assessment template (Compliance Manager)' 'CHECK' 'Verify a CJIS/US-gov template is available in YOUR cloud (GCC High / Azure Gov) - portal-read'
Add-Row 'CJIS environment authorization' 'CHECK' 'GCC High / Azure Government + signed CJIS Addendum - CSA/CSO determination; this script cannot attest it'

# --- Graph licensing ---
if (-not $SkipGraphLicensing -and (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    try {
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        Connect-MgGraph -Scopes 'Organization.Read.All' -NoWelcome
        $skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
        $planNames = $skus | ForEach-Object { $_.servicePlans.servicePlanName } | Sort-Object -Unique
        $checks = @{
            'Advanced Audit / Audit Premium (M365_ADVANCED_AUDITING)' = 'M365_ADVANCED_AUDITING'
            'Insider Risk (INSIDER_RISK_MANAGEMENT)'                    = 'INSIDER_RISK_MANAGEMENT'
            'Information Protection / advanced DLP (MIP_S_CLP2)'        = 'MIP_S_CLP2'
            'Records Management (RECORDS_MANAGEMENT)'                   = 'RECORDS_MANAGEMENT'
        }
        foreach ($k in $checks.Keys) {
            $present = $planNames -contains $checks[$k]
            Add-Row "Licensing: $k" ($(if($present){'PRESENT'}else{'CHECK'})) ($(if($present){"$($checks[$k]) in subscribedSkus"}else{"$($checks[$k]) not found - verify licensing/tenant/cloud"}))
        }
    } catch { Add-Row 'Graph licensing' 'CHECK' $_.Exception.Message }
} else { Add-Row 'Graph licensing' 'CHECK' 'Graph licensing check skipped/unavailable' }

Write-Host "`n=== CJIS Program - Discovery Baseline ===" -ForegroundColor Cyan
$rows | Format-Table -AutoSize | Out-String | Write-Host
Write-Host "CHECK = verify your licensing/tenant/cloud (GCC High / Azure Gov) with your CSA/CSO before relying on the item." -ForegroundColor Yellow
Write-Host "This script configures nothing and cannot attest CJIS authorization." -ForegroundColor Yellow
if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host "Exported to $CsvPath" -ForegroundColor Green }

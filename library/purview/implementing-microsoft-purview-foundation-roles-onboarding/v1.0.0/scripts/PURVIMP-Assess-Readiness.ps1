<#
.SYNOPSIS
    PURVIMP-Assess-Readiness.ps1 — read-only Microsoft Purview readiness, licensing, and role assessment (no changes).
.DESCRIPTION
    PURPOSE
        Builds the Purview foundation baseline: which compliance SKUs the tenant has (E3 / E5 /
        E5 Compliance), the existing Security & Compliance role groups and their members, whether the
        unified audit log is ingesting, and whether the S&C PowerShell + Graph toolchain connects.
        Read-only — makes no changes. Writes the export "Purview Readiness - Foundation - Assess".
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVIMP-Assess-Readiness.ps1 -CsvPath .\PurviewReadiness.csv
        PowerShell 5.1+ or 7+. Requires ExchangeOnlineManagement (Connect-IPPSSession / Connect-ExchangeOnline)
        and the Microsoft Graph SDK; Graph read scopes: Organization.Read.All, Directory.Read.All.
    EXPECTED RESULTS
        A console summary of compliance SKUs, role groups (name + member count), and audit status,
        plus an optional CSV. PASS = you can state, per capability, "available on this plan" or "deferred".
.NOTES
    Purview — Implementing Microsoft Purview: Foundation, Roles & Onboarding. Read-only. No secrets in code.
    Purview is licensing-dependent and the portal is evolving — verify capability availability in your tenant.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [string]$ReportName = 'Purview Readiness - Foundation - Assess'
)

Write-Host ("=== {0} ===" -f $ReportName) -ForegroundColor Cyan

# --- Toolchain: connect Microsoft Graph (read-only) ---
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Organization.Read.All','Directory.Read.All' -NoWelcome

# --- Compliance licensing: which SKUs are present ---
# Service plans that indicate Purview/compliance capability (illustrative; verify against your tenant/plan).
$capPlans = @{
    'Audit (Standard)'                 = @('EXCHANGE_S_ENTERPRISE')
    'Advanced/Premium compliance (E5)' = @('INFORMATION_BARRIERS','RECORDS_MANAGEMENT','INSIDER_RISK_MANAGEMENT','COMMUNICATION_COMPLIANCE','CUSTOMER_KEY','MIP_S_CLP2','M365_ADVANCED_AUDITING')
}
$skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
$planNames = $skus | ForEach-Object { $_.servicePlans } | ForEach-Object { $_.servicePlanName } | Sort-Object -Unique

Write-Host '--- Compliance licensing (subscribed SKUs) ---' -ForegroundColor Cyan
$skus | Sort-Object skuPartNumber |
    Select-Object skuPartNumber, @{n='Purchased';e={$_.prepaidUnits.enabled}}, consumedUnits |
    Format-Table -AutoSize

Write-Host '--- Capability availability (indicative — verify in your tenant) ---' -ForegroundColor Cyan
$capRows = foreach ($cap in $capPlans.Keys) {
    $present = @($capPlans[$cap] | Where-Object { $planNames -contains $_ }).Count -gt 0
    [pscustomobject]@{ Capability = $cap; Available = $(if ($present) {'Available'} else {'Deferred (not licensed)'}) }
}
$capRows | Format-Table -AutoSize

# --- Existing Security & Compliance role groups + members ---
Write-Host '--- Connecting Security & Compliance PowerShell (Connect-IPPSSession) ---' -ForegroundColor Cyan
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

$foundation = @('Compliance Administrator','Compliance Data Administrator','Information Protection',
    'Information Protection Admin','Records Management','Insider Risk Management','eDiscovery Manager',
    'Audit Manager','Audit Reader','Content Explorer Content Viewer','Content Explorer List Viewer',
    'Communication Compliance')

$rgRows = foreach ($rgName in $foundation) {
    $rg = Get-RoleGroup -Identity $rgName -ErrorAction SilentlyContinue
    if ($rg) {
        $members = @(Get-RoleGroupMember -Identity $rgName -ErrorAction SilentlyContinue)
        [pscustomobject]@{ RoleGroup = $rgName; Exists = $true; MemberCount = $members.Count;
            Members = ($members.Name -join '; ') }
    } else {
        [pscustomobject]@{ RoleGroup = $rgName; Exists = $false; MemberCount = 0; Members = '' }
    }
}
Write-Host '--- Foundation role groups ---' -ForegroundColor Cyan
$rgRows | Format-Table RoleGroup, Exists, MemberCount -AutoSize

# --- Unified audit log status (Exchange Online) ---
Write-Host '--- Connecting Exchange Online for audit status ---' -ForegroundColor Cyan
Connect-ExchangeOnline -ShowBanner:$false
$auditCfg = Get-AdminAuditLogConfig -ErrorAction SilentlyContinue
$auditOn  = $false
if ($auditCfg -and ($auditCfg.PSObject.Properties.Name -contains 'UnifiedAuditLogIngestionEnabled')) {
    $auditOn = [bool]$auditCfg.UnifiedAuditLogIngestionEnabled
}
Write-Host ("Unified audit log ingestion enabled: {0}" -f $auditOn) -ForegroundColor $(if ($auditOn) {'Green'} else {'Yellow'})

if ($CsvPath) {
    $rgRows | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved '{0}' to {1}" -f $ReportName, $CsvPath) -ForegroundColor Green
}

Disconnect-ExchangeOnline -Confirm:$false | Out-Null
Disconnect-MgGraph | Out-Null
Write-Host 'Readiness assessment complete (read-only).' -ForegroundColor Green

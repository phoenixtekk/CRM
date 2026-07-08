<#
.SYNOPSIS
    PURVAUDIT-Set-RetentionPolicy.ps1 — enable unified audit + create/update/remove audit retention policies (-WhatIf default).
.DESCRIPTION
    PURPOSE
        Configuration/remediation helper. With -EnableUnifiedAudit it turns unified audit log ingestion
        on. Otherwise it creates or updates an audit log retention policy (record types / operations /
        users / duration / priority), or removes one with -Remove. SAFE BY DEFAULT: prints the exact
        change under -WhatIf and only writes with -Commit.
    HOW TO RUN
        # Preview enabling unified audit:
        powershell -File .\PURVAUDIT-Set-RetentionPolicy.ps1 -EnableUnifiedAudit -WhatIf
        # Create a mailbox high-value retention policy (preview then commit):
        .\PURVAUDIT-Set-RetentionPolicy.ps1 -PolicyName "Audit Retention - Mailbox High-Value - Premium" `
            -RecordTypes ExchangeItem -Operations MailItemsAccessed,Send,SendAs,New-InboxRule,Set-InboxRule `
            -Duration TenYears -Priority 100 -WhatIf
        .\PURVAUDIT-Set-RetentionPolicy.ps1 ... -Commit
        Enable uses Exchange Online PowerShell (Connect-ExchangeOnline); retention-policy cmdlets use
        Security & Compliance PowerShell (Connect-IPPSSession). No secrets in code.
    EXPECTED RESULTS
        Under -WhatIf: the exact cmdlet that would run and its parameters. Under -Commit: the policy is
        created/updated/removed (or ingestion enabled) and the resulting object is printed.
.NOTES
    Purview category — Audit. Retention duration/ten-year tier are LICENSING-DEPENDENT; verify accepted
    RetentionDuration values and licensing in your tenant before -Commit. Pilot-first per the guide.
#>
[CmdletBinding()]
param(
    [switch]$EnableUnifiedAudit,

    [string]$PolicyName,
    [string[]]$RecordTypes,                 # e.g. ExchangeItem, AzureActiveDirectory, AzureActiveDirectoryStsLogon, SharePointFileOperation
    [string[]]$Operations,                  # optional, e.g. MailItemsAccessed, Send, New-InboxRule
    [string[]]$UserIds,                     # optional scope by user
    [string]$Duration = 'OneYear',          # verify accepted values in your tenant (e.g. ThreeMonths/SixMonths/NineMonths/OneYear/TenYears); TenYears requires the add-on
    [int]$Priority,
    [string]$Description = 'Created by PURVAUDIT-Set-RetentionPolicy.ps1',
    [switch]$Remove,

    [string]$UserPrincipalName,
    [switch]$Commit                          # required to actually make changes; otherwise -WhatIf behavior
)

$ErrorActionPreference = 'Stop'
$apply = $Commit.IsPresent
function Plan($m){ Write-Host ("[WHATIF] {0}" -f $m) -ForegroundColor Yellow }
function Did($m){ Write-Host ("[COMMIT] {0}" -f $m) -ForegroundColor Green }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser" -ForegroundColor Red; return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$cp = @{ ShowBanner = $false }; if ($UserPrincipalName) { $cp['UserPrincipalName'] = $UserPrincipalName }

# --- Enable unified audit log ingestion ---
if ($EnableUnifiedAudit) {
    Connect-ExchangeOnline @cp
    $cur = (Get-AdminAuditLogConfig).UnifiedAuditLogIngestionEnabled
    Write-Host "Current UnifiedAuditLogIngestionEnabled = $cur"
    if ($cur) { Write-Host "Already enabled — nothing to do." -ForegroundColor Green; return }
    if ($apply) {
        Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true
        Did "Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled `$true (activation can take time; NOT retroactive)."
    } else {
        Plan "Would run: Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled `$true"
    }
    return
}

# --- Retention policy create/update/remove (Security & Compliance PowerShell) ---
if (-not $PolicyName) { Write-Host "Provide -PolicyName (or use -EnableUnifiedAudit)." -ForegroundColor Red; return }
Connect-IPPSSession @cp | Out-Null
$existing = Get-UnifiedAuditLogRetentionPolicy -Identity $PolicyName -ErrorAction SilentlyContinue

if ($Remove) {
    if (-not $existing) { Write-Host "Policy '$PolicyName' not found — nothing to remove." -ForegroundColor Yellow; return }
    if ($apply) { Remove-UnifiedAuditLogRetentionPolicy -Identity $PolicyName -Confirm:$false; Did "Removed retention policy '$PolicyName'." }
    else { Plan "Would run: Remove-UnifiedAuditLogRetentionPolicy -Identity '$PolicyName'" }
    return
}

if (-not $RecordTypes) { Write-Host "Provide -RecordTypes for a create/update (e.g. ExchangeItem, AzureActiveDirectory)." -ForegroundColor Red; return }
if (-not $PSBoundParameters.ContainsKey('Priority')) { Write-Host "Provide a unique -Priority (lower = evaluated first)." -ForegroundColor Red; return }

$common = @{ RecordTypes = $RecordTypes; RetentionDuration = $Duration; Priority = $Priority; Description = $Description }
if ($Operations) { $common['Operations'] = $Operations }
if ($UserIds)    { $common['UserIds']    = $UserIds }

if ($existing) {
    if ($apply) { Set-UnifiedAuditLogRetentionPolicy -Identity $PolicyName @common; Did "Updated retention policy '$PolicyName'." ; Get-UnifiedAuditLogRetentionPolicy -Identity $PolicyName | Format-List Name,RecordTypes,Operations,RetentionDuration,Priority,UserIds }
    else { Plan ("Would run: Set-UnifiedAuditLogRetentionPolicy -Identity '$PolicyName' " + ($common.GetEnumerator() | ForEach-Object { "-$($_.Key) $($_.Value -join ',')" }) -join ' ') }
} else {
    if ($apply) { New-UnifiedAuditLogRetentionPolicy -Name $PolicyName @common; Did "Created retention policy '$PolicyName'." ; Get-UnifiedAuditLogRetentionPolicy -Identity $PolicyName | Format-List Name,RecordTypes,Operations,RetentionDuration,Priority,UserIds }
    else { Plan ("Would run: New-UnifiedAuditLogRetentionPolicy -Name '$PolicyName' " + (($common.GetEnumerator() | ForEach-Object { "-$($_.Key) $($_.Value -join ',')" }) -join ' ')) }
}

if (-not $apply) { Write-Host "`nNo changes made (default). Re-run with -Commit to apply. Verify RetentionDuration values + licensing first." -ForegroundColor Cyan }

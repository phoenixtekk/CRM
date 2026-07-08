<#
.SYNOPSIS
    CMPNIST-Set-ControlPolicy.ps1 — configure NIST-supporting Purview controls: audit + AU retention + SC/MP DLP (simulation-first, -WhatIf default).
.DESCRIPTION
    PURPOSE
        Configuration/remediation helper for the supporting controls. Modes:
          -EnableUnifiedAudit ............. turns unified audit log ingestion on (AU foundation).
          -AuditRetentionName ............. creates/removes the AU audit-log retention policy.
          -DlpPolicyName (create) ......... creates the SC/MP control DLP policy IN SIMULATION
                                             (Mode = TestWithoutNotifications) — detects, does not block.
          -DlpPolicyName -SetMode <mode> .. changes an existing DLP policy's mode (e.g. promote to Enable).
          -Remove ......................... removes the named audit-retention or DLP policy.
        SAFE BY DEFAULT: prints the exact cmdlet under -WhatIf and only writes with -Commit. New DLP
        policies are ALWAYS created in simulation; promotion to enforce is a separate, deliberate -SetMode.
    HOW TO RUN
        # Enable unified audit (preview then commit):
        .\CMPNIST-Set-ControlPolicy.ps1 -EnableUnifiedAudit -WhatIf
        # Create the AU audit-retention policy:
        .\CMPNIST-Set-ControlPolicy.ps1 -AuditRetentionName "Control Evidence - NIST AU - Audit Retention" `
            -RecordTypes AzureActiveDirectory,ExchangeItem,SharePointFileOperation -Duration OneYear -Priority 100 -WhatIf
        # Create the SC/MP DLP control in simulation, scoped to the pilot:
        .\CMPNIST-Set-ControlPolicy.ps1 -DlpPolicyName "Control Evidence - NIST SC-MP - DLP (Simulation)" `
            -Workloads Exchange,SharePoint,OneDrive,Endpoint -PilotGroup "NIST Pilot - Control Set - Stage1" -WhatIf
        # Promote the DLP control to enforce after the pilot passes:
        .\CMPNIST-Set-ControlPolicy.ps1 -DlpPolicyName "Control Evidence - NIST SC-MP - DLP (Simulation)" -SetMode Enable -WhatIf
        Enable uses Connect-ExchangeOnline; DLP/retention use Connect-IPPSSession. No secrets in code.
    EXPECTED RESULTS
        Under -WhatIf: the exact cmdlet(s) that would run. Under -Commit: the change is made and the object
        printed. New DLP always lands in TestWithoutNotifications (simulation).
.NOTES
    Purview category — NIST 800-53 program. DLP/labels/retention changes are HIGH-IMPACT: pilot-in-simulation
    first. RetentionDuration/long-term tier are licensing-dependent — verify before -Commit. Authorization,
    applicability, and retention-schedule adequacy are deferred to your AO/security/compliance/records/legal.
#>
[CmdletBinding()]
param(
    # --- AU: enable unified audit ---
    [switch]$EnableUnifiedAudit,

    # --- AU: audit-log retention policy ---
    [string]$AuditRetentionName,
    [string[]]$RecordTypes,                     # e.g. AzureActiveDirectory, ExchangeItem, SharePointFileOperation
    [string]$Duration = 'OneYear',              # verify accepted values in your tenant; long-term tiers need the add-on
    [int]$Priority,

    # --- SC/MP: DLP control policy ---
    [string]$DlpPolicyName,
    [ValidateSet('Exchange','SharePoint','OneDrive','Teams','Endpoint')]
    [string[]]$Workloads = @('Exchange','SharePoint','OneDrive'),
    [string]$PilotGroup,                        # optional scope (distribution group / site) for the pilot
    [ValidateSet('Enable','TestWithNotifications','TestWithoutNotifications','Disable')]
    [string]$SetMode,                           # change an existing DLP policy's mode (promote/demote)

    [switch]$Remove,
    [string]$Description = 'Created by CMPNIST-Set-ControlPolicy.ps1 (NIST 800-53 supporting control)',
    [string]$UserPrincipalName,
    [switch]$Commit                             # required to actually make changes; otherwise -WhatIf behavior
)

$ErrorActionPreference = 'Stop'
$apply = $Commit.IsPresent
function Plan($m){ Write-Host ("[WHATIF] {0}" -f $m) -ForegroundColor Yellow }
function Did($m){ Write-Host ("[COMMIT] {0}" -f $m) -ForegroundColor Green }
function Err($m){ Write-Host $m -ForegroundColor Red }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Err "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser"; return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$cp = @{ ShowBanner = $false }; if ($UserPrincipalName) { $cp['UserPrincipalName'] = $UserPrincipalName }

# =========================================================================================
# AU — enable unified audit log ingestion (Exchange Online)
# =========================================================================================
if ($EnableUnifiedAudit) {
    Connect-ExchangeOnline @cp | Out-Null
    $cur = (Get-AdminAuditLogConfig).UnifiedAuditLogIngestionEnabled
    Write-Host "Current UnifiedAuditLogIngestionEnabled = $cur"
    if ($cur) { Did "Already enabled — nothing to do."; return }
    if ($apply) { Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true; Did "Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled `$true (activation can take time; NOT retroactive)." }
    else { Plan "Would run: Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled `$true" }
    return
}

# =========================================================================================
# AU — audit-log retention policy (Security & Compliance PowerShell)
# =========================================================================================
if ($AuditRetentionName) {
    Connect-IPPSSession @cp | Out-Null
    $existing = Get-UnifiedAuditLogRetentionPolicy -Identity $AuditRetentionName -ErrorAction SilentlyContinue
    if ($Remove) {
        if (-not $existing) { Write-Host "Audit-retention policy '$AuditRetentionName' not found — nothing to remove." -ForegroundColor Yellow; return }
        if ($apply) { Remove-UnifiedAuditLogRetentionPolicy -Identity $AuditRetentionName -Confirm:$false; Did "Removed audit-retention policy '$AuditRetentionName'." }
        else { Plan "Would run: Remove-UnifiedAuditLogRetentionPolicy -Identity '$AuditRetentionName'" }
        return
    }
    if (-not $RecordTypes) { Err "Provide -RecordTypes (e.g. AzureActiveDirectory,ExchangeItem,SharePointFileOperation)."; return }
    if (-not $PSBoundParameters.ContainsKey('Priority')) { Err "Provide a unique -Priority (lower = evaluated first)."; return }
    $common = @{ RecordTypes = $RecordTypes; RetentionDuration = $Duration; Priority = $Priority; Description = $Description }
    if ($existing) {
        if ($apply) { Set-UnifiedAuditLogRetentionPolicy -Identity $AuditRetentionName @common; Did "Updated audit-retention policy '$AuditRetentionName'."; Get-UnifiedAuditLogRetentionPolicy -Identity $AuditRetentionName | Format-List Name,RecordTypes,RetentionDuration,Priority }
        else { Plan ("Would run: Set-UnifiedAuditLogRetentionPolicy -Identity '$AuditRetentionName' -RecordTypes $($RecordTypes -join ',') -RetentionDuration $Duration -Priority $Priority") }
    } else {
        if ($apply) { New-UnifiedAuditLogRetentionPolicy -Name $AuditRetentionName @common; Did "Created audit-retention policy '$AuditRetentionName'."; Get-UnifiedAuditLogRetentionPolicy -Identity $AuditRetentionName | Format-List Name,RecordTypes,RetentionDuration,Priority }
        else { Plan ("Would run: New-UnifiedAuditLogRetentionPolicy -Name '$AuditRetentionName' -RecordTypes $($RecordTypes -join ',') -RetentionDuration $Duration -Priority $Priority") }
    }
    if (-not $apply) { Write-Host "`nNo changes made (default). Verify RetentionDuration values + licensing, then re-run with -Commit." -ForegroundColor Cyan }
    return
}

# =========================================================================================
# SC/MP — DLP control policy (Security & Compliance PowerShell) — simulation-first
# =========================================================================================
if ($DlpPolicyName) {
    Connect-IPPSSession @cp | Out-Null
    $existing = Get-DlpCompliancePolicy -Identity $DlpPolicyName -ErrorAction SilentlyContinue

    if ($Remove) {
        if (-not $existing) { Write-Host "DLP policy '$DlpPolicyName' not found — nothing to remove." -ForegroundColor Yellow; return }
        if ($apply) { Remove-DlpCompliancePolicy -Identity $DlpPolicyName -Confirm:$false; Did "Removed DLP policy '$DlpPolicyName'." }
        else { Plan "Would run: Remove-DlpCompliancePolicy -Identity '$DlpPolicyName'" }
        return
    }

    # Promote/demote an existing policy's mode (deliberate, e.g. simulation -> Enable)
    if ($SetMode) {
        if (-not $existing) { Err "DLP policy '$DlpPolicyName' not found — create it in simulation first."; return }
        Write-Host "Current Mode = $($existing.Mode); requested = $SetMode"
        if ($apply) { Set-DlpCompliancePolicy -Identity $DlpPolicyName -Mode $SetMode; Did "Set DLP policy '$DlpPolicyName' Mode = $SetMode." }
        else { Plan "Would run: Set-DlpCompliancePolicy -Identity '$DlpPolicyName' -Mode $SetMode" }
        if ($SetMode -eq 'Enable' -and -not $apply) { Write-Host "Promotion to ENFORCE — ensure the pilot passed before -Commit." -ForegroundColor Cyan }
        return
    }

    # Create a new DLP control policy — ALWAYS in simulation (TestWithoutNotifications)
    if ($existing) { Write-Host "DLP policy '$DlpPolicyName' already exists (Mode = $($existing.Mode)). Use -SetMode to change it, or -Remove." -ForegroundColor Yellow; return }

    # Build the location/scope splat from -Workloads
    $loc = @{}
    if ($Workloads -contains 'Exchange')   { $loc['ExchangeLocation']   = 'All' }
    if ($Workloads -contains 'SharePoint') { $loc['SharePointLocation'] = 'All' }
    if ($Workloads -contains 'OneDrive')   { $loc['OneDriveLocation']   = 'All' }
    if ($Workloads -contains 'Teams')      { $loc['TeamsLocation']      = 'All' }
    if ($Workloads -contains 'Endpoint')   { $loc['EndpointDlpLocation'] = 'All' }
    # NOTE: 'All' is the broadest scope. For a true pilot, replace 'All' with the pilot site/group per your
    # tenant's supported scoping, and confirm the in-scope information types with compliance/security (2.4).

    if ($apply) {
        New-DlpCompliancePolicy -Name $DlpPolicyName -Comment $Description -Mode TestWithoutNotifications @loc | Out-Null
        Did "Created DLP policy '$DlpPolicyName' in SIMULATION (Mode = TestWithoutNotifications), workloads: $($Workloads -join ',')."
        Write-Host "NEXT: add a rule (New-DlpComplianceRule) with the in-scope sensitive-information-types/labels agreed with compliance/security." -ForegroundColor Cyan
        if ($PilotGroup) { Write-Host "Reminder: narrow location scope to '$PilotGroup' for a true pilot (default here is 'All')." -ForegroundColor Cyan }
        Get-DlpCompliancePolicy -Identity $DlpPolicyName | Format-List Name, Mode, Workload
    } else {
        Plan ("Would run: New-DlpCompliancePolicy -Name '$DlpPolicyName' -Mode TestWithoutNotifications " + (($loc.GetEnumerator() | ForEach-Object { "-$($_.Key) $($_.Value)" }) -join ' '))
        Plan "Then: New-DlpComplianceRule -Policy '$DlpPolicyName' -ContentContainsSensitiveInformation <in-scope types> (agree types with compliance/security)."
        Write-Host "`nNo changes made (default). New DLP is created in SIMULATION; promote to Enable only after the pilot passes." -ForegroundColor Cyan
    }
    return
}

Err "Specify one action: -EnableUnifiedAudit | -AuditRetentionName | -DlpPolicyName [-SetMode|-Remove]. See .EXAMPLE in the header."

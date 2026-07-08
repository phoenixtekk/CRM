<#
.SYNOPSIS
    PURVSOX-ConfigureControls.ps1 — create/update the SOX Purview controls; DLP in SIMULATION first (-WhatIf default).
.DESCRIPTION
    PURPOSE
        Configuration/remediation helper for the SOX-aligned Purview controls. With -EnableUnifiedAudit
        it turns unified audit ingestion on. With -Control it creates/updates/removes one control: a
        sensitivity Label, a scoped LabelPolicy, a DLP policy (created in TEST/SIMULATION mode), a
        Retention policy (period supplied by you — never invented), or an audit-log AuditRetention
        policy. SAFE BY DEFAULT: prints the exact change under -WhatIf; only writes with -Commit.
    HOW TO RUN
        # Enable the evidence foundation (preview then commit):
        .\PURVSOX-ConfigureControls.ps1 -EnableUnifiedAudit -WhatIf
        # Create the financial-data DLP policy in SIMULATION (preview then commit):
        .\PURVSOX-ConfigureControls.ps1 -Control Dlp -Name "DLP – SOX Financial Data – Simulation" `
            -Workloads SharePoint,OneDrive,Exchange -PilotUsers "financepilot@contoso.com" -WhatIf
        .\PURVSOX-ConfigureControls.ps1 -Control Dlp -Name "DLP – SOX Financial Data – Simulation" ... -Commit
        # Later, move DLP from simulation to enforce (after the pilot passes):
        .\PURVSOX-ConfigureControls.ps1 -Control Dlp -Name "DLP – SOX Financial Data – Simulation" -SetMode Enable -Commit
        Uses Exchange Online PowerShell for -EnableUnifiedAudit; Security & Compliance PowerShell
        (Connect-IPPSSession) for labels/DLP/retention/audit-retention. No secrets in code.
    EXPECTED RESULTS
        Under -WhatIf: the exact cmdlet(s) that would run and their parameters. Under -Commit: the
        control is created/updated/removed and the resulting object is printed. DLP is created in
        TestWithNotifications (simulation) unless you explicitly -SetMode Enable.
.NOTES
    Purview category — SOX Compliance Program. DLP MUST be piloted in simulation before enforce.
    Retention DURATION is your records/legal determination — supplied via -RetainDays; the script does
    not assume one. RetentionDuration values and any long-term audit tier are licensing-dependent;
    verify in your tenant before -Commit.
#>
[CmdletBinding()]
param(
    [switch]$EnableUnifiedAudit,

    [ValidateSet('Label','LabelPolicy','Dlp','Retention','AuditRetention')]
    [string]$Control,

    [string]$Name,                                  # the named artifact (use the standard names from the Overview)
    [string[]]$Workloads,                           # SharePoint, OneDrive, Exchange, Teams (per control)
    [string[]]$PilotUsers,                          # pilot-ring UPNs (label policy / DLP location scope)
    [string[]]$PilotSites,                          # pilot SharePoint site URLs (retention / DLP location scope)
    [string[]]$SensitiveInfoTypes,                  # optional: SIT names the DLP rule matches (e.g. 'Credit Card Number')
    [string]$MatchLabelName = 'Financial – SOX Reporting – Confidential', # DLP/retention keys off this label by default

    [ValidateSet('TestWithNotifications','TestWithoutNotifications','Enable','Disable')]
    [string]$SetMode = 'TestWithNotifications',     # DLP mode; SIMULATION by default, Enable only to enforce

    [int]$RetainDays,                               # retention period FROM YOUR RECORDS SCHEDULE (required for -Control Retention)
    [ValidateSet('Keep','KeepAndDelete','Delete')]
    [string]$RetentionAction = 'Keep',

    [string[]]$RecordTypes,                         # audit-retention record types (e.g. SharePointFileOperation, ExchangeItem)
    [string]$Duration = 'OneYear',                  # audit-retention duration; verify accepted values + licensing
    [int]$Priority,                                 # audit-retention unique priority (lower = first)

    [switch]$Remove,
    [string]$UserPrincipalName,
    [switch]$Commit
)

$ErrorActionPreference = 'Stop'
$apply = $Commit.IsPresent
function Plan($m){ Write-Host ("[WHATIF] {0}" -f $m) -ForegroundColor Yellow }
function Did($m){ Write-Host ("[COMMIT] {0}" -f $m) -ForegroundColor Green }
function Fail($m){ Write-Host $m -ForegroundColor Red }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Fail "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser"; return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$cp = @{ ShowBanner = $false }; if ($UserPrincipalName) { $cp['UserPrincipalName'] = $UserPrincipalName }

# ---------- Enable unified audit (Exchange Online) ----------
if ($EnableUnifiedAudit) {
    Connect-ExchangeOnline @cp | Out-Null
    $cur = (Get-AdminAuditLogConfig).UnifiedAuditLogIngestionEnabled
    Write-Host "Current UnifiedAuditLogIngestionEnabled = $cur"
    if ($cur) { Write-Host "Already enabled — nothing to do." -ForegroundColor Green; return }
    if ($apply) { Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true; Did "Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled `$true (activation can take time; NOT retroactive)." }
    else { Plan "Would run: Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled `$true" }
    return
}

if (-not $Control) { Fail "Provide -Control (Label|LabelPolicy|Dlp|Retention|AuditRetention) or use -EnableUnifiedAudit."; return }
if (-not $Name)    { Fail "Provide -Name (use the standard artifact name from the Overview)."; return }

# Labels/DLP/retention/audit-retention all live in Security & Compliance PowerShell
Connect-IPPSSession @cp | Out-Null

switch ($Control) {

    'Label' {
        $existing = Get-Label -Identity $Name -ErrorAction SilentlyContinue
        if ($Remove) {
            if (-not $existing) { Write-Host "Label '$Name' not found." -ForegroundColor Yellow; return }
            if ($apply) { Remove-Label -Identity $Name -Confirm:$false; Did "Removed label '$Name'." } else { Plan "Would run: Remove-Label -Identity '$Name'" }
            return
        }
        if ($existing) { Write-Host "Label '$Name' already exists — nothing to create." -ForegroundColor Green; return }
        if ($apply) { New-Label -Name $Name -DisplayName $Name -Tooltip "Financial reporting data in scope for SOX ICFR." | Out-Null; Did "Created sensitivity label '$Name' (publish it to the pilot with -Control LabelPolicy)." }
        else { Plan "Would run: New-Label -Name '$Name' -DisplayName '$Name' -Tooltip 'Financial reporting data in scope for SOX ICFR.'" }
    }

    'LabelPolicy' {
        $polName = "$Name – Policy"
        $existing = Get-LabelPolicy -Identity $polName -ErrorAction SilentlyContinue
        if ($Remove) {
            if (-not $existing) { Write-Host "Label policy '$polName' not found." -ForegroundColor Yellow; return }
            if ($apply) { Remove-LabelPolicy -Identity $polName -Confirm:$false; Did "Removed label policy '$polName'." } else { Plan "Would run: Remove-LabelPolicy -Identity '$polName'" }
            return
        }
        if (-not $PilotUsers) { Fail "Provide -PilotUsers to scope the label policy to the pilot ring (do not publish tenant-wide first)."; return }
        if ($apply) { New-LabelPolicy -Name $polName -Labels $Name -ExchangeLocation $PilotUsers | Out-Null; Did "Published label '$Name' to pilot users via '$polName'." }
        else { Plan "Would run: New-LabelPolicy -Name '$polName' -Labels '$Name' -ExchangeLocation $($PilotUsers -join ',')" }
    }

    'Dlp' {
        $existing = Get-DlpCompliancePolicy -Identity $Name -ErrorAction SilentlyContinue
        if ($Remove) {
            if (-not $existing) { Write-Host "DLP policy '$Name' not found." -ForegroundColor Yellow; return }
            if ($apply) { Remove-DlpCompliancePolicy -Identity $Name -Confirm:$false; Did "Removed DLP policy '$Name'." } else { Plan "Would run: Remove-DlpCompliancePolicy -Identity '$Name'" }
            return
        }
        # If it exists and -SetMode was supplied, change the mode (e.g. simulation -> enforce)
        if ($existing) {
            if ($apply) { Set-DlpCompliancePolicy -Identity $Name -Mode $SetMode; Did "Set DLP policy '$Name' Mode = $SetMode." ; Get-DlpCompliancePolicy -Identity $Name | Format-List Name,Mode,Workload }
            else { Plan "Would run: Set-DlpCompliancePolicy -Identity '$Name' -Mode $SetMode  (current Mode = $($existing.Mode))" }
            return
        }
        # Create NEW in simulation mode with locations, then a rule keyed off the SOX label / SITs
        if (-not $Workloads) { Fail "Provide -Workloads (e.g. SharePoint,OneDrive,Exchange) for a new DLP policy."; return }
        $mode = if ($SetMode -eq 'Enable') { 'TestWithNotifications' } else { $SetMode }  # never create straight into Enable
        $loc = @{}
        if ($Workloads -contains 'SharePoint') { $loc['SharePointLocation'] = @('All') }
        if ($Workloads -contains 'OneDrive')   { $loc['OneDriveLocation']   = @('All') }
        if ($Workloads -contains 'Exchange')   { $loc['ExchangeLocation']   = @('All') }
        if ($Workloads -contains 'Teams')      { $loc['TeamsLocation']      = @('All') }
        if ($apply) {
            New-DlpCompliancePolicy -Name $Name -Mode $mode @loc -Comment "SOX financial-data DLP — piloted in simulation." | Out-Null
            $ruleParams = @{ Name = "$Name – Rule"; Policy = $Name }
            if ($MatchLabelName)       { $ruleParams['ContentContainsSensitiveInformation'] = @(@{ groupName='SOX'; labels=@(@{ name=$MatchLabelName; type='Sensitivity' }) }) }
            elseif ($SensitiveInfoTypes){ $ruleParams['ContentContainsSensitiveInformation'] = @($SensitiveInfoTypes | ForEach-Object { @{ Name = $_ } }) }
            New-DlpComplianceRule @ruleParams | Out-Null
            Did "Created DLP policy '$Name' in SIMULATION ($mode) with a rule matching '$MatchLabelName'. Review simulation matches before moving to Enable."
            Get-DlpCompliancePolicy -Identity $Name | Format-List Name,Mode,Workload
        } else {
            Plan "Would run: New-DlpCompliancePolicy -Name '$Name' -Mode $mode $((($loc.GetEnumerator() | ForEach-Object { "-$($_.Key) All" }) -join ' '))"
            Plan "Would run: New-DlpComplianceRule -Name '$Name – Rule' -Policy '$Name' -ContentContainsSensitiveInformation (label '$MatchLabelName' or SITs: $($SensitiveInfoTypes -join ','))"
            Write-Host "NOTE: new DLP policies are created in TEST/SIMULATION mode; use -SetMode Enable only after the pilot passes." -ForegroundColor Cyan
        }
    }

    'Retention' {
        $existing = Get-RetentionCompliancePolicy -Identity $Name -ErrorAction SilentlyContinue
        if ($Remove) {
            if (-not $existing) { Write-Host "Retention policy '$Name' not found." -ForegroundColor Yellow; return }
            if ($apply) { Remove-RetentionCompliancePolicy -Identity $Name -Confirm:$false; Did "Removed retention policy '$Name'." } else { Plan "Would run: Remove-RetentionCompliancePolicy -Identity '$Name'" }
            return
        }
        if (-not $PSBoundParameters.ContainsKey('RetainDays')) { Fail "Provide -RetainDays from YOUR RECORDS/LEGAL SCHEDULE — the script does not assume a SOX retention period."; return }
        if (-not $PilotSites) { Fail "Provide -PilotSites (SharePoint site URLs) to scope retention to the pilot (do not apply org-wide first)."; return }
        if ($apply) {
            New-RetentionCompliancePolicy -Name $Name -SharePointLocation $PilotSites -Comment "SOX financial records retention — period set by records schedule." | Out-Null
            New-RetentionComplianceRule -Name "$Name – Rule" -Policy $Name -RetentionDuration $RetainDays -RetentionComplianceAction $RetentionAction | Out-Null
            Did "Created retention policy '$Name' ($RetentionAction $RetainDays days) scoped to the pilot sites."
        } else {
            Plan "Would run: New-RetentionCompliancePolicy -Name '$Name' -SharePointLocation $($PilotSites -join ',')"
            Plan "Would run: New-RetentionComplianceRule -Name '$Name – Rule' -Policy '$Name' -RetentionDuration $RetainDays -RetentionComplianceAction $RetentionAction"
            Write-Host "NOTE: $RetainDays days must come from your records/legal schedule — disposition/file-plan determinations are deferred." -ForegroundColor Cyan
        }
    }

    'AuditRetention' {
        $existing = Get-UnifiedAuditLogRetentionPolicy -Identity $Name -ErrorAction SilentlyContinue
        if ($Remove) {
            if (-not $existing) { Write-Host "Audit retention policy '$Name' not found." -ForegroundColor Yellow; return }
            if ($apply) { Remove-UnifiedAuditLogRetentionPolicy -Identity $Name -Confirm:$false; Did "Removed audit retention policy '$Name'." } else { Plan "Would run: Remove-UnifiedAuditLogRetentionPolicy -Identity '$Name'" }
            return
        }
        if (-not $RecordTypes) { Fail "Provide -RecordTypes (e.g. SharePointFileOperation,ExchangeItem)."; return }
        if (-not $PSBoundParameters.ContainsKey('Priority')) { Fail "Provide a unique -Priority (lower = evaluated first)."; return }
        $p = @{ RecordTypes = $RecordTypes; RetentionDuration = $Duration; Priority = $Priority; Description = 'SOX financial-data access/change audit retention.' }
        if ($existing) {
            if ($apply) { Set-UnifiedAuditLogRetentionPolicy -Identity $Name @p; Did "Updated audit retention policy '$Name'." ; Get-UnifiedAuditLogRetentionPolicy -Identity $Name | Format-List Name,RecordTypes,RetentionDuration,Priority }
            else { Plan "Would run: Set-UnifiedAuditLogRetentionPolicy -Identity '$Name' -RecordTypes $($RecordTypes -join ',') -RetentionDuration $Duration -Priority $Priority" }
        } else {
            if ($apply) { New-UnifiedAuditLogRetentionPolicy -Name $Name @p; Did "Created audit retention policy '$Name'." ; Get-UnifiedAuditLogRetentionPolicy -Identity $Name | Format-List Name,RecordTypes,RetentionDuration,Priority }
            else { Plan "Would run: New-UnifiedAuditLogRetentionPolicy -Name '$Name' -RecordTypes $($RecordTypes -join ',') -RetentionDuration $Duration -Priority $Priority" }
        }
        if (-not $apply) { Write-Host "NOTE: verify accepted RetentionDuration values and any long-term tier licensing in your tenant before -Commit." -ForegroundColor Cyan }
    }
}

if (-not $apply) { Write-Host "`nNo changes made (default). Re-run with -Commit to apply. Pilot-first; keep DLP in simulation until validated." -ForegroundColor Cyan }

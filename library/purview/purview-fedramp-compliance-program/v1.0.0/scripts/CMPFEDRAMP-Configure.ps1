<#
.SYNOPSIS
    CMPFEDRAMP-Configure.ps1 — create label/DLP/audit/retention controls, pilot-in-simulation/test first (-WhatIf default; writes on -Commit).
.DESCRIPTION
    PURPOSE
        Configures one FedRAMP control domain at a time (-Control Label|DLP|Audit|Retention) using
        Security & Compliance PowerShell. SAFE BY DEFAULT: prints the exact cmdlet it WOULD run and makes
        NO change unless -Commit is passed. DLP is ALWAYS created in TEST/simulation mode (no blocking);
        switching it to enforce (Enable) requires the explicit -Enforce switch AND sign-off. Sensitivity
        labels are created without encryption unless you add it per your design (encryption changes
        access — pilot on benign content first). No secrets in code.
    HOW TO RUN
        # 1) Sensitivity label + publish policy — preview then commit:
        .\CMPFEDRAMP-Configure.ps1 -Control Label -WhatIf
        .\CMPFEDRAMP-Configure.ps1 -Control Label -Publish -PilotScope "FedRAMP Pilot – Controlled Data – Stage1" -Commit
        # 2) DLP policy IN TEST/simulation (no blocking):
        .\CMPFEDRAMP-Configure.ps1 -Control DLP -PilotScope "FedRAMP Pilot – Controlled Data – Stage1" -WhatIf
        # 2b) After the pilot passes AND sign-off — switch DLP to enforce:
        .\CMPFEDRAMP-Configure.ps1 -Control DLP -Enforce -WhatIf
        # 3) Audit evidence retention:
        .\CMPFEDRAMP-Configure.ps1 -Control Audit -PolicyName "Audit Retention – FedRAMP Evidence – LongTerm" -RecordTypes AzureActiveDirectory -Duration TenYears -Priority 150 -WhatIf
        # 4) Controlled-records retention:
        .\CMPFEDRAMP-Configure.ps1 -Control Retention -PilotScope "FedRAMP Pilot – Controlled Data – Stage1" -WhatIf
        Requires ExchangeOnlineManagement (Connect-IPPSSession). Interactive modern-auth / MFA admin.
    EXPECTED RESULTS
        -WhatIf prints each intended create/remove/change with no change. -Commit performs it and re-reads
        the object. PASS = object exists as intended (DLP in TEST until -Enforce). Remove objects with
        -Remove. Switching DLP to Enable can block users — do it only under sign-off.
.NOTES
    Purview category — FedRAMP Compliance Program. High-impact: DLP, encryption labels, and retention are
    piloted in simulation/test/disabled mode first. Baseline, NIST 800-53 applicability, DLP conditions,
    and retention durations are security/compliance/legal determinations — supplied by you, not invented
    here. No certification/ATO asserted. Verify cmdlet/plan availability for your tenant.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Label','DLP','Audit','Retention')][string]$Control,

    # --- Label ---
    [string]$LabelName = 'Protect – FedRAMP Controlled – Confidential',
    [switch]$Publish,                                    # also create/publish the label policy
    [string]$LabelPolicyName = 'Protect – FedRAMP Controlled – Publish',

    # --- DLP ---
    [string]$DlpPolicyName = 'DLP – FedRAMP Controlled – Simulate',
    [string]$DlpMode = 'TestWithoutNotifications',        # TEST/simulation default (no blocking)
    [switch]$Enforce,                                     # switch existing DLP policy to -Mode Enable (requires sign-off)
    [string[]]$SensitiveInfoTypes = @('U.S. Social Security Number (SSN)'),  # example match — replace per your controlled-data definition

    # --- Audit ---
    [string]$PolicyName,
    [string[]]$RecordTypes = @('AzureActiveDirectory'),
    [string[]]$Operations,
    [string]$Duration = 'TenYears',
    [int]$Priority = 150,

    # --- Retention ---
    [string]$RetentionPolicyName = 'Retention – FedRAMP Records – Publish',
    [string]$RetentionDuration = 'SevenYears',

    # --- Common ---
    [string]$PilotScope = 'FedRAMP Pilot – Controlled Data – Stage1',
    [switch]$Remove,
    [switch]$WhatIf,
    [switch]$Commit
)

$ErrorActionPreference = 'Stop'
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }
function Info($m){ Write-Host $m -ForegroundColor Cyan }
function Would($m){ Write-Host "  [WhatIf] WOULD: $m" -ForegroundColor Magenta }

if ($Commit -and $WhatIf) { Warn "Both -Commit and -WhatIf passed; -WhatIf wins (no changes will be made)."; $Commit = $false }
$doCommit = $Commit.IsPresent -and -not $WhatIf
if (-not $doCommit) { Info "SAFE MODE (-WhatIf / no -Commit): no changes will be made." }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Warn "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser"; return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Connect-IPPSSession -ErrorAction Stop | Out-Null } catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message)"; return }

switch ($Control) {

    'Label' {
        Warn "Sensitivity labels support ENCRYPTION, which changes who can open content. This helper creates the label WITHOUT encryption; add encryption per your design and pilot on benign content first."
        if ($Remove) {
            $cmdP = "Remove-LabelPolicy -Identity '$LabelPolicyName'"; $cmdL = "Remove-Label -Identity '$LabelName'"
            if ($doCommit) {
                try { Remove-LabelPolicy -Identity $LabelPolicyName -Confirm:$false -ErrorAction Stop; Ok "Removed label policy: $LabelPolicyName" } catch { Warn $_.Exception.Message }
                try { Remove-Label -Identity $LabelName -Confirm:$false -ErrorAction Stop; Ok "Removed label: $LabelName" } catch { Warn $_.Exception.Message }
            } else { Would $cmdP; Would $cmdL }
            break
        }
        $cmdL = "New-Label -Name 'FedRAMPControlled' -DisplayName '$LabelName' -Tooltip 'Controlled data (FedRAMP / NIST 800-53 AC/MP/SC)'"
        if ($doCommit) {
            Info "Creating sensitivity label '$LabelName' (no encryption; add per design) ..."
            New-Label -Name 'FedRAMPControlled' -DisplayName $LabelName -Tooltip 'Controlled data (FedRAMP / NIST 800-53 AC/MP/SC)' -ErrorAction Stop | Out-Null
            Ok "Created label: $LabelName"
        } else { Would $cmdL }
        if ($Publish) {
            $cmdLP = "New-LabelPolicy -Name '$LabelPolicyName' -Labels '$LabelName' (scope to pilot: $PilotScope)"
            if ($doCommit) {
                Info "Publishing label via policy '$LabelPolicyName' (scope to your pilot locations/users, not All) ..."
                New-LabelPolicy -Name $LabelPolicyName -Labels $LabelName -ErrorAction Stop | Out-Null
                Ok "Created label policy: $LabelPolicyName — now scope it to the pilot in-portal or via Set-LabelPolicy."
            } else { Would $cmdLP; Warn "In production, scope the label policy to the pilot users/locations, not All." }
        }
    }

    'DLP' {
        if ($Enforce) {
            Warn "ENFORCE requested: switching '$DlpPolicyName' to -Mode Enable. This can BLOCK user actions. Only proceed after the test/simulation pilot passes and security/compliance sign off."
            $cmd = "Set-DlpCompliancePolicy -Identity '$DlpPolicyName' -Mode Enable"
            if ($doCommit) {
                Set-DlpCompliancePolicy -Identity $DlpPolicyName -Mode Enable -ErrorAction Stop | Out-Null
                Ok "Switched DLP policy to ENFORCE (Enable): $DlpPolicyName"
            } else { Would $cmd }
            break
        }
        if ($Remove) {
            $cmd = "Remove-DlpCompliancePolicy -Identity '$DlpPolicyName'"
            if ($doCommit) { try { Remove-DlpCompliancePolicy -Identity $DlpPolicyName -Confirm:$false -ErrorAction Stop; Ok "Removed DLP policy: $DlpPolicyName" } catch { Warn $_.Exception.Message } }
            else { Would $cmd }
            break
        }
        Warn "DLP will be created in TEST/simulation mode ('$DlpMode') — it MATCHES and REPORTS but does NOT block. Conditions/sensitive info types are your controlled-data definition (security/compliance's determination)."
        $ruleName = "$DlpPolicyName Rule"
        $sit = $SensitiveInfoTypes -join ', '
        $cmdP = "New-DlpCompliancePolicy -Name '$DlpPolicyName' -Mode $DlpMode -ExchangeLocation All/SharePointLocation All (scope to pilot: $PilotScope)"
        $cmdR = "New-DlpComplianceRule -Name '$ruleName' -Policy '$DlpPolicyName' -ContentContainsSensitiveInformation @(SITs: $sit)"
        if ($doCommit) {
            Info "Creating DLP policy '$DlpPolicyName' in TEST/simulation mode '$DlpMode' ..."
            # NOTE: scope to the pilot locations in production; 'All' shown for the pilot-preview only.
            New-DlpCompliancePolicy -Name $DlpPolicyName -Mode $DlpMode -ExchangeLocation All -SharePointLocation All -ErrorAction Stop | Out-Null
            Ok "Created DLP policy (TEST/simulation — no blocking): $DlpPolicyName"
            Info "Creating matching rule '$ruleName' (edit the sensitive info types / label to your controlled-data definition) ..."
            $sitObjects = $SensitiveInfoTypes | ForEach-Object { @{ Name = $_ } }
            New-DlpComplianceRule -Name $ruleName -Policy $DlpPolicyName -ContentContainsSensitiveInformation $sitObjects -ErrorAction Stop | Out-Null
            Ok "Created DLP rule (test/simulation): $ruleName — review DLP simulation/overview results before enforcing."
        } else { Would $cmdP; Would $cmdR; Warn "In production, scope the DLP policy to the pilot locations, not All; keep it in TEST until sign-off, then -Enforce." }
    }

    'Audit' {
        if (-not $PolicyName) { $PolicyName = 'Audit Retention – FedRAMP Evidence – LongTerm' }
        if ($Remove) {
            $cmd = "Remove-UnifiedAuditLogRetentionPolicy -Identity '$PolicyName'"
            if ($doCommit) { try { Remove-UnifiedAuditLogRetentionPolicy -Identity $PolicyName -Confirm:$false -ErrorAction Stop; Ok "Removed audit retention policy: $PolicyName" } catch { Warn $_.Exception.Message } }
            else { Would $cmd }
            break
        }
        $opPart = if ($Operations) { " -Operations $($Operations -join ',')" } else { '' }
        $cmd = "New-UnifiedAuditLogRetentionPolicy -Name '$PolicyName' -RecordTypes $($RecordTypes -join ',')$opPart -RetentionDuration $Duration -Priority $Priority"
        Warn "VERIFY accepted -RetentionDuration values and that the long-term tier ($Duration) is licensed in your tenant before committing."
        if ($doCommit) {
            Info "Creating audit evidence retention policy '$PolicyName' (NIST AU) ..."
            $p = @{ Name=$PolicyName; RecordTypes=$RecordTypes; RetentionDuration=$Duration; Priority=$Priority }
            if ($Operations) { $p['Operations'] = $Operations }
            New-UnifiedAuditLogRetentionPolicy @p -ErrorAction Stop | Out-Null
            Ok "Created audit retention policy: $PolicyName"
        } else { Would $cmd }
    }

    'Retention' {
        if ($Remove) {
            $cmd = "Remove-RetentionCompliancePolicy -Identity '$RetentionPolicyName'"
            if ($doCommit) { try { Remove-RetentionCompliancePolicy -Identity $RetentionPolicyName -Confirm:$false -ErrorAction Stop; Ok "Removed retention policy: $RetentionPolicyName" } catch { Warn $_.Exception.Message } }
            else { Would $cmd }
            break
        }
        $ruleName = "$RetentionPolicyName Rule"
        $cmdP = "New-RetentionCompliancePolicy -Name '$RetentionPolicyName' -ExchangeLocation All/SharePointLocation All (scope to pilot: $PilotScope)"
        $cmdR = "New-RetentionComplianceRule -Name '$ruleName' -Policy '$RetentionPolicyName' -RetentionDuration $RetentionDuration -RetentionComplianceAction Keep"
        Warn "Retention duration is a compliance determination. Scope to the pilot locations, not All, in production."
        if ($doCommit) {
            Info "Creating controlled-records retention policy '$RetentionPolicyName' ..."
            New-RetentionCompliancePolicy -Name $RetentionPolicyName -ExchangeLocation All -SharePointLocation All -ErrorAction Stop | Out-Null
            New-RetentionComplianceRule -Name $ruleName -Policy $RetentionPolicyName -RetentionDuration $RetentionDuration -RetentionComplianceAction Keep -ErrorAction Stop | Out-Null
            Ok "Created retention policy + rule: $RetentionPolicyName"
        } else { Would $cmdP; Would $cmdR }
    }
}

Write-Host "`nDone. Re-run CMPFEDRAMP-Discovery.ps1 / CMPFEDRAMP-Validate.ps1 to confirm state." -ForegroundColor White

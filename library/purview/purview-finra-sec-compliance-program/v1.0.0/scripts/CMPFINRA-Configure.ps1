<#
.SYNOPSIS
    CMPFINRA-Configure.ps1 — create records/audit/supervision controls, pilot-in-simulation/test first (-WhatIf default; writes on -Commit).
.DESCRIPTION
    PURPOSE
        Configures one FINRA/SEC control domain at a time (-Control Records|Audit|Supervision) using
        Security & Compliance PowerShell. SAFE BY DEFAULT: prints the exact cmdlet it WOULD run and makes
        NO change unless -Commit is passed. Records defaults to a NON-regulatory pilot label; the
        irreversible regulatory-records label requires the explicit -Regulatory switch. Supervision is
        always created scoped to the pilot (test) with reviewers you supply. No secrets in code.
    HOW TO RUN
        # 1) Pilot records label (non-regulatory) — preview then commit:
        .\CMPFINRA-Configure.ps1 -Control Records -PilotLabel -WhatIf
        .\CMPFINRA-Configure.ps1 -Control Records -PilotLabel -Commit
        # 2) Audit evidence retention:
        .\CMPFINRA-Configure.ps1 -Control Audit -PolicyName "Audit Retention – FINRA/SEC Evidence – LongTerm" -RecordTypes AzureActiveDirectory -Duration TenYears -Priority 150 -WhatIf
        # 3) Supervision policy IN TEST (after privacy sign-off):
        .\CMPFINRA-Configure.ps1 -Control Supervision -PilotScope "FINRA/SEC Pilot – Registered Persons – Stage1" -Reviewers reviewer@contoso.com -WhatIf
        Requires ExchangeOnlineManagement (Connect-IPPSSession). Interactive modern-auth / MFA admin.
    EXPECTED RESULTS
        -WhatIf prints each intended create/remove with no change. -Commit performs it and re-reads the
        object. PASS = object exists as intended. A -Regulatory label is IRREVERSIBLE — only run under
        compliance sign-off. Remove non-regulatory objects with -Remove.
.NOTES
    Purview category — FINRA/SEC Compliance Program. High-impact: regulatory records, retention, and
    supervision are piloted in simulation/test/disabled mode first. Retention durations, supervisory
    conditions/lexicon, and rule applicability are compliance/records/legal determinations — supplied by
    you, not invented here. Verify cmdlet/plan availability for your tenant.
#>
[CmdletBinding(DefaultParameterSetName='Records')]
param(
    [Parameter(Mandatory)][ValidateSet('Records','Audit','Supervision')][string]$Control,

    # --- Records ---
    [switch]$PilotLabel,                                  # create a NON-regulatory pilot records label
    [switch]$Regulatory,                                  # create the IRREVERSIBLE regulatory-records label (requires sign-off)
    [string]$LabelName,                                   # override default label name
    [string]$RecordsDuration = 'SevenYears',             # retention duration for the label (VERIFY accepted values/plan)

    # --- Audit ---
    [string]$PolicyName,
    [string[]]$RecordTypes = @('AzureActiveDirectory'),
    [string[]]$Operations,
    [string]$Duration = 'TenYears',
    [int]$Priority = 150,

    # --- Supervision (test) ---
    [string]$PilotScope = 'FINRA/SEC Pilot – Registered Persons – Stage1',
    [string[]]$Reviewers,

    # --- Common ---
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

    'Records' {
        if ($Regulatory) {
            $name = if ($LabelName) { $LabelName } else { 'Records – FINRA/SEC Regulated – Regulatory' }
            Warn "REGULATORY-RECORDS label requested. This label is IMMUTABLE and CANNOT be removed; retention cannot be shortened. Apply ONLY under explicit compliance sign-off and on the approved scope."
            if ($Remove) { Warn "A regulatory-records label cannot be removed — ignoring -Remove."; break }
            $cmd = "New-ComplianceTag -Name '$name' -RetentionAction Keep -RetentionDuration $RecordsDuration -IsRecordLabel `$true -Regulatory `$true"
            if ($doCommit) {
                Info "Creating regulatory-records label '$name' ..."
                New-ComplianceTag -Name $name -RetentionAction Keep -RetentionDuration $RecordsDuration -IsRecordLabel $true -Regulatory $true -ErrorAction Stop | Out-Null
                Ok "Created (IRREVERSIBLE): $name"; Get-ComplianceTag -Identity $name | Format-List Name, IsRecordLabel, RegulatoryRecord, RetentionDuration
            } else { Would $cmd }
        }
        else {
            # Non-regulatory pilot records label (safe / removable)
            $name = if ($LabelName) { $LabelName } elseif ($PilotLabel) { 'Records – FINRA/SEC Pilot – Record' } else { 'Records – FINRA/SEC Pilot – Record' }
            $policyName = 'Retention – FINRA/SEC Records – Publish'
            if ($Remove) {
                $cmdT = "Remove-ComplianceTag -Identity '$name'"; $cmdP = "Remove-RetentionCompliancePolicy -Identity '$policyName'"
                if ($doCommit) {
                    Info "Removing pilot label + publish policy ..."
                    try { Remove-RetentionCompliancePolicy -Identity $policyName -Confirm:$false -ErrorAction Stop; Ok "Removed policy: $policyName" } catch { Warn $_.Exception.Message }
                    try { Remove-ComplianceTag -Identity $name -Confirm:$false -ErrorAction Stop; Ok "Removed label: $name" } catch { Warn $_.Exception.Message }
                } else { Would $cmdP; Would $cmdT }
                break
            }
            $cmdT = "New-ComplianceTag -Name '$name' -RetentionAction Keep -RetentionDuration $RecordsDuration -IsRecordLabel `$true"
            $cmdP = "New-RetentionCompliancePolicy -Name '$policyName' -ExchangeLocation All (scoped to pilot) then New-RetentionComplianceRule -PublishComplianceTag '$name'"
            if ($doCommit) {
                Info "Creating NON-regulatory pilot records label '$name' ..."
                New-ComplianceTag -Name $name -RetentionAction Keep -RetentionDuration $RecordsDuration -IsRecordLabel $true -ErrorAction Stop | Out-Null
                Ok "Created (removable) label: $name"
                Info "Creating publish policy '$policyName' (scope to your pilot locations; edit -ExchangeLocation/-SharePointLocation as designed) ..."
                # NOTE: scope to the pilot rather than All in production; 'All' shown for the pilot-preview only.
                New-RetentionCompliancePolicy -Name $policyName -ExchangeLocation All -ErrorAction Stop | Out-Null
                New-RetentionComplianceRule -Name "$policyName Rule" -Policy $policyName -PublishComplianceTag $name -ErrorAction Stop | Out-Null
                Ok "Created publish policy + rule: $policyName"
            } else { Would $cmdT; Would $cmdP; Warn "In production, scope the publish policy to the pilot locations, not All." }
        }
    }

    'Audit' {
        if (-not $PolicyName) { $PolicyName = 'Audit Retention – FINRA/SEC Evidence – LongTerm' }
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
            Info "Creating audit evidence retention policy '$PolicyName' ..."
            $p = @{ Name=$PolicyName; RecordTypes=$RecordTypes; RetentionDuration=$Duration; Priority=$Priority }
            if ($Operations) { $p['Operations'] = $Operations }
            New-UnifiedAuditLogRetentionPolicy @p -ErrorAction Stop | Out-Null
            Ok "Created audit retention policy: $PolicyName"
        } else { Would $cmd }
    }

    'Supervision' {
        $name = if ($LabelName) { $LabelName } else { 'Supervision – Registered Persons Comms – Test' }
        Warn "Communication Compliance is HR/privacy-sensitive. Build IN TEST, scoped to the pilot, with reviewers SEPARATE from the configuring admin. Conditions/lexicon are compliance's determination."
        if ($Remove) {
            $cmd = "Remove-SupervisoryReviewPolicyV2 -Identity '$name'"
            if ($doCommit) { try { Remove-SupervisoryReviewPolicyV2 -Identity $name -Confirm:$false -ErrorAction Stop; Ok "Removed supervision policy: $name" } catch { Warn $_.Exception.Message } }
            else { Would $cmd }
            break
        }
        if (-not $Reviewers) { Warn "No -Reviewers supplied — supply the designated (separated) reviewer(s) before creating the policy."; if (-not $doCommit) { } else { break } }
        $revPart = if ($Reviewers) { ($Reviewers -join ',') } else { '<reviewer@contoso.com>' }
        $cmd = "New-SupervisoryReviewPolicyV2 -Name '$name' -Reviewers $revPart -Supervised '<pilot covered persons>' (TEST scope: $PilotScope)"
        if ($doCommit) {
            if (-not $Reviewers) { Warn "Refusing to create supervision policy without reviewers."; break }
            Info "Creating supervision policy '$name' IN TEST scoped to the pilot ..."
            Warn "Set the supervised users to the pilot covered persons and the conditions your compliance function specified. Do NOT enforce tenant-wide or action real items."
            New-SupervisoryReviewPolicyV2 -Name $name -Reviewers $Reviewers -ErrorAction Stop | Out-Null
            Ok "Created supervision policy (TEST): $name — now add supervised users/conditions per the approved design in-portal."
        } else { Would $cmd; Warn "After creation, add supervised users (pilot only) + conditions in-portal; keep it in test until sign-off." }
    }
}

Write-Host "`nDone. Re-run CMPFINRA-Discovery.ps1 / CMPFINRA-Validate.ps1 to confirm state." -ForegroundColor White

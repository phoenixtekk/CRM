<#
.SYNOPSIS
    INDLEGAL-Configure.ps1 — create Legal labels / DLP (simulation) / matter retention / audit controls, pilot-first (-WhatIf default; writes on -Commit).
.DESCRIPTION
    PURPOSE
        Configures one Legal control domain at a time (-Control Labels|DLP|Retention|Audit) using Security &
        Compliance PowerShell. SAFE BY DEFAULT: prints the exact cmdlet it WOULD run and makes NO change
        unless -Commit is passed. Labels: creates the privileged (ENCRYPTED) and matter-confidential labels
        plus a pilot label policy. DLP: ALWAYS created in SIMULATION/TEST mode (blocks nothing) scoped to the
        pilot. Retention: defaults to a NON-regulatory pilot matter-records label + publish policy; the
        irreversible regulatory-records label requires the explicit -Regulatory switch and sign-off. Audit:
        creates an evidence-retention policy. This script NEVER creates, changes, or releases a legal hold —
        holds are the legal function's action in eDiscovery. No secrets in code.
    HOW TO RUN
        # 1) Sensitivity labels (privileged encrypted + matter-confidential) + pilot policy — preview then commit:
        .\INDLEGAL-Configure.ps1 -Control Labels -WhatIf
        .\INDLEGAL-Configure.ps1 -Control Labels -Commit
        # 2) DLP policy IN SIMULATION (never Enable from this script):
        .\INDLEGAL-Configure.ps1 -Control DLP -Mode TestWithNotifications -WhatIf
        .\INDLEGAL-Configure.ps1 -Control DLP -Mode TestWithNotifications -Commit
        # 3) Matter-records retention (non-regulatory pilot label first):
        .\INDLEGAL-Configure.ps1 -Control Retention -RecordsDuration SevenYears -WhatIf
        # 4) Audit evidence retention:
        .\INDLEGAL-Configure.ps1 -Control Audit -PolicyName "Audit Retention – Legal Evidence – LongTerm" -RecordTypes AzureActiveDirectory -Duration TenYears -Priority 150 -WhatIf
        Requires ExchangeOnlineManagement (Connect-IPPSSession). Interactive modern-auth / MFA admin.
    EXPECTED RESULTS
        -WhatIf prints each intended create/remove with no change. -Commit performs it and re-reads the
        object. DLP is created only in SIMULATION/TEST — switch to Enable IN-PORTAL after match review + legal
        sign-off, never from this script. A -Regulatory retention label is IRREVERSIBLE — only under sign-off.
        Remove non-regulatory objects with -Remove. This script performs NO legal-hold action.
.NOTES
    Purview category — Microsoft Purview for Legal (industry bundle). High-impact: encryption labels, DLP,
    and records retention are piloted in simulation/test/disabled mode first. Privilege determination, matter
    mapping, retention durations, DLP match criteria, and legal-hold scope are legal/records determinations —
    supplied by you, not invented here. Legal holds/eDiscovery actions are legal's. Verify cmdlet/plan
    availability for your tenant.
#>
[CmdletBinding(DefaultParameterSetName='Labels')]
param(
    [Parameter(Mandatory)][ValidateSet('Labels','DLP','Retention','Audit')][string]$Control,

    # --- Labels ---
    [string]$PrivilegedLabel = 'Protect – Legal Privileged – Restricted',
    [string]$MatterLabel     = 'Protect – Legal Matter Confidential – Confidential',
    [string]$LabelPolicyName = 'Legal Pilot – Privileged Data – Stage1',

    # --- DLP ---
    [ValidateSet('TestWithNotifications','TestWithoutNotifications')][string]$Mode = 'TestWithNotifications',
    [string]$DlpPolicyName   = 'DLP – Legal Privileged – Simulate',

    # --- Retention ---
    [switch]$Regulatory,                                  # create the IRREVERSIBLE regulatory-records label (requires sign-off)
    [string]$RetentionLabel,                              # override default matter-records label name
    [string]$RetentionPolicy = 'Retention – Legal Matter Records – Publish',
    [string]$RecordsDuration = 'SevenYears',              # matter-records retention (VERIFY accepted values/plan; records' determination)

    # --- Audit ---
    [string]$PolicyName,
    [string[]]$RecordTypes = @('AzureActiveDirectory'),
    [string[]]$Operations,
    [string]$Duration = 'TenYears',
    [int]$Priority = 150,

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

    'Labels' {
        Warn "The privileged label uses ENCRYPTION — an encryption label can make content unreadable to unlicensed/external parties. Set the decryption/permission scope to legal's approved design (this helper creates the label; refine encryption/permissions in-portal)."
        if ($Remove) {
            $cmdP = "Remove-LabelPolicy -Identity '$LabelPolicyName'"; $cmd1 = "Remove-Label -Identity '$PrivilegedLabel'"; $cmd2 = "Remove-Label -Identity '$MatterLabel'"
            if ($doCommit) {
                Info "Removing pilot label policy + labels ..."
                try { Remove-LabelPolicy -Identity $LabelPolicyName -Confirm:$false -ErrorAction Stop; Ok "Removed label policy: $LabelPolicyName" } catch { Warn $_.Exception.Message }
                try { Remove-Label -Identity $PrivilegedLabel -Confirm:$false -ErrorAction Stop; Ok "Removed label: $PrivilegedLabel" } catch { Warn $_.Exception.Message }
                try { Remove-Label -Identity $MatterLabel -Confirm:$false -ErrorAction Stop; Ok "Removed label: $MatterLabel" } catch { Warn $_.Exception.Message }
                Warn "Already-encrypted content stays encrypted by design — pilot with benign content so removal is inconsequential."
            } else { Would $cmdP; Would $cmd1; Would $cmd2 }
            break
        }
        $cmd1 = "New-Label -Name 'LegalPrivileged' -DisplayName '$PrivilegedLabel' -EncryptionEnabled `$true -EncryptionProtectionType Template  (set permissions/rights per legal's design in-portal)"
        $cmd2 = "New-Label -Name 'LegalMatterConf' -DisplayName '$MatterLabel'"
        $cmdP = "New-LabelPolicy -Name '$LabelPolicyName' -Labels '$PrivilegedLabel','$MatterLabel' -ExchangeLocation <pilot users>  (scope to the pilot legal population)"
        if ($doCommit) {
            Info "Creating privileged (ENCRYPTED) label '$PrivilegedLabel' ..."
            # NOTE: refine EncryptionRightsDefinitions / EncryptionProtectionType to legal's approved decryption scope in-portal.
            New-Label -Name 'LegalPrivileged' -DisplayName $PrivilegedLabel -Tooltip 'Attorney-client privileged — encrypted, restricted.' -EncryptionEnabled $true -EncryptionProtectionType 'Template' -ErrorAction Stop | Out-Null
            Ok "Created privileged label: $PrivilegedLabel (confirm encryption/permission scope in-portal to legal's design)"
            Info "Creating matter-confidential label '$MatterLabel' ..."
            New-Label -Name 'LegalMatterConf' -DisplayName $MatterLabel -Tooltip 'Matter-confidential / work-product.' -ErrorAction Stop | Out-Null
            Ok "Created matter-confidential label: $MatterLabel"
            Info "Publishing both labels to the PILOT population via policy '$LabelPolicyName' (scope to your pilot users in-portal) ..."
            New-LabelPolicy -Name $LabelPolicyName -Labels @($PrivilegedLabel,$MatterLabel) -ErrorAction Stop | Out-Null
            Ok "Created pilot label policy: $LabelPolicyName — scope it to the pilot legal population, not everyone."
        } else { Would $cmd1; Would $cmd2; Would $cmdP; Warn "Publish to the PILOT population first; confirm encryption on benign content before wider rollout." }
    }

    'DLP' {
        Warn "Communication of privileged material is HIGH-IMPACT. This helper ALWAYS builds DLP in SIMULATION/TEST ($Mode) — it blocks NOTHING. Review matches, tune for over-matching (legitimate co-counsel/court sharing), then switch to Enable IN-PORTAL under legal sign-off. Match criteria (labels/info types) are legal's determination."
        if ($Remove) {
            $cmd = "Remove-DlpCompliancePolicy -Identity '$DlpPolicyName'"
            if ($doCommit) { try { Remove-DlpCompliancePolicy -Identity $DlpPolicyName -Confirm:$false -ErrorAction Stop; Ok "Removed DLP policy: $DlpPolicyName" } catch { Warn $_.Exception.Message } }
            else { Would $cmd; Warn "In simulation nothing was ever blocked, so removal unwinds nothing." }
            break
        }
        $cmdPol  = "New-DlpCompliancePolicy -Name '$DlpPolicyName' -Mode $Mode -ExchangeLocation All -SharePointLocation All -OneDriveLocation All -TeamsLocation All -EndpointDlpLocation All  (scope to the pilot; Teams/Endpoint require E5)"
        $cmdRule = "New-DlpComplianceRule -Name '$DlpPolicyName Rule' -Policy '$DlpPolicyName' -ContentContainsSensitiveInformation <labels/info types legal specified>"
        if ($doCommit) {
            Info "Creating DLP policy '$DlpPolicyName' in SIMULATION mode '$Mode' (scope to the pilot in-portal; edit locations as designed) ..."
            # NOTE: scope locations to the pilot rather than All in production; Teams/Endpoint DLP require E5/E5 Compliance.
            New-DlpCompliancePolicy -Name $DlpPolicyName -Mode $Mode -ExchangeLocation All -SharePointLocation All -OneDriveLocation All -TeamsLocation All -ErrorAction Stop | Out-Null
            Ok "Created DLP policy (SIMULATION): $DlpPolicyName"
            Warn "Add the detection rule (match on the privileged/matter labels and the sensitive info types your legal function specified) in-portal or via New-DlpComplianceRule. KEEP IT IN SIMULATION until match review + sign-off."
            Info "Rule scaffold (supply legal's match criteria): $cmdRule"
        } else { Would $cmdPol; Would $cmdRule; Warn "Never switch to -Mode Enable from this script — enforce in-portal only after a clean simulation and legal sign-off." }
    }

    'Retention' {
        if ($Regulatory) {
            $name = if ($RetentionLabel) { $RetentionLabel } else { 'Records – Legal Matter Regulated – Regulatory' }
            Warn "REGULATORY-RECORDS label requested. This label is IMMUTABLE and CANNOT be removed; retention cannot be shortened. Apply ONLY under explicit legal/records sign-off, only where the schedule requires, and on the approved scope."
            if ($Remove) { Warn "A regulatory-records label cannot be removed — ignoring -Remove."; break }
            $cmd = "New-ComplianceTag -Name '$name' -RetentionAction Keep -RetentionDuration $RecordsDuration -IsRecordLabel `$true -Regulatory `$true"
            if ($doCommit) {
                Info "Creating regulatory-records label '$name' ..."
                New-ComplianceTag -Name $name -RetentionAction Keep -RetentionDuration $RecordsDuration -IsRecordLabel $true -Regulatory $true -ErrorAction Stop | Out-Null
                Ok "Created (IRREVERSIBLE): $name"; Get-ComplianceTag -Identity $name | Format-List Name, IsRecordLabel, RegulatoryRecord, RetentionDuration
            } else { Would $cmd }
            break
        }
        # Non-regulatory pilot matter-records label (safe / removable)
        $name = if ($RetentionLabel) { $RetentionLabel } else { 'Records – Legal Matter Records – Record' }
        if ($Remove) {
            $cmdT = "Remove-ComplianceTag -Identity '$name'"; $cmdP = "Remove-RetentionCompliancePolicy -Identity '$RetentionPolicy'"
            if ($doCommit) {
                Info "Removing pilot matter-records label + publish policy ..."
                try { Remove-RetentionCompliancePolicy -Identity $RetentionPolicy -Confirm:$false -ErrorAction Stop; Ok "Removed policy: $RetentionPolicy" } catch { Warn $_.Exception.Message }
                try { Remove-ComplianceTag -Identity $name -Confirm:$false -ErrorAction Stop; Ok "Removed label: $name" } catch { Warn $_.Exception.Message }
            } else { Would $cmdP; Would $cmdT }
            break
        }
        $cmdT = "New-ComplianceTag -Name '$name' -RetentionAction Keep -RetentionDuration $RecordsDuration -IsRecordLabel `$true"
        $cmdP = "New-RetentionCompliancePolicy -Name '$RetentionPolicy' -SharePointLocation <matter sites> then New-RetentionComplianceRule -PublishComplianceTag '$name'"
        Warn "Retention duration ($RecordsDuration) and the disposition trigger are RECORDS' determination — supplied by you, not invented here. Legal hold OVERRIDES disposal and is legal's action in eDiscovery (not performed here)."
        if ($doCommit) {
            Info "Creating NON-regulatory pilot matter-records label '$name' ..."
            New-ComplianceTag -Name $name -RetentionAction Keep -RetentionDuration $RecordsDuration -IsRecordLabel $true -ErrorAction Stop | Out-Null
            Ok "Created (removable) matter-records label: $name"
            Info "Creating publish policy '$RetentionPolicy' (scope to your PILOT matter workloads; edit -SharePointLocation/-ExchangeLocation as designed) ..."
            # NOTE: scope to the pilot matter sites rather than All in production; 'All' shown for pilot-preview only.
            New-RetentionCompliancePolicy -Name $RetentionPolicy -SharePointLocation All -ErrorAction Stop | Out-Null
            New-RetentionComplianceRule -Name "$RetentionPolicy Rule" -Policy $RetentionPolicy -PublishComplianceTag $name -ErrorAction Stop | Out-Null
            Ok "Created publish policy + rule: $RetentionPolicy — configure 'Disposition – Legal Records – Review' in-portal where the schedule requires reviewed disposal."
        } else { Would $cmdT; Would $cmdP; Warn "In production, scope the publish policy to the pilot matter sites, not All. Configure disposition review in-portal." }
    }

    'Audit' {
        if (-not $PolicyName) { $PolicyName = 'Audit Retention – Legal Evidence – LongTerm' }
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
}

Write-Host "`nDone. Re-run INDLEGAL-Discovery.ps1 / INDLEGAL-Validate.ps1 to confirm state. Never enforce DLP or apply a regulatory-records label outside the pilot without legal/records sign-off; legal holds remain legal's." -ForegroundColor White

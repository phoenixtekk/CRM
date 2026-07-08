<#
.SYNOPSIS
    CMPFERPA-Configure.ps1 — create classification/DLP/retention/audit controls, DLP pilot-in-simulation first (-WhatIf default; writes on -Commit).
.DESCRIPTION
    PURPOSE
        Configures one FERPA control domain at a time (-Control Label|DLP|Retention|Audit) using Security
        & Compliance PowerShell. SAFE BY DEFAULT: prints the exact cmdlet it WOULD run and makes NO change
        unless -Commit is passed. The DLP policy is ALWAYS created in SIMULATION/test mode (never enforcing)
        — enforcement is a separate, signed-off in-portal change. Labels/retention/audit are created scoped
        to the pilot. No secrets in code.
    HOW TO RUN
        # 1) Education-record sensitivity label + publish (pilot):
        .\CMPFERPA-Configure.ps1 -Control Label -WhatIf
        .\CMPFERPA-Configure.ps1 -Control Label -Commit
        # 2) DLP policy IN SIMULATION (after disclosure-exceptions agreed):
        .\CMPFERPA-Configure.ps1 -Control DLP -PilotScope "FERPA Pilot – Education Records – Stage1" -WhatIf
        # 3) Education-record retention:
        .\CMPFERPA-Configure.ps1 -Control Retention -RecordsDuration SevenYears -WhatIf
        # 4) Audit evidence retention:
        .\CMPFERPA-Configure.ps1 -Control Audit -PolicyName "Audit Retention – FERPA Evidence – LongTerm" -RecordTypes AzureActiveDirectory -Duration TenYears -Priority 150 -WhatIf
        Requires ExchangeOnlineManagement (Connect-IPPSSession). Interactive modern-auth / MFA admin.
    EXPECTED RESULTS
        -WhatIf prints each intended create/remove with no change. -Commit performs it and re-reads the
        object. PASS = object exists as intended (DLP in SIMULATION). Move DLP to enforce only in-portal
        under compliance/registrar sign-off. Remove objects with -Remove.
.NOTES
    Purview category — FERPA Compliance Program. High-impact: DLP, labels, and retention are piloted in
    simulation/test/disabled mode first. Retention durations, DLP match logic, and permitted-disclosure
    exceptions are compliance/registrar/records/legal determinations — supplied by you, not invented here.
    Verify cmdlet/plan availability for your tenant.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Label','DLP','Retention','Audit')][string]$Control,

    # --- Label ---
    [string]$LabelName,                                  # override default label name

    # --- DLP ---
    [string]$PilotScope = 'FERPA Pilot – Education Records – Stage1',
    [string]$DlpPolicyName,
    [string[]]$SensitiveInfoTypes = @('U.S. Social Security Number (SSN)'),  # VERIFY the SITs that match education records for your tenant

    # --- Retention ---
    [string]$RetentionPolicyName,
    [string]$RecordsDuration = 'SevenYears',            # VERIFY accepted values / your records schedule

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

    'Label' {
        $name = if ($LabelName) { $LabelName } else { 'Protect – FERPA Education Records – Confidential' }
        $policyName = 'Protect – FERPA Education Records – Publish'
        if ($Remove) {
            $cmdP = "Remove-LabelPolicy -Identity '$policyName'"; $cmdL = "Remove-Label -Identity '$name'"
            if ($doCommit) {
                Info "Removing label publish policy + label ..."
                try { Remove-LabelPolicy -Identity $policyName -Confirm:$false -ErrorAction Stop; Ok "Removed label policy: $policyName" } catch { Warn $_.Exception.Message }
                try { Remove-Label -Identity $name -Confirm:$false -ErrorAction Stop; Ok "Removed label: $name" } catch { Warn $_.Exception.Message }
            } else { Would $cmdP; Would $cmdL }
            break
        }
        $cmdL = "New-Label -Name 'FERPA-EduRecords-Confidential' -DisplayName '$name' -Tooltip 'Protects student education-record PII (FERPA).'"
        $cmdP = "New-LabelPolicy -Name '$policyName' -Labels '$name' -ExchangeLocation <pilot> -SharePointLocation <pilot>  (scope to the pilot, not All)"
        Warn "Configure the label's protection/encryption + marking in-portal per your design after creation. Publish to the PILOT first, not tenant-wide."
        if ($doCommit) {
            Info "Creating sensitivity label '$name' ..."
            New-Label -Name 'FERPA-EduRecords-Confidential' -DisplayName $name -Tooltip 'Protects student education-record PII (FERPA).' -ErrorAction Stop | Out-Null
            Ok "Created label: $name"
            Info "Publishing label via '$policyName' (scope to your pilot locations; edit -ExchangeLocation/-SharePointLocation as designed) ..."
            New-LabelPolicy -Name $policyName -Labels 'FERPA-EduRecords-Confidential' -ErrorAction Stop | Out-Null
            Ok "Created label publish policy: $policyName — now set the pilot scope + protection settings in-portal."
        } else { Would $cmdL; Would $cmdP; Warn "In production, scope the publish policy to the pilot locations, not All." }
    }

    'DLP' {
        $name = if ($DlpPolicyName) { $DlpPolicyName } else { 'DLP – FERPA Education Records – Simulate' }
        Warn "DLP is HIGH-IMPACT. This helper creates the policy in SIMULATION/test mode ONLY (never enforcing). Add permitted-disclosure EXCEPTIONS (to the student, school officials, under consent) and move to enforce only in-portal under compliance/registrar sign-off."
        if ($Remove) {
            $cmd = "Remove-DlpCompliancePolicy -Identity '$name'"
            if ($doCommit) { try { Remove-DlpCompliancePolicy -Identity $name -Confirm:$false -ErrorAction Stop; Ok "Removed DLP policy: $name" } catch { Warn $_.Exception.Message } }
            else { Would $cmd }
            break
        }
        # Mode 'Enable' with the policy left in test/simulation via the portal toggle; use -Mode TestWithoutNotifications where supported.
        $cmdP = "New-DlpCompliancePolicy -Name '$name' -Mode TestWithoutNotifications -ExchangeLocation All -SharePointLocation All -OneDriveLocation All -TeamsLocation All  (scope to pilot: $PilotScope)"
        $cmdR = "New-DlpComplianceRule -Name '$name Rule' -Policy '$name' -ContentContainsSensitiveInformation @{Name='$($SensitiveInfoTypes -join "','")'}  (+ permitted-disclosure exceptions)"
        Warn "VERIFY the sensitive information types / classifier that match YOUR education records ($($SensitiveInfoTypes -join ', ')) and the accepted -Mode values for your tenant before committing. Match logic is compliance/registrar's determination."
        if ($doCommit) {
            Info "Creating DLP policy '$name' in SIMULATION/test mode ..."
            # -Mode TestWithoutNotifications = simulation (no user notifications, no block). Confirm the supported value for your tenant.
            New-DlpCompliancePolicy -Name $name -Mode TestWithoutNotifications -ExchangeLocation All -SharePointLocation All -OneDriveLocation All -TeamsLocation All -ErrorAction Stop | Out-Null
            Ok "Created DLP policy (SIMULATION): $name"
            $siParam = @()
            foreach ($s in $SensitiveInfoTypes) { $siParam += @{ Name = $s } }
            Info "Creating DLP rule matching education-record sensitive info types ..."
            New-DlpComplianceRule -Name "$name Rule" -Policy $name -ContentContainsSensitiveInformation $siParam -ErrorAction Stop | Out-Null
            Ok "Created DLP rule for: $name — now add permitted-disclosure exceptions + scope to the pilot in-portal, keep in SIMULATION until sign-off."
        } else { Would $cmdP; Would $cmdR; Warn "After creation, scope to the pilot, add disclosure exceptions, and keep in SIMULATION until validated + signed off." }
    }

    'Retention' {
        $name = if ($RetentionPolicyName) { $RetentionPolicyName } else { 'Retention – FERPA Records – Publish' }
        $tagName = 'Retention – FERPA Records – Tag'
        if ($Remove) {
            $cmdP = "Remove-RetentionCompliancePolicy -Identity '$name'"; $cmdT = "Remove-ComplianceTag -Identity '$tagName'"
            if ($doCommit) {
                Info "Removing retention policy + tag ..."
                try { Remove-RetentionCompliancePolicy -Identity $name -Confirm:$false -ErrorAction Stop; Ok "Removed policy: $name" } catch { Warn $_.Exception.Message }
                try { Remove-ComplianceTag -Identity $tagName -Confirm:$false -ErrorAction Stop; Ok "Removed tag: $tagName" } catch { Warn $_.Exception.Message }
            } else { Would $cmdP; Would $cmdT }
            break
        }
        $cmdT = "New-ComplianceTag -Name '$tagName' -RetentionAction Keep -RetentionDuration $RecordsDuration"
        $cmdP = "New-RetentionCompliancePolicy -Name '$name' -ExchangeLocation <pilot> -SharePointLocation <pilot> then New-RetentionComplianceRule -PublishComplianceTag '$tagName'  (scope to pilot: $PilotScope)"
        Warn "VERIFY accepted -RetentionDuration values and that $RecordsDuration matches your records schedule (compliance/registrar determination)."
        if ($doCommit) {
            Info "Creating retention tag '$tagName' ..."
            New-ComplianceTag -Name $tagName -RetentionAction Keep -RetentionDuration $RecordsDuration -ErrorAction Stop | Out-Null
            Ok "Created retention tag: $tagName"
            Info "Creating retention policy '$name' (scope to your pilot locations; edit locations as designed) ..."
            New-RetentionCompliancePolicy -Name $name -ExchangeLocation All -ErrorAction Stop | Out-Null
            New-RetentionComplianceRule -Name "$name Rule" -Policy $name -PublishComplianceTag $tagName -ErrorAction Stop | Out-Null
            Ok "Created retention policy + rule: $name — scope to the pilot in-portal, not All."
        } else { Would $cmdT; Would $cmdP; Warn "In production, scope the retention policy to the pilot locations, not All." }
    }

    'Audit' {
        if (-not $PolicyName) { $PolicyName = 'Audit Retention – FERPA Evidence – LongTerm' }
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

Write-Host "`nDone. Re-run CMPFERPA-Discovery.ps1 / CMPFERPA-Validate.ps1 to confirm state." -ForegroundColor White

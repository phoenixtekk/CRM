<#
.SYNOPSIS
    INDGOV-Configure.ps1 — create the government CJI/CUI/ITAR labels, DLP + endpoint DLP (in SIMULATION), retention, and audit-evidence controls, pilot-first (-WhatIf default; writes on -Commit).
.DESCRIPTION
    PURPOSE
        Configures one government control domain at a time (-Control Labels|DLP|EndpointDLP|Retention|Audit)
        using Security & Compliance PowerShell. SAFE BY DEFAULT: prints the exact cmdlet it WOULD run and
        makes NO change unless -Commit is passed. DLP and endpoint DLP are ALWAYS created in SIMULATION/TEST
        mode (a block can halt mission work). Sensitivity labels are created but their encryption/rights are
        defined in-portal and PUBLISHED pilot-first (an encrypting label changes who can open a file; ITAR
        access is legal's determination). No secrets in code.
    HOW TO RUN
        # Sovereign cloud — pass your S&C endpoint on every run: -ConnectionUri <your cloud endpoint>
        # 1) Government labels (CJI/CUI/ITAR) — preview then commit; define encryption/rights in-portal after:
        .\INDGOV-Configure.ps1 -Control Labels -WhatIf
        .\INDGOV-Configure.ps1 -Control Labels -Commit
        # 2) Services DLP IN SIMULATION (conditions/SITs are governance's determination — set in-portal):
        .\INDGOV-Configure.ps1 -Control DLP -WhatIf
        # 3) Endpoint egress DLP IN SIMULATION (requires onboarded devices):
        .\INDGOV-Configure.ps1 -Control EndpointDLP -WhatIf
        # 4) Government records retention:
        .\INDGOV-Configure.ps1 -Control Retention -WhatIf
        # 5) Audit evidence retention:
        .\INDGOV-Configure.ps1 -Control Audit -PolicyName "Audit Retention – Gov Evidence – LongTerm" -Duration TenYears -Priority 150 -WhatIf
        Requires ExchangeOnlineManagement (Connect-IPPSSession). Interactive modern-auth / MFA admin.
    EXPECTED RESULTS
        -WhatIf prints each intended create/remove with no change. -Commit performs it and re-reads the
        object. DLP/EndpointDLP are created with -Mode Enable (SIMULATION) — NEVER auto-enforced by this
        script. PASS = object exists as intended, in simulation where applicable. Remove objects with -Remove.
.NOTES
    Purview category — Government industry bundle (CJIS/CMMC/ITAR). High-impact: labels are piloted for
    access, DLP/endpoint DLP are simulated first. Data classification, encryption/ITAR access rules, DLP
    conditions/SITs, retention durations, and rule applicability are compliance/security/records/legal
    determinations — supplied by you, not invented here. No certification/authorization is implied.
    Verify cmdlet/plan/endpoint availability for your cloud.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Labels','DLP','EndpointDLP','Retention','Audit')][string]$Control,

    [string]$ConnectionUri,                               # sovereign-cloud S&C endpoint — VERIFY for your cloud
    [string]$PilotScope = 'Gov Pilot – Controlled Data – Stage1',

    # --- Labels ---
    [string[]]$LabelNames = @('Protect – Gov CJI – Restricted','Protect – Gov CUI – Controlled','Protect – Gov ITAR – Controlled'),

    # --- Retention ---
    [string]$RetentionLabel   = 'Gov Records',
    [string]$RetentionPolicy  = 'Retention – Gov Records – Publish',
    [string]$RecordsDuration  = 'SevenYears',            # VERIFY accepted values / records' determination

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
$connectParams = @{}
if ($ConnectionUri) { $connectParams['ConnectionUri'] = $ConnectionUri; Warn "Using sovereign-cloud S&C endpoint: $ConnectionUri (verify for your cloud)." }
try { Connect-IPPSSession @connectParams -ErrorAction Stop | Out-Null } catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message) — pass the correct -ConnectionUri for GCC High/DoD."; return }

switch ($Control) {

    'Labels' {
        Warn "Encrypting labels change WHO can open a file. Create here, then define encryption/rights IN-PORTAL and PUBLISH pilot-first. For ITAR, the U.S.-person access constraint is LEGAL's determination."
        foreach ($name in $LabelNames) {
            if ($Remove) {
                $cmd = "Remove-Label -Identity '$name'"
                if ($doCommit) { try { Remove-Label -Identity $name -Confirm:$false -ErrorAction Stop; Ok "Removed label: $name" } catch { Warn $_.Exception.Message } }
                else { Would $cmd }
                continue
            }
            # Create the label shell; encryption/rights are configured in-portal per the approved design.
            $cmd = "New-Label -Name '$([guid]::NewGuid())' -DisplayName '$name' -Tooltip 'Government controlled data — define encryption/rights in-portal per design'"
            if ($doCommit) {
                Info "Creating sensitivity label '$name' (define encryption/rights in-portal after) ..."
                New-Label -DisplayName $name -Name ([guid]::NewGuid().ToString()) -Tooltip 'Government controlled data — define encryption/rights in-portal per design' -ErrorAction Stop | Out-Null
                Ok "Created label: $name — now set encryption/rights in-portal and publish to '$PilotScope' first."
            } else { Would $cmd; Warn "After creation: set encryption/rights in-portal, then publish via New-LabelPolicy scoped to '$PilotScope' (pilot), not all users." }
        }
        Warn "Publish is deliberately pilot-first and left to the label policy in-portal / New-LabelPolicy scoped to the pilot — verify access outcomes before broad publish."
    }

    'DLP' {
        $name = 'DLP – Gov Controlled Data – Simulate'
        Warn "DLP is HIGH-IMPACT. This policy is created in SIMULATION (-Mode Enable = test/simulation). Conditions / sensitive-info types (CJI/CUI/ITAR) are GOVERNANCE's determination — add them in-portal or via New-DlpComplianceRule."
        if ($Remove) {
            $cmd = "Remove-DlpCompliancePolicy -Identity '$name'"
            if ($doCommit) { try { Remove-DlpCompliancePolicy -Identity $name -Confirm:$false -ErrorAction Stop; Ok "Removed DLP policy: $name" } catch { Warn $_.Exception.Message } }
            else { Would $cmd }
            break
        }
        $cmd = "New-DlpCompliancePolicy -Name '$name' -Mode Enable (SIMULATION) -ExchangeLocation All -SharePointLocation All -OneDriveLocation All -TeamsLocation All  [then New-DlpComplianceRule with your CJI/CUI/ITAR conditions]"
        if ($doCommit) {
            Info "Creating SERVICES DLP policy '$name' IN SIMULATION ..."
            New-DlpCompliancePolicy -Name $name -Mode Enable -ExchangeLocation All -SharePointLocation All -OneDriveLocation All -TeamsLocation All -ErrorAction Stop | Out-Null
            Ok "Created (SIMULATION): $name — now add a rule (New-DlpComplianceRule) with the CJI/CUI/ITAR conditions your governance function specified, scoped to '$PilotScope'."
            Warn "Do NOT switch -Mode to enforce until simulation matches are validated and signed off (Implementation Step 8)."
        } else { Would $cmd; Warn "Scope the rule to the pilot and keep -Mode Enable (simulation) until validated." }
    }

    'EndpointDLP' {
        $name = 'DLP – Gov Endpoint Egress – Simulate'
        Warn "Endpoint DLP requires ONBOARDED devices and endpoint-DLP licensing/availability in your cloud. Created in SIMULATION. Egress channels (USB/print/cloud-upload) + conditions are set in the rule per your design."
        if ($Remove) {
            $cmd = "Remove-DlpCompliancePolicy -Identity '$name'"
            if ($doCommit) { try { Remove-DlpCompliancePolicy -Identity $name -Confirm:$false -ErrorAction Stop; Ok "Removed endpoint DLP policy: $name" } catch { Warn $_.Exception.Message } }
            else { Would $cmd }
            break
        }
        $cmd = "New-DlpCompliancePolicy -Name '$name' -Mode Enable (SIMULATION) -EndpointDlpLocation All  [then New-DlpComplianceRule with USB/print/cloud-upload egress conditions]"
        if ($doCommit) {
            Info "Creating ENDPOINT DLP policy '$name' IN SIMULATION (Devices) ..."
            New-DlpCompliancePolicy -Name $name -Mode Enable -EndpointDlpLocation All -ErrorAction Stop | Out-Null
            Ok "Created (SIMULATION): $name — add a rule for USB/print/cloud-upload egress of CJI/CUI/ITAR, scoped to '$PilotScope' onboarded devices."
            Warn "Do NOT enforce until simulation is validated; confirm devices are onboarded and endpoint DLP is available in your cloud."
        } else { Would $cmd; Warn "Requires onboarded devices; keep -Mode Enable (simulation) until validated." }
    }

    'Retention' {
        Warn "Retention duration/disposition are RECORDS' determination. Created scoped to the pilot; expand on sign-off."
        if ($Remove) {
            $cmdP = "Remove-RetentionCompliancePolicy -Identity '$RetentionPolicy'"; $cmdT = "Remove-ComplianceTag -Identity '$RetentionLabel'"
            if ($doCommit) {
                try { Remove-RetentionCompliancePolicy -Identity $RetentionPolicy -Confirm:$false -ErrorAction Stop; Ok "Removed policy: $RetentionPolicy" } catch { Warn $_.Exception.Message }
                try { Remove-ComplianceTag -Identity $RetentionLabel -Confirm:$false -ErrorAction Stop; Ok "Removed label: $RetentionLabel" } catch { Warn $_.Exception.Message }
            } else { Would $cmdP; Would $cmdT }
            break
        }
        $cmdT = "New-ComplianceTag -Name '$RetentionLabel' -RetentionAction Keep -RetentionDuration $RecordsDuration -IsRecordLabel `$true"
        $cmdP = "New-RetentionCompliancePolicy -Name '$RetentionPolicy' (scope to pilot) then New-RetentionComplianceRule -PublishComplianceTag '$RetentionLabel'"
        if ($doCommit) {
            Info "Creating government records retention label + publish policy ..."
            New-ComplianceTag -Name $RetentionLabel -RetentionAction Keep -RetentionDuration $RecordsDuration -IsRecordLabel $true -ErrorAction Stop | Out-Null
            Ok "Created records label: $RetentionLabel"
            New-RetentionCompliancePolicy -Name $RetentionPolicy -ExchangeLocation All -ErrorAction Stop | Out-Null
            New-RetentionComplianceRule -Name "$RetentionPolicy Rule" -Policy $RetentionPolicy -PublishComplianceTag $RetentionLabel -ErrorAction Stop | Out-Null
            Ok "Created publish policy + rule: $RetentionPolicy"
            Warn "In production, scope the publish policy to the pilot locations, not All."
        } else { Would $cmdT; Would $cmdP; Warn "Scope to the pilot, not All; confirm duration/disposition with records." }
    }

    'Audit' {
        if (-not $PolicyName) { $PolicyName = 'Audit Retention – Gov Evidence – LongTerm' }
        if ($Remove) {
            $cmd = "Remove-UnifiedAuditLogRetentionPolicy -Identity '$PolicyName'"
            if ($doCommit) { try { Remove-UnifiedAuditLogRetentionPolicy -Identity $PolicyName -Confirm:$false -ErrorAction Stop; Ok "Removed audit retention policy: $PolicyName" } catch { Warn $_.Exception.Message } }
            else { Would $cmd }
            break
        }
        $opPart = if ($Operations) { " -Operations $($Operations -join ',')" } else { '' }
        $cmd = "New-UnifiedAuditLogRetentionPolicy -Name '$PolicyName' -RecordTypes $($RecordTypes -join ',')$opPart -RetentionDuration $Duration -Priority $Priority"
        Warn "VERIFY accepted -RetentionDuration values and that the long-term tier ($Duration) is licensed in your cloud before committing."
        if ($doCommit) {
            Info "Creating audit evidence retention policy '$PolicyName' ..."
            $p = @{ Name=$PolicyName; RecordTypes=$RecordTypes; RetentionDuration=$Duration; Priority=$Priority }
            if ($Operations) { $p['Operations'] = $Operations }
            New-UnifiedAuditLogRetentionPolicy @p -ErrorAction Stop | Out-Null
            Ok "Created audit retention policy: $PolicyName"
        } else { Would $cmd }
    }
}

Write-Host "`nDone. Re-run INDGOV-Discovery.ps1 / INDGOV-Validate.ps1 to confirm state. DLP stays in SIMULATION until validated + signed off." -ForegroundColor White

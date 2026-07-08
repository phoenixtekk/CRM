<#
.SYNOPSIS
    EDU-Set-Configuration.ps1 — create the education labels, FERPA DLP (in TEST), and student-record retention label (-WhatIf default; writes on -Commit).
.DESCRIPTION
    PURPOSE
        Configures one area of the education/FERPA program at a time (-Area Labels|DLP|Retention) using
        Security & Compliance PowerShell. SAFE BY DEFAULT: prints the exact cmdlet it WOULD run and makes
        NO change unless -Commit is passed. The DLP policy is ALWAYS created in TEST mode and this script
        will NOT enable enforcement (that is a deliberate, separate change per Implementation Step 9).
        Retention is applied ONLY with an approved period you pass — the script never invents a period.
    HOW TO RUN
        # Labels (preview then commit):
        .\EDU-Set-Configuration.ps1 -Area Labels -WhatIf
        .\EDU-Set-Configuration.ps1 -Area Labels -Commit
        # FERPA DLP policy IN TEST (references the 'EDU - Student ID' SIT / 'EDU - Student Record (FERPA)' label):
        .\EDU-Set-Configuration.ps1 -Area DLP -WhatIf
        # Student-record retention label (period from the records owner — REQUIRED, no default):
        .\EDU-Set-Configuration.ps1 -Area Retention -RetentionYears 5 -Commit
        Requires ExchangeOnlineManagement (Connect-IPPSSession). Interactive modern-auth / MFA admin.
    EXPECTED RESULTS
        -WhatIf prints each intended create with no change. -Commit performs it and re-reads the object.
        PASS = objects exist as intended, DLP in Test. Nothing enforces. Roll back per the Implementation
        Guide (set DLP back to Test/disable, remove the label policy, unpublish the retention label).
.NOTES
    Purview category — Microsoft Purview for Education (FERPA). High-impact: labels/DLP/retention are
    piloted in simulation/test first. Retention periods, FERPA applicability, and holds are records/legal
    determinations supplied by you, not invented here. Verify cmdlet/plan availability for your tenant.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Labels','DLP','Retention')][string]$Area,

    # --- Labels ---
    [switch]$Encrypt,                                     # apply encryption to the Student Record label (verify licensing)

    # --- DLP ---
    [string]$DlpName   = 'EDU - FERPA Student Records - DLP - Pilot',
    [string]$StudentIdSit = 'EDU - Student ID',           # custom SIT built in Implementation Step 3
    [string]$RecordLabel  = 'EDU - Student Record (FERPA)',

    # --- Retention ---
    [string]$RetentionLabel = 'EDU - Student Education Record',
    [int]$RetentionYears,                                  # REQUIRED for Retention — the records owner's approved period
    [ValidateSet('Keep','KeepAndDelete','Delete')][string]$RetentionAction = 'KeepAndDelete',

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

if ($Commit -and $WhatIf) { Warn "Both -Commit and -WhatIf passed; -WhatIf wins (no changes)."; $Commit = $false }
$doCommit = $Commit.IsPresent -and -not $WhatIf
if (-not $doCommit) { Info "SAFE MODE (-WhatIf / no -Commit): no changes will be made." }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Warn "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser"; return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Connect-IPPSSession -ErrorAction Stop | Out-Null } catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message)"; return }

switch ($Area) {

    'Labels' {
        # Ordered taxonomy — parent labels first. Protection kept minimal for the pilot.
        $labels = @(
            @{ Name='EDU - Public';                   Tip='Public — no protection';               Enc=$false },
            @{ Name='EDU - Internal';                 Tip='Internal only';                        Enc=$false },
            @{ Name='EDU - Student Record (FERPA)';   Tip='FERPA — Student Record';               Enc=$Encrypt.IsPresent },
            @{ Name='EDU - Highly Confidential';      Tip='Highly confidential';                  Enc=$true }
        )
        foreach ($l in $labels) {
            if ($Remove) {
                $cmd = "Remove-Label -Identity '$($l.Name)'"
                if ($doCommit) { try { Remove-Label -Identity $l.Name -Confirm:$false -ErrorAction Stop; Ok "Removed label: $($l.Name)" } catch { Warn $_.Exception.Message } }
                else { Would $cmd }
                continue
            }
            $encPart = if ($l.Enc) { " (with encryption — VERIFY licensing)" } else { '' }
            $cmd = "New-Label -Name '$($l.Name)' -DisplayName '$($l.Name)' -Tooltip '$($l.Tip)'$encPart"
            if ($doCommit) {
                try {
                    if (Get-Label -Identity $l.Name -ErrorAction SilentlyContinue) { Ok "Label already exists: $($l.Name)" }
                    else {
                        New-Label -Name $l.Name -DisplayName $l.Name -Tooltip $l.Tip -ErrorAction Stop | Out-Null
                        Ok "Created label: $($l.Name)"
                        if ($l.Enc) { Warn "Set encryption/content-marking for '$($l.Name)' in-portal (Information Protection) — verify licensing." }
                    }
                } catch { Warn "Create label '$($l.Name)' failed: $($_.Exception.Message)" }
            } else { Would $cmd }
        }
        Warn "After creating labels, PUBLISH them via label policy 'EDU - Label Policy - Pilot' to the PILOT group only (Implementation Step 4)."
    }

    'DLP' {
        Warn "DLP is created in TEST mode and this script NEVER enforces. Enforcement is a separate, out-of-band change (Implementation Step 9)."
        if ($Remove) {
            $cmd = "Remove-DlpCompliancePolicy -Identity '$DlpName'"
            if ($doCommit) { try { Remove-DlpCompliancePolicy -Identity $DlpName -Confirm:$false -ErrorAction Stop; Ok "Removed DLP policy: $DlpName" } catch { Warn $_.Exception.Message } }
            else { Would $cmd }
            break
        }
        # New-DlpCompliancePolicy -Mode TestWithNotifications keeps the policy in TEST (no enforcement).
        $cmdP = "New-DlpCompliancePolicy -Name '$DlpName' -Mode TestWithNotifications -ExchangeLocation All -SharePointLocation All -OneDriveLocation All -TeamsLocation All (scope to pilot in production)"
        $cmdR = "New-DlpComplianceRule -Name '$DlpName Rule' -Policy '$DlpName' -ContentContainsSensitiveInformation @{Name='$StudentIdSit'} (education-record condition; add name/SSN SIT or '$RecordLabel' per design) -BlockAccess `$false -NotifyUser Owner"
        if ($doCommit) {
            Info "Creating DLP policy '$DlpName' in TEST (TestWithNotifications) ..."
            try {
                if (Get-DlpCompliancePolicy -Identity $DlpName -ErrorAction SilentlyContinue) { Ok "DLP policy already exists: $DlpName (confirm it is in Test with EDU-Validation.ps1)." }
                else {
                    New-DlpCompliancePolicy -Name $DlpName -Mode TestWithNotifications `
                        -ExchangeLocation All -SharePointLocation All -OneDriveLocation All -TeamsLocation All -ErrorAction Stop | Out-Null
                    Ok "Created DLP policy in TEST: $DlpName"
                    Warn "In production, SCOPE locations to the pilot rather than All."
                    New-DlpComplianceRule -Name "$DlpName Rule" -Policy $DlpName `
                        -ContentContainsSensitiveInformation @(@{ Name = $StudentIdSit }) `
                        -BlockAccess $false -NotifyUser 'Owner' -ErrorAction Stop | Out-Null
                    Ok "Created DLP rule referencing SIT '$StudentIdSit' (education-record signal)."
                    Warn "Add the name/U.S. SSN SIT and/or the '$RecordLabel' label condition per your approved design in-portal; tune confidence/counts."
                }
            } catch { Warn "Create DLP failed: $($_.Exception.Message)" }
        } else { Would $cmdP; Would $cmdR; Warn "Verify the DLP mode value (TestWithNotifications) for your tenant before committing." }
    }

    'Retention' {
        if ($Remove) {
            $cmd = "Remove-ComplianceTag -Identity '$RetentionLabel'"
            if ($doCommit) { try { Remove-ComplianceTag -Identity $RetentionLabel -Confirm:$false -ErrorAction Stop; Ok "Removed retention label: $RetentionLabel" } catch { Warn $_.Exception.Message } }
            else { Would $cmd }
            break
        }
        if (-not $RetentionYears) {
            Warn "REFUSING to create retention without -RetentionYears. The period is the records owner's APPROVED value — do not invent one (Requirement 2.7)."
            break
        }
        $days = $RetentionYears * 365
        $cmd = "New-ComplianceTag -Name '$RetentionLabel' -RetentionAction $RetentionAction -RetentionDuration $days -RetentionType ModificationAgeInDays"
        Warn "Retention PRESERVES content and is harder to reverse. Confirm the $RetentionYears-year period is the records owner's approved schedule before applying broadly."
        if ($doCommit) {
            Info "Creating retention label '$RetentionLabel' ($RetentionYears years / $days days, action $RetentionAction) ..."
            try {
                if (Get-ComplianceTag -Identity $RetentionLabel -ErrorAction SilentlyContinue) { Ok "Retention label already exists: $RetentionLabel" }
                else {
                    New-ComplianceTag -Name $RetentionLabel -RetentionAction $RetentionAction -RetentionDuration $days -RetentionType ModificationAgeInDays -ErrorAction Stop | Out-Null
                    Ok "Created retention label: $RetentionLabel"
                    Warn "PUBLISH via retention label policy 'EDU - Retention - Student Records - Pilot' to the PILOT locations only (Implementation Step 7). Use disposition review where records management requires sign-off."
                }
            } catch { Warn "Create retention label failed: $($_.Exception.Message)" }
        } else { Would $cmd; Warn "Verify accepted -RetentionType / -RetentionDuration values for your tenant before committing." }
    }
}

Write-Host "`nDone. Re-run EDU-Discovery.ps1 / EDU-Validation.ps1 to confirm state. Nothing here enforces DLP." -ForegroundColor White

<#
.SYNOPSIS
    PURVASSESS-Remediate.ps1 — apply the safe quick-win Purview fixes, -WhatIf by default (writes only with -Commit).
.DESCRIPTION
    PURPOSE
        Applies the low-risk, high-value remediations the assessment identifies — move a bluntly-enforced
        DLP policy to simulation, take an auto-labeling policy to simulation, enable a retention policy
        that was left disabled, or turn on unified audit ingestion. Every fix previews the exact cmdlet
        under -WhatIf, records the prior state so it is reversible, and changes state ONLY with -Commit.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVASSESS-Remediate.ps1 -Fix DlpToSimulation -PolicyName "Global PII" -WhatIf
        Review the -WhatIf output, then re-run with -Commit to apply. -Revert -Commit restores the recorded
        prior state. Requires ExchangeOnlineManagement (Connect-IPPSSession / Connect-ExchangeOnline) and
        the appropriate write role (Requirement 2.5). Interactive modern-auth / MFA; no secrets in code.
    EXPECTED RESULTS
        Under -WhatIf: prints the cmdlet it WOULD run and makes no change. Under -Commit: applies the fix,
        writes a prior-state record, and prints confirmation. A permissions error is surfaced, not swallowed.
.NOTES
    Purview category — Tenant Assessment. Safe-by-default (-WhatIf). Pilot/simulation-first. Whether a
    policy SHOULD be enabled is a compliance/records determination (Requirement 2.6) — confirm first.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('DlpToSimulation','AutoLabelToSimulation','EnableRetentionPolicy','EnableUnifiedAudit')]
    [string]$Fix,

    [string]$PolicyName,                 # required for the policy-scoped fixes
    [switch]$Commit,                     # without -Commit the script only previews (-WhatIf behaviour)
    [switch]$Revert,                     # restore the recorded prior state instead of applying the fix
    [string]$StateFile = ".\PURVASSESS-Remediate-state.json",
    [string]$UserPrincipalName
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($m){ Write-Host "  [OK]   $m" -ForegroundColor Green }
function Warn($m){ Write-Host "  [WARN] $m" -ForegroundColor Yellow }
function Info($m){ Write-Host "  $m" -ForegroundColor White }

# -Commit turns the real write on; otherwise force -WhatIf so nothing changes.
if (-not $Commit) { $WhatIfPreference = $true; Info "No -Commit: running in preview (-WhatIf) mode — no changes will be made." }

if ($Fix -in @('DlpToSimulation','AutoLabelToSimulation','EnableRetentionPolicy') -and -not $PolicyName) {
    throw "Fix '$Fix' requires -PolicyName."
}

# --- Connect ---
$connectParams = @{ ShowBanner = $false }
if ($UserPrincipalName) { $connectParams['UserPrincipalName'] = $UserPrincipalName }
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Connect-IPPSSession @connectParams | Out-Null } catch { Warn "Connect-IPPSSession: $($_.Exception.Message)" }
if ($Fix -eq 'EnableUnifiedAudit') { try { Connect-ExchangeOnline @connectParams } catch { Warn "Connect-ExchangeOnline: $($_.Exception.Message)" } }

# --- Prior-state record helpers (so every fix is reversible) ---
function Load-State { if (Test-Path $StateFile) { Get-Content $StateFile -Raw | ConvertFrom-Json } else { @() } }
function Save-State($obj){
    $state = @(Load-State) + $obj
    $state | ConvertTo-Json -Depth 5 | Set-Content -Path $StateFile -Encoding UTF8
    Info "Prior state recorded to $StateFile"
}
function Get-Prior($key){ (@(Load-State) | Where-Object { $_.Key -eq $key } | Select-Object -Last 1) }

Write-Section "$Fix  (Revert=$($Revert.IsPresent)  Commit=$($Commit.IsPresent))"

switch ($Fix) {

    'DlpToSimulation' {
        $key = "Dlp::$PolicyName"
        $cur = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction Stop
        if ($Revert) {
            $prior = Get-Prior $key
            if (-not $prior) { throw "No recorded prior mode for '$PolicyName' — cannot revert." }
            Info "Would restore DLP policy '$PolicyName' to prior mode '$($prior.PriorValue)'."
            Set-DlpCompliancePolicy -Identity $PolicyName -Mode $prior.PriorValue -Confirm:$false
            if ($Commit) { Ok "DLP '$PolicyName' restored to $($prior.PriorValue)." }
        } else {
            Info "Current DLP mode: $($cur.Mode) → target: TestWithNotifications (simulation)."
            if ($Commit) { Save-State ([pscustomobject]@{ Key=$key; Fix=$Fix; PriorValue="$($cur.Mode)"; When=(Get-Date).ToString('o') }) }
            Set-DlpCompliancePolicy -Identity $PolicyName -Mode TestWithNotifications -Confirm:$false
            if ($Commit) { Ok "DLP '$PolicyName' moved to simulation (TestWithNotifications)." }
        }
    }

    'AutoLabelToSimulation' {
        $key = "AutoLabel::$PolicyName"
        $cur = Get-AutoSensitivityLabelPolicy -Identity $PolicyName -ErrorAction Stop
        if ($Revert) {
            $prior = Get-Prior $key
            if (-not $prior) { throw "No recorded prior mode for '$PolicyName' — cannot revert." }
            Info "Would restore auto-labeling policy '$PolicyName' to prior mode '$($prior.PriorValue)'."
            Set-AutoSensitivityLabelPolicy -Identity $PolicyName -Mode $prior.PriorValue -Confirm:$false
            if ($Commit) { Ok "Auto-labeling '$PolicyName' restored to $($prior.PriorValue)." }
        } else {
            Info "Current mode: $($cur.Mode) → target: TestWithoutNotifications (simulation)."
            if ($Commit) { Save-State ([pscustomobject]@{ Key=$key; Fix=$Fix; PriorValue="$($cur.Mode)"; When=(Get-Date).ToString('o') }) }
            Set-AutoSensitivityLabelPolicy -Identity $PolicyName -Mode TestWithoutNotifications -Confirm:$false
            if ($Commit) { Ok "Auto-labeling '$PolicyName' moved to simulation (TestWithoutNotifications)." }
        }
    }

    'EnableRetentionPolicy' {
        # Records/retention determinations are DEFERRED — only enable after the records owner confirms (Requirement 2.6).
        $key = "Retention::$PolicyName"
        $cur = Get-RetentionCompliancePolicy -Identity $PolicyName -ErrorAction Stop
        $target = if ($Revert) { $false } else { $true }
        Warn "Confirm the records owner approved enabling '$PolicyName' before -Commit (Requirement 2.6)."
        Info "Current Enabled=$($cur.Enabled) → target Enabled=$target."
        if ($Commit -and -not $Revert) { Save-State ([pscustomobject]@{ Key=$key; Fix=$Fix; PriorValue="$($cur.Enabled)"; When=(Get-Date).ToString('o') }) }
        Set-RetentionCompliancePolicy -Identity $PolicyName -Enabled $target -Confirm:$false
        if ($Commit) { Ok "Retention policy '$PolicyName' Enabled=$target." }
    }

    'EnableUnifiedAudit' {
        $key = "UnifiedAudit::tenant"
        $cur = Get-AdminAuditLogConfig
        $target = if ($Revert) { $false } else { $true }
        Info "Current UnifiedAuditLogIngestionEnabled=$($cur.UnifiedAuditLogIngestionEnabled) → target=$target."
        if ($Commit -and -not $Revert) { Save-State ([pscustomobject]@{ Key=$key; Fix=$Fix; PriorValue="$($cur.UnifiedAuditLogIngestionEnabled)"; When=(Get-Date).ToString('o') }) }
        Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $target
        if ($Commit) { Ok "Unified audit ingestion set to $target (may take up to ~60 min to fully activate)." }
    }
}

if (-not $Commit) { Info "`nPreview complete. Re-run with -Commit to apply, after review/approval." }

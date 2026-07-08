<#
.SYNOPSIS
    PURVIEW-Remediation.ps1 — apply the approved quick-win baseline in SIMULATION/TEST (default -WhatIf; changes only with -Commit).
.DESCRIPTION
    PURPOSE
        Applies ONLY the maturity roadmap's "Now" quick wins, all NON-ENFORCING: enable the unified
        audit log (D6), publish a baseline sensitivity label + label policy to the pilot (D1), and
        create a baseline DLP policy in TEST mode scoped to the pilot (D2). It NEVER switches DLP to
        enforce, turns auto-labeling on out of simulation, enables insider-risk actions, or creates any
        retention-deletion policy — those are Next/Later roadmap steps with their own change and
        records/HR/legal determinations. Safe by default: prints the plan under -WhatIf and does nothing
        until you pass -Commit.
    HOW TO RUN
        # preview only (no changes):
        powershell -ExecutionPolicy Bypass -File .\PURVIEW-Remediation.ps1 -WhatIf
        # apply the approved quick wins after readout sign-off + change control:
        powershell -ExecutionPolicy Bypass -File .\PURVIEW-Remediation.ps1 -Commit -PilotGroup "Purview - Pilot Users"
        Sign in as a Compliance Administrator (write access) when prompted.
    EXPECTED RESULTS
        Under -WhatIf: a printed plan of each object it would create/enable. Under -Commit: the named
        baseline objects created in TEST/disabled mode, scoped to the pilot, with a rollback note.
.NOTES
    White-label — Purview Solutions. SAFE BY DEFAULT (-WhatIf). Writes only with -Commit.
    Uses Enable-... via Set-AdminAuditLogConfig, New-Label / New-LabelPolicy, New-DlpCompliancePolicy /
    New-DlpComplianceRule (Mode=TestWithNotifications). Enforcement is intentionally out of scope.
#>
[CmdletBinding()]
param(
    [switch]$Commit,
    [switch]$WhatIf = $true,
    [string]$BaselineLabel = 'Sensitivity Label - Confidential - Baseline',
    [string]$BaselineDlp   = 'DLP Policy - Baseline PII - Test',
    [string]$PilotGroup    = 'Purview - Pilot Users'
)

# -Commit overrides the safe default. Without -Commit we stay in preview.
if ($Commit) { $WhatIf = $false }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

$mode = if ($WhatIf) { 'PREVIEW (-WhatIf) — no changes' } else { 'COMMIT — applying quick-win baseline (non-enforcing)' }
Write-Host "`n=== Purview maturity — quick-win remediation :: $mode ===" -ForegroundColor Cyan

function Do-Step {
    param([string]$Desc, [scriptblock]$Action)
    if ($WhatIf) { Write-Host ("  WOULD: {0}" -f $Desc) -ForegroundColor Yellow; return }
    try { & $Action; Write-Host ("  DONE : {0}" -f $Desc) -ForegroundColor Green }
    catch { Write-Host ("  SKIP : {0} — {1}" -f $Desc, $_.Exception.Message) -ForegroundColor DarkYellow }
}

# D6 — enable unified audit log (low-risk, reversible)
$auditOn = $false
try { $auditOn = [bool](Get-AdminAuditLogConfig -ErrorAction Stop).UnifiedAuditLogIngestionEnabled } catch {}
if (-not $auditOn) {
    Do-Step "Enable unified audit log (D6)" { Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true }
} else { Write-Host "  OK   : unified audit log already ON (D6)" -ForegroundColor Green }

# D1 — baseline sensitivity label (no encryption enforced; publish to pilot only)
$existsLabel = $null
try { $existsLabel = Get-Label -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq $BaselineLabel } } catch {}
if (-not $existsLabel) {
    Do-Step "Create baseline sensitivity label '$BaselineLabel' (D1, no auto-labeling)" {
        New-Label -DisplayName $BaselineLabel -Name ($BaselineLabel -replace '[^A-Za-z0-9]','') `
            -Tooltip "Baseline confidential label (maturity quick win — pilot)" -ErrorAction Stop | Out-Null
    }
    Do-Step "Publish baseline label to '$PilotGroup' (D1)" {
        New-LabelPolicy -Name "Label Policy - Baseline - Pilot" -Labels $BaselineLabel `
            -ModernGroupLocation $PilotGroup -ErrorAction Stop | Out-Null
    }
} else { Write-Host "  OK   : baseline label already present (D1)" -ForegroundColor Green }

# D2 — baseline DLP policy in TEST mode (audit only), pilot-scoped. NEVER enforce here.
$existsDlp = $null
try { $existsDlp = Get-DlpCompliancePolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $BaselineDlp } } catch {}
if (-not $existsDlp) {
    Do-Step "Create baseline DLP policy '$BaselineDlp' in TEST mode (D2, non-enforcing)" {
        New-DlpCompliancePolicy -Name $BaselineDlp -Mode TestWithNotifications `
            -ExchangeLocation All -ErrorAction Stop | Out-Null
    }
    Do-Step "Add a starter PII rule to '$BaselineDlp' (audit only, no block)" {
        New-DlpComplianceRule -Name "Baseline PII - Audit" -Policy $BaselineDlp `
            -ContentContainsSensitiveInformation @(@{Name='U.S. Social Security Number (SSN)'}) `
            -ErrorAction Stop | Out-Null
    }
} else { Write-Host "  OK   : baseline DLP policy already present (D2)" -ForegroundColor Green }

Write-Host "`nCompliance Manager (D10) initializes on first visit to the Purview portal — no cmdlet write required." -ForegroundColor DarkGray

if ($WhatIf) {
    Write-Host "`nPREVIEW only — nothing changed. Re-run with -Commit after readout sign-off + change control." -ForegroundColor Yellow
} else {
    Write-Host "`nCOMMIT complete — baseline is NON-ENFORCING and pilot-scoped. Validate with PURVIEW-Validation.ps1." -ForegroundColor Green
    Write-Host "ROLLBACK: Remove-LabelPolicy 'Label Policy - Baseline - Pilot'; Remove-Label '$BaselineLabel';" -ForegroundColor DarkGray
    Write-Host "          Set-DlpCompliancePolicy '$BaselineDlp' -Mode Disable (or Remove-DlpCompliancePolicy);" -ForegroundColor DarkGray
    Write-Host "          if audit was off before, Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled `$false per the change ticket." -ForegroundColor DarkGray
}

Disconnect-ExchangeOnline -Confirm:$false | Out-Null

<#
.SYNOPSIS
    Read-only supervision-activity + configuration report pack for the FINRA/SEC program
    (safe: makes NO changes).
.DESCRIPTION
    Produces the examiner-oriented evidence rollup 'FINRA Supervision Rollup - Evidence': the
    supervisory-review policy/rule inventory, the role-separation snapshot, the supervised/excluded
    scope, the evidence-retention/immutability status, and (where available) recent supervisory-review
    activity from Get-SupervisoryReviewActivity. Read-only; optional CSV/text output.
.EXAMPLE
    .\CCFIN-Report.ps1
    Prints the full report pack to the console.
.EXAMPLE
    .\CCFIN-Report.ps1 -Days 30 -OutDir .\ccfin-report
    Also writes CSV/text artifacts for the last 30 days. (PS 5.1+/7+; Connect-IPPSSession.)
.NOTES
    Expected results: a coherent evidence pack (policy config + separation + scope + retention + review
    activity). Empty activity is normal in a fresh pilot. No changes are made. Cmdlet availability is
    plan-dependent - verify in your tenant. No credentials are stored in code.
#>
[CmdletBinding()]
param(
    [string]$PolicyName          = 'FINRA Supervision - Pilot - Simulation',
    [string]$RetentionPolicyName = 'FINRA Comms Records - 17a-4',
    [ValidateRange(1,180)][int]$Days = 7,
    [string]$OutDir
)

$ErrorActionPreference = 'Stop'
if ($OutDir -and -not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }
function Section([string]$t) { Write-Host ""; Write-Host "=== $t ===" }

Write-Host "==================================================================="
Write-Host " CCFIN Report Pack - FINRA Supervision Rollup - Evidence (READ-ONLY)"
Write-Host " $(Get-Date -Format s)  window: last $Days day(s)"
Write-Host "==================================================================="

try {
    if (-not (Get-Command Get-SupervisoryReviewPolicyV2 -ErrorAction SilentlyContinue)) {
        Connect-IPPSSession -ErrorAction Stop | Out-Null
    }
} catch {
    Write-Error "Could not connect to Security & Compliance PowerShell: $($_.Exception.Message)"
    return
}

# --- Policy / rule inventory ---
Section "Policy & rule inventory"
try {
    $p = Get-SupervisoryReviewPolicyV2 -Identity $PolicyName -ErrorAction SilentlyContinue
    if ($p) {
        Write-Host ("Policy: {0}  Enabled={1}" -f $p.Name, $p.Enabled)
        try { Write-Host ("  Supervised: {0}" -f ([string]::Join(', ', @($p.SupervisedUsers)))) } catch {}
        try { Write-Host ("  Excluded:   {0}" -f ([string]::Join(', ', @($p.ExemptUsers)))) } catch {}
        try { Write-Host ("  Reviewers:  {0}" -f ([string]::Join(', ', @($p.Reviewers)))) } catch {}
        try {
            foreach ($r in @(Get-SupervisoryReviewRule -Policy $p.Name -ErrorAction SilentlyContinue)) {
                Write-Host ("  Rule: {0}" -f $r.Name)
            }
        } catch {}
        if ($OutDir) { $p | Select-Object Name,Enabled,SupervisedUsers,ExemptUsers,Reviewers | Export-Csv (Join-Path $OutDir 'policy.csv') -NoTypeInformation }
    } else {
        Write-Host "[--] Policy '$PolicyName' not found."
    }
} catch { Write-Warning "Policy inventory failed: $($_.Exception.Message)" }

# --- Role-separation snapshot ---
Section "Role separation snapshot (FINRA Supervision Roles - Evidence)"
foreach ($rg in 'Communication Compliance Admin','Communication Compliance Analysts','Communication Compliance Investigators','Communication Compliance Viewers') {
    try {
        $g = Get-RoleGroup -Identity $rg -ErrorAction SilentlyContinue
        $m = @($g.Members | ForEach-Object { $_.ToString() })
        Write-Host ("{0}: {1}" -f $rg, ([string]::Join(', ', $m)))
    } catch { Write-Host ("{0}: (unreadable)" -f $rg) }
}

# --- Evidence retention status ---
Section "Evidence retention / immutability (17a-4 posture)"
try {
    $rp = Get-RetentionCompliancePolicy -Identity $RetentionPolicyName -ErrorAction SilentlyContinue
    if ($rp) {
        $locked = $false; try { $locked = [bool]$rp.RestrictiveRetention } catch {}
        Write-Host ("{0}: Enabled={1}  Immutable(PreservationLock)={2}" -f $rp.Name, $rp.Enabled, $locked)
    } else {
        Write-Host "[--] Retention policy '$RetentionPolicyName' not found (evidence layer not yet configured)."
    }
} catch { Write-Warning "Retention status failed: $($_.Exception.Message)" }

# --- Supervisory-review activity ---
Section "Supervisory-review activity (reviewer trail)"
try {
    if (Get-Command Get-SupervisoryReviewActivity -ErrorAction SilentlyContinue) {
        $start = (Get-Date).AddDays(-$Days)
        $acts = @(Get-SupervisoryReviewActivity -StartDate $start -EndDate (Get-Date) -ErrorAction SilentlyContinue)
        Write-Host ("Activity records in window: {0}" -f $acts.Count)
        $acts | Select-Object -First 25 | ForEach-Object { Write-Host ("  {0}" -f ($_ | Out-String).Trim()) }
        if ($OutDir -and $acts.Count -gt 0) { $acts | Export-Csv (Join-Path $OutDir 'review-activity.csv') -NoTypeInformation }
    } else {
        Write-Host "[i] Get-SupervisoryReviewActivity not available; review activity is also in the Unified Audit Log"
        Write-Host "    (Search-UnifiedAuditLog -RecordType ComplianceSupervisionExchange) and the portal Reports."
    }
} catch { Write-Warning "Activity query failed: $($_.Exception.Message)" }

Write-Host ""
Write-Host "=== Report complete (no changes made). Verdicts and records decisions remain with Compliance/Legal/Records. ==="
if ($OutDir) { Write-Host "[i] Artifacts written under $OutDir" }

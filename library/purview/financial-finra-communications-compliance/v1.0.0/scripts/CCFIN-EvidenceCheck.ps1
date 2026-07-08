<#
.SYNOPSIS
    Read-only scope + evidence health helper: verifies the supervised/excluded scope and the immutable
    communications-retention (SEC 17a-4 posture) coverage (safe: makes NO changes).
.DESCRIPTION
    The program health helper. Reports whether the supervisory-review policy is scoped to the approved
    registered population (and not "everyone"), whether the exclusion group is applied, and whether the
    evidence-retention policy covers communications and is immutable (Preservation Lock) where the
    records decision requires it. Flags scope creep and evidence gaps. Read-only.
.EXAMPLE
    .\CCFIN-EvidenceCheck.ps1
    Prints the scope + evidence health summary for the default pilot artifacts.
.EXAMPLE
    .\CCFIN-EvidenceCheck.ps1 -RequireImmutable
    Also flags FAIL if the evidence retention is not locked. (PS 5.1+/7+; Connect-IPPSSession.)
.NOTES
    Expected results: scope equals the approved group with exclusions applied, and evidence retention
    exists (locked if -RequireImmutable). Any gap is flagged with the Implementation step to fix it. No
    changes are made; never applies a lock. Cmdlet availability is plan-dependent. No secrets in code.
#>
[CmdletBinding()]
param(
    [string]$PolicyName          = 'FINRA Supervision - Pilot - Simulation',
    [string]$SupervisedGroup     = 'FINRA Supervised - Pilot',
    [string]$ExclusionGroup      = 'FINRA Excluded - Privacy',
    [string]$RetentionPolicyName = 'FINRA Comms Records - 17a-4',
    [switch]$RequireImmutable
)

$ErrorActionPreference = 'Stop'
$issues = 0
function Flag([string]$m) { Write-Host "[GAP]  $m"; $script:issues++ }
function Good([string]$m) { Write-Host "[OK]   $m" }
function Info([string]$m) { Write-Host "[i]    $m" }

Write-Host "==================================================================="
Write-Host " CCFIN Evidence & Scope Health (READ-ONLY)  $(Get-Date -Format s)"
Write-Host "==================================================================="

try {
    if (-not (Get-Command Get-SupervisoryReviewPolicyV2 -ErrorAction SilentlyContinue)) {
        Connect-IPPSSession -ErrorAction Stop | Out-Null
    }
} catch {
    Write-Error "Could not connect to Security & Compliance PowerShell: $($_.Exception.Message)"
    return
}

# --- Scope health ---
Write-Host ""
Write-Host "--- Supervised scope health ---"
$p = $null
try { $p = Get-SupervisoryReviewPolicyV2 -Identity $PolicyName -ErrorAction SilentlyContinue } catch {}
if (-not $p) {
    Flag "Policy '$PolicyName' not found - nothing scoped yet (Implementation Steps 3-4)."
} else {
    $supervised = @(); $excluded = @()
    try { $supervised = @($p.SupervisedUsers) } catch {}
    try { $excluded   = @($p.ExemptUsers) } catch {}
    if (($supervised -contains 'All') -or ($supervised -contains 'Everyone') -or ($supervised.Count -eq 0)) {
        Flag "Supervised scope looks over-broad or empty: [$([string]::Join(',',$supervised))]. Scope to the approved registered population (Requirement 2.3)."
    } else {
        Good "Supervised scope is a defined population: [$([string]::Join(',',$supervised))]"
        if ($supervised -notcontains $SupervisedGroup) { Info "Expected group '$SupervisedGroup' not literally listed - confirm the named group is correct." }
    }
    if ($excluded.Count -eq 0) {
        Info "No exclusion set on the policy - confirm '$ExclusionGroup' is intended to be empty (Requirement 2.3/2.7)."
    } else {
        Good "Exclusions applied: [$([string]::Join(',',$excluded))]"
    }
}

# --- Evidence (retention/immutability) health ---
Write-Host ""
Write-Host "--- Evidence retention health (17a-4 posture) ---"
$rp = $null
try { $rp = Get-RetentionCompliancePolicy -Identity $RetentionPolicyName -ErrorAction SilentlyContinue } catch {}
if (-not $rp) {
    Flag "Evidence-retention policy '$RetentionPolicyName' not found - supervised comms may not be preserved (Implementation Step 7)."
} else {
    Good "Retention policy '$RetentionPolicyName' exists (Enabled=$($rp.Enabled))."
    $locked = $false; try { $locked = [bool]$rp.RestrictiveRetention } catch {}
    if ($locked) {
        Good "Retention is IMMUTABLE (Preservation Lock) - tamper-evident, cannot be shortened/disabled/deleted."
    } else {
        if ($RequireImmutable) {
            Flag "Retention is NOT locked but immutability was required. Apply Preservation Lock ONLY with written Compliance/Records approval (Step 7)."
        } else {
            Info "Retention is not locked. Lock only if the records decision (Requirement 2.6) requires immutability - it is irreversible."
        }
    }
    Info "Whether this policy covers ALL in-scope supervised workloads for the approved period is a Compliance/Records determination - confirm scope in the portal."
}

# --- Summary ---
Write-Host ""
Write-Host "-------------------------------------------------------------------"
if ($issues -eq 0) {
    Write-Host "HEALTH: OK - scope is defined and evidence retention is present. (Coverage adequacy is a Compliance/Records call.)"
} else {
    Write-Host "HEALTH: $issues gap(s) flagged - resolve per the referenced Implementation steps, then re-run."
}
Write-Host "-------------------------------------------------------------------"

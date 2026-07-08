<#
.SYNOPSIS
    Create/update the FINRA/SEC supervisory-review policy + rule in SIMULATION (safe: -WhatIf by default;
    writes require -Commit; irreversible retention lock requires an extra explicit switch).
.DESCRIPTION
    Builds the 'FINRA Supervision - Pilot - Simulation' supervisory-review policy and 'FINRA Conduct Rule
    - Pilot' rule (lexicons/classifiers, supervised scope, designated-principal reviewers, sampling) via
    the New-SupervisoryReviewPolicyV2 / New-SupervisoryReviewRule cmdlets, and can optionally configure
    the evidence-retention policy. Nothing is changed unless -Commit is passed; the irreversible
    Preservation Lock additionally requires -ApplyPreservationLock.
.EXAMPLE
    .\CCFIN-Configuration.ps1 -SupervisedGroup 'FINRA Supervised - Pilot' -Reviewers 'principal1@contoso.com' -WhatIf
    Previews exactly what would be created; makes NO changes (default).
.EXAMPLE
    .\CCFIN-Configuration.ps1 -SupervisedGroup 'FINRA Supervised - Pilot' -Reviewers 'principal1@contoso.com' -SamplingPercentage 20 -Commit
    Creates the simulation policy/rule. (PowerShell 5.1+/7+; Connect-IPPSSession.)
.EXAMPLE
    .\CCFIN-Configuration.ps1 -Remove -Commit
    Removes the pilot policy (rollback). No supervised communications are affected.
.NOTES
    Expected results: with -WhatIf, prints the intended objects and exits (PASS = plan looks correct).
    With -Commit, the policy/rule exist and are scoped to the pilot in SIMULATION. Preservation Lock is
    PERMANENT and only applied with -ApplyPreservationLock -Commit under written Compliance/Records
    approval. Cmdlet/classifier availability is plan-dependent - verify in your tenant. No secrets in code.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$PolicyName        = 'FINRA Supervision - Pilot - Simulation',
    [string]$RuleName          = 'FINRA Conduct Rule - Pilot',
    [string]$SupervisedGroup   = 'FINRA Supervised - Pilot',
    [string]$ExclusionGroup    = 'FINRA Excluded - Privacy',
    [string[]]$Reviewers,
    # Regulated-conduct classifiers to attach (availability plan-dependent; some in preview - verify):
    [string[]]$Classifiers     = @('Money laundering','Stock manipulation','Unauthorized disclosure','Gifts & entertainment','Customer complaints'),
    [ValidateRange(1,100)][int]$SamplingPercentage = 10,
    [switch]$Remove,
    [switch]$Commit,
    # Evidence layer (optional):
    [switch]$ConfigureRetention,
    [string]$RetentionPolicyName = 'FINRA Comms Records - 17a-4',
    [switch]$ApplyPreservationLock
)

$ErrorActionPreference = 'Stop'
$doWrite = $Commit.IsPresent
function Plan([string]$m) { if ($doWrite) { Write-Host "[APPLY] $m" } else { Write-Host "[WHATIF] $m" } }

Write-Host "==================================================================="
Write-Host " CCFIN Configuration  (mode: $(if($doWrite){'COMMIT'}else{'WHATIF (no changes)'}))"
Write-Host "==================================================================="

try {
    if (-not (Get-Command Get-SupervisoryReviewPolicyV2 -ErrorAction SilentlyContinue)) {
        Write-Host "[*] Connecting to Security & Compliance PowerShell..."
        Connect-IPPSSession -ErrorAction Stop | Out-Null
    }
} catch {
    Write-Error "Could not connect to Security & Compliance PowerShell: $($_.Exception.Message)"
    return
}

# --- Rollback path ---
if ($Remove) {
    Plan "Remove supervisory-review policy '$PolicyName' (and its rules)."
    if ($doWrite -and $PSCmdlet.ShouldProcess($PolicyName, "Remove supervisory-review policy")) {
        try {
            Remove-SupervisoryReviewPolicyV2 -Identity $PolicyName -Confirm:$false -ErrorAction Stop
            Write-Host "[OK] Removed '$PolicyName'. No supervised communications were affected."
        } catch { Write-Error "Remove failed: $($_.Exception.Message)" }
    }
    return
}

# --- Guardrails before build ---
if (-not $Reviewers -or $Reviewers.Count -eq 0) {
    Write-Warning "No -Reviewers supplied. Designated principals (Analysts) MUST review; supply reviewers before -Commit."
    if ($doWrite) { Write-Error "Refusing to create a supervisory policy with no reviewers."; return }
}

# --- 1. Policy (simulation-first) ---
Write-Host ""
Write-Host "--- 1. Supervisory-review policy (lexicons + scope + reviewers) ---"
Plan "Create policy '$PolicyName'  Supervised='$SupervisedGroup'  Excluded='$ExclusionGroup'  Reviewers=[$([string]::Join(', ',$Reviewers))]"
$existing = $null
try { $existing = Get-SupervisoryReviewPolicyV2 -Identity $PolicyName -ErrorAction SilentlyContinue } catch {}

if ($doWrite -and $PSCmdlet.ShouldProcess($PolicyName, "Create/verify supervisory-review policy (SIMULATION scope)")) {
    try {
        if ($existing) {
            Write-Host "[OK] Policy '$PolicyName' already exists - leaving scope/reviewers as-is (adjust in portal or -Remove first)."
        } else {
            New-SupervisoryReviewPolicyV2 -Name $PolicyName `
                -Reviewers $Reviewers `
                -SupervisedUsers $SupervisedGroup `
                -ExemptUsers $ExclusionGroup -ErrorAction Stop | Out-Null
            Write-Host "[OK] Created policy '$PolicyName' scoped to the pilot (simulation)."
        }
    } catch {
        Write-Error "Policy create failed (verify cmdlet availability / licensing - Requirement 2.1): $($_.Exception.Message)"
        return
    }
}

# --- 2. Rule (classifiers/lexicon/conditions/sampling) ---
Write-Host ""
Write-Host "--- 2. Rule: classifiers + FINRA Lexicon - Conduct + sampling $SamplingPercentage% ---"
Plan "Create rule '$RuleName' on '$PolicyName' with classifiers [$([string]::Join(', ',$Classifiers))] and sampling $SamplingPercentage%."
Write-Host "[i] Attach the firm keyword dictionary 'FINRA Lexicon - Conduct' (Compliance-supplied terms) to this rule in the portal"
Write-Host "    if it cannot be expressed via cmdlet in your tenant. Do NOT invent terms - Compliance owns the lexicon (Requirement 2.4)."
if ($doWrite -and $PSCmdlet.ShouldProcess($RuleName, "Create supervisory-review rule (simulation)")) {
    try {
        New-SupervisoryReviewRule -Name $RuleName -Policy $PolicyName `
            -Ccsi $Classifiers `
            -SamplingRate $SamplingPercentage -ErrorAction Stop | Out-Null
        Write-Host "[OK] Created rule '$RuleName' (simulation). Verify classifier binding + lexicon in the portal."
    } catch {
        Write-Warning "Rule create via cmdlet failed (parameter names vary by tenant version): $($_.Exception.Message)"
        Write-Warning "Complete the rule (classifiers, lexicon, conditions, sampling) in the portal, then re-run CCFIN-Validation.ps1."
    }
}

# --- 3. Optional: evidence retention (never locks by default) ---
if ($ConfigureRetention) {
    Write-Host ""
    Write-Host "--- 3. Evidence-retention policy '$RetentionPolicyName' (17a-4 posture) ---"
    Plan "Ensure retention policy '$RetentionPolicyName' exists over the supervised comms (period set by Compliance/Records)."
    if ($doWrite -and $PSCmdlet.ShouldProcess($RetentionPolicyName, "Create/verify retention policy")) {
        try {
            $rp = Get-RetentionCompliancePolicy -Identity $RetentionPolicyName -ErrorAction SilentlyContinue
            if (-not $rp) {
                Write-Host "[i] Create '$RetentionPolicyName' with the approved scope/period in the portal or via New-RetentionCompliancePolicy;"
                Write-Host "    period + immutability are a Compliance/Records determination (Requirement 2.6). Not auto-created here."
            } else {
                Write-Host "[OK] Retention policy '$RetentionPolicyName' exists."
            }
        } catch { Write-Warning "Retention check failed: $($_.Exception.Message)" }
    }

    if ($ApplyPreservationLock) {
        Write-Host ""
        Write-Host "*** PRESERVATION LOCK IS PERMANENT AND IRREVERSIBLE ***"
        Plan "Apply Preservation Lock (RestrictiveRetention) to '$RetentionPolicyName' - CANNOT be undone."
        if (-not $doWrite) {
            Write-Host "[WHATIF] Lock NOT applied. Re-run with -ApplyPreservationLock -Commit AND written Compliance/Records approval."
        } elseif ($PSCmdlet.ShouldProcess($RetentionPolicyName, "APPLY IRREVERSIBLE Preservation Lock")) {
            try {
                Set-RetentionCompliancePolicy -Identity $RetentionPolicyName -RestrictiveRetention $true -ErrorAction Stop
                Write-Host "[OK] Preservation Lock applied. '$RetentionPolicyName' is now immutable (tamper-evident, cannot be shortened/deleted)."
            } catch { Write-Error "Lock failed: $($_.Exception.Message)" }
        }
    }
}

Write-Host ""
if ($doWrite) {
    Write-Host "=== Configuration committed. Policy is in SIMULATION - validate with CCFIN-Validation.ps1 before any expansion. ==="
} else {
    Write-Host "=== WHATIF complete - no changes made. Re-run with -Commit to apply (lock needs -ApplyPreservationLock too). ==="
}

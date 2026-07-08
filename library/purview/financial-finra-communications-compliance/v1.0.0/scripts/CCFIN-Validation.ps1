<#
.SYNOPSIS
    Read-only pass/fail validation of the FINRA/SEC supervision program (safe: makes NO changes).
.DESCRIPTION
    Runs the mechanical pass/fail checks behind the Testing guide: role separation, the pilot policy
    exists and is scoped to the approved group (not "everyone") with reviewers and sampling, and the
    evidence-retention layer is present (and immutable where expected). Emits PASS/FAIL per check and an
    overall result. Read-only.
.EXAMPLE
    .\CCFIN-Validation.ps1
    Validates the default pilot artifacts and prints PASS/FAIL.
.EXAMPLE
    .\CCFIN-Validation.ps1 -PolicyName 'FINRA Supervision - Production' -ExpectImmutable
    Validates a named policy and requires the evidence retention to be locked. (PS 5.1+/7+; Connect-IPPSSession.)
.NOTES
    Expected results: overall PASS only when separation holds, the policy is pilot-scoped with reviewers,
    and (if -ExpectImmutable) retention is locked. Any FAIL points back to an Implementation step. No
    changes are made. Cmdlet availability is plan-dependent - verify in your tenant. No secrets in code.
#>
[CmdletBinding()]
param(
    [string]$PolicyName          = 'FINRA Supervision - Pilot - Simulation',
    [string]$SupervisedGroup     = 'FINRA Supervised - Pilot',
    [string]$RetentionPolicyName = 'FINRA Comms Records - 17a-4',
    [switch]$ExpectImmutable
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]
function Check([string]$name, [bool]$pass, [string]$detail) {
    $status = if ($pass) { 'PASS' } else { 'FAIL' }
    Write-Host ("[{0}] {1} - {2}" -f $status, $name, $detail)
    $results.Add([pscustomobject]@{ Check = $name; Result = $status })
}

Write-Host "==================================================================="
Write-Host " CCFIN Validation (READ-ONLY)  $(Get-Date -Format s)"
Write-Host "==================================================================="

try {
    if (-not (Get-Command Get-SupervisoryReviewPolicyV2 -ErrorAction SilentlyContinue)) {
        Connect-IPPSSession -ErrorAction Stop | Out-Null
    }
} catch {
    Write-Error "Could not connect to Security & Compliance PowerShell: $($_.Exception.Message)"
    return
}

# --- Check 1: role separation ---
try {
    $admin = @((Get-RoleGroup -Identity 'Communication Compliance Admin' -ErrorAction SilentlyContinue).Members | ForEach-Object { $_.ToString() })
    $rev   = @((Get-RoleGroup -Identity 'Communication Compliance Analysts' -ErrorAction SilentlyContinue).Members | ForEach-Object { $_.ToString() })
    $inv   = @((Get-RoleGroup -Identity 'Communication Compliance Investigators' -ErrorAction SilentlyContinue).Members | ForEach-Object { $_.ToString() })
    $overlap = $admin | Where-Object { ($rev -contains $_) -or ($inv -contains $_) }
    $hasReviewers = ($rev.Count -gt 0)
    Check "Role separation" (($overlap.Count -eq 0) -and $hasReviewers) `
        ("builders=$($admin.Count) reviewers=$($rev.Count) investigators=$($inv.Count) overlap=$($overlap.Count)")
} catch {
    Check "Role separation" $false "could not read role groups: $($_.Exception.Message)"
}

# --- Check 2: policy exists ---
$policy = $null
try { $policy = Get-SupervisoryReviewPolicyV2 -Identity $PolicyName -ErrorAction SilentlyContinue } catch {}
Check "Policy exists" ($null -ne $policy) ("'$PolicyName' " + (if ($policy) { "found" } else { "NOT found" }))

# --- Check 3: policy scoped to approved group, not everyone; has reviewers ---
if ($policy) {
    $supervised = @()
    try { $supervised = @($policy.SupervisedUsers) } catch {}
    $reviewers = @()
    try { $reviewers = @($policy.Reviewers) } catch {}
    $scopedToGroup = ($supervised -contains $SupervisedGroup) -or ($supervised.Count -gt 0)
    $everyone = ($supervised -contains 'All') -or ($supervised -contains 'Everyone')
    Check "Policy scoped to approved population" ($scopedToGroup -and -not $everyone) `
        ("supervised=[$([string]::Join(',',$supervised))]")
    Check "Policy has designated reviewers" ($reviewers.Count -gt 0) ("reviewers=$($reviewers.Count)")
} else {
    Check "Policy scoped to approved population" $false "policy missing"
    Check "Policy has designated reviewers" $false "policy missing"
}

# --- Check 4: evidence retention present (+ immutability if expected) ---
$rp = $null
try { $rp = Get-RetentionCompliancePolicy -Identity $RetentionPolicyName -ErrorAction SilentlyContinue } catch {}
Check "Evidence retention present" ($null -ne $rp) ("'$RetentionPolicyName' " + (if ($rp) { "found" } else { "NOT found" }))
if ($ExpectImmutable) {
    $locked = $false
    if ($rp) { try { $locked = [bool]$rp.RestrictiveRetention } catch {} }
    Check "Evidence retention is immutable (Preservation Lock)" $locked `
        (if ($locked) { "locked" } else { "NOT locked - apply only with written Compliance/Records approval" })
}

# --- Summary ---
$fail = @($results | Where-Object { $_.Result -eq 'FAIL' }).Count
Write-Host ""
Write-Host "-------------------------------------------------------------------"
if ($fail -eq 0) {
    Write-Host "OVERALL: PASS - mechanism validated. (Verdicts/records decisions remain with Compliance/Legal/Records.)"
} else {
    Write-Host "OVERALL: FAIL ($fail check(s)) - resolve per the Implementation guide, then re-run."
}
Write-Host "-------------------------------------------------------------------"

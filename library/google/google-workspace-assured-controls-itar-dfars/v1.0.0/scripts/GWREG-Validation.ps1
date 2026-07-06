<#
.SYNOPSIS
    GWREG-Validation.ps1 — per-scope controlled-data controls validation against the required posture (read-only).
.DESCRIPTION
    PURPOSE
        Read-only pass/fail validation of each controlled-data control on a target scope (OU) AGAINST
        the required posture that legal/compliance approved: data region (e.g. United States), Access
        Management policy (e.g. us-only or cjis-irs), Access Approvals on, and CSE where relied upon.
        The REQUIRED values are supplied as parameters - the script does not decide them; it only checks
        the live/observed state matches. Regulatory sufficiency remains a legal/compliance determination.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWREG-Validation.ps1 -OrgUnitPath /Controlled `
            -RequiredRegion unitedstates -RequiredAccessMgmt us-only -RequireAccessApprovals `
            [-RequireCSE] [-CustomerId your-customer-id]
        Requires a super-admin OAuth token in GOOGLE_OAUTH_TOKEN with READ-ONLY compliance/reporting
        scopes for the surfaces you validate. Nothing is written. Where a control cannot be read via API,
        the check is reported UNVERIFIED (confirm in the Admin console) rather than passed.
    EXPECTED RESULTS
        A pass/fail (or UNVERIFIED) line per control for the scope, and an overall gate result. FAIL or
        UNVERIFIED blocks the pilot-exit gate until remediated (GWREG-Remediation.ps1) or confirmed in
        the Admin console. Attach the output to the evidence record via GWREG-Report.ps1.
.NOTES
    White-label — the repeatable way. Read-only. Checks OBSERVED state against REQUIRED inputs; does not
    interpret regulation. Assured Controls policy options / add-on gating are cited or flagged "verify in
    your tenant"; unread controls are UNVERIFIED, never assumed compliant.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$OrgUnitPath,
    [ValidateSet('nopreference','unitedstates','europe')][string]$RequiredRegion = 'unitedstates',
    [ValidateSet('no-preference','us-only','cjis-irs','eu-only')][string]$RequiredAccessMgmt = 'us-only',
    [switch]$RequireAccessApprovals,
    [switch]$RequireCSE,
    [string]$CustomerId
)

$token = $env:GOOGLE_OAUTH_TOKEN
if (-not $token) {
    Write-Host "Set GOOGLE_OAUTH_TOKEN to a super-admin OAuth access token (e.g. 'gcloud auth print-access-token')." -ForegroundColor Red
    return
}

$results = New-Object System.Collections.Generic.List[object]
function Add-Result([string]$control, [string]$state, [string]$detail) {
    $results.Add([pscustomobject]@{ Control = $control; Result = $state; Detail = $detail })
    $color = switch ($state) { 'PASS' {'Green'} 'FAIL' {'Red'} default {'Yellow'} }
    Write-Host ("  [{0,-10}] {1} - {2}" -f $state, $control, $detail) -ForegroundColor $color
}

Write-Host "`n=== Controlled-data controls validation — scope: $OrgUnitPath ===" -ForegroundColor Cyan
Write-Host "Required posture (from legal/compliance): region=$RequiredRegion accessMgmt=$RequiredAccessMgmt approvals=$($RequireAccessApprovals.IsPresent) cse=$($RequireCSE.IsPresent)`n"

# NOTE: The compliance settings APIs for Access Management / Access Approvals / Data regions per-OU are
# add-on-gated and not uniformly exposed for read. Where a live read is unavailable, the control is
# reported UNVERIFIED so the operator confirms it in the Admin console (Menu > Data > Compliance > ...).
# This avoids inventing Assured Controls specifics or asserting a pass we cannot observe.

# --- Data region (residency) ---
# Attempt a read where the tenant exposes it; otherwise UNVERIFIED.
Add-Result 'Data region (residency)' 'UNVERIFIED' `
    "Confirm Data > Compliance > Data regions for $OrgUnitPath = '$RequiredRegion' (Data at rest). Advanced reporting confirms in-region."

# --- Access Management (Google-staff support limits) ---
Add-Result 'Access Management policy' 'UNVERIFIED' `
    "Confirm Data > Compliance > Access Management for $OrgUnitPath = '$RequiredAccessMgmt' AND OU is Assured Controls-licensed (policy is silent on unlicensed OUs)."

# --- Access Approvals ---
if ($RequireAccessApprovals) {
    Add-Result 'Access Approvals' 'UNVERIFIED' `
        "Confirm Data > Compliance > Access Approvals is CHECKED for $OrgUnitPath."
} else {
    Add-Result 'Access Approvals' 'PASS' 'Not required for this scope (per legal/compliance input).'
}

# --- Access Transparency (evidence surface) ---
Add-Result 'Access Transparency (evidence)' 'UNVERIFIED' `
    "Confirm Reporting > 'Access Transparency log events' is available/queryable (evidence for Access Management/Approvals)."

# --- Client-side encryption ---
if ($RequireCSE) {
    Add-Result 'Client-side encryption' 'UNVERIFIED' `
        "Legal relies on ITAR e2ee carve-out: confirm Data > Compliance > Client-side encryption ON for required services on $OrgUnitPath, key service connected."
} else {
    Add-Result 'Client-side encryption' 'PASS' 'Not relied upon for this scope (per legal/compliance input).'
}

# --- Gate ---
$fail = ($results | Where-Object Result -eq 'FAIL').Count
$unv  = ($results | Where-Object Result -eq 'UNVERIFIED').Count
Write-Host ""
if ($fail -gt 0) {
    Write-Host "GATE: FAIL - $fail control(s) failed. Remediate (GWREG-Remediation.ps1) and re-validate." -ForegroundColor Red
} elseif ($unv -gt 0) {
    Write-Host "GATE: NOT MET - $unv control(s) UNVERIFIED. Confirm in the Admin console (paths above), then re-run or record confirmation." -ForegroundColor Yellow
} else {
    Write-Host "GATE: technical checks PASS. Legal/compliance must still sign off before expanding." -ForegroundColor Green
}
Write-Host "Reminder: a technical pass is NOT an ITAR/DFARS compliance determination - that is legal/compliance's sign-off." -ForegroundColor DarkYellow

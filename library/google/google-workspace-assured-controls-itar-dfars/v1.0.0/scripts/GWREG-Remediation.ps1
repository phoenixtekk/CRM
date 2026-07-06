<#
.SYNOPSIS
    GWREG-Remediation.ps1 — bring a controlled-data scope to the required posture (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Safely brings a target OU to the REQUIRED controlled-data posture that legal/compliance approved:
        data region (e.g. United States), Access Management policy (e.g. us-only or cjis-irs), and Access
        Approvals on. It DEFAULTS TO -WhatIf and only PREVIEWS the intended changes; nothing is applied
        until you pass -Execute inside an approved change window. It does not decide the required posture
        and never enables CSE automatically (CSE is stood up deliberately per legal - see the guide).
    HOW TO RUN
        Preview (default, safe):
          powershell -ExecutionPolicy Bypass -File .\GWREG-Remediation.ps1 -OrgUnitPath /Controlled `
            -RequiredRegion unitedstates -RequiredAccessMgmt us-only -RequireAccessApprovals
        Apply (only in the approved change window):
          ... same parameters ... -Execute
        Requires a SUPER-ADMIN OAuth token in GOOGLE_OAUTH_TOKEN with the compliance-admin scopes for the
        surfaces changed (Access Management requires super-admin). Re-validate with GWREG-Validation.ps1.
    EXPECTED RESULTS
        In -WhatIf (default): a numbered list of the exact changes that WOULD be made, and no change. With
        -Execute: each change attempted with a pass/fail line. Some compliance settings are applied in the
        Admin console when no write API is available - those are emitted as explicit MANUAL steps, never
        silently skipped.
.NOTES
    White-label — the repeatable way. Default -WhatIf; changes only with -Execute in an approved window.
    Required posture comes from legal/compliance, not this script. Assured Controls policy options / write
    surfaces are add-on-gated and cited or flagged "verify in your tenant"; never invents specifics.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$OrgUnitPath,
    [ValidateSet('nopreference','unitedstates','europe')][string]$RequiredRegion = 'unitedstates',
    [ValidateSet('no-preference','us-only','cjis-irs','eu-only')][string]$RequiredAccessMgmt = 'us-only',
    [switch]$RequireAccessApprovals,
    [switch]$Execute
)

$WhatIf = -not $Execute
$token = $env:GOOGLE_OAUTH_TOKEN
if (-not $token) {
    Write-Host "Set GOOGLE_OAUTH_TOKEN to a SUPER-ADMIN OAuth access token (e.g. 'gcloud auth print-access-token')." -ForegroundColor Red
    return
}

Write-Host "`n=== Controlled-data remediation — scope: $OrgUnitPath ===" -ForegroundColor Cyan
if ($WhatIf) { Write-Host "MODE: -WhatIf (PREVIEW ONLY - no changes). Pass -Execute in an approved change window to apply.`n" -ForegroundColor Yellow }
else { Write-Host "MODE: -Execute (LIVE CHANGES). Ensure change approval + rollback are in place.`n" -ForegroundColor Red }
Write-Host "Required posture (from legal/compliance): region=$RequiredRegion accessMgmt=$RequiredAccessMgmt approvals=$($RequireAccessApprovals.IsPresent)`n"

$plan = New-Object System.Collections.Generic.List[string]
$plan.Add("Set Data region (data at rest) = '$RequiredRegion' for OU '$OrgUnitPath'  [Menu > Data > Compliance > Data regions]")
$plan.Add("Set Access Management policy = '$RequiredAccessMgmt' for OU '$OrgUnitPath' (confirm OU is Assured Controls-licensed)  [Menu > Data > Compliance > Access Management, super-admin]")
if ($RequireAccessApprovals) {
    $plan.Add("Enable Access Approvals (require Google-staff approval before viewing support data) for OU '$OrgUnitPath'  [Menu > Data > Compliance > Access Approvals]")
}

$i = 0
foreach ($step in $plan) {
    $i++
    if ($WhatIf) {
        Write-Host ("  WHATIF {0}. {1}" -f $i, $step) -ForegroundColor Yellow
    } else {
        # Per-OU compliance settings (Access Management / Access Approvals / Data regions) are add-on-gated
        # and not uniformly writable via public API. Where no write API is available, emit as a MANUAL
        # Admin-console step so nothing is silently skipped and no specifics are invented.
        Write-Host ("  MANUAL {0}. {1}" -f $i, $step) -ForegroundColor Cyan
        Write-Host "         Apply in the Admin console (path above), then verify. If a write API is enabled"
        Write-Host "         for your tenant, script it here with least-privilege scope - verify in your tenant."
    }
}

Write-Host ""
Write-Host "CSE is NOT remediated automatically - it is stood up deliberately per legal (Implementation Step 5)." -ForegroundColor DarkYellow
if ($WhatIf) { Write-Host "No changes made. Review with the change approver, then re-run with -Execute." -ForegroundColor Yellow }
else { Write-Host "After applying, re-run GWREG-Validation.ps1 and GWREG-Report.ps1 for the scope." -ForegroundColor Green }
Write-Host "Rollback: revert region to No Preference, restore prior Access Management policy, uncheck Access Approvals - per the change ticket." -ForegroundColor DarkYellow

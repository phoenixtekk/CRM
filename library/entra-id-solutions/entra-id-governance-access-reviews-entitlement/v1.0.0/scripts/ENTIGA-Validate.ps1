<#
.SYNOPSIS
    ENTIGA-Validate.ps1 — validate the named ENTIGA governance objects are present and wired (read-only).
.DESCRIPTION
    PURPOSE
        The automated form of the pilot gate table. Confirms the objects from the implementation guide
        exist and are correctly configured: the access package has an approval policy WITH an expiry,
        each access review has auto-apply enabled, and each lifecycle workflow is enabled. Reports each
        check as PASS / FAIL / WARN so you know exactly what to fix before expanding.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTIGA-Validate.ps1
        Optional: -Prefix 'ENTIGA' to match objects by naming convention (default 'ENTIGA').
    EXPECTED RESULTS
        A checklist with PASS/FAIL per gate and a final count. PASS on all gates = ready to expand.
.NOTES
    White-label — Entra ID Solutions. Read-only against Microsoft Graph. No credentials stored.
.EXAMPLE
    .\ENTIGA-Validate.ps1 -Prefix 'ENTIGA'
#>
[CmdletBinding()] param([string]$Prefix = 'ENTIGA')

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'EntitlementManagement.Read.All','AccessReview.Read.All','LifecycleWorkflows.Read.All' -NoWelcome

$pass = 0; $fail = 0; $warn = 0
function Check($ok, $msg, [switch]$Warn) {
    if ($ok)      { Write-Host "  [PASS] $msg" -ForegroundColor Green; $script:pass++ }
    elseif ($Warn){ Write-Host "  [WARN] $msg" -ForegroundColor Yellow; $script:warn++ }
    else          { Write-Host "  [FAIL] $msg" -ForegroundColor Red; $script:fail++ }
}
function Get-AllPages([string]$Uri) {
    $items=@(); do { $r=Invoke-MgGraphRequest -Method GET -Uri $Uri; $items+=$r.value; $Uri=$r.'@odata.nextLink' } while ($Uri); return $items
}

Write-Host "`n=== ENTIGA validation (prefix '$Prefix') ===" -ForegroundColor Cyan

# Catalog
$cats = Get-AllPages "/v1.0/identityGovernance/entitlementManagement/catalogs"
$cat  = $cats | Where-Object displayName -like "$Prefix*" | Select-Object -First 1
Check ($null -ne $cat) "Governance catalog '$Prefix - Catalog - *' exists"
if ($cat) { Check ($cat.isExternallyVisible -eq $true) "Catalog is enabled for external users (guests can request)" -Warn }

# Access package + policies (approval + expiry)
$pkgs = Get-AllPages "/v1.0/identityGovernance/entitlementManagement/accessPackages?`$expand=assignmentPolicies"
$pkg  = $pkgs | Where-Object displayName -like "$Prefix*" | Select-Object -First 1
Check ($null -ne $pkg) "Access package '$Prefix - Package - *' exists"
if ($pkg) {
    $hasApproval = $pkg.assignmentPolicies | Where-Object { $_.requestApprovalSettings.isApprovalRequired -eq $true }
    Check ($null -ne $hasApproval) "At least one assignment policy requires approval"
    $hasExpiry = $pkg.assignmentPolicies | Where-Object { $_.expiration.type -ne 'noExpiration' -and $null -ne $_.expiration }
    Check ($null -ne $hasExpiry) "At least one assignment policy is time-bound (has an expiry)"
    $guestPol = $pkg.assignmentPolicies | Where-Object { $_.displayName -like '*Guest*' }
    Check ($null -ne $guestPol) "A guest / external assignment policy exists" -Warn
}

# Access reviews (auto-apply)
$reviews = Get-AllPages "/v1.0/identityGovernance/accessReviews/definitions"
$entRev  = $reviews | Where-Object displayName -like "$Prefix*"
Check ($entRev.Count -ge 1) "At least one ENTIGA access review definition exists ($($entRev.Count) found)"
foreach ($r in $entRev) {
    Check ($r.settings.autoApplyDecisionsEnabled -eq $true) "Review '$($r.displayName)' has auto-apply enabled" -Warn
}

# Lifecycle workflows (enabled)
$wfs   = Get-AllPages "/v1.0/identityGovernance/lifecycleWorkflows/workflows"
$entWf = $wfs | Where-Object displayName -like "$Prefix*"
Check ($entWf.Count -ge 1) "At least one ENTIGA lifecycle workflow exists ($($entWf.Count) found)"
foreach ($w in $entWf) {
    Check ($w.isEnabled -eq $true) "Workflow '$($w.displayName)' is enabled" -Warn
    Check ($w.tasks.Count -ge 1) "Workflow '$($w.displayName)' has at least one task"
}

Write-Host ("`nResult: {0} PASS, {1} WARN, {2} FAIL" -f $pass,$warn,$fail) -ForegroundColor Cyan
if ($fail -eq 0) { Write-Host "All hard gates passed — review any WARNings, then expand." -ForegroundColor Green }
else { Write-Host "Fix the FAIL items before expanding (see 06-troubleshooting)." -ForegroundColor Red }
Disconnect-MgGraph | Out-Null

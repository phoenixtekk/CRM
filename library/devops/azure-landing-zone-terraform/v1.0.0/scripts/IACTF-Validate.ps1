<#
.SYNOPSIS
    IACTF-Validate.ps1 — pre/post-apply validation: state backend, plan/drift, provider pinning (plan-only).
.DESCRIPTION
    PURPOSE
        The safety pre-flight around the Terraform run. Verifies (1) the remote state backend is
        reachable and versioned, (2) `terraform plan` in detailed-exitcode mode — exit 2 = pending
        changes/drift, exit 0 = no changes, exit 1 = error, and (3) that providers are PINNED and the
        lock file is committed. It NEVER applies — it is a plan/what-if-only gate.
    HOW TO RUN
        Full check:    .\IACTF-Validate.ps1 -TfDir . -StateRg rg-iactf-tfstate -StateSa stiactftfstate<unique>
        Backend only:  .\IACTF-Validate.ps1 -BackendOnly -StateRg rg-iactf-tfstate -StateSa stiactftfstate<unique>
    EXPECTED RESULTS
        PASS/FAIL lines for backend, provider pinning, and the plan exit code. A clean run = ready to
        review the plan and (via the pipeline, approval-gated) apply.
.NOTES
    White-label — DevOps / IaC. Plan/what-if only — this script never runs `terraform apply`.
    Requires terraform + Az on PATH. No credentials stored.
.EXAMPLE
    .\IACTF-Validate.ps1 -BackendOnly -StateRg rg-iactf-tfstate -StateSa stiactftfstateabc123
#>
[CmdletBinding()]
param(
    [string]$TfDir = ".",
    [string]$StateRg,
    [string]$StateSa,
    [string]$StateContainer = "tfstate",
    [switch]$BackendOnly
)

$pass = 0; $fail = 0
function Check($ok, $msg, [switch]$Warn) {
    if ($ok)       { Write-Host "  [PASS] $msg" -ForegroundColor Green; $script:pass++ }
    elseif ($Warn) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
    else           { Write-Host "  [FAIL] $msg" -ForegroundColor Red; $script:fail++ }
}

Write-Host "`n=== IACTF validation (plan/what-if only) ===" -ForegroundColor Cyan

# --- 1. State backend reachable + versioned -----------------------------------
if ($StateRg -and $StateSa) {
    if (-not (Get-Module -ListAvailable -Name Az.Storage)) { Install-Module Az.Storage -Scope CurrentUser -Force -AllowClobber }
    Import-Module Az.Accounts, Az.Storage -ErrorAction SilentlyContinue
    if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
    try {
        $sa = Get-AzStorageAccount -ResourceGroupName $StateRg -Name $StateSa -ErrorAction Stop
        Check $true "State storage account '$StateSa' exists (RG '$StateRg')"
        $ver = (Get-AzStorageBlobServiceProperty -ResourceGroupName $StateRg -StorageAccountName $StateSa -ErrorAction SilentlyContinue).IsVersioningEnabled
        Check ($ver -eq $true) "Blob versioning enabled on the state account" -Warn:([bool]!$ver)
        $ctx = $sa.Context
        $container = Get-AzStorageContainer -Name $StateContainer -Context $ctx -ErrorAction SilentlyContinue
        Check ($null -ne $container) "State container '$StateContainer' present"
    } catch {
        Check $false "State backend not reachable — bootstrap it (03-implementation Step 2). $($_.Exception.Message)"
    }
} else {
    Write-Host "  [WARN] -StateRg/-StateSa not supplied; skipping backend check." -ForegroundColor Yellow
}

if ($BackendOnly) {
    Write-Host ("`nResult (backend-only): {0} PASS, {1} FAIL" -f $pass,$fail) -ForegroundColor Cyan
    return
}

# --- 2. Provider pinning + lock file ------------------------------------------
$mainTf = Join-Path $TfDir "main.tf"
if (Test-Path $mainTf) {
    $content = Get-Content $mainTf -Raw
    Check ($content -match 'required_version') "Terraform required_version is pinned in main.tf"
    Check ($content -match 'version\s*=\s*"~>|version\s*=\s*"=') "Provider versions are pinned (required_providers)"
} else { Check $false "main.tf not found in '$TfDir'" }
Check (Test-Path (Join-Path $TfDir ".terraform.lock.hcl")) "Provider lock file (.terraform.lock.hcl) is committed" -Warn

# --- 3. terraform plan in detailed-exitcode mode (NO apply) -------------------
if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    Check $false "terraform not found on PATH — install the pinned CLI version (02-requirements 2.2)"
} else {
    Push-Location $TfDir
    Write-Host "`n  Running: terraform init -input=false (backend)" -ForegroundColor Gray
    terraform init -input=false | Out-Null
    Write-Host "  Running: terraform plan -detailed-exitcode (what-if only, no apply)" -ForegroundColor Gray
    terraform plan -input=false -detailed-exitcode -out iactf.tfplan
    $code = $LASTEXITCODE
    Pop-Location
    switch ($code) {
        0 { Check $true  "terraform plan: NO changes / no drift (exit 0)"; }
        2 { Write-Host "  [INFO] terraform plan: pending changes or drift (exit 2) — REVIEW the plan before approving apply." -ForegroundColor Yellow }
        default { Check $false "terraform plan errored (exit $code) — see output above / 06-troubleshooting" }
    }
}

Write-Host ("`nResult: {0} PASS, {1} FAIL" -f $pass,$fail) -ForegroundColor Cyan
if ($fail -eq 0) { Write-Host "Validation clean — review the plan, then apply via the approval-gated pipeline." -ForegroundColor Green }
else { Write-Host "Fix the FAIL items before applying (see 06-troubleshooting)." -ForegroundColor Red }

<#
.SYNOPSIS
    IACTF-Report.ps1 — governance report: policy compliance state + Terraform drift summary (read-only).
.DESCRIPTION
    PURPOSE
        Produces the governance/audit evidence for the landing zone: the Azure Policy COMPLIANCE state
        per assignment and scope (so you can confirm guardrails are in Audit and what they would flag
        before promoting to Deny), plus a drift summary from `terraform plan` (resources changed
        outside Terraform). Read-only — never applies.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IACTF-Report.ps1 -TfDir . -CsvFolder C:\Temp\iactf-gov
        Requires Az PowerShell (Az.Accounts, Az.Resources, Az.PolicyInsights) and, for drift, terraform.
    EXPECTED RESULTS
        Compliance table (assignment / scope / compliant vs non-compliant counts) + a drift line, plus
        CSVs. Keep the compliance CSV as governance evidence; a non-empty drift means reconcile in code.
.NOTES
    White-label — DevOps / IaC. Read-only. No credentials stored. Reconcile drift by re-applying code,
    never by editing the portal (06-best-practices).
.EXAMPLE
    .\IACTF-Report.ps1 -CsvFolder C:\Temp\iactf-gov
#>
[CmdletBinding()] param([string]$TfDir = ".", [string]$CsvFolder = ".\iactf-gov")

foreach ($m in 'Az.Accounts','Az.Resources','Az.PolicyInsights') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module $m -Scope CurrentUser -Force -AllowClobber }
    Import-Module $m -ErrorAction SilentlyContinue
}
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if (-not (Test-Path $CsvFolder)) { New-Item -ItemType Directory -Path $CsvFolder | Out-Null }

# --- Policy compliance state ---------------------------------------------------
Write-Host "`n=== Azure Policy compliance (governance evidence) ===" -ForegroundColor Cyan
$assignments = Get-AzPolicyAssignment -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'IACTF*' -or $_.Properties.DisplayName -like 'IACTF*' }
$compRows = @()
try {
    $states = Get-AzPolicyState -ErrorAction Stop
    foreach ($a in $assignments) {
        $forThis = $states | Where-Object { $_.PolicyAssignmentName -eq $a.Name }
        $nonComp = ($forThis | Where-Object ComplianceState -eq 'NonCompliant').Count
        $comp    = ($forThis | Where-Object ComplianceState -eq 'Compliant').Count
        $compRows += [pscustomobject]@{
            Assignment   = $a.Properties.DisplayName
            Scope        = $a.Properties.Scope
            Enforcement  = $a.Properties.EnforcementMode  # Default (enforced) vs DoNotEnforce (audit-like)
            Compliant    = $comp
            NonCompliant = $nonComp
        }
    }
    if ($compRows) { $compRows | Format-Table -AutoSize } else { Write-Host "  (no IACTF policy assignments / no state yet — evaluation is periodic)" -ForegroundColor Yellow }
    if ($compRows) { $compRows | Export-Csv (Join-Path $CsvFolder 'policy-compliance.csv') -NoTypeInformation }
} catch {
    Write-Host "  [WARN] Could not read policy state (rights or no evaluation yet). Trigger: az policy state trigger-scan" -ForegroundColor Yellow
}

# --- Non-compliant resource detail --------------------------------------------
Write-Host "`n=== Non-compliant resources (top 50) ===" -ForegroundColor Cyan
try {
    $nc = Get-AzPolicyState -Filter "ComplianceState eq 'NonCompliant'" -Top 50 -ErrorAction SilentlyContinue
    $ncRows = $nc | ForEach-Object { [pscustomobject]@{ Resource=$_.ResourceId; Policy=$_.PolicyDefinitionName; Assignment=$_.PolicyAssignmentName } }
    if ($ncRows) { $ncRows | Format-Table -AutoSize; $ncRows | Export-Csv (Join-Path $CsvFolder 'non-compliant.csv') -NoTypeInformation }
    else { Write-Host "  (none reported)" -ForegroundColor Green }
} catch {}

# --- Terraform drift summary ---------------------------------------------------
Write-Host "`n=== Terraform drift summary ===" -ForegroundColor Cyan
if (Get-Command terraform -ErrorAction SilentlyContinue) {
    Push-Location $TfDir
    terraform init -input=false | Out-Null
    terraform plan -input=false -detailed-exitcode -out iactf-drift.tfplan *> $null
    $code = $LASTEXITCODE
    Pop-Location
    switch ($code) {
        0 { Write-Host "  No drift — deployed state matches code (exit 0)." -ForegroundColor Green }
        2 { Write-Host "  DRIFT/PENDING CHANGES detected (exit 2) — reconcile by re-applying the code, not the portal." -ForegroundColor Yellow }
        default { Write-Host "  terraform plan errored (exit $code) — see 06-troubleshooting." -ForegroundColor Red }
    }
} else {
    Write-Host "  terraform not on PATH — skipping drift summary." -ForegroundColor Yellow
}

Write-Host "`nGovernance evidence written to $CsvFolder" -ForegroundColor Green

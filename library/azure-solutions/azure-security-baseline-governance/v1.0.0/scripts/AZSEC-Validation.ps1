<#
.SYNOPSIS
    AZSEC-Validation.ps1 — confirm the guardrail assignment, least-privilege RBAC, and the
    PolicyInsights provider are in place at the target scope.
.DESCRIPTION
    PURPOSE
        Read-only validation for the "Azure Security Baseline & Governance" solution. Checks three
        things at the scope in context (or a named subscription / management group):
          1. the named guardrail initiative assignment is present (default name
             'Security Baseline Guardrails - Pilot MG - Audit', override with -AssignmentName);
          2. RBAC is least-privilege — reports the count of standing Owner assignments and whether
             the custom role 'Resource Operator LeastPriv - Pilot Sub - Prod' exists;
          3. the Microsoft.PolicyInsights resource provider is registered.
        Makes no changes; prints PASS/WARN per check.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AZSEC-Validation.ps1
        powershell -ExecutionPolicy Bypass -File .\AZSEC-Validation.ps1 -SubscriptionId '<sub id>'
        powershell -ExecutionPolicy Bypass -File .\AZSEC-Validation.ps1 -ManagementGroupId '<mg id>' -AssignmentName 'Security Baseline Guardrails - Pilot MG - Deny'
        Requires Az.Accounts, Az.Resources, Az.PolicyInsights. Run Connect-AzAccount first, or the
        script will prompt.
    EXPECTED RESULTS
        A short PASS/WARN report: guardrail assignment present, standing-Owner count (0 is best),
        custom least-privilege role present, and PolicyInsights registered — the go/no-go gate before
        moving guardrails to deny or expanding scope.
.NOTES
    Workplace Marketplace — Azure Solutions. Read-only. The repeatable way.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$ManagementGroupId,
    [string]$AssignmentName = 'Security Baseline Guardrails - Pilot MG - Audit',
    [string]$CustomRoleName = 'Resource Operator LeastPriv - Pilot Sub - Prod'
)

foreach ($m in 'Az.Accounts','Az.Resources','Az.PolicyInsights') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Az -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.Resources -ErrorAction Stop
Import-Module Az.PolicyInsights -ErrorAction Stop

if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }

if ($ManagementGroupId) {
    $scope = "/providers/Microsoft.Management/managementGroups/$ManagementGroupId"
} else {
    $scope = "/subscriptions/$((Get-AzContext).Subscription.Id)"
}

Write-Host "`n=== Azure Security Baseline & Governance — validation ===" -ForegroundColor Cyan
Write-Host ("Scope: {0}" -f $scope)
$pass = $true

# 1. Guardrail assignment present
try {
    $a = Get-AzPolicyAssignment -Scope $scope -ErrorAction Stop | Where-Object { $_.Name -eq $AssignmentName -or $_.Properties.DisplayName -eq $AssignmentName }
    if ($a) { Write-Host ("[PASS] Guardrail assignment present: {0}" -f $AssignmentName) -ForegroundColor Green }
    else { Write-Host ("[WARN] Guardrail assignment not found: {0}" -f $AssignmentName) -ForegroundColor Yellow; $pass = $false }
} catch { Write-Host ("[WARN] Could not read assignments: {0}" -f $_.Exception.Message) -ForegroundColor Yellow; $pass = $false }

# 2a. Standing Owner count
try {
    $owners = Get-AzRoleAssignment -Scope $scope -ErrorAction Stop | Where-Object { $_.RoleDefinitionName -eq 'Owner' }
    $count = ($owners | Measure-Object).Count
    if ($count -eq 0) { Write-Host "[PASS] No standing Owner assignments at scope." -ForegroundColor Green }
    else { Write-Host ("[WARN] {0} standing Owner assignment(s) at scope — review for least privilege." -f $count) -ForegroundColor Yellow; $pass = $false }
} catch { Write-Host ("[WARN] Could not read role assignments: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# 2b. Custom least-privilege role exists
try {
    $role = Get-AzRoleDefinition -Name $CustomRoleName -ErrorAction SilentlyContinue
    if ($role) { Write-Host ("[PASS] Custom least-privilege role present: {0}" -f $CustomRoleName) -ForegroundColor Green }
    else { Write-Host ("[WARN] Custom role not found: {0}" -f $CustomRoleName) -ForegroundColor Yellow }
} catch { Write-Host ("[WARN] Could not read role definitions: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# 3. PolicyInsights provider registered (subscription scope only)
if (-not $ManagementGroupId) {
    try {
        $prov = Get-AzResourceProvider -ProviderNamespace Microsoft.PolicyInsights -ErrorAction Stop | Select-Object -First 1
        if ($prov.RegistrationState -eq 'Registered') { Write-Host "[PASS] Microsoft.PolicyInsights registered." -ForegroundColor Green }
        else { Write-Host ("[WARN] Microsoft.PolicyInsights is {0} — register it." -f $prov.RegistrationState) -ForegroundColor Yellow; $pass = $false }
    } catch { Write-Host ("[WARN] Could not read provider state: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}

Write-Host ("`nValidation result: {0}" -f $(if ($pass) { 'PASS' } else { 'REVIEW WARNINGS' })) -ForegroundColor ($(if ($pass) { 'Green' } else { 'Yellow' }))

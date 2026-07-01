<#
.SYNOPSIS
    PPKV-Validation.ps1 — confirm the vault uses the RBAC model, the Power Platform service principal
    has Key Vault Secrets User, and a secret resolves.
.DESCRIPTION
    PURPOSE
        Read-only validation for the "Standardize Power Platform Secrets in Azure Key Vault" solution.
        Checks three things on a named vault:
          1) the vault uses the Azure RBAC permission model (not legacy access policies);
          2) the Power Platform / Dataverse first-party service principal holds the
             'Key Vault Secrets User' role on the vault (or a named secret);
          3) a specified secret exists and is enabled (metadata) so the reference will resolve.
        Makes no changes and prints NO secret values.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PPKV-Validation.ps1 -VaultName 'pp-secrets-prod-kv'
        Optional: -SecretName 'crm-api-key'  -PowerPlatformAppId '<app id>'
        Requires Az.Accounts, Az.KeyVault, Az.Resources and Microsoft.Graph.Authentication /
        Microsoft.Graph.Applications (to resolve the Power Platform service principal). Run
        Connect-AzAccount first, or the script will prompt.
    EXPECTED RESULTS
        A PASS/FAIL line for each of the three checks. All PASS means Pattern A (Secret environment
        variables) can resolve secrets from this vault.
.NOTES
    Workplace Marketplace — Azure Solutions. Read-only. The repeatable way.
    The Power Platform / Dataverse first-party app can be identified by its well-known application ID;
    if your tenant differs, pass -PowerPlatformAppId explicitly. Operates on metadata only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$VaultName,
    [string]$SecretName,
    [string]$SubscriptionId,
    # Well-known first-party app IDs seen for Power Platform / Dataverse Key Vault reference resolution.
    # Override if your tenant surfaces a different service principal.
    [string]$PowerPlatformAppId
)

foreach ($m in 'Az.Accounts','Az.KeyVault','Az.Resources') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Az -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.KeyVault -ErrorAction Stop
Import-Module Az.Resources -ErrorAction Stop
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }

$pass = @{}
Write-Host "`n=== Power Platform secrets — validation ===" -ForegroundColor Cyan

$vault = Get-AzKeyVault -VaultName $VaultName -ErrorAction Stop

# --- Check 1: permission model is RBAC ---
$rbac = [bool]$vault.EnableRbacAuthorization
$pass['RBAC model'] = $rbac
Write-Host ("[{0}] Vault permission model is Azure RBAC" -f $(if ($rbac) {'PASS'} else {'FAIL'})) -ForegroundColor ($(if ($rbac){'Green'}else{'Red'}))
if (-not $rbac) { Write-Host "      Vault is on legacy access policies — switch to Azure RBAC (requirement 2.2)." -ForegroundColor Yellow }

# --- Resolve the Power Platform / Dataverse service principal ---
Connect-MgGraph -Scopes 'Application.Read.All' -NoWelcome
$ppSp = $null
if ($PowerPlatformAppId) {
    $ppSp = Get-AzADServicePrincipal -ApplicationId $PowerPlatformAppId -ErrorAction SilentlyContinue
} else {
    # Try common display-name matches for the Power Platform / Dataverse first-party principals.
    foreach ($name in 'Dataverse','Microsoft Power Platform','Common Data Service','Power Platform') {
        $ppSp = Get-AzADServicePrincipal -DisplayName $name -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($ppSp) { break }
    }
}
if (-not $ppSp) {
    Write-Host "[WARN] Could not auto-resolve the Power Platform service principal. Pass -PowerPlatformAppId." -ForegroundColor Yellow
} else {
    Write-Host ("      Power Platform SP: {0} ({1})" -f $ppSp.DisplayName, $ppSp.Id)
}

# --- Check 2: the Power Platform SP has Key Vault Secrets User on the vault (or the named secret) ---
$hasRole = $false
if ($ppSp) {
    $scope = $vault.ResourceId
    if ($SecretName) { $scope = "$($vault.ResourceId)/secrets/$SecretName" }
    $assign = Get-AzRoleAssignment -ObjectId $ppSp.Id -ErrorAction SilentlyContinue |
              Where-Object { $_.RoleDefinitionName -eq 'Key Vault Secrets User' -and $vault.ResourceId -like ($_.Scope + '*') -or $_.Scope -eq $scope }
    $hasRole = [bool]$assign
}
$pass['PP SP has Key Vault Secrets User'] = $hasRole
Write-Host ("[{0}] Power Platform SP holds 'Key Vault Secrets User'" -f $(if ($hasRole){'PASS'}else{'FAIL'})) -ForegroundColor ($(if ($hasRole){'Green'}else{'Red'}))
if (-not $hasRole) { Write-Host "      Assign the role (Implementation Step 3) or run PPKV-Remediation.ps1." -ForegroundColor Yellow }

# --- Check 3: the named secret exists and is enabled (metadata only) ---
if ($SecretName) {
    $sec = Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName -ErrorAction SilentlyContinue  # metadata; -AsPlainText NOT used
    $ok = ($sec -and $sec.Enabled)
    $pass['Secret exists + enabled'] = $ok
    Write-Host ("[{0}] Secret '{1}' exists and is enabled" -f $(if ($ok){'PASS'}else{'FAIL'}), $SecretName) -ForegroundColor ($(if ($ok){'Green'}else{'Red'}))
    if ($sec -and $sec.Expires) { Write-Host ("      Expires: {0}" -f $sec.Expires.ToString('yyyy-MM-dd')) }
}

Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
$fail = ($pass.Values | Where-Object { -not $_ }).Count
Write-Host ("`nValidation complete — {0} check(s) failed." -f $fail) -ForegroundColor ($(if ($fail -eq 0){'Green'}else{'Yellow'}))

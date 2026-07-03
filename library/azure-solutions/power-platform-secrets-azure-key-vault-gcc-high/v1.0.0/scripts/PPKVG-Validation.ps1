<#
.SYNOPSIS
    PPKVG-Validation.ps1 — read-only pass/fail check that a GCC High Key Vault is correctly wired for Power Platform secret environment variables.
.DESCRIPTION
    PURPOSE
        Validates the prerequisites for Power Platform environment-variable secrets on a
        US Government (GCC High) tenant: Microsoft.PowerPlatform provider registered, the
        target vault using the RBAC permission model, the Dataverse first-party principal
        granted Key Vault Secrets User, network access reachable for Power Platform, and the
        named secret present (by name only). Set the placeholders below such as
        your-subscription-id and your-vault-name.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PPKVG-Validation.ps1
        Modules: Az.Accounts, Az.KeyVault, Az.Resources.
        Connects to Azure Government: Connect-AzAccount -Environment AzureUSGovernment.
    EXPECTED RESULTS
        A checklist with PASS / FAIL / REVIEW per control and an overall result.
        PASS: every required control is green. FAIL: one or more required controls red —
        the line names the fix (see PPKVG-Remediation.ps1 / 03-implementation.md).
.NOTES
    White-label — the repeatable way. Read-only; never reads secret values. US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId = 'your-subscription-id',
    [Parameter(Mandatory = $false)][string]$VaultName = 'your-vault-name',
    # Secret the Power Platform environment variable will reference — name only.
    [string]$SecretName = 'your-secret-name',
    [ValidateSet('AzureUSGovernment', 'AzureCloud')]
    [string]$Environment = 'AzureUSGovernment'
)

$ErrorActionPreference = 'Stop'
$DataverseAppId = '00000007-0000-0000-c000-000000000000'   # Commercial; verify for GCC High
$results = New-Object System.Collections.Generic.List[object]

function Add-Check($name, $status, $detail) {
    $results.Add([pscustomobject]@{ Check = $name; Status = $status; Detail = $detail })
    $color = switch ($status) { 'PASS' { 'Green' } 'FAIL' { 'Red' } default { 'Yellow' } }
    Write-Host ("[{0,-6}] {1} — {2}" -f $status, $name, $detail) -ForegroundColor $color
}

# --- Connect ----------------------------------------------------------------
$ctx = Get-AzContext -ErrorAction SilentlyContinue
if (-not $ctx -or $ctx.Environment.Name -ne $Environment) {
    Connect-AzAccount -Environment $Environment -Subscription $SubscriptionId | Out-Null
}
else { Set-AzContext -Subscription $SubscriptionId | Out-Null }
$ctx = Get-AzContext

# Check 0: correct sovereign cloud endpoint
if ($ctx.Environment.ResourceManagerUrl -match 'usgovcloudapi\.net') {
    Add-Check 'Sovereign endpoint' 'PASS' "ARM = $($ctx.Environment.ResourceManagerUrl)"
}
else {
    Add-Check 'Sovereign endpoint' 'REVIEW' "ARM = $($ctx.Environment.ResourceManagerUrl) (expected management.usgovcloudapi.net for GCC High)"
}

# Check 1: resource provider
$rp = Get-AzResourceProvider -ProviderNamespace 'Microsoft.PowerPlatform' -ErrorAction SilentlyContinue
$rpState = if ($rp) { ($rp | Select-Object -First 1).RegistrationState } else { 'NotFound' }
if ($rpState -eq 'Registered') { Add-Check 'PowerPlatform provider' 'PASS' 'Registered' }
else { Add-Check 'PowerPlatform provider' 'FAIL' "State=$rpState — run Register-AzResourceProvider -ProviderNamespace Microsoft.PowerPlatform" }

# --- Vault-scoped checks ----------------------------------------------------
$vault = $null
try { $vault = Get-AzKeyVault -VaultName $VaultName -ErrorAction Stop } catch {}
if (-not $vault) {
    Add-Check 'Key Vault exists' 'FAIL' "Vault '$VaultName' not found in subscription"
}
else {
    Add-Check 'Key Vault exists' 'PASS' "$($vault.VaultName) in $($vault.ResourceGroupName)"

    # Check 2: permission model
    if ($vault.EnableRbacAuthorization) { Add-Check 'Permission model' 'PASS' 'Azure RBAC' }
    else { Add-Check 'Permission model' 'REVIEW' 'Vault access policy — Microsoft recommends switching to Azure RBAC' }

    # Check 3: Dataverse principal has Key Vault Secrets User
    $assignments = @()
    try { $assignments = Get-AzRoleAssignment -Scope $vault.ResourceId -ErrorAction Stop } catch {}
    $secretsUser = $assignments | Where-Object { $_.RoleDefinitionName -eq 'Key Vault Secrets User' }
    $dv = $secretsUser | Where-Object {
        $_.DisplayName -match 'Dataverse|PowerApps|Power Platform' -or $_.ObjectId
    }
    if ($secretsUser) {
        Add-Check 'Key Vault Secrets User' 'PASS' "$($secretsUser.Count) assignment(s) at vault scope"
    }
    else {
        Add-Check 'Key Vault Secrets User' 'FAIL' 'No Key Vault Secrets User assignment — Dataverse principal and users need it'
    }
    if ($dv) {
        Add-Check 'Dataverse principal' 'REVIEW' 'Secrets User present — confirm one member is the Dataverse first-party app (verify object id for GCC High)'
    }
    else {
        Add-Check 'Dataverse principal' 'REVIEW' 'Could not confirm Dataverse first-party app by name — verify for GCC High (Enterprise applications)'
    }

    # Check 4: network reachability for Power Platform
    if ($vault.PublicNetworkAccess -eq 'Enabled' -and (-not $vault.NetworkAcls -or $vault.NetworkAcls.DefaultAction -eq 'Allow')) {
        Add-Check 'Network access' 'PASS' 'Public access enabled / no restrictive ACL'
    }
    else {
        Add-Check 'Network access' 'REVIEW' "Firewall/Private Link in play — allow Power Platform US Gov IP ranges or use VNet/Private Link (see 03-implementation.md)"
    }

    # Check 5: secret present (name only)
    $secret = $null
    try { $secret = Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName -ErrorAction Stop } catch {}
    if ($secret) {
        $exp = if ($secret.Expires) { "expires $($secret.Expires)" } else { 'no expiry set' }
        Add-Check 'Target secret' 'PASS' "'$SecretName' exists ($exp) — value NOT read"
    }
    else {
        Add-Check 'Target secret' 'FAIL' "Secret '$SecretName' not found in '$VaultName'"
    }
}

# --- Verdict ----------------------------------------------------------------
$fail = ($results | Where-Object Status -eq 'FAIL').Count
$review = ($results | Where-Object Status -eq 'REVIEW').Count
Write-Host ""
if ($fail -eq 0) {
    Write-Host "OVERALL: PASS ($review item(s) to review)" -ForegroundColor Green
}
else {
    Write-Host "OVERALL: FAIL — $fail required control(s) failed, $review to review" -ForegroundColor Red
}

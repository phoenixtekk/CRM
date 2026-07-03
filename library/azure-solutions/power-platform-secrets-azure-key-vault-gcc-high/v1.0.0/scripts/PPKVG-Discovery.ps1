<#
.SYNOPSIS
    PPKVG-Discovery.ps1 — read-only inventory of Azure Key Vaults, secret metadata, and RBAC on a GCC High / Azure Government tenant.
.DESCRIPTION
    PURPOSE
        Inventories the current state needed to standardize Power Platform secrets in Azure
        Key Vault on a US Government (GCC High) tenant. Lists key vaults, their permission
        model, secret NAMES and metadata (never values), and Key Vault Secrets User role
        assignments — so you can see what exists before you change anything.
        Set the placeholders below (for example your-subscription-id, your-vault-name).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PPKVG-Discovery.ps1
        Modules: Az.Accounts, Az.KeyVault, Az.Resources (Install-Module Az -Scope CurrentUser).
        Connects to Azure Government: Connect-AzAccount -Environment AzureUSGovernment.
    EXPECTED RESULTS
        A console table plus a CSV of vaults, secret metadata, and role assignments.
        PASS: at least one vault is found and the Microsoft.PowerPlatform provider is Registered.
        FAIL/REVIEW: no vaults, provider NotRegistered, or vaults still on the vault-access-policy
        model (RBAC recommended) are flagged in the output.
.NOTES
    White-label — the repeatable way. Read-only; never reads secret values. US Gov endpoints.
#>

[CmdletBinding()]
param(
    # Azure subscription that holds (or will hold) the key vaults — e.g. your-subscription-id
    [string]$SubscriptionId = 'your-subscription-id',

    # Optional: limit discovery to one resource group — e.g. your-resource-group
    [string]$ResourceGroupName,

    # Azure environment. Keep AzureUSGovernment for GCC High / Azure Government.
    [ValidateSet('AzureUSGovernment', 'AzureCloud')]
    [string]$Environment = 'AzureUSGovernment',

    # Where to write the CSV report.
    [string]$OutputPath = ".\PPKVG-Discovery-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
)

$ErrorActionPreference = 'Stop'

# Dataverse first-party application id (Commercial). NOTE: the first-party service-principal
# object that must hold Key Vault Secrets User can differ in GCC High — verify for GCC High in
# your tenant (Entra ID > Enterprise applications). See gcc-high-parity-notes.md.
$DataverseAppId = '00000007-0000-0000-c000-000000000000'

function Write-Section($text) { Write-Host "`n=== $text ===" -ForegroundColor Cyan }

# --- Connect (US Gov) -------------------------------------------------------
Write-Section "Connecting to Azure ($Environment)"
$ctx = Get-AzContext -ErrorAction SilentlyContinue
if (-not $ctx -or $ctx.Environment.Name -ne $Environment) {
    Connect-AzAccount -Environment $Environment -Subscription $SubscriptionId | Out-Null
}
else {
    Set-AzContext -Subscription $SubscriptionId | Out-Null
}
$ctx = Get-AzContext
Write-Host "Tenant : $($ctx.Tenant.Id)"
Write-Host "Subscription : $($ctx.Subscription.Name) ($($ctx.Subscription.Id))"
Write-Host "ARM endpoint : $($ctx.Environment.ResourceManagerUrl)"   # expect management.usgovcloudapi.net for Gov

# --- Resource provider check ------------------------------------------------
Write-Section "Microsoft.PowerPlatform resource provider"
$rp = Get-AzResourceProvider -ProviderNamespace 'Microsoft.PowerPlatform' -ErrorAction SilentlyContinue
$rpState = if ($rp) { ($rp | Select-Object -First 1).RegistrationState } else { 'NotFound' }
if ($rpState -eq 'Registered') {
    Write-Host "Microsoft.PowerPlatform : Registered" -ForegroundColor Green
}
else {
    Write-Host "Microsoft.PowerPlatform : $rpState  (required — see PPKVG-Remediation.ps1)" -ForegroundColor Yellow
}

# --- Enumerate key vaults ---------------------------------------------------
Write-Section "Key Vaults"
$vaults = if ($ResourceGroupName) {
    Get-AzKeyVault -ResourceGroupName $ResourceGroupName
}
else {
    Get-AzKeyVault
}

if (-not $vaults) {
    Write-Host "No key vaults found in this subscription/scope." -ForegroundColor Yellow
}

$rows = New-Object System.Collections.Generic.List[object]

foreach ($v in $vaults) {
    $vault = Get-AzKeyVault -VaultName $v.VaultName
    $rbacEnabled = [bool]$vault.EnableRbacAuthorization
    $permModel = if ($rbacEnabled) { 'RBAC' } else { 'VaultAccessPolicy' }

    Write-Host ("Vault: {0}  [{1}]  net={2}" -f $vault.VaultName, $permModel, $vault.PublicNetworkAccess)

    # Role assignments for Key Vault Secrets User at the vault scope (metadata only)
    $scope = $vault.ResourceId
    $secretsUserAssignments = @()
    try {
        $secretsUserAssignments = Get-AzRoleAssignment -Scope $scope -ErrorAction Stop |
            Where-Object { $_.RoleDefinitionName -eq 'Key Vault Secrets User' }
    }
    catch {
        Write-Host "  (could not read role assignments: $($_.Exception.Message))" -ForegroundColor DarkYellow
    }

    $dataversePresent = [bool]($secretsUserAssignments | Where-Object {
            $_.ObjectId -and ($_.DisplayName -match 'Dataverse' -or $_.DisplayName -match 'PowerApps' -or $_.DisplayName -match 'Power Platform')
        })

    # Secret metadata ONLY — names, enabled, expiry, tags. Never Get-AzKeyVaultSecret value.
    $secrets = @()
    try {
        $secrets = Get-AzKeyVaultSecret -VaultName $vault.VaultName -ErrorAction Stop
    }
    catch {
        Write-Host "  (could not list secrets: $($_.Exception.Message))" -ForegroundColor DarkYellow
    }

    if (-not $secrets) {
        $rows.Add([pscustomobject]@{
                VaultName          = $vault.VaultName
                ResourceGroup      = $vault.ResourceGroupName
                Location           = $vault.Location
                PermissionModel    = $permModel
                PublicNetworkAccess= $vault.PublicNetworkAccess
                SecretName         = '(none)'
                SecretEnabled      = ''
                SecretExpires      = ''
                SecretTags         = ''
                SecretsUserCount   = $secretsUserAssignments.Count
                DataverseSecretsUser = $dataversePresent
            })
    }
    foreach ($s in $secrets) {
        $tags = if ($s.Tags) { ($s.Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ';' } else { '' }
        $rows.Add([pscustomobject]@{
                VaultName          = $vault.VaultName
                ResourceGroup      = $vault.ResourceGroupName
                Location           = $vault.Location
                PermissionModel    = $permModel
                PublicNetworkAccess= $vault.PublicNetworkAccess
                SecretName         = $s.Name          # NAME ONLY — value is never retrieved
                SecretEnabled      = $s.Enabled
                SecretExpires      = $s.Expires
                SecretTags         = $tags            # e.g. AllowedBots / AllowedEnvironments
                SecretsUserCount   = $secretsUserAssignments.Count
                DataverseSecretsUser = $dataversePresent
            })
    }
}

# --- Output -----------------------------------------------------------------
Write-Section "Summary"
$rows | Format-Table VaultName, PermissionModel, SecretName, SecretEnabled, SecretExpires, DataverseSecretsUser -AutoSize
$rows | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host "`nReport written: $OutputPath" -ForegroundColor Green
Write-Host "Reminder: this script lists secret NAMES and metadata only — it never reads secret values." -ForegroundColor DarkCyan

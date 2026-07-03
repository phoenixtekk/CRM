<#
.SYNOPSIS
    PPKVG-Remediation.ps1 — safely bring a GCC High Key Vault to the required state for Power Platform secrets (WhatIf by default).
.DESCRIPTION
    PURPOSE
        Applies the standard configuration for Power Platform environment-variable secrets on
        a US Government (GCC High) tenant: registers the Microsoft.PowerPlatform provider,
        switches the target vault to the Azure RBAC permission model, and grants Key Vault
        Secrets User to the Dataverse first-party principal and a named admin group. Runs in
        preview (-WhatIf) mode by default; pass -Apply to make changes. It NEVER creates,
        reads, or writes secret values. Set placeholders such as your-subscription-id,
        your-vault-name, and your-admin-group-object-id.
    HOW TO RUN
        Preview : powershell -ExecutionPolicy Bypass -File .\PPKVG-Remediation.ps1
        Apply   : powershell -ExecutionPolicy Bypass -File .\PPKVG-Remediation.ps1 -Apply
        Modules: Az.Accounts, Az.KeyVault, Az.Resources.
        Connects to Azure Government: Connect-AzAccount -Environment AzureUSGovernment.
    EXPECTED RESULTS
        Preview: prints each action it WOULD take, changes nothing.
        Apply: performs the actions and prints PASS/updated per step. Re-run PPKVG-Validation.ps1
        afterward to confirm all controls are green.
.NOTES
    White-label — the repeatable way. Read-only for secrets; never reads secret values. US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId = 'your-subscription-id',
    [Parameter(Mandatory = $false)][string]$VaultName = 'your-vault-name',

    # Entra object id of the admin group to grant Key Vault Secrets User (makers/operators).
    [string]$AdminGroupObjectId = 'your-admin-group-object-id',

    # Set to actually apply. Omit to preview only (default is -WhatIf behavior).
    [switch]$Apply,

    [ValidateSet('AzureUSGovernment', 'AzureCloud')]
    [string]$Environment = 'AzureUSGovernment'
)

$ErrorActionPreference = 'Stop'
# Dataverse first-party app id (Commercial). In GCC High the first-party principal that must
# hold Key Vault Secrets User may be a different object — VERIFY FOR GCC HIGH before -Apply.
$DataverseAppId = '00000007-0000-0000-c000-000000000000'
$whatIf = -not $Apply

function Do-Step {
    param([string]$What, [scriptblock]$Action)
    if ($whatIf) {
        Write-Host "[WHATIF] Would: $What" -ForegroundColor Yellow
    }
    else {
        Write-Host "[APPLY ] $What" -ForegroundColor Cyan
        & $Action
        Write-Host "         done" -ForegroundColor Green
    }
}

# --- Connect ----------------------------------------------------------------
$ctx = Get-AzContext -ErrorAction SilentlyContinue
if (-not $ctx -or $ctx.Environment.Name -ne $Environment) {
    Connect-AzAccount -Environment $Environment -Subscription $SubscriptionId | Out-Null
}
else { Set-AzContext -Subscription $SubscriptionId | Out-Null }
$ctx = Get-AzContext
Write-Host "Cloud: $($ctx.Environment.Name)  ARM: $($ctx.Environment.ResourceManagerUrl)"
if ($whatIf) { Write-Host "PREVIEW MODE — no changes will be made. Re-run with -Apply to enact." -ForegroundColor Yellow }

# --- Step 1: resource provider ---------------------------------------------
$rp = Get-AzResourceProvider -ProviderNamespace 'Microsoft.PowerPlatform' -ErrorAction SilentlyContinue
$rpState = if ($rp) { ($rp | Select-Object -First 1).RegistrationState } else { 'NotFound' }
if ($rpState -ne 'Registered') {
    Do-Step "Register-AzResourceProvider Microsoft.PowerPlatform (currently $rpState)" {
        Register-AzResourceProvider -ProviderNamespace 'Microsoft.PowerPlatform' | Out-Null
    }
}
else { Write-Host "[OK    ] Microsoft.PowerPlatform already Registered" -ForegroundColor Green }

# --- Vault-scoped steps -----------------------------------------------------
$vault = Get-AzKeyVault -VaultName $VaultName -ErrorAction Stop
$scope = $vault.ResourceId

# Step 2: switch to RBAC permission model
if (-not $vault.EnableRbacAuthorization) {
    Do-Step "Switch vault '$VaultName' to Azure RBAC permission model" {
        Update-AzKeyVault -VaultName $VaultName -ResourceGroupName $vault.ResourceGroupName -EnableRbacAuthorization $true | Out-Null
    }
}
else { Write-Host "[OK    ] Vault already on Azure RBAC" -ForegroundColor Green }

# Helper: grant Key Vault Secrets User if not already present
function Grant-SecretsUser {
    param([string]$ObjectId, [string]$Label)
    if (-not $ObjectId -or $ObjectId -like 'your-*') {
        Write-Host "[SKIP  ] $Label — object id not provided (placeholder)" -ForegroundColor DarkYellow
        return
    }
    $existing = Get-AzRoleAssignment -Scope $scope -ObjectId $ObjectId -RoleDefinitionName 'Key Vault Secrets User' -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "[OK    ] $Label already has Key Vault Secrets User" -ForegroundColor Green
    }
    else {
        Do-Step "Grant Key Vault Secrets User to $Label ($ObjectId)" {
            New-AzRoleAssignment -Scope $scope -ObjectId $ObjectId -RoleDefinitionName 'Key Vault Secrets User' | Out-Null
        }
    }
}

# Step 3: Dataverse first-party principal
$dvSp = Get-AzADServicePrincipal -ApplicationId $DataverseAppId -ErrorAction SilentlyContinue
if ($dvSp) {
    Grant-SecretsUser -ObjectId $dvSp.Id -Label 'Dataverse first-party app'
}
else {
    Write-Host "[REVIEW] Dataverse app $DataverseAppId not resolvable in this tenant — VERIFY FOR GCC HIGH (Enterprise applications), then grant Key Vault Secrets User manually." -ForegroundColor Yellow
}

# Step 4: admin/maker group
Grant-SecretsUser -ObjectId $AdminGroupObjectId -Label 'Admin/maker group'

Write-Host "`nNext: run PPKVG-Validation.ps1 to confirm all controls PASS." -ForegroundColor Cyan
if ($whatIf) { Write-Host "No changes were made (preview mode)." -ForegroundColor Yellow }

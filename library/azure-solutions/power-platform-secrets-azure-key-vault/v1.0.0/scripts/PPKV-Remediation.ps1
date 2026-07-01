<#
.SYNOPSIS
    PPKV-Remediation.ps1 — safe remediation: assign 'Key Vault Secrets User' and set secret expiry.
.DESCRIPTION
    PURPOSE
        Safe, targeted fixes for the "Standardize Power Platform Secrets in Azure Key Vault" solution.
        Two actions:
          'GrantRead' — assign the 'Key Vault Secrets User' RBAC role to a principal (by object id
                        or the Power Platform service principal) on the vault or a named secret;
          'SetExpiry' — set an expiration date on a named secret (metadata only).
        DEFAULTS TO -WhatIf — it prints the change it would make and changes nothing until you pass
        -Execute. Never reads or prints secret values.
    HOW TO RUN
        Preview (default, no change):
            powershell -ExecutionPolicy Bypass -File .\PPKV-Remediation.ps1 -VaultName 'pp-secrets-prod-kv' -Action GrantRead -PrincipalObjectId '<sp object id>'
            powershell -ExecutionPolicy Bypass -File .\PPKV-Remediation.ps1 -VaultName 'pp-secrets-prod-kv' -Action SetExpiry -SecretName 'crm-api-key' -ExpiresOn '2027-01-01'
        Apply for real (explicit):
            ... -Execute
        Requires Az.Accounts, Az.KeyVault, Az.Resources. Run Connect-AzAccount first, or the script
        will prompt. Assigning roles requires Owner / User Access Administrator on the vault scope.
    EXPECTED RESULTS
        In -WhatIf mode (default): a printed description of the role assignment or expiry change —
        nothing changes. With -Execute: the role is assigned, or the secret's expiry is set.
.NOTES
    Workplace Marketplace — Azure Solutions. Defaults to -WhatIf. The repeatable way.
    SetExpiry updates metadata only — it does NOT read or change the secret value. GrantRead assigns
    read (not manage) access, per least privilege.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$VaultName,
    [Parameter(Mandatory)] [ValidateSet('GrantRead','SetExpiry')] [string]$Action,
    [string]$PrincipalObjectId,   # for GrantRead (omit to target the Power Platform SP)
    [string]$SecretName,          # for GrantRead (per-secret scope) or SetExpiry
    [datetime]$ExpiresOn,         # for SetExpiry
    [string]$SubscriptionId,
    [switch]$Execute              # omit for -WhatIf (default safe mode)
)

foreach ($m in 'Az.Accounts','Az.KeyVault','Az.Resources') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Az -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.KeyVault -ErrorAction Stop
Import-Module Az.Resources -ErrorAction Stop

if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }

$whatIf = -not $Execute
$vault  = Get-AzKeyVault -VaultName $VaultName -ErrorAction Stop

switch ($Action) {

    'GrantRead' {
        # Resolve the target principal.
        $objId = $PrincipalObjectId
        if (-not $objId) {
            foreach ($name in 'Dataverse','Microsoft Power Platform','Common Data Service','Power Platform') {
                $sp = Get-AzADServicePrincipal -DisplayName $name -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($sp) { $objId = $sp.Id; break }
            }
        }
        if (-not $objId) { Write-Host "Could not resolve a principal. Pass -PrincipalObjectId." -ForegroundColor Red; return }

        $scope = $vault.ResourceId
        if ($SecretName) { $scope = "$($vault.ResourceId)/secrets/$SecretName" }

        if ($whatIf) {
            Write-Host ("[WhatIf] Would assign 'Key Vault Secrets User' to {0} at scope {1}. No change made. Re-run with -Execute." -f $objId, $scope) -ForegroundColor Yellow
        } else {
            try {
                New-AzRoleAssignment -ObjectId $objId -RoleDefinitionName 'Key Vault Secrets User' -Scope $scope -ErrorAction Stop | Out-Null
                Write-Host ("Assigned 'Key Vault Secrets User' to {0} at {1}." -f $objId, $scope) -ForegroundColor Green
            } catch {
                Write-Host ("Assignment failed (may already exist): {0}" -f $_.Exception.Message) -ForegroundColor Yellow
            }
        }
    }

    'SetExpiry' {
        if (-not $SecretName) { Write-Host "SetExpiry requires -SecretName." -ForegroundColor Red; return }
        if (-not $ExpiresOn)  { Write-Host "SetExpiry requires -ExpiresOn (e.g. 2027-01-01)." -ForegroundColor Red; return }
        # Operate on the CURRENT version's metadata only — value is never read.
        $cur = Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName -ErrorAction Stop
        if ($whatIf) {
            Write-Host ("[WhatIf] Would set expiry of secret '{0}' to {1}. No change made. Re-run with -Execute." -f $SecretName, $ExpiresOn.ToString('yyyy-MM-dd')) -ForegroundColor Yellow
        } else {
            try {
                Update-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName -Version $cur.Version -Expires $ExpiresOn -ErrorAction Stop | Out-Null
                Write-Host ("Set expiry of secret '{0}' to {1}." -f $SecretName, $ExpiresOn.ToString('yyyy-MM-dd')) -ForegroundColor Green
            } catch {
                Write-Host ("Set-expiry failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
            }
        }
    }
}

Write-Host ("`nRemediation complete ({0})." -f $(if ($whatIf){'WhatIf — no changes'}else{'executed'})) -ForegroundColor ($(if ($whatIf){'Yellow'}else{'Green'}))

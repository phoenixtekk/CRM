<#
.SYNOPSIS
    PPKVG-Set-ScopeTargeting.ps1 — set the Copilot Studio access tags (AllowedBots / AllowedEnvironments) on a GCC High Key Vault secret (WhatIf by default).
.DESCRIPTION
    PURPOSE
        Builds and applies the metadata TAGS that scope which Copilot Studio agents (or which
        whole environments) may consume a Power Platform environment-variable secret on a US
        Government (GCC High) tenant. It sets the 'AllowedBots' or 'AllowedEnvironments' tag on
        the named secret's current version. It ONLY writes tag metadata — it never creates,
        reads, or changes the secret value. Runs in preview (-WhatIf) mode by default; pass
        -Apply to write the tag. Set placeholders such as your-vault-name, your-secret-name,
        and the environment/agent ids.
    HOW TO RUN
        Preview : powershell -ExecutionPolicy Bypass -File .\PPKVG-Set-ScopeTargeting.ps1 -AllowedEnvironments 'your-environment-id'
        Apply   : powershell -ExecutionPolicy Bypass -File .\PPKVG-Set-ScopeTargeting.ps1 -AllowedEnvironments 'your-environment-id' -Apply
        Modules: Az.Accounts, Az.KeyVault. Connect: Connect-AzAccount -Environment AzureUSGovernment.
    EXPECTED RESULTS
        Preview: prints the exact tag name/value it WOULD set on the secret. Nothing changes.
        Apply: sets the tag and prints the resulting (metadata-only) tag set.
        PASS: tag is present on the secret; Copilot Studio agents in scope can now resolve it.
.NOTES
    White-label — the repeatable way. Writes tag metadata only; never reads secret values. US Gov endpoints.
#>

[CmdletBinding(DefaultParameterSetName = 'Bots')]
param(
    [string]$SubscriptionId = 'your-subscription-id',
    [Parameter(Mandatory = $false)][string]$VaultName = 'your-vault-name',
    [Parameter(Mandatory = $false)][string]$SecretName = 'your-secret-name',

    # Scope to specific agents: values formatted {envId}/{schemaName}. Comma-separate multiple.
    [Parameter(ParameterSetName = 'Bots')]
    [string[]]$AllowedBots,

    # Scope to entire environment(s): environment id(s). Comma-separate multiple.
    [Parameter(ParameterSetName = 'Envs')]
    [string[]]$AllowedEnvironments,

    [switch]$Apply,
    [ValidateSet('AzureUSGovernment', 'AzureCloud')]
    [string]$Environment = 'AzureUSGovernment'
)

$ErrorActionPreference = 'Stop'
$whatIf = -not $Apply

# --- Connect ----------------------------------------------------------------
$ctx = Get-AzContext -ErrorAction SilentlyContinue
if (-not $ctx -or $ctx.Environment.Name -ne $Environment) {
    Connect-AzAccount -Environment $Environment -Subscription $SubscriptionId | Out-Null
}
else { Set-AzContext -Subscription $SubscriptionId | Out-Null }
$ctx = Get-AzContext
Write-Host "Cloud: $($ctx.Environment.Name)  Vault: $VaultName  Secret: $SecretName"

# --- Determine the tag ------------------------------------------------------
if ($PSCmdlet.ParameterSetName -eq 'Bots') {
    if (-not $AllowedBots) { throw "Provide -AllowedBots '<envId>/<schemaName>' (comma-separated for multiple)." }
    $tagName = 'AllowedBots'
    $tagValue = ($AllowedBots -join ',')
}
else {
    if (-not $AllowedEnvironments) { throw "Provide -AllowedEnvironments '<environmentId>' (comma-separated for multiple)." }
    $tagName = 'AllowedEnvironments'
    $tagValue = ($AllowedEnvironments -join ',')
}
Write-Host "Tag to set: $tagName = $tagValue"

# --- Read existing tags (metadata only) ------------------------------------
$secret = Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName -ErrorAction Stop  # metadata object; value not accessed
$tags = @{}
if ($secret.Tags) { $secret.Tags.GetEnumerator() | ForEach-Object { $tags[$_.Key] = $_.Value } }
$tags[$tagName] = $tagValue

if ($whatIf) {
    Write-Host "[WHATIF] Would set tags on '$VaultName/$SecretName':" -ForegroundColor Yellow
    $tags.GetEnumerator() | ForEach-Object { Write-Host ("           {0} = {1}" -f $_.Key, $_.Value) }
    Write-Host "PREVIEW MODE — no changes made. Re-run with -Apply to write the tag." -ForegroundColor Yellow
    return
}

# --- Apply the tag (metadata only) -----------------------------------------
# Update-AzKeyVaultSecret with -Tag updates metadata on the current version; the value is untouched.
Update-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName -Tag $tags | Out-Null
$after = Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName
Write-Host "[APPLY ] Tags now on '$VaultName/$SecretName':" -ForegroundColor Green
$after.Tags.GetEnumerator() | ForEach-Object { Write-Host ("           {0} = {1}" -f $_.Key, $_.Value) }
Write-Host "Reminder: only tag metadata was changed. The secret value was never read or modified." -ForegroundColor DarkCyan

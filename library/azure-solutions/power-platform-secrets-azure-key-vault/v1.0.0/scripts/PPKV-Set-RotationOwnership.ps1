<#
.SYNOPSIS
    PPKV-Set-RotationOwnership.ps1 — set rotation/expiry and ownership tags on Key Vault secrets.
.DESCRIPTION
    PURPOSE
        Governance helper for the "Standardize Power Platform Secrets in Azure Key Vault" solution.
        For one named secret or every secret in a vault, sets an expiration date and applies
        consistent governance tags — 'owner', 'purpose', and 'rotationDays' (the intended rotation
        cadence) — so ownership and rotation are explicit and reportable (PPKV-Report.ps1 reads them).
        DEFAULTS TO -WhatIf — prints what it would change and changes nothing until you pass -Execute.
        Never reads or prints secret values; operates on metadata/tags only.
    HOW TO RUN
        Preview (default, no change):
            powershell -ExecutionPolicy Bypass -File .\PPKV-Set-RotationOwnership.ps1 -VaultName 'pp-secrets-prod-kv' -Owner 'integrations-team' -Purpose 'CRM API' -RotationDays 90 -SecretName 'crm-api-key'
        All secrets in a vault:
            ... -VaultName 'pp-secrets-prod-kv' -Owner 'integrations-team' -RotationDays 90
        Apply for real (explicit):
            ... -Execute
        Requires Az.Accounts, Az.KeyVault. Run Connect-AzAccount first, or the script will prompt.
        Requires 'Key Vault Secrets Officer' (or equivalent) to update secret attributes.
    EXPECTED RESULTS
        In -WhatIf mode (default): per-secret lines showing the tags and expiry that would be set —
        nothing changes. With -Execute: each secret gets the owner/purpose/rotationDays tags and an
        expiry computed as (today + RotationDays) unless -ExpiresOn is given.
.NOTES
    Workplace Marketplace — Azure Solutions. Defaults to -WhatIf. The repeatable way.
    Setting expiry/tags does NOT rotate the value — it records the cadence and ownership. Actual
    rotation is adding a new secret version; because consumers reference the versionless secret, a
    rotated value flows through with no app/flow rebuild.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$VaultName,
    [string]$SecretName,                 # omit to apply to all secrets in the vault
    [string]$Owner,
    [string]$Purpose,
    [int]$RotationDays = 90,
    [datetime]$ExpiresOn,                 # overrides the computed today+RotationDays expiry
    [string]$SubscriptionId,
    [switch]$Execute                      # omit for -WhatIf (default safe mode)
)

foreach ($m in 'Az.Accounts','Az.KeyVault') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Az -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.KeyVault -ErrorAction Stop

if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }

$whatIf   = -not $Execute
$computed = if ($ExpiresOn) { $ExpiresOn } else { (Get-Date).AddDays($RotationDays) }

$targets = if ($SecretName) {
    ,(Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName -ErrorAction Stop)   # metadata only
} else {
    Get-AzKeyVaultSecret -VaultName $VaultName -ErrorAction Stop
}

Write-Host "`n=== Set rotation / ownership on secrets ===" -ForegroundColor Cyan
Write-Host ("   Vault: {0}   Expiry target: {1}   RotationDays: {2}" -f $VaultName, $computed.ToString('yyyy-MM-dd'), $RotationDays)

foreach ($s in $targets) {
    # Merge governance tags onto any existing tags (metadata only — value never touched).
    $tags = @{}
    if ($s.Tags) { $s.Tags.GetEnumerator() | ForEach-Object { $tags[$_.Key] = $_.Value } }
    if ($Owner)   { $tags['owner']   = $Owner }
    if ($Purpose) { $tags['purpose'] = $Purpose }
    $tags['rotationDays'] = "$RotationDays"

    $desc = ("{0}: owner='{1}' purpose='{2}' rotationDays={3} expires={4}" -f $s.Name, $tags['owner'], $tags['purpose'], $tags['rotationDays'], $computed.ToString('yyyy-MM-dd'))

    if ($whatIf) {
        Write-Host ("   [WhatIf] Would set {0}" -f $desc) -ForegroundColor Yellow
    } else {
        try {
            Update-AzKeyVaultSecret -VaultName $VaultName -Name $s.Name -Version $s.Version -Expires $computed -Tag $tags -ErrorAction Stop | Out-Null
            Write-Host ("   Set {0}" -f $desc) -ForegroundColor Green
        } catch {
            Write-Host ("   FAILED {0} — {1}" -f $s.Name, $_.Exception.Message) -ForegroundColor Red
        }
    }
}

Write-Host ("`nComplete ({0})." -f $(if ($whatIf){'WhatIf — no changes'}else{'executed'})) -ForegroundColor ($(if ($whatIf){'Yellow'}else{'Green'}))

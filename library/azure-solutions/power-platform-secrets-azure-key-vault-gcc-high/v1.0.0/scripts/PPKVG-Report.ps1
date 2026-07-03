<#
.SYNOPSIS
    PPKVG-Report.ps1 — read-only HTML/CSV governance report of Power Platform secret vaults on a GCC High tenant.
.DESCRIPTION
    PURPOSE
        Produces a shareable governance report for standardizing Power Platform secrets in
        Azure Key Vault on a US Government (GCC High) tenant. Summarizes vaults, permission
        model, secret metadata (names, expiry, tags — never values), Key Vault Secrets User
        assignments, and flags hygiene issues (secrets with no expiry, vaults on access-policy
        model, missing tags). Set the placeholders below such as your-subscription-id.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PPKVG-Report.ps1
        Modules: Az.Accounts, Az.KeyVault, Az.Resources.
        Connects to Azure Government: Connect-AzAccount -Environment AzureUSGovernment.
    EXPECTED RESULTS
        Writes a timestamped PPKVG-Report .html and .csv to the output folder and prints a summary.
        PASS: report generated; review the Findings section for any REVIEW/ACTION rows.
        FAIL: connection or module missing — the error names what to install/fix.
.NOTES
    White-label — the repeatable way. Read-only; never reads secret values. US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId = 'your-subscription-id',
    [string]$ResourceGroupName,
    [ValidateSet('AzureUSGovernment', 'AzureCloud')]
    [string]$Environment = 'AzureUSGovernment',
    [string]$OutputFolder = '.'
)

$ErrorActionPreference = 'Stop'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$htmlPath = Join-Path $OutputFolder "PPKVG-Report-$stamp.html"
$csvPath = Join-Path $OutputFolder "PPKVG-Report-$stamp.csv"

# --- Connect ----------------------------------------------------------------
$ctx = Get-AzContext -ErrorAction SilentlyContinue
if (-not $ctx -or $ctx.Environment.Name -ne $Environment) {
    Connect-AzAccount -Environment $Environment -Subscription $SubscriptionId | Out-Null
}
else { Set-AzContext -Subscription $SubscriptionId | Out-Null }
$ctx = Get-AzContext

$rows = New-Object System.Collections.Generic.List[object]
$findings = New-Object System.Collections.Generic.List[string]

$vaults = if ($ResourceGroupName) { Get-AzKeyVault -ResourceGroupName $ResourceGroupName } else { Get-AzKeyVault }

# Provider hygiene
$rp = Get-AzResourceProvider -ProviderNamespace 'Microsoft.PowerPlatform' -ErrorAction SilentlyContinue
$rpState = if ($rp) { ($rp | Select-Object -First 1).RegistrationState } else { 'NotFound' }
if ($rpState -ne 'Registered') { $findings.Add("ACTION: Microsoft.PowerPlatform resource provider is '$rpState' — register it.") }

foreach ($v in $vaults) {
    $vault = Get-AzKeyVault -VaultName $v.VaultName
    $permModel = if ($vault.EnableRbacAuthorization) { 'RBAC' } else { 'VaultAccessPolicy' }
    if ($permModel -eq 'VaultAccessPolicy') { $findings.Add("REVIEW: '$($vault.VaultName)' uses the vault access policy model — switch to Azure RBAC.") }

    $secretsUser = @()
    try {
        $secretsUser = Get-AzRoleAssignment -Scope $vault.ResourceId -ErrorAction Stop |
            Where-Object { $_.RoleDefinitionName -eq 'Key Vault Secrets User' }
    } catch {}
    if (-not $secretsUser) { $findings.Add("ACTION: '$($vault.VaultName)' has no Key Vault Secrets User assignment (Dataverse + users need it).") }

    $secrets = @()
    try { $secrets = Get-AzKeyVaultSecret -VaultName $vault.VaultName -ErrorAction Stop } catch {}

    foreach ($s in $secrets) {
        $tags = if ($s.Tags) { ($s.Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ';' } else { '' }
        if (-not $s.Expires) { $findings.Add("REVIEW: secret '$($vault.VaultName)/$($s.Name)' has no expiry date set.") }
        $rows.Add([pscustomobject]@{
                Vault            = $vault.VaultName
                ResourceGroup    = $vault.ResourceGroupName
                Location         = $vault.Location
                PermissionModel  = $permModel
                Network          = $vault.PublicNetworkAccess
                Secret           = $s.Name         # NAME ONLY
                Enabled          = $s.Enabled
                Expires          = $s.Expires
                Tags             = $tags
                SecretsUserCount = $secretsUser.Count
            })
    }
    if (-not $secrets) {
        $rows.Add([pscustomobject]@{
                Vault = $vault.VaultName; ResourceGroup = $vault.ResourceGroupName; Location = $vault.Location
                PermissionModel = $permModel; Network = $vault.PublicNetworkAccess; Secret = '(none)'
                Enabled = ''; Expires = ''; Tags = ''; SecretsUserCount = $secretsUser.Count
            })
    }
}

# --- CSV --------------------------------------------------------------------
$rows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

# --- HTML -------------------------------------------------------------------
$style = @"
<style>
 body{font-family:Segoe UI,Arial,sans-serif;margin:24px;color:#222}
 h1{font-size:20px} h2{font-size:15px;margin-top:24px}
 table{border-collapse:collapse;width:100%;font-size:12px}
 th,td{border:1px solid #ccc;padding:6px 8px;text-align:left}
 th{background:#0b3d2e;color:#fff}
 .meta{color:#555;font-size:12px} .f{color:#8a1f11}
</style>
"@
$findingHtml = if ($findings.Count) {
    "<ul>" + (($findings | Sort-Object -Unique | ForEach-Object { "<li class='f'>$([System.Web.HttpUtility]::HtmlEncode($_))</li>" }) -join '') + "</ul>"
} else { "<p>No hygiene findings. All vaults on RBAC, provider registered, secrets have expiry.</p>" }

$table = $rows | ConvertTo-Html -Fragment
$html = @"
<!doctype html><html><head><meta charset='utf-8'>$style<title>PPKVG Governance Report</title></head><body>
<h1>Standardize Power Platform Secrets in Azure Key Vault — Governance Report (GCC High)</h1>
<p class='meta'>Generated $stamp &middot; Tenant $($ctx.Tenant.Id) &middot; Subscription $($ctx.Subscription.Name) &middot; Cloud $($ctx.Environment.Name)<br>
Secret VALUES are never read by this report — names and metadata only.</p>
<h2>Findings</h2>$findingHtml
<h2>Vaults &amp; secret metadata</h2>$table
</body></html>
"@
Add-Type -AssemblyName System.Web -ErrorAction SilentlyContinue
Set-Content -Path $htmlPath -Value $html -Encoding UTF8

Write-Host "HTML report : $htmlPath" -ForegroundColor Green
Write-Host "CSV report  : $csvPath" -ForegroundColor Green
Write-Host "Findings    : $($findings.Count)" -ForegroundColor Cyan

<#
.SYNOPSIS
    MIM365-Find-StoredCredentials.ps1 — report Logic Apps / Function Apps still using stored
    service-account connections or client secrets (the migration worklist).
.DESCRIPTION
    PURPOSE
        Read-only migration triage for the "Managed Identities for Azure Logic Apps & Functions"
        solution. Flags the workflows that still depend on a stored credential rather than a managed
        identity, by reporting:
          - Logic Apps referencing an API connection (Microsoft.Web/connections) — e.g. a saved
            Office 365 Outlook / service-account connection;
          - Function Apps whose Application settings contain likely secret keys (names matching
            *SECRET*, *PASSWORD*, *PWD*, *CLIENTSECRET*, *CONNECTIONSTRING* — the value is NOT read
            or printed, only the presence of the key);
          - resources with NO managed identity enabled (cannot yet use the credential-free pattern).
        Read-only: it inventories, it does not change or remove anything.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MIM365-Find-StoredCredentials.ps1
        powershell -ExecutionPolicy Bypass -File .\MIM365-Find-StoredCredentials.ps1 -SubscriptionId '<sub id>' -OutputCsv '.\MIM365-migration-worklist.csv'
        Requires Az.Accounts, Az.Resources, Az.Websites. Run Connect-AzAccount first, or it will prompt.
    GRAPH SCOPES
        None — this script queries Azure Resource Manager only (no Microsoft Graph call). It never reads
        or outputs secret VALUES, only the presence of stored-credential indicators.
    EXPECTED RESULTS
        A console table and CSV of the migration worklist: each resource still using a stored
        credential or lacking a managed identity, with the reason. Re-run after each migration; a
        migrated workflow drops off the list.
.NOTES
    Azure Solutions — read-only. The repeatable way.
    Reports indicators only; never reads, logs, or prints secret values. White-label sample tenant: contoso.com.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$OutputCsv = ".\MIM365-migration-worklist.csv"
)

foreach ($m in 'Az.Accounts','Az.Resources','Az.Websites') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Az -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.Resources -ErrorAction Stop
Import-Module Az.Websites -ErrorAction Stop

if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }

$secretKeyPattern = 'SECRET|PASSWORD|PWD|CLIENTSECRET|CONNECTIONSTRING'
$worklist = @()

# --- Logic Apps: flag those with API connections in their resource group, or no managed identity. ---
$logicApps = Get-AzResource -ResourceType 'Microsoft.Logic/workflows' -ErrorAction SilentlyContinue
foreach ($la in $logicApps) {
    $full = Get-AzResource -ResourceId $la.ResourceId -ExpandProperties -ErrorAction SilentlyContinue
    $hasIdentity = $full.Identity -and $full.Identity.Type -and $full.Identity.Type -ne 'None'
    $conns = Get-AzResource -ResourceGroupName $la.ResourceGroupName -ResourceType 'Microsoft.Web/connections' -ErrorAction SilentlyContinue
    if ($conns) {
        $worklist += [pscustomobject]@{ Resource=$la.Name; Type='Logic App'; Reason=("Stored API connection(s): " + (($conns.Name) -join ', ')); HasManagedIdentity=$hasIdentity }
    }
    if (-not $hasIdentity) {
        $worklist += [pscustomobject]@{ Resource=$la.Name; Type='Logic App'; Reason='No managed identity enabled'; HasManagedIdentity=$false }
    }
}

# --- Function Apps: flag secret-looking app settings, or no managed identity. ---
$funcApps = Get-AzResource -ResourceType 'Microsoft.Web/sites' -ErrorAction SilentlyContinue | Where-Object { $_.Kind -match 'functionapp' }
foreach ($fa in $funcApps) {
    $full = Get-AzResource -ResourceId $fa.ResourceId -ExpandProperties -ErrorAction SilentlyContinue
    $hasIdentity = $full.Identity -and $full.Identity.Type -and $full.Identity.Type -ne 'None'
    try {
        $settings = Get-AzWebApp -ResourceGroupName $fa.ResourceGroupName -Name $fa.Name -ErrorAction Stop
        $keys = @()
        foreach ($s in $settings.SiteConfig.AppSettings) { if ($s.Name -match $secretKeyPattern) { $keys += $s.Name } }
        if ($keys.Count -gt 0) {
            $worklist += [pscustomobject]@{ Resource=$fa.Name; Type='Function App'; Reason=("Secret-like app setting key(s): " + ($keys -join ', ')); HasManagedIdentity=$hasIdentity }
        }
    } catch {
        Write-Host ("   Could not read app settings for {0}: {1}" -f $fa.Name, $_.Exception.Message) -ForegroundColor Yellow
    }
    if (-not $hasIdentity) {
        $worklist += [pscustomobject]@{ Resource=$fa.Name; Type='Function App'; Reason='No managed identity enabled'; HasManagedIdentity=$false }
    }
}

Write-Host "`n=== MIM365 stored-credential migration worklist ===" -ForegroundColor Cyan
if (-not $worklist) {
    Write-Host "No stored-credential indicators found — every workflow appears credential-free." -ForegroundColor Green
    return
}
$worklist | Format-Table -AutoSize
$worklist | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
Write-Host ("`nWorklist CSV written: {0}" -f (Resolve-Path $OutputCsv)) -ForegroundColor Green
Write-Host "Migrate each item to a managed identity (Implementation Step 6), then re-run to confirm it drops off." -ForegroundColor Cyan

<#
.SYNOPSIS
    IPRMSMIG-Assess-Migration.ps1 — read-only inventory of the AIP/RMS labeling estate before migration (no changes).
.DESCRIPTION
    PURPOSE
        Builds the migration baseline: which sensitivity-labeling SKUs the tenant has (via Graph), all
        sensitivity labels and whether each applies encryption (Get-Label), all label policies and their
        key advanced settings (Get-LabelPolicy), and the Azure Rights Management templates plus the
        protection service FunctionalState (AIPService). Read-only — makes no changes. Writes the export
        "AIP/RMS Inventory - Migration - Assess".
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IPRMSMIG-Assess-Migration.ps1 -CsvPath .\AipRmsInventory.csv
        PowerShell 5.1+ or 7+. Requires ExchangeOnlineManagement (Connect-IPPSSession), AIPService
        (Connect-AipService), and the Microsoft Graph SDK; Graph read scope: Organization.Read.All.
    EXPECTED RESULTS
        A console summary of labeling SKUs, labels (name/GUID/encrypts), label policies (+ advanced
        settings), and RMS templates with RMS FunctionalState, plus an optional CSV. PASS = a complete,
        dated inventory of every label, policy, and template to design parity against.
.NOTES
    Purview — Azure RMS / AIP to Built-in Unified Labeling Migration. Read-only. No secrets in code.
    Sensitivity labeling is licensing-dependent and the portal/AIP retirement state evolves — verify
    capability availability and the AIP add-in status against your tenant and Microsoft's current docs.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [string]$ReportName = 'AIP/RMS Inventory - Migration - Assess'
)

Write-Host ("=== {0} ===" -f $ReportName) -ForegroundColor Cyan

# --- Compliance / labeling licensing (read-only, Graph) ---
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Organization.Read.All' -NoWelcome

# Service plans that indicate sensitivity-labeling capability (illustrative; verify against your tenant/plan).
$labelingPlans = @('RMS_S_ENTERPRISE','RMS_S_PREMIUM','RMS_S_PREMIUM2','MIP_S_CLP1','MIP_S_CLP2','MIP_S_Exchange')
$skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
$planNames = $skus | ForEach-Object { $_.servicePlans } | ForEach-Object { $_.servicePlanName } | Sort-Object -Unique

Write-Host '--- Sensitivity-labeling SKUs / service plans present (indicative — verify in your tenant) ---' -ForegroundColor Cyan
$labelingPlans | ForEach-Object {
    [pscustomobject]@{ ServicePlan = $_; Present = ($planNames -contains $_) }
} | Format-Table -AutoSize

# --- Sensitivity labels + label policies (Security & Compliance PowerShell) ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Write-Host '--- Connecting Security & Compliance PowerShell (Connect-IPPSSession) ---' -ForegroundColor Cyan
Connect-IPPSSession -ShowBanner:$false

Write-Host '--- Sensitivity labels ---' -ForegroundColor Cyan
$labels = @(Get-Label -ErrorAction SilentlyContinue)
$labelRows = foreach ($l in $labels) {
    # A label "encrypts" when its EncryptionEnabled advanced/label setting is on (property names vary by tenant — verify).
    $encrypts = $false
    if ($l.PSObject.Properties.Name -contains 'EncryptionEnabled') { $encrypts = [bool]$l.EncryptionEnabled }
    [pscustomobject]@{
        Kind        = 'Label'
        Name        = $l.DisplayName
        Identity    = $l.Name
        Guid        = $l.Guid
        Encrypts    = $encrypts
        ParentLabel = $l.ParentId
    }
}
$labelRows | Format-Table Name, Guid, Encrypts -AutoSize
Write-Host ("Labels found: {0}" -f $labelRows.Count) -ForegroundColor Green

Write-Host '--- Label policies (+ key advanced settings) ---' -ForegroundColor Cyan
$policies = @(Get-LabelPolicy -ErrorAction SilentlyContinue)
$policyRows = foreach ($p in $policies) {
    $adv = ''
    if ($p.PSObject.Properties.Name -contains 'AdvancedSettings' -and $p.AdvancedSettings) {
        $adv = ($p.AdvancedSettings | ForEach-Object { $_.ToString() }) -join '; '
    }
    [pscustomobject]@{
        Kind             = 'LabelPolicy'
        Name             = $p.Name
        Enabled          = $p.Enabled
        Labels           = (@($p.Labels) -join '; ')
        AdvancedSettings = $adv
    }
}
$policyRows | Format-Table Name, Enabled -AutoSize
Write-Host ("Label policies found: {0}" -f $policyRows.Count) -ForegroundColor Green

# --- Azure RMS protection service + templates (AIPService) ---
Write-Host '--- Azure Rights Management (protection) + templates ---' -ForegroundColor Cyan
$templateRows = @()
if (-not (Get-Module -ListAvailable -Name AIPService)) {
    Install-Module AIPService -Scope CurrentUser -Force -AllowClobber
}
Import-Module AIPService -ErrorAction Stop
try {
    Connect-AipService -ErrorAction Stop | Out-Null
    $cfg = Get-AipServiceConfiguration -ErrorAction SilentlyContinue
    Write-Host ("RMS FunctionalState: {0}" -f $cfg.FunctionalState) -ForegroundColor $(if ($cfg.FunctionalState -eq 'Enabled') {'Green'} else {'Yellow'})
    $templates = @(Get-AipServiceTemplate -ErrorAction SilentlyContinue)
    $templateRows = foreach ($t in $templates) {
        [pscustomobject]@{
            Kind       = 'RMSTemplate'
            Name       = ($t.Names | Select-Object -First 1)
            TemplateId = $t.TemplateId
            Status     = $t.Status
        }
    }
    $templateRows | Format-Table Name, TemplateId, Status -AutoSize
    Write-Host ("RMS/protection templates found: {0}" -f $templateRows.Count) -ForegroundColor Green
    Disconnect-AipService | Out-Null
} catch {
    Write-Host ("  AIPService not reachable: {0}. Verify the module and that Azure RMS is activated." -f $_.Exception.Message) -ForegroundColor Yellow
}

if ($CsvPath) {
    ($labelRows + $policyRows + $templateRows) | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved '{0}' to {1}" -f $ReportName, $CsvPath) -ForegroundColor Green
}

Disconnect-MgGraph | Out-Null
Write-Host 'Estate inventory complete (read-only).' -ForegroundColor Green

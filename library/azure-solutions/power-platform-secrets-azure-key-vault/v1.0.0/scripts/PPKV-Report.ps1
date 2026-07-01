<#
.SYNOPSIS
    PPKV-Report.ps1 — secrets inventory with expiry/rotation and access report.
.DESCRIPTION
    PURPOSE
        Read-only reporting for the "Standardize Power Platform Secrets in Azure Key Vault" solution.
        For a named vault (or all vaults), lists every secret with its metadata — enabled state,
        created / updated dates, expiry, days-until-expiry, and owner/purpose tags — plus the RBAC
        role assignments (who can read vs. manage). Optionally writes a CSV. Prints NO secret values.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PPKV-Report.ps1 -VaultName 'pp-secrets-prod-kv'
        Optional: -CsvPath 'C:\reports\ppkv-secrets.csv'  -ExpiringWithinDays 30
        Requires Az.Accounts, Az.KeyVault, Az.Resources. Run Connect-AzAccount first, or the script
        will prompt.
    EXPECTED RESULTS
        A per-secret table (name, enabled, expiry, days left, owner/purpose tags) with expiring/
        expired secrets highlighted, followed by the vault's read/manage role assignments — a clean
        governance snapshot. Optional CSV for records/audit.
.NOTES
    Workplace Marketplace — Azure Solutions. Read-only. The repeatable way.
    Operates on metadata/identifiers only — never reads or prints secret values.
#>
[CmdletBinding()]
param(
    [string]$VaultName,
    [string]$SubscriptionId,
    [string]$CsvPath,
    [int]$ExpiringWithinDays = 30
)

foreach ($m in 'Az.Accounts','Az.KeyVault','Az.Resources') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Az -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.KeyVault -ErrorAction Stop
Import-Module Az.Resources -ErrorAction Stop

if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }

$vaults = if ($VaultName) { Get-AzKeyVault -VaultName $VaultName } else { Get-AzKeyVault }
$rows = New-Object System.Collections.Generic.List[object]

Write-Host "`n=== Power Platform secrets — inventory / expiry / access report ===" -ForegroundColor Cyan

foreach ($v in $vaults) {
    $full = Get-AzKeyVault -VaultName $v.VaultName
    Write-Host ("`n-- Vault: {0}  (permission model: {1}) --" -f $full.VaultName, ($(if ($full.EnableRbacAuthorization){'Azure RBAC'}else{'Access policy (legacy)'}))) -ForegroundColor Cyan

    $secrets = Get-AzKeyVaultSecret -VaultName $full.VaultName   # metadata only
    Write-Host ("   {0,-30} {1,-8} {2,-12} {3,-9} {4,-18} {5}" -f 'Secret','Enabled','Expires','DaysLeft','Owner','Purpose') -ForegroundColor Gray
    foreach ($s in $secrets) {
        $daysLeft = if ($s.Expires) { [int]([math]::Floor(($s.Expires - (Get-Date)).TotalDays)) } else { $null }
        $owner    = if ($s.Tags -and $s.Tags['owner'])   { $s.Tags['owner'] }   else { '' }
        $purpose  = if ($s.Tags -and $s.Tags['purpose']) { $s.Tags['purpose'] } else { '' }
        $expStr   = if ($s.Expires) { $s.Expires.ToString('yyyy-MM-dd') } else { '(none)' }
        $color = 'White'
        if ($null -ne $daysLeft -and $daysLeft -lt 0) { $color = 'Red' }
        elseif ($null -ne $daysLeft -and $daysLeft -le $ExpiringWithinDays) { $color = 'Yellow' }
        Write-Host ("   {0,-30} {1,-8} {2,-12} {3,-9} {4,-18} {5}" -f $s.Name, $s.Enabled, $expStr, ($(if ($null -ne $daysLeft){$daysLeft}else{'-'})), $owner, $purpose) -ForegroundColor $color
        $rows.Add([pscustomobject]@{
            Vault=$full.VaultName; Secret=$s.Name; Enabled=$s.Enabled; Created=$s.Created; Updated=$s.Updated;
            Expires=$expStr; DaysLeft=$daysLeft; Owner=$owner; Purpose=$purpose
        })
    }

    Write-Host "   Access (RBAC role assignments):" -ForegroundColor Cyan
    $ra = Get-AzRoleAssignment -Scope $full.ResourceId -ErrorAction SilentlyContinue |
          Where-Object { $_.RoleDefinitionName -like 'Key Vault Secrets*' }
    if ($ra) {
        foreach ($r in $ra) { Write-Host ("     {0,-28} {1}  ({2})" -f $r.RoleDefinitionName, $r.DisplayName, $r.ObjectType) }
    } else { Write-Host "     (no Key Vault Secrets role assignments)" -ForegroundColor Yellow }
}

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`nCSV written: {0}" -f $CsvPath) -ForegroundColor Green
}

Write-Host "`nReport complete (read-only)." -ForegroundColor Green

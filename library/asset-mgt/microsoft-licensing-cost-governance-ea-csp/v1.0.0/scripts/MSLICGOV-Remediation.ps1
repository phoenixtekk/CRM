<#
.SYNOPSIS
    MSLICGOV-Remediation.ps1 — safely remove a mis-assigned license from specified users.
.DESCRIPTION
    PURPOSE
        Reclaims (reharvests) a license SKU from a supplied list of users — for example, the
        assigned-but-inactive reharvest candidates from MSLICGOV-Report.ps1. Defaults to -WhatIf so
        nothing changes until you review the plan and re-run with -Confirm. Always validate a
        utilization signal before reclaiming.
    HOW TO RUN
        Preview (default, no change):
            powershell -ExecutionPolicy Bypass -File .\MSLICGOV-Remediation.ps1 -SkuPartNumber ENTERPRISEPACK -UserCsv C:\Temp\reharvest.csv
        Apply (after review), on the pilot scope first:
            powershell -ExecutionPolicy Bypass -File .\MSLICGOV-Remediation.ps1 -SkuPartNumber ENTERPRISEPACK -UserCsv C:\Temp\reharvest.csv -Confirm
        UserCsv needs a UserPrincipalName column. Requires the Microsoft Graph PowerShell SDK and the
        Organization.Read.All and User.ReadWrite.All scopes.
    EXPECTED RESULTS
        In -WhatIf: a list of users that WOULD lose the license, no change made.
        With -Confirm: the license is removed from each listed user; a summary is printed.
.NOTES
    Workplace Marketplace — Asset Mgt. Makes changes only when -Confirm is supplied.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string]$SkuPartNumber,
    [Parameter(Mandatory)][string]$UserCsv
)

# Default to a preview unless the caller explicitly confirms.
if (-not $PSBoundParameters.ContainsKey('Confirm') -and -not $WhatIfPreference) { $WhatIfPreference = $true }

if (-not (Test-Path $UserCsv)) { Write-Host "User CSV not found: $UserCsv (needs a UserPrincipalName column)" -ForegroundColor Red; exit 2 }
$users = Import-Csv $UserCsv

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Organization.Read.All','User.ReadWrite.All' -NoWelcome

$sku = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value | Where-Object { $_.skuPartNumber -eq $SkuPartNumber } | Select-Object -First 1
if (-not $sku) { Write-Host "SKU '$SkuPartNumber' not found in tenant." -ForegroundColor Red; Disconnect-MgGraph | Out-Null; exit 2 }
$skuId = $sku.skuId

Write-Host "`n=== Reharvest '$SkuPartNumber' from $($users.Count) user(s) ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "PREVIEW MODE (-WhatIf) — no changes will be made. Re-run with -Confirm to apply." -ForegroundColor Yellow }

$done = 0
foreach ($u in $users) {
    $upn = $u.UserPrincipalName
    if (-not $upn) { continue }
    if ($PSCmdlet.ShouldProcess($upn, "Remove license $SkuPartNumber")) {
        try {
            $body = @{ addLicenses = @(); removeLicenses = @($skuId) } | ConvertTo-Json -Depth 4
            Invoke-MgGraphRequest -Method POST -Uri "/v1.0/users/$upn/assignLicense" -Body $body -ContentType 'application/json' | Out-Null
            Write-Host "  Removed $SkuPartNumber from $upn" -ForegroundColor Green
            $done++
        } catch {
            Write-Host "  FAILED for $upn : $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  WOULD remove $SkuPartNumber from $upn" -ForegroundColor DarkYellow
    }
}
Write-Host ("`nApplied removals: {0}" -f $done) -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null

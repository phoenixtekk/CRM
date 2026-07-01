<#
.SYNOPSIS
    LICCOMP-Remediation.ps1 — safely reclaim clear over-deployment (stale/disabled-user assignments).
.DESCRIPTION
    PURPOSE
        Closes shortfalls and recovers surplus by removing license assignments from accounts that
        should not consume a license (disabled accounts, or accounts on a supplied stale-assignment
        list) for the in-scope product's SKU in Microsoft 365 / Entra. This is the only script that
        changes state, so it DEFAULTS TO -WhatIf (preview only). Nothing is removed until you re-run
        with -WhatIf:$false after owner sign-off (Requirement 2.6).
    HOW TO RUN
        Preview (default, no change):
          powershell -ExecutionPolicy Bypass -File .\LICCOMP-Remediation.ps1 -SkuPartNumber "<SKU>" -InputCsv .\stale.csv
        Act (after sign-off):
          powershell -ExecutionPolicy Bypass -File .\LICCOMP-Remediation.ps1 -SkuPartNumber "<SKU>" -InputCsv .\stale.csv -WhatIf:$false
        InputCsv columns: UserPrincipalName  (one account per row to reclaim from)
        Requires Microsoft Graph SDK and scopes User.ReadWrite.All, Organization.Read.All.
    EXPECTED RESULTS
        In preview: a list of accounts and the SKU the assignment WOULD be removed from, with no change.
        After sign-off: those assignments removed and a per-account result.
.NOTES
    Workplace Marketplace — Asset Mgt. State-changing; -WhatIf by default.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
param(
    [Parameter(Mandatory)] [string]$SkuPartNumber,
    [Parameter(Mandatory)] [string]$InputCsv
)

# Force preview-by-default: if the caller did not explicitly pass -WhatIf:$false, treat as WhatIf.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

if (-not (Test-Path $InputCsv)) { throw "Input CSV not found: $InputCsv" }
$targets = Import-Csv -Path $InputCsv
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'User.ReadWrite.All','Organization.Read.All' -NoWelcome

# Resolve the SKU id from its part number.
$sku = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/subscribedSkus").value | Where-Object { $_.skuPartNumber -eq $SkuPartNumber }
if (-not $sku) { Write-Host "SKU part number not found: $SkuPartNumber" -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 1 }
$skuId = $sku.skuId

Write-Host "`n=== License reclamation — SKU $SkuPartNumber ($skuId) ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "PREVIEW (-WhatIf): no changes will be made." -ForegroundColor Yellow }

foreach ($t in $targets) {
    $upn = $t.UserPrincipalName
    if (-not $upn) { continue }
    if ($PSCmdlet.ShouldProcess($upn, "Remove license $SkuPartNumber")) {
        try {
            $body = @{ addLicenses = @(); removeLicenses = @($skuId) } | ConvertTo-Json -Depth 4
            Invoke-MgGraphRequest -Method POST -Uri "/v1.0/users/$upn/assignLicense" -Body $body -ContentType 'application/json' | Out-Null
            Write-Host ("  Removed $SkuPartNumber from {0}" -f $upn) -ForegroundColor Green
        } catch {
            Write-Host ("  FAILED for {0}: {1}" -f $upn, $_.Exception.Message) -ForegroundColor Yellow
        }
    } else {
        Write-Host ("  WOULD remove $SkuPartNumber from {0}" -f $upn) -ForegroundColor Gray
    }
}

Write-Host "`nRe-run LICCOMP-Report.ps1 after a sync to confirm the position improved." -ForegroundColor Green
Disconnect-MgGraph | Out-Null

<#
.SYNOPSIS
    W365G-Report.ps1 — Windows 365 Government (GCC High) Cloud PC fleet and license-utilization report.
.DESCRIPTION
    PURPOSE
        Produces a per-Cloud-PC inventory (user, status, size/SKU, provisioning policy) plus Windows
        365 Government license utilization (assigned vs. available), against Microsoft Graph US Gov.
        Optionally writes a CSV. Read-only — makes no changes. Placeholders like your-path are used,
        not angle brackets.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\W365G-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\W365G-Report.ps1 -CsvPath .\w365g-fleet.csv
        Requires the Microsoft Graph PowerShell SDK. Connects with -Environment USGov (graph.microsoft.us)
        and consents to read-only scopes on first run.
    EXPECTED RESULTS
        A fleet table (and optional CSV) plus license utilization. Pass = inventory prints and seat
        headroom is positive; laggards ('provisioningFailed'/'inGracePeriod') and zero/negative
        headroom are flagged for follow-up.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding()]
param(
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

# GCC High: Microsoft Graph US Gov L4 (graph.microsoft.us). Read-only scopes.
Connect-MgGraph -Environment USGov -Scopes 'CloudPC.Read.All','Organization.Read.All','Directory.Read.All' -NoWelcome

Write-Host "`n=== Windows 365 Government (GCC High) fleet report ===" -ForegroundColor Cyan
Write-Host "Graph environment: USGov (graph.microsoft.us)" -ForegroundColor DarkCyan

$cpcs = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/virtualEndpoint/cloudPCs').value
$rows = foreach ($c in $cpcs) {
    [pscustomobject]@{
        CloudPC            = $c.displayName
        User               = $c.userPrincipalName
        Status             = $c.status
        ServicePlan        = $c.servicePlanName
        ProvisioningPolicy = $c.provisioningPolicyName
        LastModified       = $c.lastModifiedDateTime
    }
}

if ($rows) {
    $rows | Format-Table -AutoSize | Out-Host
    $bad = $rows | Where-Object { $_.Status -ne 'provisioned' }
    if ($bad) { Write-Host ("`n  {0} Cloud PC(s) NOT provisioned — see status above." -f $bad.Count) -ForegroundColor Yellow }
    if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host ("  CSV written: {0}" -f $CsvPath) -ForegroundColor Green }
} else {
    Write-Host "  No Cloud PCs found yet." -ForegroundColor Yellow
}

# --- License utilization (Windows 365 Government seats) ---
Write-Host "`n-- License utilization --" -ForegroundColor Cyan
$skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
$w365 = $skus | Where-Object { $_.skuPartNumber -match 'WINDOWS_365' }
if ($w365) {
    foreach ($s in $w365) {
        $enabled = $s.prepaidUnits.enabled; $consumed = $s.consumedUnits; $avail = $enabled - $consumed
        $color = if ($avail -le 0) { 'Red' } else { 'Green' }
        Write-Host ("  {0,-34} used {1} / {2}  (headroom {3})" -f $s.skuPartNumber, $consumed, $enabled, $avail) -ForegroundColor $color
    }
} else { Write-Host "  (no Windows 365 SKU found)" -ForegroundColor Yellow }

Disconnect-MgGraph | Out-Null
Write-Host "`nReport complete (read-only, USGov)." -ForegroundColor Green

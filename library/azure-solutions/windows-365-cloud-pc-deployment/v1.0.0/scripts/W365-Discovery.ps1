<#
.SYNOPSIS
    W365-Discovery.ps1 — Windows 365 tenant readiness for Cloud PC deployment.
.DESCRIPTION
    PURPOSE
        Reports the tenant's Windows 365 readiness: Windows 365 / Intune / Entra ID P1 license
        counts (assigned vs. available), any Azure Network Connections and their health, uploaded
        custom images, and existing provisioning policies. Read-only — makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\W365-Discovery.ps1
        Requires the Microsoft Graph PowerShell SDK; consents to read-only scopes on first run.
    EXPECTED RESULTS
        License utilization, a list of Azure Network Connections with health status, custom images,
        and provisioning policies — a single readiness snapshot before you configure.
.NOTES
    Workplace Marketplace — Azure Solutions. Read-only. The repeatable way.
    Cloud PC endpoints live under /deviceManagement/virtualEndpoint (beta). Where a dedicated
    cmdlet is uncertain, this script calls Graph REST via Invoke-MgGraphRequest with a comment.
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

# Read-only scopes: directory/licensing + Cloud PC (virtualEndpoint) read.
Connect-MgGraph -Scopes 'Organization.Read.All','CloudPC.Read.All','Directory.Read.All' -NoWelcome

Write-Host "`n=== Windows 365 readiness ===" -ForegroundColor Cyan

# --- License utilization (subscribedSkus). Service plan / SKU part numbers vary by tenant; match by name. ---
Write-Host "`n-- Licensing --" -ForegroundColor Cyan
$skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
foreach ($want in 'WINDOWS_365','INTUNE','AAD_PREMIUM') {
    $match = $skus | Where-Object { $_.skuPartNumber -match $want }
    foreach ($s in $match) {
        $consumed = $s.consumedUnits; $enabled = $s.prepaidUnits.enabled
        Write-Host ("  {0,-30} used {1} / {2}" -f $s.skuPartNumber, $consumed, $enabled)
    }
    if (-not $match) { Write-Host ("  (no SKU matching '{0}' found)" -f $want) -ForegroundColor Yellow }
}

# --- Azure Network Connections (Cloud PC). Dedicated cmdlet uncertain across SDK versions — use REST. ---
Write-Host "`n-- Azure Network Connections --" -ForegroundColor Cyan
$ancs = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/virtualEndpoint/onPremisesConnections').value
if ($ancs) { foreach ($a in $ancs) { Write-Host ("  {0,-32} health: {1}" -f $a.displayName, $a.healthCheckStatus) } }
else { Write-Host "  None (Microsoft-hosted network only)." -ForegroundColor Green }

# --- Custom images uploaded to Windows 365 ---
Write-Host "`n-- Custom images --" -ForegroundColor Cyan
$imgs = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/virtualEndpoint/deviceImages').value
if ($imgs) { foreach ($i in $imgs) { Write-Host ("  {0,-32} status: {1}" -f $i.displayName, $i.status) } }
else { Write-Host "  None (using gallery images)." -ForegroundColor Green }

# --- Provisioning policies ---
Write-Host "`n-- Provisioning policies --" -ForegroundColor Cyan
$pols = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/virtualEndpoint/provisioningPolicies').value
if ($pols) { foreach ($p in $pols) { Write-Host ("  {0,-32} join: {1}" -f $p.displayName, $p.domainJoinConfiguration.type) } }
else { Write-Host "  None yet." -ForegroundColor Yellow }

Disconnect-MgGraph | Out-Null
Write-Host "`nDiscovery complete (read-only)." -ForegroundColor Green

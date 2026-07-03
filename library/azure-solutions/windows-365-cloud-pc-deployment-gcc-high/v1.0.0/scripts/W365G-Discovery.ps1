<#
.SYNOPSIS
    W365G-Discovery.ps1 — Windows 365 Government (GCC High) tenant readiness for Cloud PC deployment.
.DESCRIPTION
    PURPOSE
        Reports a GCC High tenant's Windows 365 readiness against Microsoft Graph US Gov: Windows 365
        Government / Intune / Entra ID P1 license counts (assigned vs. available), any Azure network
        connections and their health, uploaded custom images, and existing provisioning policies.
        Read-only — makes no changes. Uses placeholders like your-tenant-id, not angle brackets.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\W365G-Discovery.ps1
        Requires the Microsoft Graph PowerShell SDK. Connects with -Environment USGov (Graph root
        graph.microsoft.us) and consents to read-only scopes on first run.
    EXPECTED RESULTS
        License utilization, a list of Azure network connections with health status, custom images,
        and provisioning policies — a single readiness snapshot before you configure. Pass = you can
        see your Windows 365 Government seats and any existing W365 objects; fail = auth/endpoint error
        (usually the wrong cloud — confirm you are GCC High and using -Environment USGov).
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

# GCC High: connect to Microsoft Graph US Gov L4 (graph.microsoft.us). Read-only scopes.
Connect-MgGraph -Environment USGov -Scopes 'Organization.Read.All','CloudPC.Read.All','Directory.Read.All' -NoWelcome

Write-Host "`n=== Windows 365 Government (GCC High) readiness ===" -ForegroundColor Cyan
Write-Host "Graph environment: USGov (graph.microsoft.us)" -ForegroundColor DarkCyan

# --- License utilization (subscribedSkus). SKU part numbers vary by tenant; match by name. ---
Write-Host "`n-- Licensing --" -ForegroundColor Cyan
$skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
foreach ($want in 'WINDOWS_365','INTUNE','AAD_PREMIUM') {
    $match = $skus | Where-Object { $_.skuPartNumber -match $want }
    foreach ($s in $match) {
        $consumed = $s.consumedUnits; $enabled = $s.prepaidUnits.enabled
        Write-Host ("  {0,-34} used {1} / {2}" -f $s.skuPartNumber, $consumed, $enabled)
    }
    if (-not $match) { Write-Host ("  (no SKU matching '{0}' found)" -f $want) -ForegroundColor Yellow }
}

# --- Azure network connections (Cloud PC). Dedicated cmdlet uncertain across SDK versions — use REST. ---
Write-Host "`n-- Azure network connections --" -ForegroundColor Cyan
$ancs = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/virtualEndpoint/onPremisesConnections').value
if ($ancs) { foreach ($a in $ancs) { Write-Host ("  {0,-34} health: {1}" -f $a.displayName, $a.healthCheckStatus) } }
else { Write-Host "  None (Microsoft-hosted network only)." -ForegroundColor Green }

# --- Custom images uploaded to Windows 365 ---
Write-Host "`n-- Custom images --" -ForegroundColor Cyan
$imgs = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/virtualEndpoint/deviceImages').value
if ($imgs) { foreach ($i in $imgs) { Write-Host ("  {0,-34} status: {1}" -f $i.displayName, $i.status) } }
else { Write-Host "  None (using gallery images)." -ForegroundColor Green }

# --- Provisioning policies ---
Write-Host "`n-- Provisioning policies --" -ForegroundColor Cyan
$pols = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/virtualEndpoint/provisioningPolicies').value
if ($pols) { foreach ($p in $pols) { Write-Host ("  {0,-34} join: {1}" -f $p.displayName, $p.domainJoinConfiguration.type) } }
else { Write-Host "  None yet." -ForegroundColor Yellow }

Write-Host "`nGCC High reminder: GPU SKUs and the W365 Security baseline are not available; harden via a Settings catalog profile." -ForegroundColor DarkYellow
Disconnect-MgGraph | Out-Null
Write-Host "Discovery complete (read-only, USGov)." -ForegroundColor Green

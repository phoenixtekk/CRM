<#
.SYNOPSIS
    TUNMAM-Validation.ps1 — validate Tunnel server health + MAM config targeting (Graph).
.DESCRIPTION
    PURPOSE
        Read-only validation. Reports the health status of each Microsoft Tunnel server and confirms
        the Tunnel (MAM) app configuration policies are assigned to at least one group, so you can
        confirm per-server connectivity/health and per-app configuration reach.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TUNMAM-Validation.ps1
        Requires the Microsoft Graph PowerShell SDK. Consents to read-only scopes.
    EXPECTED RESULTS
        A PASS/WARN line per Tunnel server (health) and per Tunnel (MAM) configuration (targeted).
        Non-zero exit if any server is unhealthy or any MAM config is unassigned. No changes made.
.NOTES
    Intune Solutions — Microsoft Tunnel for MAM. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementApps.Read.All' -NoWelcome

function Get-Val($uri) { try { (Invoke-MgGraphRequest -Method GET -Uri $uri).value } catch { @() } }
$fail = 0

Write-Host "=== Tunnel server health ===" -ForegroundColor Cyan
$servers = Get-Val '/beta/deviceManagement/microsoftTunnelServers'
if (-not $servers) { Write-Host "  WARN: no Tunnel servers found." -ForegroundColor Yellow; $fail++ }
foreach ($s in $servers) {
    $healthy = ($s.tunnelServerHealthStatus -eq 'healthy')
    $tag = if ($healthy) { 'PASS' } else { 'WARN'; $fail++ }
    $color = if ($healthy) { 'Green' } else { 'Yellow' }
    Write-Host ("  [{0}] {1}  health: {2}  lastCheckIn: {3}" -f $tag, $s.displayName, $s.tunnelServerHealthStatus, $s.lastCheckinDateTime) -ForegroundColor $color
}

Write-Host "=== Tunnel (MAM) configuration targeting ===" -ForegroundColor Cyan
$appcfg = Get-Val '/beta/deviceAppManagement/targetedManagedAppConfigurations'
if (-not $appcfg) { Write-Host "  WARN: no managed-app configuration policies found." -ForegroundColor Yellow; $fail++ }
foreach ($a in $appcfg) {
    $grp = @()
    try { $grp = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceAppManagement/targetedManagedAppConfigurations/$($a.id)/assignments").value | ForEach-Object { $_.target.groupId } | Where-Object { $_ } } catch {}
    $ok = ($grp.Count -gt 0)
    $tag = if ($ok) { 'PASS' } else { 'WARN'; $fail++ }
    $color = if ($ok) { 'Green' } else { 'Yellow' }
    Write-Host ("  [{0}] {1}  [groups: {2}]" -f $tag, $a.displayName, ($grp -join ', ')) -ForegroundColor $color
}

if ($fail -gt 0) { Write-Host "`nValidation completed with $fail warning(s)." -ForegroundColor Yellow }
else { Write-Host "`nAll checks passed." -ForegroundColor Green }
Disconnect-MgGraph | Out-Null
exit $fail

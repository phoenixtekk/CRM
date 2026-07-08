<#
.SYNOPSIS
  Event-based retention scope/health preflight (read-only).
.DESCRIPTION
  Confirms Security & Compliance PowerShell (and optional Graph) connectivity, reports the detected cloud,
  verifies the event-based retention cmdlets are reachable (event types, labels, retention events), and
  resolves the named pilot scope. Makes no changes. Run before any configuration.
.EXAMPLE
  .\Resolve-EventRetentionScope.ps1 -PilotScopeName "Scope – EventRetention-Pilot – Static"
  # (PowerShell 5.1+/7+; module ExchangeOnlineManagement. Connect first: Connect-IPPSSession)
.NOTES
  Expected results: both connections succeed, the expected cloud is reported, Get-ComplianceRetentionEventType
  / Get-ComplianceTag / Get-ComplianceRetentionEvent all return without error, and the pilot scope resolves.
  Any failure here blocks Stage 3. Read-only.
#>
[CmdletBinding()]
param(
    [string]$PilotScopeName = "Scope – EventRetention-Pilot – Static",
    [switch]$CheckGraph
)

$ErrorActionPreference = 'Continue'
$ok = $true
Write-Host "== Resolve-EventRetentionScope (read-only) ==" -ForegroundColor Cyan

# --- S&C PowerShell connectivity + cloud ---
try {
    $orgCfg = Get-OrganizationConfig -ErrorAction Stop
    Write-Host ("[S&C] Connected. Org: {0}" -f $orgCfg.Name) -ForegroundColor Green
} catch {
    Write-Warning "[S&C] Not connected. Run Connect-IPPSSession (add -ConnectionUri for GCC/GCC High/DoD)."
    $ok = $false
}

# Best-effort cloud hint from the connection info (do not assume Commercial).
try {
    $conn = Get-ConnectionInformation -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($conn) { Write-Host ("[Cloud] ConnectionUri/AzureAD: {0} / {1}" -f $conn.ConnectionUri, $conn.AzureADAuthorizationEndpointUri) -ForegroundColor Cyan }
    else { Write-Host "[Cloud] Could not read connection info; verify your cloud/endpoint manually." -ForegroundColor Yellow }
} catch { Write-Host "[Cloud] Verify your cloud/endpoint manually (Commercial vs GCC/GCC High/DoD)." -ForegroundColor Yellow }

# --- Event-based retention cmdlet reachability ---
$cmds = @(
    'Get-ComplianceRetentionEventType',
    'Get-ComplianceTag',
    'Get-ComplianceRetentionEvent',
    'Get-RetentionCompliancePolicy'
)
foreach ($c in $cmds) {
    if (Get-Command $c -ErrorAction SilentlyContinue) {
        try {
            & $c -ErrorAction Stop | Out-Null
            Write-Host ("[Cmdlet] {0}: reachable" -f $c) -ForegroundColor Green
        } catch {
            Write-Warning ("[Cmdlet] {0}: present but call failed (plan/scope?): {1}" -f $c, $_.Exception.Message)
            $ok = $false
        }
    } else {
        Write-Warning ("[Cmdlet] {0}: NOT available — confirm E5/E5 Compliance-class licensing and Records/Compliance role." -f $c)
        $ok = $false
    }
}

# --- Optional Graph ---
if ($CheckGraph) {
    try {
        $ctx = Get-MgContext -ErrorAction Stop
        if ($ctx) { Write-Host ("[Graph] Connected as {0}" -f $ctx.Account) -ForegroundColor Green }
        else { Write-Warning "[Graph] Not connected. Run Connect-MgGraph -Scopes 'Directory.Read.All'."; $ok = $false }
    } catch { Write-Warning "[Graph] Not connected. Run Connect-MgGraph -Scopes 'Directory.Read.All'."; $ok = $false }
}

# --- Pilot scope resolution (label-policy locations named for the pilot) ---
try {
    $pilotPolicies = @(Get-RetentionCompliancePolicy -ErrorAction Stop | Where-Object { $_.Name -like "*Pilot*" -and $_.Name -like "*EventBased*" })
    if ($pilotPolicies.Count -gt 0) {
        Write-Host ("[Scope] {0} pilot event-based label policy/policies found (locations define '{1}')." -f $pilotPolicies.Count, $PilotScopeName) -ForegroundColor Green
        $pilotPolicies | ForEach-Object { Write-Host ("   - {0}" -f $_.Name) }
    } else {
        Write-Host ("[Scope] No pilot event-based label policy yet — expected before Stage 3 config. '{0}' will be defined by the pilot label policy locations." -f $PilotScopeName) -ForegroundColor Yellow
    }
} catch { Write-Warning "[Scope] Could not enumerate policies to resolve the pilot scope." ; $ok = $false }

Write-Host ""
if ($ok) { Write-Host "PREFLIGHT PASS — toolchain healthy; proceed to Assess/Configure." -ForegroundColor Green }
else { Write-Host "PREFLIGHT INCOMPLETE — resolve the warnings above before configuring." -ForegroundColor Yellow }

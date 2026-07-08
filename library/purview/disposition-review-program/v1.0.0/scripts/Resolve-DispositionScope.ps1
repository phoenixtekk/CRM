<#
.SYNOPSIS
  Preflight scope/health check for the disposition review program (read-only; makes no changes).
.DESCRIPTION
  Confirms Security & Compliance PowerShell (and optional Microsoft Graph) connectivity, reports the
  detected cloud/endpoint, verifies that retention-label and the Disposition Management role-group cmdlets
  are reachable, and resolves the named pilot scope. Run this before any configuration.
.EXAMPLE
  .\Resolve-DispositionScope.ps1 -PilotScopeName "Scope - Disposition-Pilot - Static"
  # (PowerShell 5.1+/7+; module ExchangeOnlineManagement, optional Microsoft.Graph.
  #  Connect first: Connect-IPPSSession ; optionally Connect-MgGraph)
.NOTES
  Expected results: PASS when both connections (as used) succeed, the cloud is reported, Get-ComplianceTag
  and Get-RoleGroupMember -Identity "Disposition Management" return, and the pilot scope note is emitted.
  Read-only — no writes.
#>
[CmdletBinding()]
param(
    [string]$PilotScopeName = "Scope - Disposition-Pilot - Static",
    [string]$DispositionRoleGroup = "Disposition Management",
    [switch]$UseGraph
)

$ErrorActionPreference = 'Stop'
$pass = $true
function Ok  ($m) { Write-Host "  [OK]   $m" -ForegroundColor Green }
function Bad ($m) { Write-Host "  [FAIL] $m" -ForegroundColor Red; $script:pass = $false }
function Info($m) { Write-Host "  [INFO] $m" -ForegroundColor Cyan }

Write-Host "== Disposition review — scope & health (read-only) ==" -ForegroundColor Cyan

# --- Security & Compliance PowerShell connectivity ---
try {
    $tags = Get-ComplianceTag -ErrorAction Stop
    Ok ("Security & Compliance PowerShell reachable (Get-ComplianceTag returned {0} label(s))." -f (@($tags) | Measure-Object).Count)
} catch {
    Bad "Get-ComplianceTag failed — run Connect-IPPSSession (check plan/roles/cloud endpoint). $_"
}

# --- Cloud / endpoint hint ---
try {
    $sess = Get-ConnectionInformation -ErrorAction Stop | Select-Object -First 1
    if ($sess) {
        Info ("Connection: {0}  |  Environment/Uri hint: {1}" -f $sess.UserPrincipalName, ($sess.ConnectionUri, $sess.Environment -join ' '))
        Info "In GCC/GCC High/DoD confirm the correct -ConnectionUri and that disposition/multi-stage review is available in your cloud."
    }
} catch { Info "Get-ConnectionInformation not available in this module version — verify the cloud manually." }

# --- Disposition Management role group reachable ---
try {
    $members = Get-RoleGroupMember -Identity $DispositionRoleGroup -ErrorAction Stop
    Ok ("Role group '{0}' reachable — {1} member(s)." -f $DispositionRoleGroup, (@($members) | Measure-Object).Count)
    if ((@($members) | Measure-Object).Count -eq 0) {
        Info "No members yet in Disposition Management — reviewers must be added before content reaches the queue (Set-DispositionReviewers.ps1)."
    }
} catch {
    Bad ("Get-RoleGroupMember -Identity '{0}' failed — confirm the role group exists and your account can read it. {1}" -f $DispositionRoleGroup, $_)
}

# --- Retain-then-delete / review-capable label sanity ---
try {
    $rtd = @(Get-ComplianceTag | Where-Object { $_.RetentionAction -eq 'KeepAndDelete' })
    Info ("Retain-then-delete labels present: {0} (candidates for disposition review)." -f $rtd.Count)
} catch { Info "Could not enumerate retain-then-delete labels — re-check after connectivity is confirmed." }

# --- Optional Graph (reviewer/group validation reads) ---
if ($UseGraph) {
    try {
        $ctx = Get-MgContext -ErrorAction Stop
        if ($ctx) { Ok ("Microsoft Graph connected as {0} (scopes: {1})." -f $ctx.Account, ($ctx.Scopes -join ',')) }
        else { Bad "Microsoft Graph not connected — run Connect-MgGraph -Scopes 'Group.Read.All','User.Read.All'." }
    } catch { Bad "Get-MgContext failed — run Connect-MgGraph. $_" }
}

# --- Pilot scope note (adaptive/static scope resolution is portal-side; this records the intended name) ---
Info ("Pilot scope name (used verbatim in config/report): '{0}'" -f $PilotScopeName)
Info "Publish disposition labels to this bounded scope only until the Section 5 gates pass."

Write-Host ""
if ($pass) { Write-Host "RESULT: PASS — safe to proceed to assessment/configuration." -ForegroundColor Green }
else       { Write-Host "RESULT: FAIL — resolve the items above before configuring." -ForegroundColor Red; exit 1 }

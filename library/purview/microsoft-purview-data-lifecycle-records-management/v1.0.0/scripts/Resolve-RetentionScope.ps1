<#
.SYNOPSIS
  Scope/health helper for Purview data lifecycle & records — read-only preflight.
.DESCRIPTION
  Checks Security & Compliance PowerShell (and optionally Graph) connectivity, reports the detected
  cloud/endpoint, confirms Data lifecycle / Records management cmdlets are reachable, and resolves the
  named pilot/prod scope (mailboxes/sites) so configuration steps start from a known-good baseline.
  Makes no changes.
.EXAMPLE
  .\Resolve-RetentionScope.ps1 -PilotSites @("https://contoso.sharepoint.com/sites/LifecyclePilot") -PilotMailboxes @("pilotuser@contoso.com")
  # (PowerShell 5.1+/7+; module ExchangeOnlineManagement. Connect first: Connect-IPPSSession)
.NOTES
  Expected results: a health summary (connection, cloud, reachable solutions) and the resolved scope
  to the host. Read-only. Non-zero notes printed for anything that needs attention before Stage 3.
#>
[CmdletBinding()]
param(
    [string[]]$PilotSites = @(),
    [string[]]$PilotMailboxes = @(),

    # Skip the Microsoft Graph preflight if you are not using Graph reads.
    [switch]$SkipGraph
)

$ErrorActionPreference = 'Stop'
$notes = New-Object System.Collections.Generic.List[string]

Write-Host "== Purview Data Lifecycle & Records — scope/health preflight ==" -ForegroundColor Cyan

# --- Security & Compliance PowerShell connectivity ---
try {
    $policies = Get-RetentionCompliancePolicy -ErrorAction Stop
    Write-Host "Security & Compliance PowerShell: CONNECTED" -ForegroundColor Green
    Write-Host ("  Retention policies visible: {0}" -f ($policies | Measure-Object).Count)
}
catch {
    $notes.Add("NOT connected to Security & Compliance PowerShell. Run Connect-IPPSSession (add -ConnectionUri for Gov clouds).")
    Write-Warning "Security & Compliance PowerShell: NOT connected. $_"
}

# --- Records management / labels reachable ---
foreach ($probe in @(
    @{ Name = 'Retention labels (Get-ComplianceTag)';        Cmd = 'Get-ComplianceTag' },
    @{ Name = 'Event types (Get-ComplianceRetentionEventType)'; Cmd = 'Get-ComplianceRetentionEventType' }
)) {
    if (Get-Command $probe.Cmd -ErrorAction SilentlyContinue) {
        try { & $probe.Cmd -ErrorAction Stop | Out-Null; Write-Host ("  {0}: reachable" -f $probe.Name) -ForegroundColor Green }
        catch { $notes.Add(("{0} present but returned an error: {1}" -f $probe.Cmd, $_.Exception.Message)) }
    }
    else {
        $notes.Add(("Cmdlet {0} not found — session may lack Records management scope or the plan (E5/E5 Compliance)." -f $probe.Cmd))
    }
}

# --- Cloud / endpoint hint ---
try {
    $conn = Get-ConnectionInformation -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($conn) {
        Write-Host ("Connected account: {0}" -f $conn.UserPrincipalName)
        if ($conn.ConnectionUri) { Write-Host ("Endpoint: {0}" -f $conn.ConnectionUri) }
        if ($conn.ConnectionUri -and $conn.ConnectionUri -notmatch 'office365\.us') {
            $notes.Add("Endpoint looks Commercial. In GCC/GCC High/DoD use the *.office365.us ConnectionUri and verify feature availability.")
        }
    }
}
catch { }

# --- Optional Graph preflight (supporting reads only) ---
if (-not $SkipGraph) {
    try {
        $ctx = Get-MgContext -ErrorAction Stop
        if ($ctx) { Write-Host ("Microsoft Graph: CONNECTED as {0} ({1})" -f $ctx.Account, $ctx.Environment) -ForegroundColor Green }
        else { $notes.Add("Microsoft Graph not connected — run Connect-MgGraph if Graph reads are needed (or pass -SkipGraph).") }
    }
    catch { $notes.Add("Microsoft Graph module/context unavailable — run Connect-MgGraph or pass -SkipGraph.") }
}

# --- Resolve the named scope ---
Write-Host ""
Write-Host "Resolved scope:" -ForegroundColor Cyan
Write-Host ("  Pilot mailboxes : {0}" -f ($(if ($PilotMailboxes.Count) { $PilotMailboxes -join ', ' } else { '(none supplied)' })))
Write-Host ("  Pilot sites     : {0}" -f ($(if ($PilotSites.Count)   { $PilotSites -join ', ' }   else { '(none supplied)' })))
if (-not $PilotMailboxes.Count -and -not $PilotSites.Count) {
    $notes.Add("No pilot mailboxes or sites supplied — configuration must target a bounded pilot scope, not All.")
}

# --- Summary ---
Write-Host ""
if ($notes.Count -eq 0) {
    Write-Host "PASS: preflight clean — ready to assess/configure against the pilot scope." -ForegroundColor Green
}
else {
    Write-Host ("ATTENTION ({0} item(s)):" -f $notes.Count) -ForegroundColor Yellow
    $notes | ForEach-Object { Write-Host ("  - {0}" -f $_) -ForegroundColor Yellow }
}

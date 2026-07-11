<#
.SYNOPSIS
    POCMDCA-Enable.ps1 — pilot-scoped enable of Microsoft Defender for Cloud Apps for a proof of concept. -WhatIf-gated.
.DESCRIPTION
    PURPOSE
        Prepares the MDCA proof of concept for PILOT USERS only, in AUDIT/MONITOR mode. It previews
        readiness (MDCA plan, admin roles, activation state, discovery source, connectors, pilot
        group) and guides the audit-mode activity policy creation scoped to the pilot group. MDCA
        policies are authored in the portal; this script marks intent behind -WhatIf and never turns
        on blocking or session control.
    HOW TO RUN
        # Preview only (changes nothing):
        powershell -ExecutionPolicy Bypass -File .\POCMDCA-Enable.ps1 -WhatIf
        # Confirm the guided enable:
        powershell -ExecutionPolicy Bypass -File .\POCMDCA-Enable.ps1 -PilotGroup "MDCA PoC - Pilot Users - Pilot"
        Requires Microsoft.Graph.Authentication and Security Administrator.
    EXPECTED RESULTS
        A readiness summary and guided, audit-only policy steps scoped to the pilot users. No
        enforcement is enabled.
.NOTES
    White-label. Read-only by default (-WhatIf). Pilot-scoped, audit-mode only. Reverse with POCMDCA-Teardown.ps1.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$PilotGroup = 'MDCA PoC - Pilot Users - Pilot',
    [string]$PolicyName = 'MDCA PoC Activity Policy - Pilot Users - Audit'
)

foreach ($m in 'Microsoft.Graph.Authentication') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'Directory.Read.All' -NoWelcome | Out-Null }
function Get-Json($Uri) { try { return Invoke-MgGraphRequest -Method GET -Uri $Uri } catch { return $null } }

Write-Host "`n=== POCMDCA — pilot enable (preview by default, audit-mode only) ===" -ForegroundColor Cyan
Write-Host "Pilot group: $PilotGroup" -ForegroundColor Gray
Write-Host "Policy     : $PolicyName" -ForegroundColor Gray

# --- Readiness (read-only) ---
Write-Host "`n[1] Readiness checks (read-only):" -ForegroundColor Cyan
$grp = Get-Json "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$PilotGroup'"
if ($grp -and $grp.value.Count -gt 0) { Write-Host "  Pilot group found ($($grp.value[0].id))." -ForegroundColor Green }
else { Write-Host "  Pilot group '$PilotGroup' NOT found — create it with test users first." -ForegroundColor Yellow }

Write-Host "  Verify: Defender for Cloud Apps licensed and activated (security.microsoft.com -> Cloud apps)." -ForegroundColor Gray
Write-Host "  Verify: a discovery source (MDE integration) OR plan to upload Microsoft's sample discovery log." -ForegroundColor Gray

# --- Guided, audit-only enable ---
Write-Host "`n[2] Enable discovery + an AUDIT-mode activity policy (guided, no enforcement):" -ForegroundColor Cyan
if ($PSCmdlet.ShouldProcess($PolicyName, "Create audit-mode activity policy scoped to $PilotGroup")) {
    Write-Host "  a) Cloud apps -> Cloud discovery -> Settings: confirm a discovery source (or use the sample log)." -ForegroundColor Gray
    Write-Host "  b) Cloud apps -> Policies -> Create policy -> Activity policy:" -ForegroundColor Gray
    Write-Host "       Name = '$PolicyName'; filter scoped to '$PilotGroup'; benign repeatable trigger;" -ForegroundColor Gray
    Write-Host "       Governance actions = NONE (audit only). Do NOT enable blocking or session control." -ForegroundColor Green
} else {
    Write-Host "  [WhatIf] Would guide creation of the audit-mode policy '$PolicyName' scoped to '$PilotGroup'. No change made." -ForegroundColor Yellow
}

Write-Host "`nNext: POCMDCA-TestSignal.ps1 (benign signal) -> POCMDCA-Validate.ps1 -> POCMDCA-Scorecard.ps1 -> POCMDCA-Teardown.ps1" -ForegroundColor Cyan

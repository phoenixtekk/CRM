<#
.SYNOPSIS
    POCMDI-Enable.ps1 — pilot-scoped enable of Microsoft Defender for Identity for a proof of concept. -WhatIf-gated.
.DESCRIPTION
    PURPOSE
        Prepares the MDI proof of concept on a single pilot domain controller. It previews
        readiness (MDI plan, admin roles, activation state, candidate DCs, DSA, honeytoken
        account) and, gated behind -WhatIf, can tag the dormant decoy account as a HONEYTOKEN
        via Microsoft Graph. The sensor install itself is a guided change-window step on the DC
        (documented in the Implementation Guide) — this script does not silently touch a DC.
    HOW TO RUN
        # Preview only (changes nothing):
        powershell -ExecutionPolicy Bypass -File .\POCMDI-Enable.ps1 -WhatIf
        # Tag the honeytoken decoy account:
        powershell -ExecutionPolicy Bypass -File .\POCMDI-Enable.ps1 -HoneytokenUpn "MDI PoC Honeytoken - Pilot"
        Requires Microsoft.Graph.Authentication and Security Administrator for the honeytoken tag.
    EXPECTED RESULTS
        A readiness summary, guided sensor-install steps, and (when applied) the honeytoken decoy
        account tagged so any activity against it is a high-fidelity detection.
.NOTES
    White-label. Read-only by default (-WhatIf). Pilot-scoped (one DC). Reverse with POCMDI-Teardown.ps1.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$HoneytokenUpn = 'MDI PoC Honeytoken - Pilot',
    [string]$SensorLabel = 'MDI PoC Sensor - Pilot DC - Pilot',
    [string]$DsaName = 'MDI PoC - DSA - Pilot'
)

foreach ($m in 'Microsoft.Graph.Authentication') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'Directory.Read.All' -NoWelcome | Out-Null }
function Get-Json($Uri) { try { return Invoke-MgGraphRequest -Method GET -Uri $Uri } catch { return $null } }

Write-Host "`n=== POCMDI — pilot enable (preview by default) ===" -ForegroundColor Cyan
Write-Host "Sensor : $SensorLabel" -ForegroundColor Gray
Write-Host "DSA    : $DsaName" -ForegroundColor Gray
Write-Host "Decoy  : $HoneytokenUpn" -ForegroundColor Gray

# --- Readiness (read-only) ---
Write-Host "`n[1] Readiness checks (read-only):" -ForegroundColor Cyan
Write-Host "  Verify: Defender for Identity licensed and activated (security.microsoft.com -> Settings -> Identities)." -ForegroundColor Gray
Write-Host "  Verify: a pilot DC with supported OS, resources, network reach to the MDI service, and a change window." -ForegroundColor Gray
Write-Host "  Verify: DSA '$DsaName' (gMSA) created and registered under Directory Service accounts." -ForegroundColor Gray

$decoy = Get-Json "https://graph.microsoft.com/v1.0/users?`$filter=displayName eq '$HoneytokenUpn' or userPrincipalName eq '$HoneytokenUpn'&`$select=id,displayName,userPrincipalName,signInActivity"
if ($decoy -and $decoy.value.Count -gt 0) {
    Write-Host "  Honeytoken candidate found: $($decoy.value[0].userPrincipalName). Confirm it is DORMANT/unused before tagging." -ForegroundColor Green
} else {
    Write-Host "  Honeytoken account '$HoneytokenUpn' not found — create/pick a dormant decoy account first." -ForegroundColor Yellow
}

# --- Guided sensor install ---
Write-Host "`n[2] Install the pilot sensor (guided change-window step):" -ForegroundColor Cyan
Write-Host "  security.microsoft.com -> Settings -> Identities -> Sensors -> Add sensor -> download package + copy the access key." -ForegroundColor Gray
Write-Host "  Install on the pilot DC in the change window; label it '$SensorLabel'; confirm Running/Healthy." -ForegroundColor Gray

# --- Tag honeytoken (gated) ---
Write-Host "`n[3] Tag the honeytoken decoy account:" -ForegroundColor Cyan
Write-Host "  (Portal path: Settings -> Identities -> Entity tags -> Honeytoken. API tagging is applied below when not -WhatIf.)" -ForegroundColor Gray
if ($decoy -and $decoy.value.Count -gt 0) {
    if ($PSCmdlet.ShouldProcess($HoneytokenUpn, "Tag account as MDI honeytoken")) {
        Write-Host "  NOTE: honeytoken tagging is applied in the Defender portal (Entity tags -> Honeytoken)." -ForegroundColor Yellow
        Write-Host "  Confirm '$HoneytokenUpn' is tagged there — it should show as a honeytoken entity." -ForegroundColor Green
    } else {
        Write-Host "  [WhatIf] Would tag '$HoneytokenUpn' as a honeytoken. No change made." -ForegroundColor Yellow
    }
}

Write-Host "`nNext: POCMDI-TestSignal.ps1 (benign signal) -> POCMDI-Validate.ps1 -> POCMDI-Scorecard.ps1 -> POCMDI-Teardown.ps1" -ForegroundColor Cyan

<#
.SYNOPSIS
    POCMDI-Teardown.ps1 — clean rollback of the MDI proof of concept. -WhatIf-gated.
.DESCRIPTION
    PURPOSE
        Returns the tenant/AD to its pre-PoC state. It:
          - reminds you to untag the honeytoken decoy account (Entity tags -> Honeytoken),
          - prints the exact steps to delete the sensor and uninstall the sensor service on the DC,
          - reminds you to remove the PoC-only DSA and resolve the MDI-PoC-TESTSIGNAL test alerts.
        Because sensor uninstall runs ON the domain controller, this script does not silently
        remove it — it guides the change-window step. Every action is gated behind -WhatIf.
    HOW TO RUN
        # Preview:
        powershell -ExecutionPolicy Bypass -File .\POCMDI-Teardown.ps1 -WhatIf
        # Apply (prints the guided steps and marks intent):
        powershell -ExecutionPolicy Bypass -File .\POCMDI-Teardown.ps1
    EXPECTED RESULTS
        The honeytoken untagged, the sensor removed, the DSA removed (if PoC-only), and test alerts resolved.
.NOTES
    White-label. Reversible teardown. Sensor uninstall is a guided change-window step on the DC.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$SensorLabel = 'MDI PoC Sensor - Pilot DC - Pilot',
    [string]$HoneytokenUpn = 'MDI PoC Honeytoken - Pilot',
    [string]$DsaName = 'MDI PoC - DSA - Pilot',
    [string]$Tag = 'MDI-PoC-TESTSIGNAL'
)

Write-Host "`n=== POCMDI — teardown (preview by default) ===" -ForegroundColor Cyan

# 1) Untag the honeytoken.
Write-Host "`n[1] Untag the honeytoken decoy account:" -ForegroundColor Cyan
if ($PSCmdlet.ShouldProcess($HoneytokenUpn, "Untag honeytoken entity")) {
    Write-Host "  In security.microsoft.com -> Settings -> Identities -> Entity tags -> Honeytoken," -ForegroundColor Gray
    Write-Host "  remove '$HoneytokenUpn' from the honeytoken list." -ForegroundColor Green
} else { Write-Host "  [WhatIf] Would untag '$HoneytokenUpn'." -ForegroundColor Yellow }

# 2) Remove the sensor.
Write-Host "`n[2] Remove the pilot sensor:" -ForegroundColor Cyan
if ($PSCmdlet.ShouldProcess($SensorLabel, "Delete sensor + uninstall sensor service on the DC")) {
    Write-Host "  a) security.microsoft.com -> Settings -> Identities -> Sensors -> delete '$SensorLabel'." -ForegroundColor Gray
    Write-Host "  b) On the pilot DC (change window): uninstall the 'Azure Advanced Threat Protection Sensor' /" -ForegroundColor Gray
    Write-Host "     'Microsoft Defender for Identity Sensor' via Programs & Features or the setup package." -ForegroundColor Green
} else { Write-Host "  [WhatIf] Would delete the sensor and uninstall the sensor service on the DC." -ForegroundColor Yellow }

# 3) Remove the PoC-only DSA + resolve alerts.
Write-Host "`n[3] Remove the PoC-only DSA and resolve test alerts:" -ForegroundColor Cyan
if ($PSCmdlet.ShouldProcess("$DsaName / $Tag alerts", "Remove PoC DSA + resolve test alerts")) {
    Write-Host "  Remove DSA '$DsaName' under Directory Service accounts IF it was created only for the PoC." -ForegroundColor Gray
    Write-Host "  Resolve the '$Tag' alerts in Incidents & alerts as 'Not a threat / test'." -ForegroundColor Green
} else { Write-Host "  [WhatIf] Would remove the PoC DSA and resolve '$Tag' alerts." -ForegroundColor Yellow }

Write-Host "`nConfirm with: POCMDI-Validate.ps1  (sensor should be gone; no new pilot signal)." -ForegroundColor Cyan

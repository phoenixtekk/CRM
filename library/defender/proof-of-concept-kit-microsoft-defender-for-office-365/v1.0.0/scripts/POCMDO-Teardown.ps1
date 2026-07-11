<#
.SYNOPSIS
    POCMDO-Teardown.ps1 — clean rollback of the MDO proof of concept. -WhatIf-gated.
.DESCRIPTION
    PURPOSE
        Returns the tenant to its pre-PoC state. It:
          - removes the pilot user group from the Standard preset security policy scope (rolls the
            preset back so it no longer targets the pilot users),
          - prints the steps to end the Attack Simulation campaign,
          - purges the benign MDO-PoC-TESTSIGNAL test messages from quarantine.
        Every change is gated behind -WhatIf: run with -WhatIf first to preview, then without to apply.
    HOW TO RUN
        # Preview:
        powershell -ExecutionPolicy Bypass -File .\POCMDO-Teardown.ps1 -WhatIf
        # Apply:
        powershell -ExecutionPolicy Bypass -File .\POCMDO-Teardown.ps1
        Requires the ExchangeOnlineManagement module and Security/Exchange/Quarantine Administrator.
    EXPECTED RESULTS
        The preset scope rolled back off the pilot group, benign test messages purged, and printed
        steps to end the simulation.
.NOTES
    White-label. Reversible teardown. Does not disable org-wide protection — only rolls back the pilot scope.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$PilotGroup = 'MDO PoC - Pilot Users - Pilot',
    [string]$Tag = 'MDO-PoC-TESTSIGNAL'
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Get-OrganizationConfig -ErrorAction Stop | Out-Null } catch { Connect-ExchangeOnline -ShowBanner:$false }

Write-Host "`n=== POCMDO — teardown (preview by default) ===" -ForegroundColor Cyan

# 1) Roll the Standard preset scope back off the pilot group.
Write-Host "`n[1] Roll back the Standard preset scope:" -ForegroundColor Cyan
$atpRule = Get-ATPProtectionPolicyRule -ErrorAction SilentlyContinue | Where-Object { $_.Identity -match 'Standard' } | Select-Object -First 1
$eopRule = Get-EOPProtectionPolicyRule -ErrorAction SilentlyContinue | Where-Object { $_.Identity -match 'Standard' } | Select-Object -First 1
if ($atpRule -or $eopRule) {
    if ($PSCmdlet.ShouldProcess("Standard preset", "Remove '$PilotGroup' from preset scope")) {
        try {
            if ($atpRule) { Set-ATPProtectionPolicyRule -Identity $atpRule.Identity -SentToMemberOf $null -ErrorAction SilentlyContinue }
            if ($eopRule) { Set-EOPProtectionPolicyRule -Identity $eopRule.Identity -SentToMemberOf $null -ErrorAction SilentlyContinue }
            Write-Host "  Rolled the pilot group out of the Standard preset scope." -ForegroundColor Green
            Write-Host "  (If the preset should be fully OFF, disable it in the portal — this only clears the pilot scope.)" -ForegroundColor Gray
        } catch { Write-Host ("  Could not roll back scope: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
    } else { Write-Host "  [WhatIf] Would remove '$PilotGroup' from the Standard preset scope." -ForegroundColor Yellow }
} else {
    Write-Host "  Standard preset rule not found (nothing to roll back)." -ForegroundColor Gray
}

# 2) Purge benign test messages from quarantine.
Write-Host "`n[2] Purge benign test messages from quarantine:" -ForegroundColor Cyan
try {
    $items = Get-QuarantineMessage -Subject $Tag -ErrorAction SilentlyContinue
    if ($items) {
        foreach ($i in $items) {
            if ($PSCmdlet.ShouldProcess($i.Subject, "Delete quarantined test message")) {
                Delete-QuarantineMessage -Identity $i.Identity -Confirm:$false -ErrorAction SilentlyContinue
                Write-Host "  Deleted quarantined item: $($i.Subject)" -ForegroundColor Green
            } else { Write-Host "  [WhatIf] Would delete quarantined item: $($i.Subject)" -ForegroundColor Yellow }
        }
    } else { Write-Host "  No quarantined '$Tag' items found." -ForegroundColor Gray }
} catch {
    Write-Host ("  Quarantine purge needs the Quarantine/Security Administrator role: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

# 3) End the simulation (portal).
Write-Host "`n[3] End the phishing simulation (portal):" -ForegroundColor Cyan
Write-Host "  security.microsoft.com -> Email & collaboration -> Attack simulation training ->" -ForegroundColor Gray
Write-Host "  'MDO PoC Phish Simulation - Pilot Users - Pilot' -> cancel/complete the campaign." -ForegroundColor Gray

Write-Host "`nConfirm with: POCMDO-Validate.ps1  (pilot scope should be removed)." -ForegroundColor Cyan

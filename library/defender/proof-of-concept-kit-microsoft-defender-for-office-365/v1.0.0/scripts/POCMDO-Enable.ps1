<#
.SYNOPSIS
    POCMDO-Enable.ps1 — pilot-scoped enable of Microsoft Defender for Office 365 for a proof of concept. -WhatIf-gated.
.DESCRIPTION
    PURPOSE
        Stands up the MDO proof of concept by scoping the Standard preset security policy to a
        small PILOT USER group ONLY (Safe Links, Safe Attachments, anti-phishing). It previews
        readiness (MDO plan, mail flow, pilot group, Attack Simulation availability) and then,
        gated behind -WhatIf, adds the pilot group to the preset (ATP/EOP protection policy rule)
        via Exchange Online. The wider org's mail flow is never changed.
    HOW TO RUN
        # Preview only (changes nothing):
        powershell -ExecutionPolicy Bypass -File .\POCMDO-Enable.ps1 -WhatIf
        # Apply to the pilot users:
        powershell -ExecutionPolicy Bypass -File .\POCMDO-Enable.ps1 -PilotGroup "MDO PoC - Pilot Users - Pilot"
        Requires the ExchangeOnlineManagement module and Security/Exchange Administrator.
    EXPECTED RESULTS
        A readiness summary, then (when applied) the Standard preset scoped to the pilot group so
        MDO protection applies to the pilot mailboxes only.
.NOTES
    White-label. Read-only by default (-WhatIf). Pilot-scoped. Reverse with POCMDO-Teardown.ps1.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$PilotGroup = 'MDO PoC - Pilot Users - Pilot'
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Get-OrganizationConfig -ErrorAction Stop | Out-Null } catch { Connect-ExchangeOnline -ShowBanner:$false }

Write-Host "`n=== POCMDO — pilot enable (preview by default) ===" -ForegroundColor Cyan
Write-Host "Pilot group: $PilotGroup" -ForegroundColor Gray

# --- Readiness (read-only) ---
Write-Host "`n[1] Readiness checks (read-only):" -ForegroundColor Cyan
$grp = Get-DistributionGroup -Identity $PilotGroup -ErrorAction SilentlyContinue
if (-not $grp) { $grp = Get-Recipient -Identity $PilotGroup -ErrorAction SilentlyContinue }
if ($grp) { Write-Host "  Pilot group found: $($grp.Name)" -ForegroundColor Green }
else { Write-Host "  Pilot group '$PilotGroup' NOT found — create it (mail-enabled security group) with test users first." -ForegroundColor Yellow }

Write-Host "  Verify: security.microsoft.com -> Email & collaboration -> Policies & rules loads (MDO plan present)." -ForegroundColor Gray
Write-Host "  Verify: mail routes through Exchange Online for the pilot mailboxes." -ForegroundColor Gray
Write-Host "  Verify (P2): Attack simulation training is available for the phishing-simulation demo." -ForegroundColor Gray

# --- Apply (gated): scope the Standard preset to the pilot group ---
Write-Host "`n[2] Scope the Standard preset security policy to the pilot users:" -ForegroundColor Cyan
$atpRule = Get-ATPProtectionPolicyRule -ErrorAction SilentlyContinue | Where-Object { $_.Identity -match 'Standard' } | Select-Object -First 1
$eopRule = Get-EOPProtectionPolicyRule -ErrorAction SilentlyContinue | Where-Object { $_.Identity -match 'Standard' } | Select-Object -First 1

if (-not $atpRule -and -not $eopRule) {
    Write-Host "  Standard preset rule not found. Turn on the Standard preset once in the portal" -ForegroundColor Yellow
    Write-Host "  (Policies & rules -> Preset security policies -> Standard), then re-run to scope it to the pilot group." -ForegroundColor Gray
    return
}

if ($PSCmdlet.ShouldProcess("Standard preset -> $PilotGroup", "Scope Standard preset security policy to pilot users")) {
    try {
        if ($atpRule) { Set-ATPProtectionPolicyRule -Identity $atpRule.Identity -SentToMemberOf $PilotGroup -ErrorAction Stop }
        if ($eopRule) { Set-EOPProtectionPolicyRule -Identity $eopRule.Identity -SentToMemberOf $PilotGroup -ErrorAction Stop }
        Write-Host "  SCOPED — Standard preset now applies to '$PilotGroup' only." -ForegroundColor Green
    } catch {
        Write-Host ("  Could not scope preset: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
        Write-Host "  You can set the recipient scope manually in the portal instead." -ForegroundColor Gray
    }
} else {
    Write-Host "  [WhatIf] Would scope the Standard preset to '$PilotGroup'. No change made." -ForegroundColor Yellow
}

Write-Host "`nNext: POCMDO-TestSignal.ps1 (benign signal) -> POCMDO-Validate.ps1 -> POCMDO-Scorecard.ps1 -> POCMDO-Teardown.ps1" -ForegroundColor Cyan

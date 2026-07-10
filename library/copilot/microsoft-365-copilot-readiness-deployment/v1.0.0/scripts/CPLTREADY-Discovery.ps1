<#
.SYNOPSIS
    CPLTREADY-Discovery.ps1 — Microsoft 365 Copilot readiness discovery for the scorecard.
.DESCRIPTION
    PURPOSE
        Captures the licensing and identity side of the readiness baseline: available Microsoft 365
        Copilot seats, which cohort users already hold Copilot, and an MFA/identity posture check.
        Feeds the 'Copilot Readiness - Tenant - Assess' scorecard. Read-only — makes no changes.
    HOW TO RUN
        Connect-MgGraph -Scopes "Organization.Read.All","User.Read.All","Directory.Read.All","Policy.Read.All"
        powershell -ExecutionPolicy Bypass -File .\CPLTREADY-Discovery.ps1 [-CohortGroupId <entra-group-object-id>]
        Requires module: Microsoft.Graph.
    EXPECTED RESULTS
        Copilot SKU total/consumed/available seats; cohort members and whether each is Copilot-licensed;
        a count of cohort members without MFA-capable methods. Note: verify the current Copilot SKU part
        number and base-plan prerequisite in your tenant.
.NOTES
    Copilot. White-label. Read-only. Licensing/preview facts: verify current availability in your tenant.
#>
[CmdletBinding()]
param(
    [string]$CohortGroupId,
    # The Copilot SKU part number can differ by tenant/offer — verify and override if needed.
    [string]$CopilotSkuPartNumber = 'Microsoft_365_Copilot'
)

Write-Host "=== CPLTREADY Discovery — readiness baseline ===" -ForegroundColor Cyan
if (-not (Get-MgContext)) { Write-Host "Run Connect-MgGraph first (see header)." -ForegroundColor Yellow; return }

# --- Copilot seats ---
Write-Host "`n--- Copilot licensing (verify SKU part number in your tenant) ---" -ForegroundColor Cyan
$skus = Get-MgSubscribedSku -All
$copilot = $skus | Where-Object { $_.SkuPartNumber -eq $CopilotSkuPartNumber -or $_.SkuPartNumber -match 'Copilot' }
if ($copilot) {
    foreach ($s in $copilot) {
        $avail = $s.PrepaidUnits.Enabled - $s.ConsumedUnits
        Write-Host ("  {0} : total={1} consumed={2} available={3}" -f $s.SkuPartNumber, $s.PrepaidUnits.Enabled, $s.ConsumedUnits, $avail) -ForegroundColor Green
    }
} else {
    Write-Host ("  No Copilot SKU found matching '{0}'. Confirm the SKU part number/offer in Billing -> Licenses." -f $CopilotSkuPartNumber) -ForegroundColor Yellow
}
$copilotSkuIds = @($copilot.SkuId)

# --- Cohort membership + license/identity posture ---
if ($CohortGroupId) {
    Write-Host "`n--- Pilot cohort ('Copilot Enablement - Pilot Cohort - Pilot') ---" -ForegroundColor Cyan
    try {
        $members = Get-MgGroupMember -GroupId $CohortGroupId -All
        $noMfa = 0; $licensed = 0
        foreach ($m in $members) {
            $u = Get-MgUser -UserId $m.Id -Property "displayName,userPrincipalName,assignedLicenses,usageLocation" -ErrorAction SilentlyContinue
            if (-not $u) { continue }
            $hasCopilot = @($u.AssignedLicenses.SkuId | Where-Object { $copilotSkuIds -contains $_ }).Count -gt 0
            if ($hasCopilot) { $licensed++ }
            # MFA-capable methods check
            $methods = @()
            try { $methods = Get-MgUserAuthenticationMethod -UserId $m.Id -ErrorAction SilentlyContinue } catch {}
            $mfaCapable = ($methods | Where-Object { $_.AdditionalProperties.'@odata.type' -match 'microsoftAuthenticator|phone|fido2|softwareOath' }).Count -gt 0
            if (-not $mfaCapable) { $noMfa++ }
            Write-Host ("  {0,-40} Copilot={1}  MFA-capable={2}  usageLoc={3}" -f $u.UserPrincipalName, $hasCopilot, $mfaCapable, $u.UsageLocation)
        }
        Write-Host ("`n  Cohort: {0} members, {1} Copilot-licensed, {2} without MFA-capable methods." -f ($members|Measure-Object).Count, $licensed, $noMfa) -ForegroundColor ($(if($noMfa -gt 0){'Yellow'}else{'Green'}))
    } catch {
        Write-Host ("  Could not read cohort group: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
} else {
    Write-Host "`n(Pass -CohortGroupId to include cohort license/MFA posture in the baseline.)" -ForegroundColor Gray
}

Write-Host "`nRecord this as part of 'Copilot Readiness - Tenant - Assess'. Next: CPLTREADY-OversharingScan.ps1." -ForegroundColor Cyan

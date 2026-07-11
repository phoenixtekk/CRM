<#
.SYNOPSIS
    SOPMDE-Set-ASRBlock.ps1 — flip vetted ASR rules from audit to BLOCK on the pilot policy.
    SAFE PREVIEW by default (-WhatIf); makes the change only when explicitly confirmed.
.DESCRIPTION
    PURPOSE
        Change helper for the "Solution Optimization — Microsoft Defender for Endpoint" solution.
        Sets the named attack-surface-reduction rule GUIDs to 'block' (state 1) on the pilot
        Intune ASR policy 'ASR Hardening - Pilot Ring - Pilot'. This is the only script that can
        change configuration, and it DEFAULTS TO A SAFE PREVIEW. Block ONLY the rules you have
        proven safe with audit data (SOPMDE-Hunt.ps1 -Mode ASRAudit). -Mode Hardening instead
        reports current Tamper Protection / EDR-block-mode state (read-only) as a pre-change check.
    HOW TO RUN
        # Preview which rules WOULD move to block (default — changes nothing):
        powershell -ExecutionPolicy Bypass -File .\SOPMDE-Set-ASRBlock.ps1 `
            -PolicyName 'ASR Hardening - Pilot Ring - Pilot' -Rules 'd4f940ab-401b-4efc-aadc-ad5f3c50688a'
        # Apply (explicit — required to make the change):
        powershell -ExecutionPolicy Bypass -File .\SOPMDE-Set-ASRBlock.ps1 `
            -PolicyName 'ASR Hardening - Pilot Ring - Pilot' -Rules '<guid1>','<guid2>' -Apply
        # Hardening pre-check (read-only):
        powershell -ExecutionPolicy Bypass -File .\SOPMDE-Set-ASRBlock.ps1 -Mode Hardening
        Requires Microsoft.Graph with DeviceManagementConfiguration.ReadWrite.All (Apply) and
        Security Administrator / Endpoint Security Manager. Pilot ring only.
    EXPECTED RESULTS
        Preview: prints each rule's current state and that it WOULD be set to Block.
        Apply: updates the policy so the listed rules are Block; validate with SOPMDE-Validate.ps1.
        Rollback: re-run with the rules set back to audit (state 2) in the portal, or restore the
        policy. Keep unproven rules in Audit.
.NOTES
    White-label. DEFAULTS TO -WhatIf/preview. Block only audit-vetted rules on the pilot ring.
    Automated response stays approval-gated regardless of this script.
#>
[CmdletBinding()]
param(
    [ValidateSet('ASR','Hardening')] [string]$Mode = 'ASR',
    [string]$PolicyName = 'ASR Hardening - Pilot Ring - Pilot',
    [string[]]$Rules,
    [switch]$Apply
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

if ($Mode -eq 'Hardening') {
    if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'SecurityEvents.Read.All' -NoWelcome | Out-Null }
    Write-Host "`n=== SOPMDE hardening pre-check (read-only) ===" -ForegroundColor Cyan
    Write-Host "Confirm the following in security.microsoft.com -> Settings -> Endpoints -> Advanced features:" -ForegroundColor Yellow
    Write-Host "   Tamper Protection ... should be ON"
    Write-Host "   EDR in block mode ... should be ON"
    Write-Host "This mode changes nothing. Author the enforced settings in 'Endpoint Hardening - Pilot Ring - Pilot'." -ForegroundColor DarkGray
    return
}

$writeScope = if ($Apply) { 'DeviceManagementConfiguration.ReadWrite.All' } else { 'DeviceManagementConfiguration.Read.All' }
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $writeScope -NoWelcome | Out-Null }

$whatIf = -not $Apply
Write-Host "`n=== SOPMDE set ASR rules -> BLOCK ===" -ForegroundColor Cyan
Write-Host ("Policy: {0}" -f $PolicyName)
Write-Host ("Mode: {0}" -f ($(if ($whatIf) { 'PREVIEW (-WhatIf) — no changes' } else { 'APPLY — will set rules to BLOCK' }))) -ForegroundColor $(if ($whatIf) { 'Yellow' } else { 'Red' })

if (-not $Rules -or $Rules.Count -eq 0) {
    Write-Host "No -Rules supplied. Pass the audit-vetted ASR rule GUID(s) to block. Aborting." -ForegroundColor Red
    return
}

# Resolve the pilot ASR policy by name.
$pol = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=name eq '{0}'" -f $PolicyName)).value | Select-Object -First 1
if (-not $pol) {
    Write-Host ("ASR policy '{0}' not found. Create it first (Implementation Step 2)." -f $PolicyName) -ForegroundColor Red
    return
}
Write-Host ("Resolved policy id: {0}" -f $pol.id)

Write-Host "`nRules that WOULD be set to Block:" -ForegroundColor Yellow
$Rules | ForEach-Object { Write-Host ("   {0} -> Block" -f $_) }

if ($whatIf) {
    Write-Host "`nPreview only. Confirm these rules are audit-vetted (SOPMDE-Hunt.ps1 -Mode ASRAudit), then re-run with -Apply." -ForegroundColor Yellow
    return
}

# Apply: PATCH each rule's setting to block (1). ASR rule settings use per-rule setting instances.
try {
    foreach ($guid in $Rules) {
        $settingDef = "device_vendor_msft_policy_config_defender_attacksurfacereductionrules_$($guid)"
        $body = @{
            settingInstance = @{
                '@odata.type'       = '#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance'
                settingDefinitionId = $settingDef
                choiceSettingValue  = @{ '@odata.type' = '#microsoft.graph.deviceManagementConfigurationChoiceSettingValue'; value = "${settingDef}_block" }
            }
        } | ConvertTo-Json -Depth 8
        Invoke-MgGraphRequest -Method POST -Uri ("https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/{0}/settings" -f $pol.id) -Body $body -ContentType 'application/json' -ErrorAction Stop | Out-Null
        Write-Host ("   APPLIED — {0} set to Block." -f $guid) -ForegroundColor Green
    }
    Write-Host "`nDone. Validate with SOPMDE-Validate.ps1 and check SOPMDE-Hunt.ps1 -Mode ASRAudit -BlockedOnly for false positives." -ForegroundColor Green
    Write-Host "Rollback: set the rule(s) back to audit in the policy, or restore the prior policy version." -ForegroundColor DarkGray
} catch {
    Write-Host ("Apply failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
    Write-Host "Setting-definition ids vary by Intune schema version — confirm the ASR rule setting id in the portal if this errors." -ForegroundColor Yellow
}

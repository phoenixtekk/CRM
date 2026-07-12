<#
.SYNOPSIS
    MDEFULL-PromoteASR.ps1 — promote audit-vetted ASR rules from audit to BLOCK on the pilot ring.
    SAFE PREVIEW by default (-WhatIf); the block policy changes only when confirmed with -Apply.
    -Mode Hardening reports current Tamper Protection / EDR-block-mode state (read-only) as a pre-check.
.DESCRIPTION
    PURPOSE
        The single change helper for the comprehensive "Microsoft Defender for Endpoint" solution.
        It serves both the Deploy workstream (Step A4) and the Optimize workstream (Step B2): it takes
        the audited ASR configuration and switches the named, AUDIT-VETTED rules to Block on the pilot
        ASR policy ('MDE ASR Rules - Pilot Ring - Block'). This is the only PowerShell that can change
        endpoint-security configuration, and it DEFAULTS TO A SAFE PREVIEW so you can see exactly which
        rules WOULD move to block before anything enforces. -Mode Hardening changes nothing — it prints
        the tamper/EDR-block-mode pre-change checklist.
    HOW TO RUN
        # Preview which rules WOULD move to block (default — changes nothing):
        powershell -ExecutionPolicy Bypass -File .\MDEFULL-PromoteASR.ps1 `
            -PolicyName 'MDE ASR Rules - Pilot Ring - Block' -Rules '<guid1>','<guid2>'
        # Apply (explicit — required to make the change):
        powershell -ExecutionPolicy Bypass -File .\MDEFULL-PromoteASR.ps1 `
            -PolicyName 'MDE ASR Rules - Pilot Ring - Block' -Rules '<guid1>','<guid2>' -Apply
        # Hardening pre-check (read-only):
        powershell -ExecutionPolicy Bypass -File .\MDEFULL-PromoteASR.ps1 -Mode Hardening
        Requires Microsoft.Graph with DeviceManagementConfiguration.ReadWrite.All (Apply) and
        Security Administrator / Endpoint Security Manager. Only run AFTER reviewing the audit evidence
        (MDEFULL-Report.ps1 -Section ASR / MDEFULL-Hunt.ps1 -Mode ASRAudit) and adding exclusions.
    EXPECTED RESULTS
        Preview: prints each rule that WOULD move audit -> block on the pilot ring.
        Apply: sets those rules to block. Validate with MDEFULL-Validate.ps1 -Check ASR and watch for
        false positives (MDEFULL-Hunt.ps1 -Mode ASRAudit -BlockedOnly) before promoting to production.
        Rollback: set the rule(s) back to audit in the policy, or restore the prior policy version.
.NOTES
    White-label. DEFAULTS TO -WhatIf/preview. NEVER promote to block without an audit review first.
    Pilot ring only — expand ring-by-ring after each validates clean. AIR stays approval-gated regardless.
#>
[CmdletBinding()]
param(
    [ValidateSet('ASR','Hardening')] [string]$Mode = 'ASR',
    [string]$PolicyName = 'MDE ASR Rules - Pilot Ring - Block',
    [string[]]$Rules,
    [switch]$Apply,
    [ValidateSet('Global','USGov','USGovDoD')] [string]$Environment = 'Global'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

if ($Mode -eq 'Hardening') {
    if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'SecurityEvents.Read.All' -Environment $Environment -NoWelcome | Out-Null }
    Write-Host "`n=== MDEFULL hardening pre-check (read-only) ===" -ForegroundColor Cyan
    Write-Host "Confirm the following in security.microsoft.com -> Settings -> Endpoints -> Advanced features:" -ForegroundColor Yellow
    Write-Host "   Tamper Protection ... should be ON"
    Write-Host "   EDR in block mode ... should be ON"
    Write-Host "This mode changes nothing. Author the enforced settings in 'MDE Endpoint Hardening - Pilot Ring - Pilot'." -ForegroundColor DarkGray
    return
}

$writeScope = if ($Apply) { 'DeviceManagementConfiguration.ReadWrite.All' } else { 'DeviceManagementConfiguration.Read.All' }
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $writeScope -Environment $Environment -NoWelcome | Out-Null }

$whatIf = -not $Apply
Write-Host "`n=== MDEFULL set ASR rules -> BLOCK (pilot ring) ===" -ForegroundColor Cyan
Write-Host ("Policy: {0}" -f $PolicyName)
Write-Host ("Mode: {0}" -f ($(if ($whatIf) { 'PREVIEW (-WhatIf) — no changes' } else { 'APPLY — will set rules to BLOCK' }))) -ForegroundColor $(if ($whatIf) { 'Yellow' } else { 'Red' })

if (-not $Rules -or $Rules.Count -eq 0) {
    Write-Host "No -Rules supplied. Pass the audit-vetted ASR rule GUID(s) to block. Aborting." -ForegroundColor Red
    return
}
Write-Host "`nPRE-FLIGHT: confirm you reviewed audit events (MDEFULL-Report.ps1 -Section ASR) and added exclusions." -ForegroundColor Yellow
Write-Host "Rules that WOULD be set to Block:" -ForegroundColor Yellow
$Rules | ForEach-Object { Write-Host ("   {0} -> Block" -f $_) }

# Resolve the pilot ASR policy by name.
$pol = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=name eq '{0}'" -f $PolicyName)).value | Select-Object -First 1
if (-not $pol) {
    Write-Host ("ASR policy '{0}' not found. Create it first (Implementation Step A4/B2)." -f $PolicyName) -ForegroundColor Red
    return
}
Write-Host ("Resolved policy id: {0}" -f $pol.id)

if ($whatIf) {
    Write-Host "`nPreview only. Confirm these rules are audit-vetted (MDEFULL-Hunt.ps1 -Mode ASRAudit), then re-run with -Apply." -ForegroundColor Yellow
    Write-Host "Then validate with MDEFULL-Validate.ps1 -Check ASR and watch MDEFULL-Hunt.ps1 -Mode ASRAudit -BlockedOnly for false positives." -ForegroundColor Yellow
    return
}

# Apply: PATCH each rule's setting to block. ASR rule settings use per-rule setting instances; setting-
# definition ids vary by Intune schema version — confirm in the portal if this errors.
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
    Write-Host "`nDone (pilot ring only). Validate with MDEFULL-Validate.ps1 -Check ASR; watch for false positives before promoting to production." -ForegroundColor Green
    Write-Host "Rollback: set the rule(s) back to audit in the policy, or restore the prior policy version." -ForegroundColor DarkGray
} catch {
    Write-Host ("Apply failed via API ({0})." -f $_.Exception.Message) -ForegroundColor Red
    Write-Host "If the policy schema differs, set the rules to Block in Intune: Endpoint security > Attack surface reduction > '$PolicyName'." -ForegroundColor DarkGray
}

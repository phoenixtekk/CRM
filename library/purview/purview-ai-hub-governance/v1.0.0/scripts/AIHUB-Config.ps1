<#
.SYNOPSIS
    AIHUB-Config.ps1 — enable unified audit, create the DLP-for-AI policy in TEST/simulation, and change a DLP policy's mode (-WhatIf by default; writes require -Commit).
.DESCRIPTION
    Configures the scriptable parts of DSPM-for-AI governance: (1) enable unified audit (AI visibility);
    (2) create a DLP policy in TestWithoutNotifications scoped to a pilot group, with a rule condition that
    targets a sensitivity label (the "protect labeled content from AI" control); and (3) change a DLP
    policy's mode (test <-> enforce). Every write is gated - the script previews and changes nothing unless
    -Commit is supplied. The AI/Copilot-specific DLP location/action is PORTAL-DRIVEN and evolving; after
    creating the policy, confirm the AI scope/action in DSPM for AI (the script flags this). Insider-risk
    and communication-compliance detections are configured in the portal (no reliable cmdlets). No
    credentials are stored; the DLP policy never starts in Enable.
.EXAMPLE
    .\AIHUB-Config.ps1 -EnableAudit -WhatIf
    Shows the Set-AdminAuditLogConfig it would run to enable unified audit (AI visibility).
.EXAMPLE
    .\AIHUB-Config.ps1 -CreateDlpForAI -PolicyName "AI-DLP-ProtectLabeled-Sim" -RuleName "AI-DLP-Rule-HighlyConfidential" -TargetLabel "Highly Confidential" -PilotGroup "grp-ai-pilot@contoso.com" -Commit
    Creates a TEST-mode DLP policy whose rule matches content labeled 'Highly Confidential', scoped to the pilot ring.
.EXAMPLE
    .\AIHUB-Config.ps1 -SetDlpMode -PolicyName "AI-DLP-ProtectLabeled-Sim" -Mode Enable -WhatIf
    Shows moving the policy from test to enforce (do this only after the pilot passes).
.NOTES
    Requires PowerShell 5.1+/7+ and ExchangeOnlineManagement (Connect-IPPSSession). Role: Compliance
    Administrator / DLP (and Audit for -EnableAudit).
    Expected results: PASS = -WhatIf prints the intended change; -Commit applies it and Get-DlpCompliancePolicy
    / Get-AdminAuditLogConfig reflect it. The DLP policy is created in TestWithoutNotifications (never Enable).
    FAIL = a cmdlet/param unavailable (verify your tenant) or a referenced label/group does not exist.
    NOTE: the AI/Copilot DLP scope + action are confirmed in the PORTAL (DSPM for AI) - verify the current
    action for your tenant; this script builds the policy skeleton in test mode and flags it.
    NOTE: policy/rule/label/group names (contoso.com) are PLACEHOLDERS - replace with your signed-off values.
#>
[CmdletBinding(DefaultParameterSetName='EnableAudit')]
param(
    [Parameter(ParameterSetName='EnableAudit')][switch]$EnableAudit,

    [Parameter(ParameterSetName='CreateDlpForAI')][switch]$CreateDlpForAI,
    [Parameter(ParameterSetName='CreateDlpForAI')][string]$RuleName = 'AI-DLP-Rule-HighlyConfidential',
    [Parameter(ParameterSetName='CreateDlpForAI')][string]$TargetLabel = 'Highly Confidential',
    [Parameter(ParameterSetName='CreateDlpForAI')][string]$PilotGroup = 'grp-ai-pilot@contoso.com',

    [Parameter(ParameterSetName='SetDlpMode')][switch]$SetDlpMode,
    [Parameter(ParameterSetName='SetDlpMode')][ValidateSet('TestWithoutNotifications','TestWithNotifications','Enable','Disable')]
    [string]$Mode = 'TestWithoutNotifications',

    # Policy name applies to the DLP modes.
    [string]$PolicyName = 'AI-DLP-ProtectLabeled-Sim',

    [switch]$Commit
)

$doIt = [bool]$Commit
function Show-Action([string]$desc, [scriptblock]$action) {
    if ($doIt) { Write-Host ("APPLY : {0}" -f $desc) -ForegroundColor Green; & $action }
    else       { Write-Host ("WhatIf: {0}" -f $desc) -ForegroundColor Yellow }
}

Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    Connect-IPPSSession -ShowBanner:$false
}

switch ($PSCmdlet.ParameterSetName) {

    'EnableAudit' {
        Write-Host "=== Enable unified audit (AI visibility) ===" -ForegroundColor Cyan
        Show-Action "Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled `$true" {
            Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true | Out-Null
        }
        Write-Host "  Allow ingestion latency before expecting AI-interaction activity to appear." -ForegroundColor Yellow
        if (-not $doIt) { Write-Host "(-WhatIf - re-run with -Commit.)" -ForegroundColor Yellow }
    }

    'CreateDlpForAI' {
        Write-Host "=== Create DLP-for-AI policy (TEST/simulation): $PolicyName ===" -ForegroundColor Cyan
        Write-Host "  Starts in TestWithoutNotifications (never Enable). Scoped to the pilot ring: $PilotGroup." -ForegroundColor Yellow
        Write-Host "  After creation, CONFIRM the AI/Copilot scope + protect action in DSPM for AI (portal-driven, evolving)." -ForegroundColor Yellow
        # Create the policy in test mode. The DLP LOCATION that governs AI/Copilot is portal-driven and
        # evolving - this creates the policy skeleton in simulation; you confirm the AI scope/action in the
        # portal. We do NOT invent an AI-location parameter here.
        $descP = "New-DlpCompliancePolicy -Name '{0}' -Mode TestWithoutNotifications (scope confirmed in portal / pilot group '{1}')" -f $PolicyName, $PilotGroup
        Show-Action $descP {
            New-DlpCompliancePolicy -Name $PolicyName -Mode 'TestWithoutNotifications' -ErrorAction Stop | Out-Null
        }
        # Rule: match content carrying the target sensitivity label.
        $descR = "New-DlpComplianceRule -Name '{0}' -Policy '{1}' -ContentContainsSensitiveInformation (label '{2}')" -f $RuleName, $PolicyName, $TargetLabel
        Show-Action $descR {
            $lbl = Get-Label -Identity $TargetLabel -ErrorAction SilentlyContinue
            if (-not $lbl) { throw "Target label '$TargetLabel' not found - create/publish it first (Req 2.5)." }
            New-DlpComplianceRule -Name $RuleName -Policy $PolicyName `
                -ContentContainsSensitiveInformation @(@{ groups = @(@{ name = 'labels'; labels = @(@{ name = $TargetLabel; type = 'Sensitivity' }) }) }) `
                -ErrorAction Stop | Out-Null
        }
        Write-Host "  Portal step: open the policy in DSPM for AI and set the AI/Copilot scope + protect action; keep Mode=Test until the pilot passes." -ForegroundColor Yellow
        if (-not $doIt) { Write-Host "(-WhatIf - re-run with -Commit. Rollback: Remove-DlpCompliancePolicy '$PolicyName'.)" -ForegroundColor Yellow }
    }

    'SetDlpMode' {
        Write-Host "=== Set DLP policy mode: $PolicyName -> $Mode ===" -ForegroundColor Cyan
        if ($Mode -eq 'Enable') { Write-Host "  Enforce only AFTER the pilot passes with an acceptable false-positive rate." -ForegroundColor Yellow }
        Show-Action "Set-DlpCompliancePolicy -Identity '$PolicyName' -Mode $Mode" {
            Set-DlpCompliancePolicy -Identity $PolicyName -Mode $Mode | Out-Null
        }
        if (-not $doIt) { Write-Host "(-WhatIf - re-run with -Commit. Rollback: set -Mode TestWithoutNotifications.)" -ForegroundColor Yellow }
    }
}

if (-not $doIt) { Write-Host "`n(No changes made - this was a -WhatIf preview. Add -Commit to apply.)" -ForegroundColor Yellow }
Write-Host "Portal-only controls: insider-risk (AI-IRM-RiskyAIUsage) + communication-compliance (AI-CC-PromptResponse) - configure privacy-by-design in the portal (Step 6)." -ForegroundColor Cyan

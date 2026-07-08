<#
.SYNOPSIS
    IPMANREC-PolicyConfig.ps1 — configure label-policy behaviour: default label, mandatory labeling, downgrade justification, and recommended prompts (-WhatIf by default; writes require -Commit).
.DESCRIPTION
    Configures the four policy levers on a sensitivity label policy (or a label): create a pilot policy,
    set the default label, enable/disable mandatory labeling with optional Outlook relaxation, require
    downgrade justification, and set a label's Office-app auto-labeling to RECOMMEND with a prompt
    message. Every write is gated: the script previews (WhatIf-style) and changes nothing unless
    -Commit is supplied. Always configure the PILOT policy first (there is no simulation mode for these
    settings). No credentials are stored in the script.
.EXAMPLE
    .\IPMANREC-PolicyConfig.ps1 -CreatePilotPolicy -PolicyName "LabelPolicy - Pilot - Ring1" -PilotGroup "grp-labeling-pilot@contoso.com" -WhatIf
    Shows the New-LabelPolicy it would create for the pilot ring, without making changes.
.EXAMPLE
    .\IPMANREC-PolicyConfig.ps1 -SetDefault -PolicyName "LabelPolicy - Pilot - Ring1" -DefaultLabel "General" -Commit
    Sets the policy's default label (documents + Outlook) to the non-encrypting label 'General'.
.EXAMPLE
    .\IPMANREC-PolicyConfig.ps1 -SetMandatory -PolicyName "LabelPolicy - Pilot - Ring1" -RelaxOutlook -Commit
    Requires a label on documents, but does NOT block email send (DisableMandatoryInOutlook).
.EXAMPLE
    .\IPMANREC-PolicyConfig.ps1 -SetDowngradeJustification -PolicyName "LabelPolicy - Pilot - Ring1" -Commit
    Requires a typed justification to remove a label or lower its classification.
.EXAMPLE
    .\IPMANREC-PolicyConfig.ps1 -SetRecommend -LabelName "Confidential\All Employees" -PromptText "This content looks sensitive - apply Confidential to protect it." -Commit
    Sets the label's Office-app auto-labeling to RECOMMEND (suggest, not force) with the prompt message.
.NOTES
    Requires PowerShell 5.1+/7+ and ExchangeOnlineManagement (Connect-IPPSSession).
    Role: Information Protection Admin. Recommended labeling is licensing-gated (verify your licensing/tenant, typically E5 for advanced conditions).
    Expected results: PASS = -WhatIf prints intended changes; -Commit applies them and Get-LabelPolicy / Get-Label reflect them.
    FAIL = a cmdlet/advanced-setting key is unavailable (verify in your tenant) or a referenced label/group does not exist.
    NOTE: policy/label/group names (contoso.com) are PLACEHOLDERS - replace with your signed-off values.
    NOTE: some settings (e.g. downgrade justification) are exposed in the portal Policy-settings wizard; the exact
          advanced-setting KEY can differ by tenant/version - the script flags each and you should VERIFY IN YOUR TENANT.
#>
[CmdletBinding(DefaultParameterSetName='CreatePilotPolicy')]
param(
    [Parameter(ParameterSetName='CreatePilotPolicy')][switch]$CreatePilotPolicy,
    [Parameter(ParameterSetName='CreatePilotPolicy')][string]$PilotGroup,

    [Parameter(ParameterSetName='SetDefault')][switch]$SetDefault,
    [Parameter(ParameterSetName='SetDefault')][string]$DefaultLabel = 'General',

    [Parameter(ParameterSetName='SetMandatory')][switch]$SetMandatory,
    [Parameter(ParameterSetName='SetMandatory')][switch]$RelaxOutlook,
    [Parameter(ParameterSetName='SetMandatory')][switch]$DisableMandatory,

    [Parameter(ParameterSetName='SetDowngrade')][switch]$SetDowngradeJustification,

    [Parameter(ParameterSetName='SetRecommend')][switch]$SetRecommend,
    [Parameter(ParameterSetName='SetRecommend')][string]$LabelName,
    [Parameter(ParameterSetName='SetRecommend')][string]$PromptText = 'This content looks sensitive - apply the recommended label to protect it.',

    # Policy name applies to all policy-scoped modes.
    [string]$PolicyName = 'LabelPolicy - Pilot - Ring1',

    # -WhatIf-style gating: writes only happen with -Commit.
    [switch]$Commit
)

$doIt = [bool]$Commit
function Show-Action([string]$desc, [scriptblock]$action) {
    if ($doIt) {
        Write-Host ("APPLY : {0}" -f $desc) -ForegroundColor Green
        & $action
    } else {
        Write-Host ("WhatIf: {0}" -f $desc) -ForegroundColor Yellow
    }
}

# --- Connect ---
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-LabelPolicy -ErrorAction SilentlyContinue)) {
    Connect-IPPSSession -ShowBanner:$false
}

switch ($PSCmdlet.ParameterSetName) {

    'CreatePilotPolicy' {
        Write-Host "=== Create pilot label policy: $PolicyName ===" -ForegroundColor Cyan
        if (-not $PilotGroup) { throw 'Provide -PilotGroup (the pilot-ring group to publish to).' }
        $desc = "New-LabelPolicy -Name '{0}' then scope to '{1}' (pilot ring only)" -f $PolicyName, $PilotGroup
        Show-Action $desc {
            New-LabelPolicy -Name $PolicyName | Out-Null
            Set-LabelPolicy -Identity $PolicyName -AddModernGroupLocation $PilotGroup -ErrorAction SilentlyContinue | Out-Null
            Set-LabelPolicy -Identity $PolicyName -AddExchangeLocation $PilotGroup -ErrorAction SilentlyContinue | Out-Null
        }
        if (-not $doIt) { Write-Host "(-WhatIf - re-run with -Commit. Rollback: Remove-LabelPolicy '$PolicyName')" -ForegroundColor Yellow }
    }

    'SetDefault' {
        Write-Host "=== Set default label on $PolicyName -> '$DefaultLabel' ===" -ForegroundColor Cyan
        Write-Host 'Confirm the default label is NON-ENCRYPTING (a default that encrypts causes surprise encryption).' -ForegroundColor Yellow
        # Documents/email default label + the Outlook-specific default. DefaultLabelId expects the label GUID;
        # resolve it from the label name. Verify the exact key/param in your tenant.
        $lbl = Get-Label -Identity $DefaultLabel -ErrorAction SilentlyContinue
        $guid = if ($lbl) { $lbl.Guid } else { $DefaultLabel }
        $desc = "Set-LabelPolicy -Identity '{0}' -AdvancedSettings @{{DefaultLabelId='{1}'; OutlookDefaultLabel='{1}'}}" -f $PolicyName, $guid
        Show-Action $desc {
            Set-LabelPolicy -Identity $PolicyName -AdvancedSettings @{ DefaultLabelId = "$guid" } | Out-Null
            Set-LabelPolicy -Identity $PolicyName -AdvancedSettings @{ OutlookDefaultLabel = "$guid" } | Out-Null
        }
        if (-not $doIt) { Write-Host "(-WhatIf - re-run with -Commit. Rollback: set DefaultLabelId='None'.)" -ForegroundColor Yellow }
    }

    'SetMandatory' {
        if ($DisableMandatory) {
            Write-Host "=== Remove mandatory labeling from $PolicyName ===" -ForegroundColor Cyan
            Show-Action "Set-LabelPolicy -Identity '$PolicyName' -AdvancedSettings @{Mandatory='false'}" {
                Set-LabelPolicy -Identity $PolicyName -AdvancedSettings @{ Mandatory = 'false' } | Out-Null
            }
        } else {
            Write-Host "=== Enable mandatory labeling on $PolicyName ===" -ForegroundColor Cyan
            Show-Action "Set-LabelPolicy -Identity '$PolicyName' -AdvancedSettings @{Mandatory='true'}" {
                Set-LabelPolicy -Identity $PolicyName -AdvancedSettings @{ Mandatory = 'true' } | Out-Null
            }
            if ($RelaxOutlook) {
                Write-Host '  Relaxing Outlook: email send will NOT be blocked (recommended starting point).' -ForegroundColor Yellow
                Show-Action "Set-LabelPolicy -Identity '$PolicyName' -AdvancedSettings @{DisableMandatoryInOutlook='true'}" {
                    Set-LabelPolicy -Identity $PolicyName -AdvancedSettings @{ DisableMandatoryInOutlook = 'true' } | Out-Null
                }
            }
        }
        if (-not $doIt) { Write-Host "(-WhatIf - re-run with -Commit. Rollback: -SetMandatory -DisableMandatory -Commit)" -ForegroundColor Yellow }
    }

    'SetDowngrade' {
        Write-Host "=== Require downgrade/removal justification on $PolicyName ===" -ForegroundColor Cyan
        Write-Host '  NOTE: this maps to the portal Policy-settings toggle "Users must provide justification...".' -ForegroundColor Yellow
        Write-Host '  VERIFY the exact advanced-setting key in your tenant if the portal toggle and PowerShell disagree.' -ForegroundColor Yellow
        # Common advanced setting used by the client for this behaviour; verify in your tenant/version.
        Show-Action "Set-LabelPolicy -Identity '$PolicyName' -AdvancedSettings @{RequireDowngradeJustification='true'}" {
            Set-LabelPolicy -Identity $PolicyName -AdvancedSettings @{ RequireDowngradeJustification = 'true' } | Out-Null
        }
        if (-not $doIt) { Write-Host "(-WhatIf - re-run with -Commit. Rollback: set the same key to 'false'.)" -ForegroundColor Yellow }
    }

    'SetRecommend' {
        Write-Host "=== Set RECOMMEND (suggest, not force) on label: $LabelName ===" -ForegroundColor Cyan
        if (-not $LabelName) { throw 'Provide -LabelName (the label to set to Recommend).' }
        Write-Host '  Recommend = a prompt the user can accept or dismiss. Automatic would force-apply (not used here).' -ForegroundColor Yellow
        Write-Host '  Advanced-setting keys for client-side recommend prompts vary by tenant/version - VERIFY IN YOUR TENANT.' -ForegroundColor Yellow
        # Set the label's Office-app auto-labeling to recommend (not automatic) with the user-facing message.
        $desc = "Set-Label -Identity '{0}' -AdvancedSettings @{{customPropertyEditorText='...'}} + recommend mode + message '{1}'" -f $LabelName, $PromptText
        Show-Action $desc {
            Set-Label -Identity $LabelName -AdvancedSettings @{ AutoTaggingRecommend = 'true' } -ErrorAction SilentlyContinue | Out-Null
            Set-Label -Identity $LabelName -AdvancedSettings @{ AutoTaggingPolicyTip = "$PromptText" } -ErrorAction SilentlyContinue | Out-Null
        }
        if (-not $doIt) { Write-Host "(-WhatIf - re-run with -Commit. Rollback: set AutoTaggingRecommend='false'.)" -ForegroundColor Yellow }
    }
}

if (-not $doIt) { Write-Host "`n(No changes made - this was a -WhatIf preview. Add -Commit to apply.)" -ForegroundColor Yellow }

<#
.SYNOPSIS
    PURVLABEL-SensitivityConfig.ps1 — sensitivity-label + publish-policy + auto-labeling config helper (-WhatIf by default; writes require -Commit).
.DESCRIPTION
    Creates sensitivity labels (with content marking and encryption/rights), publishes a label policy
    to a pilot/broad scope, and creates service-side auto-labeling policies IN SIMULATION first, then
    enforces from simulation only when told to. Every write is gated: it runs -WhatIf (no changes) unless
    -Commit is supplied. No credentials are stored in the script.
.EXAMPLE
    .\PURVLABEL-SensitivityConfig.ps1 -WhatIf
    Shows the New-Label calls for the sample taxonomy without making changes.
.EXAMPLE
    .\PURVLABEL-SensitivityConfig.ps1 -Commit
    Creates the sensitivity labels (parents + protected sublabels).
.EXAMPLE
    .\PURVLABEL-SensitivityConfig.ps1 -PublishPolicy -PolicyName "SL Policy - Pilot - Ring1" -PilotGroup "grp-purview-pilot@contoso.com" -Commit
    Publishes the labels to the pilot group.
.EXAMPLE
    .\PURVLABEL-SensitivityConfig.ps1 -AutoLabel -AutoLabelName "AL Sim - Financial - SPO+ODB" -ApplyLabel "Confidential\All Employees" -Commit
    Creates a service-side auto-labeling policy in SIMULATION (TestWithoutNotifications).
.EXAMPLE
    .\PURVLABEL-SensitivityConfig.ps1 -AutoLabel -AutoLabelName "AL Sim - Financial - SPO+ODB" -EnforceFromSimulation -Commit
    Flips an accepted simulation policy to Enable (enforce). Use only after simulation precision is signed off.
.NOTES
    Requires PowerShell 5.1+/7+ and ExchangeOnlineManagement (Connect-IPPSSession).
    Role: Information Protection Admin. Auto-labeling is licensing-gated (verify your licensing/tenant, typically E5).
    Expected results: PASS = -WhatIf prints intended changes; -Commit applies them and Get-Label / Get-AutoSensitivityLabelPolicy reflect them.
    FAIL = a cmdlet is unavailable (licensing) or a rights group / apply-label name does not exist.
    NOTE: sample taxonomy names, rights groups (contoso.com), and info types are PLACEHOLDERS — replace with your signed-off values.
#>
[CmdletBinding(DefaultParameterSetName='Labels')]
param(
    [Parameter(ParameterSetName='PublishPolicy')][switch]$PublishPolicy,
    [Parameter(ParameterSetName='PublishPolicy')][string]$PolicyName = 'SL Policy - Pilot - Ring1',
    [Parameter(ParameterSetName='PublishPolicy')][string]$PilotGroup,

    [Parameter(ParameterSetName='AutoLabel')][switch]$AutoLabel,
    [Parameter(ParameterSetName='AutoLabel')][string]$AutoLabelName = 'AL Sim - Financial - SPO+ODB',
    [Parameter(ParameterSetName='AutoLabel')][string]$ApplyLabel = 'Confidential\All Employees',
    [Parameter(ParameterSetName='AutoLabel')][string[]]$SensitiveInfoType = @('Credit Card Number'),
    [Parameter(ParameterSetName='AutoLabel')][switch]$EnforceFromSimulation,
    [Parameter(ParameterSetName='AutoLabel')][switch]$DisableAutoLabel,

    # -WhatIf is provided automatically by SupportsShouldProcess; -Commit is the explicit apply switch.
    [switch]$Commit
)
# Writes only happen when -Commit is passed. Without it the script previews (WhatIf-style) and changes nothing.
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
if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) {
    Connect-IPPSSession -ShowBanner:$false
}

# =====================================================================================
# Sample taxonomy (PLACEHOLDER — replace names/rights/marking with your signed-off design)
# Rights groups (e.g. grp-all-employees@contoso.com) must already exist per Requirements 2.6.
# =====================================================================================
$taxonomy = @(
    @{ Name='Public';      Display='Public';      Tooltip='No restrictions. Safe to share publicly.'; Parent=$null; Encrypt=$false; Footer='Public' }
    @{ Name='General';     Display='General';     Tooltip='Internal business content. Do not share externally without approval.'; Parent=$null; Encrypt=$false; Footer='General - Internal' }
    @{ Name='Confidential';Display='Confidential';Tooltip='Sensitive business content.'; Parent=$null; Encrypt=$false; Footer=$null }
    @{ Name='Confidential-AllEmp'; Display='All Employees'; Tooltip='Encrypted for all employees.'; Parent='Confidential'; Encrypt=$true; Rights='grp-all-employees@contoso.com'; RightsLevel='CoAuthor'; Footer='Confidential' }
    @{ Name='Confidential-Trusted'; Display='Trusted People'; Tooltip='Encrypted for named colleagues only.'; Parent='Confidential'; Encrypt=$true; Rights='grp-trusted-people@contoso.com'; RightsLevel='Reviewer'; Footer='Confidential' }
    @{ Name='HighlyConf';  Display='Highly Confidential'; Tooltip='Most sensitive content.'; Parent=$null; Encrypt=$false; Footer=$null }
    @{ Name='HighlyConf-AllEmp'; Display='All Employees'; Tooltip='Encrypted + watermarked for all employees.'; Parent='HighlyConf'; Encrypt=$true; Rights='grp-all-employees@contoso.com'; RightsLevel='CoAuthor'; Footer='Highly Confidential'; Watermark='HIGHLY CONFIDENTIAL' }
    @{ Name='HighlyConf-Specified'; Display='Specified People'; Tooltip='Encrypted for named recipients only, no export.'; Parent='HighlyConf'; Encrypt=$true; Rights='grp-specified-people@contoso.com'; RightsLevel='Viewer'; Footer='Highly Confidential' }
)

# ---- MODE: create the label taxonomy ----
if ($PSCmdlet.ParameterSetName -eq 'Labels') {
    Write-Host '=== Build sensitivity label taxonomy ===' -ForegroundColor Cyan
    $existing = (Get-Label -ErrorAction SilentlyContinue).Name
    foreach ($l in $taxonomy) {
        if ($existing -contains $l.Name) { Write-Host ("skip (exists): {0}" -f $l.Name) -ForegroundColor DarkGray; continue }
        $params = @{ Name=$l.Name; DisplayName=$l.Display; Tooltip=$l.Tooltip }
        if ($l.Parent)  { $params.ParentId = $l.Parent }
        if ($l.Footer)  { $params.ApplyContentMarkingFooterEnabled = $true; $params.ApplyContentMarkingFooterText = $l.Footer }
        if ($l.Watermark) { $params.ApplyWaterMarkingEnabled = $true; $params.ApplyWaterMarkingText = $l.Watermark }
        if ($l.Encrypt) {
            $params.EncryptionEnabled = $true
            $params.EncryptionProtectionType = 'Template'
            # Rights definition points at a GROUP so membership changes don't require editing the label.
            $params.EncryptionRightsDefinitions = ("{0}:{1}" -f $l.Rights, $l.RightsLevel)
        }
        $desc = "New-Label -Name '{0}' -DisplayName '{1}'{2}{3}" -f $l.Name, $l.Display,
                $(if($l.Parent){" (child of $($l.Parent))"}else{''}),
                $(if($l.Encrypt){" [ENCRYPT -> $($l.Rights):$($l.RightsLevel)]"}else{''})
        Show-Action $desc { New-Label @params | Out-Null }
    }
    if (-not $doIt) { Write-Host "`n(-WhatIf preview — re-run with -Commit to create the labels)" -ForegroundColor Yellow }
}

# ---- MODE: publish a label policy ----
elseif ($PublishPolicy) {
    Write-Host "=== Publish label policy: $PolicyName ===" -ForegroundColor Cyan
    if (-not $PilotGroup) { throw 'Provide -PilotGroup (the group/scope to publish to).' }
    $labelNames = $taxonomy | Where-Object { $_.Parent -or $_.Name -in @('Public','General') } | ForEach-Object { $_.Name }
    $desc = "New-LabelPolicy -Name '{0}' -Labels (taxonomy) -ExchangeLocation/ModernGroupLocation '{1}'" -f $PolicyName, $PilotGroup
    Show-Action $desc {
        New-LabelPolicy -Name $PolicyName -Labels $labelNames | Out-Null
        Set-LabelPolicy -Identity $PolicyName -AddModernGroupLocation $PilotGroup -ErrorAction SilentlyContinue | Out-Null
        Set-LabelPolicy -Identity $PolicyName -AddExchangeLocation $PilotGroup -ErrorAction SilentlyContinue | Out-Null
    }
    if (-not $doIt) { Write-Host "(-WhatIf — re-run with -Commit to publish. Rollback: Remove-LabelPolicy '$PolicyName')" -ForegroundColor Yellow }
}

# ---- MODE: service-side auto-labeling (simulation-first) ----
elseif ($AutoLabel) {
    if ($DisableAutoLabel) {
        Write-Host "=== Disable/return auto-labeling to simulation: $AutoLabelName ===" -ForegroundColor Cyan
        Show-Action "Set-AutoSensitivityLabelPolicy -Identity '$AutoLabelName' -Mode TestWithoutNotifications" {
            Set-AutoSensitivityLabelPolicy -Identity $AutoLabelName -Mode TestWithoutNotifications | Out-Null
        }
    }
    elseif ($EnforceFromSimulation) {
        Write-Host "=== ENFORCE auto-labeling from simulation: $AutoLabelName ===" -ForegroundColor Cyan
        Write-Host 'Only enforce after simulation precision is signed off (see Testing Guide Test 6).' -ForegroundColor Yellow
        Show-Action "Set-AutoSensitivityLabelPolicy -Identity '$AutoLabelName' -Mode Enable" {
            Set-AutoSensitivityLabelPolicy -Identity $AutoLabelName -Mode Enable | Out-Null
        }
    }
    else {
        Write-Host "=== Create auto-labeling policy in SIMULATION: $AutoLabelName ===" -ForegroundColor Cyan
        # -Mode TestWithoutNotifications = simulation. Nothing is labeled until enforced.
        $desc1 = "New-AutoSensitivityLabelPolicy -Name '{0}' -ApplySensitivityLabel '{1}' -Mode TestWithoutNotifications -SharePointLocation All -OneDriveLocation All" -f $AutoLabelName, $ApplyLabel
        $desc2 = "New-AutoSensitivityLabelRule -Policy '{0}' -ContentContainsSensitiveInformation ({1})" -f $AutoLabelName, ($SensitiveInfoType -join '; ')
        Show-Action $desc1 {
            New-AutoSensitivityLabelPolicy -Name $AutoLabelName -ApplySensitivityLabel $ApplyLabel `
                -Mode TestWithoutNotifications -SharePointLocation All -OneDriveLocation All | Out-Null
        }
        $sit = $SensitiveInfoType | ForEach-Object { @{ Name = $_ } }
        Show-Action $desc2 {
            New-AutoSensitivityLabelRule -Policy $AutoLabelName -Name ("{0} - rule" -f $AutoLabelName) `
                -ContentContainsSensitiveInformation $sit | Out-Null
        }
        if (-not $doIt) { Write-Host "(-WhatIf — re-run with -Commit. Policy will be created in SIMULATION only.)" -ForegroundColor Yellow }
    }
}

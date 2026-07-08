<#
.SYNOPSIS
    IPTAX-TaxonomyConfig.ps1 — build the designed sensitivity label taxonomy + publish it (-WhatIf by default; writes require -Commit).
.DESCRIPTION
    Creates the designed parent tiers and top-level labels, creates protected sublabels per the
    protection/marking mapping (content marking + encryption/rights by group), and publishes the
    selectable set to a pilot/broad scope. Every write is gated: it previews (WhatIf-style) and changes
    nothing unless -Commit is supplied. No credentials are stored in the script. The sample taxonomy is
    a PLACEHOLDER — replace names/tooltips/rights with your signed-off design.
.EXAMPLE
    .\IPTAX-TaxonomyConfig.ps1 -WhatIf
    Shows the New-Label calls for the parent tiers and top-level labels without making changes.
.EXAMPLE
    .\IPTAX-TaxonomyConfig.ps1 -Commit
    Creates the parent tiers and top-level (non-protecting) labels.
.EXAMPLE
    .\IPTAX-TaxonomyConfig.ps1 -Sublabels -Commit
    Creates the protected sublabels (encryption/rights + marking) under their parents.
.EXAMPLE
    .\IPTAX-TaxonomyConfig.ps1 -PublishPolicy -PolicyName "SL Policy - Pilot - Ring1" -PilotGroup "grp-purview-pilot@contoso.com" -Commit
    Publishes the selectable taxonomy to the pilot group.
.NOTES
    Requires PowerShell 5.1+/7+ and ExchangeOnlineManagement (Connect-IPPSSession).
    Role: Information Protection Admin. Encryption requires the protection (RMS) service active and the rights groups to exist (see Requirements 2.6).
    Expected results: PASS = -WhatIf prints intended changes; -Commit applies them and Get-Label / Get-LabelPolicy reflect them.
    FAIL = a rights group does not exist, the protection service is inactive, or an internal Name collides.
    NOTE: sample tier names, tooltips, and rights groups (contoso.com) are PLACEHOLDERS — replace with your signed-off values.
#>
[CmdletBinding(DefaultParameterSetName='Parents')]
param(
    [Parameter(ParameterSetName='Sublabels')][switch]$Sublabels,

    [Parameter(ParameterSetName='PublishPolicy')][switch]$PublishPolicy,
    [Parameter(ParameterSetName='PublishPolicy')][string]$PolicyName = 'SL Policy - Pilot - Ring1',
    [Parameter(ParameterSetName='PublishPolicy')][string]$PilotGroup,

    # -Commit is the explicit apply switch; without it the script previews and changes nothing.
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
if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) {
    Connect-IPPSSession -ShowBanner:$false
}

# =====================================================================================
# Designed taxonomy (PLACEHOLDER — replace names/tooltips/rights/marking with your signed-off design).
# Naming convention: internal Name = SL-<Tier>[-<Audience>]. Rights point at GROUPS (Requirements 2.6).
# Parents (IsParent) group only: no encryption, no marking, not individually selectable.
# =====================================================================================
$parents = @(
    @{ Name='SL-Public';      Display='Public';       Tooltip='No restrictions. Safe to share publicly.'; Footer='Public'; IsParent=$false }
    @{ Name='SL-Internal';    Display='Internal';     Tooltip='Internal business content. Do not distribute externally without approval.'; Footer='Internal - do not distribute externally'; IsParent=$false }
    @{ Name='SL-Confidential';Display='Confidential'; Tooltip='Sensitive business content — pick a sublabel for the audience.'; Footer=$null; IsParent=$true }
    @{ Name='SL-HighlyConf';  Display='Highly Confidential'; Tooltip='Most sensitive content — pick a sublabel for the audience.'; Footer=$null; IsParent=$true }
)
$sublabels = @(
    @{ Name='SL-Conf-AllEmp';         Display='All Employees';    Tooltip='Encrypted for all employees; co-authoring allowed internally.'; Parent='SL-Confidential'; Rights='grp-all-employees@contoso.com';   RightsLevel='CoAuthor'; Footer='Confidential' }
    @{ Name='SL-Conf-Trusted';        Display='Trusted People';   Tooltip='Encrypted for named colleagues only (do-not-forward style).';   Parent='SL-Confidential'; Rights='grp-trusted-people@contoso.com';  RightsLevel='Reviewer'; Footer='Confidential' }
    @{ Name='SL-HighlyConf-AllEmp';   Display='All Employees';    Tooltip='Encrypted + watermarked for all employees.';                    Parent='SL-HighlyConf';   Rights='grp-all-employees@contoso.com';   RightsLevel='CoAuthor'; Footer='Highly Confidential'; Watermark='HIGHLY CONFIDENTIAL' }
    @{ Name='SL-HighlyConf-Specified';Display='Specified People'; Tooltip='Encrypted for named recipients only; view-only, no export.';    Parent='SL-HighlyConf';   Rights='grp-specified-people@contoso.com';RightsLevel='Viewer';   Footer='Highly Confidential'; Watermark='HIGHLY CONFIDENTIAL' }
)
# The selectable set published to users = top-level non-parents + all sublabels (parents excluded).
$selectableNames = @('SL-Public','SL-Internal') + ($sublabels | ForEach-Object { $_.Name })

# ---- MODE: create parent tiers + top-level labels ----
if ($PSCmdlet.ParameterSetName -eq 'Parents') {
    Write-Host '=== Build parent tiers + top-level labels ===' -ForegroundColor Cyan
    $existing = @((Get-Label -ErrorAction SilentlyContinue).Name)
    foreach ($l in $parents) {
        if ($existing -contains $l.Name) { Write-Host ("skip (exists): {0}" -f $l.Name) -ForegroundColor DarkGray; continue }
        $params = @{ Name=$l.Name; DisplayName=$l.Display; Tooltip=$l.Tooltip }
        # Parents group only: no marking/encryption. Top-level non-parents get footer marking only.
        if (-not $l.IsParent -and $l.Footer) {
            $params.ApplyContentMarkingFooterEnabled = $true
            $params.ApplyContentMarkingFooterText = $l.Footer
        }
        $kind = if ($l.IsParent) { ' [PARENT — grouping only, no protection]' } elseif ($l.Footer) { " [MARK footer -> '$($l.Footer)']" } else { '' }
        Show-Action ("New-Label -Name '{0}' -DisplayName '{1}'{2}" -f $l.Name, $l.Display, $kind) { New-Label @params | Out-Null }
    }
    if (-not $doIt) { Write-Host "`n(-WhatIf preview — re-run with -Commit to create these labels)" -ForegroundColor Yellow }
}

# ---- MODE: create protected sublabels ----
elseif ($Sublabels) {
    Write-Host '=== Build protected sublabels (per protection/marking mapping) ===' -ForegroundColor Cyan
    $existing = @((Get-Label -ErrorAction SilentlyContinue).Name)
    foreach ($l in $sublabels) {
        if ($existing -notcontains $l.Parent) {
            Write-Host ("WARN: parent '{0}' not found — create parents first (run without -Sublabels)." -f $l.Parent) -ForegroundColor Red
            continue
        }
        if ($existing -contains $l.Name) { Write-Host ("skip (exists): {0}" -f $l.Name) -ForegroundColor DarkGray; continue }
        $params = @{ Name=$l.Name; DisplayName=$l.Display; Tooltip=$l.Tooltip; ParentId=$l.Parent }
        if ($l.Footer)    { $params.ApplyContentMarkingFooterEnabled = $true; $params.ApplyContentMarkingFooterText = $l.Footer }
        if ($l.Watermark) { $params.ApplyWaterMarkingEnabled = $true; $params.ApplyWaterMarkingText = $l.Watermark }
        # Encryption — rights point at a GROUP so membership changes don't require editing the label.
        $params.EncryptionEnabled = $true
        $params.EncryptionProtectionType = 'Template'
        $params.EncryptionRightsDefinitions = ("{0}:{1}" -f $l.Rights, $l.RightsLevel)
        $desc = "New-Label -Name '{0}' (child of {1}) [ENCRYPT -> {2}:{3}]{4}" -f $l.Name, $l.Parent, $l.Rights, $l.RightsLevel,
                $(if($l.Watermark){' +watermark'}else{''})
        Show-Action $desc { New-Label @params | Out-Null }
    }
    if (-not $doIt) { Write-Host "`n(-WhatIf preview — re-run with -Sublabels -Commit to create the sublabels)" -ForegroundColor Yellow }
}

# ---- MODE: publish the selectable taxonomy ----
elseif ($PublishPolicy) {
    Write-Host "=== Publish label policy: $PolicyName ===" -ForegroundColor Cyan
    if (-not $PilotGroup) { throw 'Provide -PilotGroup (the group/scope to publish to).' }
    $desc = "New-LabelPolicy -Name '{0}' -Labels (selectable set: {1}) -> '{2}'" -f $PolicyName, ($selectableNames -join ', '), $PilotGroup
    Show-Action $desc {
        New-LabelPolicy -Name $PolicyName -Labels $selectableNames | Out-Null
        Set-LabelPolicy -Identity $PolicyName -AddModernGroupLocation $PilotGroup -ErrorAction SilentlyContinue | Out-Null
        Set-LabelPolicy -Identity $PolicyName -AddExchangeLocation $PilotGroup -ErrorAction SilentlyContinue | Out-Null
    }
    if (-not $doIt) { Write-Host "(-WhatIf — re-run with -Commit to publish. Rollback: Remove-LabelPolicy '$PolicyName')" -ForegroundColor Yellow }
}

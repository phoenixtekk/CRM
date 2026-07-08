<#
.SYNOPSIS
    PURVLABEL-RetentionConfig.ps1 — retention-label + adaptive-scope config helper (-WhatIf by default; writes require -Commit).
.DESCRIPTION
    Creates retention labels (compliance tags) with the period/action your records/legal owner signed
    off, creates adaptive scopes (User/Group/Site), and publishes retention labels to a pilot group or
    to an adaptive scope. Every write is gated: it previews unless -Commit is supplied. No credentials
    are stored. Retention periods/actions are DETERMINATIONS owned by records/legal — the values here
    are placeholders to be replaced with the signed-off schedule.
.EXAMPLE
    .\PURVLABEL-RetentionConfig.ps1 -WhatIf
    Shows the New-ComplianceTag calls for the sample retention labels without making changes.
.EXAMPLE
    .\PURVLABEL-RetentionConfig.ps1 -Commit
    Creates the retention labels.
.EXAMPLE
    .\PURVLABEL-RetentionConfig.ps1 -AdaptiveScope -ScopeName "Scope - Users - Finance" -ScopeType User -Query 'Department -eq "Finance"' -Commit
    Creates a User adaptive scope resolving the Finance department.
.EXAMPLE
    .\PURVLABEL-RetentionConfig.ps1 -PublishRetention -PolicyName "RL Publish - Adaptive - FinanceUsers" -AdaptiveScopeName "Scope - Users - Finance" -Labels "Financial-Records-7yr" -Commit
    Publishes a retention label bound to an adaptive scope.
.NOTES
    Requires PowerShell 5.1+/7+ and ExchangeOnlineManagement (Connect-IPPSSession).
    Role: Records Management / Compliance Administrator. Adaptive scopes are licensing-gated (verify your licensing/tenant, typically E5).
    Expected results: PASS = -WhatIf prints intended changes; -Commit applies them and Get-ComplianceTag /
    Get-AdaptiveScope / Get-RetentionCompliancePolicy reflect them. FAIL = a cmdlet is unavailable
    (licensing) or a referenced label/scope name does not exist.
    NOTE: retention periods/actions below are PLACEHOLDERS — replace with your records/legal-signed schedule.
#>
[CmdletBinding(DefaultParameterSetName='Labels')]
param(
    [Parameter(ParameterSetName='AdaptiveScope')][switch]$AdaptiveScope,
    [Parameter(ParameterSetName='AdaptiveScope')][string]$ScopeName,
    [Parameter(ParameterSetName='AdaptiveScope')][ValidateSet('User','Group','Site')][string]$ScopeType = 'User',
    [Parameter(ParameterSetName='AdaptiveScope')][string]$Query = 'Department -eq "Finance"',

    [Parameter(ParameterSetName='Publish')][switch]$PublishRetention,
    [Parameter(ParameterSetName='Publish')][string]$PolicyName = 'RL Publish - Pilot - Ring1',
    [Parameter(ParameterSetName='Publish')][string]$PilotGroup,
    [Parameter(ParameterSetName='Publish')][string]$AdaptiveScopeName,
    [Parameter(ParameterSetName='Publish')][string[]]$Labels = @('Business-General-3yr'),

    [switch]$Commit
)
$doIt = [bool]$Commit
function Show-Action([string]$desc, [scriptblock]$action) {
    if ($doIt) { Write-Host ("APPLY : {0}" -f $desc) -ForegroundColor Green; & $action }
    else       { Write-Host ("WhatIf: {0}" -f $desc) -ForegroundColor Yellow }
}

Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-ComplianceTag -ErrorAction SilentlyContinue)) {
    Connect-IPPSSession -ShowBanner:$false
}

# =====================================================================================
# Sample retention labels (PLACEHOLDER — periods/actions are records/legal determinations)
# =====================================================================================
$retLabels = @(
    @{ Name='Business-General-3yr';  Action='Keep';          Duration=1095; Type='ModificationAgeInDays'; Comment='Keep 3 years from last modification, then disposition review.' }
    @{ Name='Financial-Records-7yr'; Action='KeepAndDelete'; Duration=2555; Type='CreationAgeInDays';     Comment='Keep 7 years from creation, then delete.' }
    @{ Name='Transitory-1yr';        Action='Delete';        Duration=365;  Type='CreationAgeInDays';     Comment='Delete 1 year after creation.' }
    @{ Name='Legal-Reference';       Action='Keep';          Duration=$null;Type=$null;                   Comment='Retain, no automatic deletion.' }
)

# ---- MODE: create retention labels ----
if ($PSCmdlet.ParameterSetName -eq 'Labels') {
    Write-Host '=== Build retention labels (compliance tags) ===' -ForegroundColor Cyan
    Write-Host 'Periods/actions are PLACEHOLDERS — confirm each with records/legal before enforcing.' -ForegroundColor Yellow
    $existing = (Get-ComplianceTag -ErrorAction SilentlyContinue).Name
    foreach ($t in $retLabels) {
        if ($existing -contains $t.Name) { Write-Host ("skip (exists): {0}" -f $t.Name) -ForegroundColor DarkGray; continue }
        $params = @{ Name=$t.Name; RetentionAction=$t.Action; Comment=$t.Comment }
        if ($t.Duration) { $params.RetentionDuration = $t.Duration; $params.RetentionType = $t.Type }
        else             { $params.RetentionDuration = 'Unlimited' }
        $desc = "New-ComplianceTag -Name '{0}' -RetentionAction {1}{2}" -f $t.Name, $t.Action,
                $(if($t.Duration){" -RetentionDuration $($t.Duration) -RetentionType $($t.Type)"}else{' -RetentionDuration Unlimited'})
        Show-Action $desc { New-ComplianceTag @params | Out-Null }
    }
    if (-not $doIt) { Write-Host "`n(-WhatIf preview — re-run with -Commit to create the retention labels)" -ForegroundColor Yellow }
}

# ---- MODE: create an adaptive scope ----
elseif ($AdaptiveScope) {
    if (-not $ScopeName) { throw 'Provide -ScopeName.' }
    Write-Host "=== Create adaptive scope: $ScopeName ($ScopeType) ===" -ForegroundColor Cyan
    $desc = "New-AdaptiveScope -Name '{0}' -LocationType {1} -RawQuery '{2}'" -f $ScopeName, $ScopeType, $Query
    Show-Action $desc {
        New-AdaptiveScope -Name $ScopeName -LocationType $ScopeType -RawQuery $Query | Out-Null
    }
    if (-not $doIt) {
        Write-Host "(-WhatIf — re-run with -Commit. Then preview membership: PURVLABEL-Validation.ps1 -ScopeName '$ScopeName')" -ForegroundColor Yellow
    }
}

# ---- MODE: publish retention labels (pilot group OR adaptive scope) ----
elseif ($PublishRetention) {
    Write-Host "=== Publish retention label(s) via policy: $PolicyName ===" -ForegroundColor Cyan
    if (-not $PilotGroup -and -not $AdaptiveScopeName) { throw 'Provide -PilotGroup (pilot) or -AdaptiveScopeName (adaptive).' }

    if ($AdaptiveScopeName) {
        $desc1 = "New-RetentionCompliancePolicy -Name '{0}' -AdaptiveScopeLocation '{1}'" -f $PolicyName, $AdaptiveScopeName
        Show-Action $desc1 {
            New-RetentionCompliancePolicy -Name $PolicyName -AdaptiveScopeLocation $AdaptiveScopeName | Out-Null
        }
    } else {
        $desc1 = "New-RetentionCompliancePolicy -Name '{0}' -ModernGroupLocation/ExchangeLocation '{1}'" -f $PolicyName, $PilotGroup
        Show-Action $desc1 {
            New-RetentionCompliancePolicy -Name $PolicyName -ExchangeLocation $PilotGroup -ErrorAction SilentlyContinue | Out-Null
        }
    }

    foreach ($lbl in $Labels) {
        $desc2 = "New-RetentionComplianceRule -Policy '{0}' -PublishComplianceTag '{1}'" -f $PolicyName, $lbl
        Show-Action $desc2 {
            New-RetentionComplianceRule -Policy $PolicyName -Name ("{0} - publish {1}" -f $PolicyName, $lbl) -PublishComplianceTag $lbl | Out-Null
        }
    }
    if (-not $doIt) {
        Write-Host "(-WhatIf — re-run with -Commit. Rollback: Remove-RetentionCompliancePolicy '$PolicyName')" -ForegroundColor Yellow
    }
}

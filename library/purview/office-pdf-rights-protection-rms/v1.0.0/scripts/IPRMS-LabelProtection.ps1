<#
.SYNOPSIS
    IPRMS-LabelProtection.ps1 — configure label encryption + usage rights: template (assigned) rights, user-defined (DNF/Encrypt-Only), offline/expiry, publish, remove (-WhatIf by default; writes require -Commit).
.DESCRIPTION
    Configures rights protection on sensitivity labels: create a pilot label policy; set a label to
    TEMPLATE (assigned) permissions with an explicit rights definition; set a label to USER-DEFINED
    permissions (Do Not Forward for mail / Encrypt-Only for files); set offline-access days and content
    expiry; publish labels to a policy; and remove protection (rollback). Every write is gated - the
    script previews and changes nothing unless -Commit is supplied. Always configure and publish to the
    PILOT policy first (there is no simulation mode for encryption). No credentials are stored.
.EXAMPLE
    .\IPRMS-LabelProtection.ps1 -CreatePilotPolicy -PolicyName "RMSPolicy - Pilot - Ring1" -PilotGroup "grp-rms-pilot@contoso.com" -WhatIf
    Shows the New-LabelPolicy it would create for the pilot ring, without making changes.
.EXAMPLE
    .\IPRMS-LabelProtection.ps1 -SetTemplate -LabelName "Confidential\All Employees" -RightsIdentity "AuthenticatedUsers" -Rights "VIEW,EDIT,PRINT,EXTRACT,DOCEDIT,OBJMODEL" -OfflineDays 30 -Expiry Never -Commit
    Enables Template (assigned) encryption granting the org audience Co-Author-style rights.
.EXAMPLE
    .\IPRMS-LabelProtection.ps1 -SetTemplate -LabelName "Highly Confidential\Named Recipients" -RightsIdentity "grp-rms-named-recipients@contoso.com" -Rights "VIEW,VIEWRIGHTSDATA" -OfflineDays 7 -Commit
    Grants Viewer-only rights to a named group and nobody else.
.EXAMPLE
    .\IPRMS-LabelProtection.ps1 -SetUserDefined -LabelName "Confidential\Recipients Only" -DoNotForward -EncryptOnly -Commit
    Sets the label to user-defined permissions (user picks recipients; Do Not Forward / Encrypt-Only).
.EXAMPLE
    .\IPRMS-LabelProtection.ps1 -PublishToPolicy -PolicyName "RMSPolicy - Pilot - Ring1" -Labels "Confidential\All Employees","Confidential\Recipients Only" -Commit
    Adds the configured labels to the pilot policy (publishes to the pilot ring only).
.EXAMPLE
    .\IPRMS-LabelProtection.ps1 -RemoveProtection -LabelName "Confidential\All Employees" -Commit
    Rollback: removes encryption/protection from the label.
.NOTES
    Requires PowerShell 5.1+/7+ and ExchangeOnlineManagement (Connect-IPPSSession). Role: Information
    Protection Admin. RMS must be ACTIVATED first (Req 2.5) and a super-user group set (Step 2) before broad
    publish, or encrypted content is unrecoverable. Rights keywords (VIEW, EDIT, PRINT, EXTRACT, DOCEDIT,
    OBJMODEL, VIEWRIGHTSDATA, OWNER, FORWARD, REPLY, REPLYALL, EXPORT) are the standard RMS usage rights -
    verify the exact set you need against current Microsoft documentation.
    Expected results: PASS = -WhatIf prints the intended Set-Label; -Commit applies it and Get-Label
    reflects EncryptionEnabled/ProtectionType/rights. FAIL = RMS not activated, a param unavailable in
    your tenant (verify), or a referenced label/group does not exist.
    NOTE: label/policy/group names (contoso.com) are PLACEHOLDERS - replace with your signed-off values.
#>
[CmdletBinding(DefaultParameterSetName='CreatePilotPolicy')]
param(
    [Parameter(ParameterSetName='CreatePilotPolicy')][switch]$CreatePilotPolicy,
    [Parameter(ParameterSetName='CreatePilotPolicy')][string]$PilotGroup,

    [Parameter(ParameterSetName='SetTemplate')][switch]$SetTemplate,
    [Parameter(ParameterSetName='SetTemplate')][string]$RightsIdentity = 'AuthenticatedUsers',
    [Parameter(ParameterSetName='SetTemplate')][string]$Rights = 'VIEW,EDIT,PRINT,EXTRACT,DOCEDIT,OBJMODEL',

    [Parameter(ParameterSetName='SetUserDefined')][switch]$SetUserDefined,
    [Parameter(ParameterSetName='SetUserDefined')][switch]$DoNotForward,
    [Parameter(ParameterSetName='SetUserDefined')][switch]$EncryptOnly,

    [Parameter(ParameterSetName='PublishToPolicy')][switch]$PublishToPolicy,
    [Parameter(ParameterSetName='PublishToPolicy')][string[]]$Labels,

    [Parameter(ParameterSetName='RemoveProtection')][switch]$RemoveProtection,

    # Shared across label-scoped modes.
    [Parameter(ParameterSetName='SetTemplate')]
    [Parameter(ParameterSetName='SetUserDefined')]
    [Parameter(ParameterSetName='RemoveProtection')]
    [string]$LabelName,

    [Parameter(ParameterSetName='SetTemplate')][int]$OfflineDays = 30,
    [Parameter(ParameterSetName='SetTemplate')][string]$Expiry = 'Never',   # 'Never' or a number of days

    # Policy name applies to policy-scoped modes.
    [string]$PolicyName = 'RMSPolicy - Pilot - Ring1',

    # -WhatIf-style gating: writes only happen with -Commit.
    [switch]$Commit
)

$doIt = [bool]$Commit
function Show-Action([string]$desc, [scriptblock]$action) {
    if ($doIt) { Write-Host ("APPLY : {0}" -f $desc) -ForegroundColor Green; & $action }
    else       { Write-Host ("WhatIf: {0}" -f $desc) -ForegroundColor Yellow }
}

Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) {
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

    'SetTemplate' {
        Write-Host "=== Set TEMPLATE (assigned) encryption on label: $LabelName ===" -ForegroundColor Cyan
        if (-not $LabelName) { throw 'Provide -LabelName.' }
        Write-Host "  Confirm RMS is ACTIVATED (Req 2.5) and a super-user group is set (Step 2) before broad publish." -ForegroundColor Yellow
        $rightsDef = "{0}:{1}" -f $RightsIdentity, $Rights   # e.g. AuthenticatedUsers:VIEW,EDIT,PRINT
        $expiryArg = if ($Expiry -match '^\d+$') { [int]$Expiry } else { 'Never' }
        $desc = "Set-Label -Identity '{0}' -EncryptionEnabled `$true -EncryptionProtectionType Template -EncryptionRightsDefinitions '{1}' -EncryptionOfflineAccessDays {2} -EncryptionContentExpiredOnDateInDaysOrNever '{3}'" -f $LabelName, $rightsDef, $OfflineDays, $expiryArg
        Show-Action $desc {
            Set-Label -Identity $LabelName `
                -EncryptionEnabled $true `
                -EncryptionProtectionType 'Template' `
                -EncryptionRightsDefinitions $rightsDef `
                -EncryptionOfflineAccessType 'DaysNumber' `
                -EncryptionOfflineAccessDays $OfflineDays `
                -EncryptionContentExpiredOnDateInDaysOrNever "$expiryArg" | Out-Null
        }
        if (-not $doIt) { Write-Host "(-WhatIf - re-run with -Commit. Rollback: -RemoveProtection -LabelName '$LabelName' -Commit)" -ForegroundColor Yellow }
    }

    'SetUserDefined' {
        Write-Host "=== Set USER-DEFINED encryption on label: $LabelName ===" -ForegroundColor Cyan
        if (-not $LabelName) { throw 'Provide -LabelName.' }
        Write-Host "  User-defined = the user picks recipients at protect time (Do Not Forward for mail / Encrypt-Only for files)." -ForegroundColor Yellow
        Write-Host "  DNF/Encrypt-Only rely on Exchange IRM being enabled (Req 2.6)." -ForegroundColor Yellow
        $desc = "Set-Label -Identity '{0}' -EncryptionEnabled `$true -EncryptionProtectionType UserDefined -EncryptionDoNotForward `${1} -EncryptionPromptUser `${2}" -f $LabelName, [bool]$DoNotForward, [bool]$EncryptOnly
        Show-Action $desc {
            Set-Label -Identity $LabelName `
                -EncryptionEnabled $true `
                -EncryptionProtectionType 'UserDefined' `
                -EncryptionDoNotForward ([bool]$DoNotForward) `
                -EncryptionPromptUser ([bool]$EncryptOnly) | Out-Null
        }
        if (-not $doIt) { Write-Host "(-WhatIf - re-run with -Commit. Rollback: -RemoveProtection -LabelName '$LabelName' -Commit)" -ForegroundColor Yellow }
    }

    'PublishToPolicy' {
        Write-Host "=== Publish labels to policy: $PolicyName ===" -ForegroundColor Cyan
        if (-not $Labels -or $Labels.Count -eq 0) { throw 'Provide -Labels (one or more label names to add to the policy).' }
        Write-Host "  Confirm this policy is scoped to the PILOT ring first; expand to the broad policy only after validation." -ForegroundColor Yellow
        $desc = "Set-LabelPolicy -Identity '{0}' -AddLabels {1}" -f $PolicyName, ($Labels -join ', ')
        Show-Action $desc {
            Set-LabelPolicy -Identity $PolicyName -AddLabels $Labels | Out-Null
        }
        if (-not $doIt) { Write-Host "(-WhatIf - re-run with -Commit. Rollback: Set-LabelPolicy -Identity '$PolicyName' -RemoveLabels <labels>)" -ForegroundColor Yellow }
    }

    'RemoveProtection' {
        Write-Host "=== Remove protection from label: $LabelName (rollback) ===" -ForegroundColor Cyan
        if (-not $LabelName) { throw 'Provide -LabelName.' }
        $desc = "Set-Label -Identity '{0}' -EncryptionEnabled `$false -EncryptionProtectionType RemoveProtection" -f $LabelName
        Show-Action $desc {
            Set-Label -Identity $LabelName -EncryptionEnabled $false -EncryptionProtectionType 'RemoveProtection' | Out-Null
        }
        if (-not $doIt) { Write-Host "(-WhatIf - re-run with -Commit.)" -ForegroundColor Yellow }
    }
}

if (-not $doIt) { Write-Host "`n(No changes made - this was a -WhatIf preview. Add -Commit to apply.)" -ForegroundColor Yellow }

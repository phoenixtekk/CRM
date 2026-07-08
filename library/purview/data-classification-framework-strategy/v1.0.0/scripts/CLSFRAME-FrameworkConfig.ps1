<#
.SYNOPSIS
    CLSFRAME-FrameworkConfig.ps1 — build the classification framework's reference implementation (tier labels, label policy, tier-aligned DLP baseline in TEST mode, tier retention labels). -WhatIf by default; writes require -Commit.
.DESCRIPTION
    A single config/remediation helper for the framework. Depending on the switch selected it will:
    create the four tier sensitivity labels (-BuildLabels, the default action); publish the tier
    labels to a pilot group or all users (-PublishLabels); create a tier-aligned DLP baseline IN TEST
    MODE and later enforce it from test (-BuildDlp / -EnforceFromTest); or create + publish the tier
    retention labels (-BuildRetention / -PublishRetention). Every write is shown under -WhatIf first
    and only executed with -Commit. The DLP baseline is created with -Mode TestWithNotifications and is
    NEVER enabled except via the explicit -EnforceFromTest path. No credentials are stored in code.
    Retention periods/actions and DLP enforcement are governance/records/legal determinations — the
    placeholders here MUST be confirmed with the accountable owner before enforcing.
.EXAMPLE
    .\CLSFRAME-FrameworkConfig.ps1 -BuildLabels -WhatIf
    Shows the New-Label calls for Public/Internal/Confidential/Restricted without making changes.
.EXAMPLE
    .\CLSFRAME-FrameworkConfig.ps1 -BuildLabels -Commit
    Creates the four tier labels (unpublished until -PublishLabels).
.EXAMPLE
    .\CLSFRAME-FrameworkConfig.ps1 -PublishLabels -PolicyName "CLS Policy – Pilot – Ring1" -PilotGroup "sg-cls-pilot" -Commit
    Publishes the tier labels to the pilot group.
.EXAMPLE
    .\CLSFRAME-FrameworkConfig.ps1 -BuildDlp -DlpName "CLS DLP – Tier2-3 – Test" -WhatIf
    Shows the New-DlpCompliancePolicy (Mode=TestWithNotifications) + rule it would create.
.NOTES
    Requires PowerShell 5.1+/7+ and the ExchangeOnlineManagement module (Connect-IPPSSession).
    Roles: Information Protection Admin (labels), DLP Compliance Management / Compliance Administrator
    (DLP), Records Management / Compliance Administrator (retention).
    Expected results: PASS = under -WhatIf the intended cmdlets are printed and nothing changes; under
    -Commit the artifact is created/published and Get-Label / Get-DlpCompliancePolicy (Mode=Test*) /
    Get-ComplianceTag confirm it. FAIL = access denied (role/propagation) or a cmdlet unavailable
    (verify your licensing/tenant). SAFETY: DLP is created in TEST mode; enforcement requires the
    explicit -EnforceFromTest path after match reports are accepted.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    # Action switches (choose one per run)
    [switch]$BuildLabels,
    [switch]$PublishLabels,
    [switch]$BuildDlp,
    [switch]$EnforceFromTest,
    [switch]$BuildRetention,
    [switch]$PublishRetention,

    # Common parameters
    [switch]$Commit,
    [string]$PolicyName,
    [string]$PilotGroup,
    [switch]$AllUsers,
    [string]$DlpName = 'CLS DLP – Tier2-3 – Test',

    # Tier definitions (names are reused verbatim across the docs). Encryption groups are placeholders.
    [string]$ConfidentialRightsGroup = 'sg-cls-confidential',
    [string]$RestrictedRightsGroup   = 'sg-cls-restricted',

    # DLP conditions — placeholder sensitive info types; confirm per §2.5 with data owners.
    [string[]]$Tier2SensitiveTypes = @('Credit Card Number','U.S. Social Security Number (SSN)')
)

function Connect-SCC {
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        Write-Warning 'ExchangeOnlineManagement module not found. Install-Module ExchangeOnlineManagement -Scope CurrentUser'
        throw 'Module missing.'
    }
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) {
        Write-Host 'Connecting to Security & Compliance PowerShell...' -ForegroundColor Cyan
        Connect-IPPSSession -ShowBanner:$false
    }
}

# Gate every write: with -Commit run it; otherwise print what WOULD run (WhatIf).
function Invoke-Write {
    param([string]$Description, [scriptblock]$Action)
    if ($Commit -and $PSCmdlet.ShouldProcess($Description)) {
        Write-Host ("  COMMIT: {0}" -f $Description) -ForegroundColor Green
        & $Action
    } else {
        Write-Host ("  WHATIF: would {0}" -f $Description) -ForegroundColor Yellow
    }
}

Connect-SCC

# ---------------------------------------------------------------------------
# BuildLabels — create the four tier sensitivity labels (unpublished)
# ---------------------------------------------------------------------------
if ($BuildLabels -or (-not ($PublishLabels -or $BuildDlp -or $EnforceFromTest -or $BuildRetention -or $PublishRetention))) {
    Write-Host "`n=== Build tier sensitivity labels ===" -ForegroundColor Cyan

    Invoke-Write "create label 'Public' (marking only)" {
        New-Label -DisplayName 'Public' -Name 'Public' -Tooltip 'Approved for public release.' `
            -ApplyContentMarkingFooterEnabled $true -ApplyContentMarkingFooterText 'Public' | Out-Null
    }
    Invoke-Write "create label 'Internal' (footer marking)" {
        New-Label -DisplayName 'Internal' -Name 'Internal' -Tooltip 'Internal use only; not for public release.' `
            -ApplyContentMarkingFooterEnabled $true -ApplyContentMarkingFooterText 'Internal' | Out-Null
    }
    Invoke-Write "create label 'Confidential' (encrypt; rights -> $ConfidentialRightsGroup)" {
        New-Label -DisplayName 'Confidential' -Name 'Confidential' -Tooltip 'Sensitive business data or PII; encrypted.' `
            -EncryptionEnabled $true -EncryptionProtectionType 'Template' `
            -EncryptionRightsDefinitions "$ConfidentialRightsGroup:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,PRINT,EXTRACT,REPLY,REPLYALL,FORWARD,OBJMODEL" `
            -ApplyContentMarkingFooterEnabled $true -ApplyContentMarkingFooterText 'Confidential' | Out-Null
    }
    Invoke-Write "create label 'Restricted' (encrypt + watermark; rights -> $RestrictedRightsGroup)" {
        New-Label -DisplayName 'Restricted' -Name 'Restricted' -Tooltip 'Highly regulated / high-impact; encrypted, named recipients.' `
            -EncryptionEnabled $true -EncryptionProtectionType 'Template' `
            -EncryptionRightsDefinitions "$RestrictedRightsGroup:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,REPLY,REPLYALL" `
            -ApplyWaterMarkingEnabled $true -ApplyWaterMarkingText 'Restricted' `
            -ApplyContentMarkingFooterEnabled $true -ApplyContentMarkingFooterText 'Restricted' | Out-Null
    }
    Write-Host '  Encryption rights definitions are placeholders — confirm the groups exist (§2.7).' -ForegroundColor DarkGray
}

# ---------------------------------------------------------------------------
# PublishLabels — publish the tier labels to a pilot group or all users
# ---------------------------------------------------------------------------
if ($PublishLabels) {
    Write-Host "`n=== Publish tier labels ===" -ForegroundColor Cyan
    if (-not $PolicyName) { throw 'Provide -PolicyName (e.g. "CLS Policy – Pilot – Ring1").' }
    $tierLabels = @('Public','Internal','Confidential','Restricted')

    if ($AllUsers) {
        Invoke-Write "publish tier labels via '$PolicyName' to ALL USERS" {
            New-LabelPolicy -Name $PolicyName -Labels $tierLabels | Out-Null
        }
    } else {
        if (-not $PilotGroup) { throw 'Provide -PilotGroup (or -AllUsers).' }
        Invoke-Write "publish tier labels via '$PolicyName' to pilot group '$PilotGroup'" {
            New-LabelPolicy -Name $PolicyName -Labels $tierLabels `
                -ModernGroupLocation $PilotGroup | Out-Null
        }
    }
    Write-Host '  Rollback: Remove-LabelPolicy "<name>" unpublishes without deleting the labels.' -ForegroundColor DarkGray
}

# ---------------------------------------------------------------------------
# BuildDlp — tier-aligned DLP baseline IN TEST MODE (never Enable here)
# ---------------------------------------------------------------------------
if ($BuildDlp) {
    Write-Host "`n=== Build tier-aligned DLP baseline (TEST mode) ===" -ForegroundColor Cyan
    $sitCondition = ($Tier2SensitiveTypes | ForEach-Object { @{ Name = $_; minCount = 1 } })

    Invoke-Write "create DLP policy '$DlpName' in Mode=TestWithNotifications (all M365 locations)" {
        New-DlpCompliancePolicy -Name $DlpName -Mode 'TestWithNotifications' `
            -ExchangeLocation 'All' -SharePointLocation 'All' -OneDriveLocation 'All' -TeamsLocation 'All' | Out-Null
    }
    Invoke-Write "create DLP rule 'CLS DLP Rule – Tier2-3' (SITs: $($Tier2SensitiveTypes -join ', '); restrict external)" {
        New-DlpComplianceRule -Name 'CLS DLP Rule – Tier2-3' -Policy $DlpName `
            -ContentContainsSensitiveInformation $sitCondition `
            -AccessScope 'NotInOrganization' `
            -NotifyUser 'Owner' | Out-Null
    }
    Write-Host '  DLP is created in TEST mode — nothing is blocked. Enforce only via -EnforceFromTest after reports are accepted.' -ForegroundColor Yellow
    Write-Host '  Rollback: Set-DlpCompliancePolicy "<name>" -Mode Disable.' -ForegroundColor DarkGray
}

# ---------------------------------------------------------------------------
# EnforceFromTest — flip the DLP baseline from Test to Enable (after sign-off)
# ---------------------------------------------------------------------------
if ($EnforceFromTest) {
    Write-Host "`n=== Enforce DLP baseline from TEST -> Enable ===" -ForegroundColor Cyan
    Write-Host '  Only do this after the test-mode match reports are accepted by the data owner (Testing §5, Test 5).' -ForegroundColor Yellow
    Invoke-Write "set DLP policy '$DlpName' Mode=Enable" {
        Set-DlpCompliancePolicy -Identity $DlpName -Mode 'Enable' | Out-Null
    }
    Write-Host '  Rollback: Set-DlpCompliancePolicy "<name>" -Mode TestWithNotifications (or Disable).' -ForegroundColor DarkGray
}

# ---------------------------------------------------------------------------
# BuildRetention — tier retention labels (periods/actions are records/legal)
# ---------------------------------------------------------------------------
if ($BuildRetention) {
    Write-Host "`n=== Build tier retention labels ===" -ForegroundColor Cyan
    Write-Host '  Periods/actions below are PLACEHOLDERS — confirm with records/legal (§2 deferral) before -Commit.' -ForegroundColor Yellow

    # Placeholder tier retention treatments — durations/actions are determinations, edit per sign-off.
    $retLabels = @(
        @{ Name='CLS Retain – Public';       Action='Keep';          Days=365;  Trigger='CreationAgeInDays' },
        @{ Name='CLS Retain – Internal';     Action='Keep';          Days=1095; Trigger='ModificationAgeInDays' },
        @{ Name='CLS Retain – Confidential'; Action='KeepAndDelete'; Days=2555; Trigger='CreationAgeInDays' },
        @{ Name='CLS Retain – Restricted';   Action='KeepAndDelete'; Days=3650; Trigger='CreationAgeInDays' }
    )
    foreach ($r in $retLabels) {
        Invoke-Write ("create retention label '{0}' ({1}, {2} days, {3})" -f $r.Name,$r.Action,$r.Days,$r.Trigger) {
            New-ComplianceTag -Name $r.Name -RetentionAction $r.Action `
                -RetentionDuration $r.Days -RetentionType $r.Trigger | Out-Null
        }.GetNewClosure()
    }
    Write-Host '  Do NOT mark anything as a record without a records/legal determination.' -ForegroundColor DarkGray
}

# ---------------------------------------------------------------------------
# PublishRetention — publish the tier retention labels to a pilot group
# ---------------------------------------------------------------------------
if ($PublishRetention) {
    Write-Host "`n=== Publish tier retention labels (pilot) ===" -ForegroundColor Cyan
    if (-not $PolicyName) { throw 'Provide -PolicyName (e.g. "CLS Retain Publish – Pilot – Ring1").' }
    if (-not $PilotGroup) { throw 'Provide -PilotGroup for the pilot ring.' }
    $tierTags = @('CLS Retain – Public','CLS Retain – Internal','CLS Retain – Confidential','CLS Retain – Restricted')

    Invoke-Write "create retention publish policy '$PolicyName' for pilot group '$PilotGroup'" {
        New-RetentionCompliancePolicy -Name $PolicyName -ModernGroupLocation $PilotGroup | Out-Null
    }
    Invoke-Write "publish tier retention labels via rule 'CLS Retain Rule – Pilot'" {
        New-RetentionComplianceRule -Name 'CLS Retain Rule – Pilot' -Policy $PolicyName `
            -PublishComplianceTag $tierTags | Out-Null
    }
    Write-Host '  Rollback: Remove-RetentionCompliancePolicy "<name>" unpublishes without deleting the labels.' -ForegroundColor DarkGray
}

if (-not $Commit) {
    Write-Host "`n[WHATIF] No changes were made. Re-run with -Commit to apply." -ForegroundColor Yellow
} else {
    Write-Host "`n[COMMIT] Requested changes attempted — verify with CLSFRAME-Discovery.ps1 / CLSFRAME-Validation.ps1." -ForegroundColor Green
}

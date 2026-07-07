<#
.SYNOPSIS
  EXOARCH-Set-MrmPolicy.ps1 — create/update the MRM move-to-archive tags + retention policy. SAFE BY DEFAULT: -WhatIf/report unless -Commit.
.DESCRIPTION
  Builds the Messaging Records Management artifacts for this solution, idempotently:
    - "Move to Archive - Default - Prod"  (default policy tag / DPT, action MoveToArchive, age N days)
    - "Archive Now - Personal - Prod"     (personal tag, action MoveToArchive, user-applied)
    - "Archive Retention Policy - EXO - Prod" (retention policy linking both tags)
  Existing artifacts are UPDATED (Set-*) rather than recreated. It does NOT assign the policy to
  mailboxes (that is a separate, explicit Set-Mailbox step) and it does NOT run the Managed Folder
  Assistant. Without -Commit it previews; -WhatIf is honored on all write cmdlets.
.EXAMPLE
  .\EXOARCH-Set-MrmPolicy.ps1 -ArchiveAgeDays 730 -WhatIf
  # Preview the tags/policy that would be created for a 2-year move-to-archive age.
.EXAMPLE
  .\EXOARCH-Set-MrmPolicy.ps1 -ArchiveAgeDays 730 -Commit
  # Create/update the tags and "Archive Retention Policy - EXO - Prod".
  # (PowerShell 5.1+/7+, ExchangeOnlineManagement module; connect with Connect-ExchangeOnline.)
.NOTES
  Expected results: Get-RetentionPolicy "Archive Retention Policy - EXO - Prod" links both tags; the
  DPT shows RetentionAction MoveToArchive / RetentionEnabled True. Assign it to mailboxes afterward,
  then Start-ManagedFolderAssistant. Messaging — Exchange Online Archiving & Messaging Retention.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [int]$ArchiveAgeDays = 730,
    [string]$DptName        = 'Move to Archive - Default - Prod',
    [string]$PersonalTag    = 'Archive Now - Personal - Prod',
    [string]$PolicyName     = 'Archive Retention Policy - EXO - Prod',
    [switch]$Commit
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-ConnectionInformation -ErrorAction SilentlyContinue)) {
    Connect-ExchangeOnline -ShowBanner:$false   # -ExchangeEnvironmentName for Gov clouds
}

if (-not $Commit) { Write-Host 'DRY RUN — no changes. Re-run with -Commit to apply.' -ForegroundColor Yellow }

function Set-ArchiveTag {
    param([string]$Name, [string]$Type, [int]$Age, [bool]$IsPersonal)
    $existing = Get-RetentionPolicyTag -Identity $Name -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host ("[update tag] {0}" -f $Name) -ForegroundColor Yellow
        if ($Commit) {
            Set-RetentionPolicyTag -Identity $Name -RetentionAction MoveToArchive -AgeLimitForRetention $Age -RetentionEnabled $true -WhatIf:$WhatIfPreference | Out-Null
        }
    } else {
        Write-Host ("[create tag] {0} (Type={1}, MoveToArchive, Age={2}d)" -f $Name, $Type, $Age) -ForegroundColor Green
        if ($Commit) {
            New-RetentionPolicyTag -Name $Name -Type $Type -RetentionAction MoveToArchive -AgeLimitForRetention $Age -RetentionEnabled $true -WhatIf:$WhatIfPreference | Out-Null
        }
    }
}

# DPT: applies automatically to all items older than N days.
Set-ArchiveTag -Name $DptName -Type 'All' -Age $ArchiveAgeDays -IsPersonal:$false
# Personal tag: user-applied on-demand move (age 0 = act when applied).
Set-ArchiveTag -Name $PersonalTag -Type 'Personal' -Age 0 -IsPersonal:$true

# Retention policy bundling both tags.
$policy = Get-RetentionPolicy -Identity $PolicyName -ErrorAction SilentlyContinue
if ($policy) {
    Write-Host ("[update policy] {0} — linking tags" -f $PolicyName) -ForegroundColor Yellow
    if ($Commit) {
        Set-RetentionPolicy -Identity $PolicyName -RetentionPolicyTagLinks $DptName, $PersonalTag -WhatIf:$WhatIfPreference | Out-Null
    }
} else {
    Write-Host ("[create policy] {0} — linking '{1}' + '{2}'" -f $PolicyName, $DptName, $PersonalTag) -ForegroundColor Green
    if ($Commit) {
        New-RetentionPolicy -Name $PolicyName -RetentionPolicyTagLinks $DptName, $PersonalTag -WhatIf:$WhatIfPreference | Out-Null
    }
}

Write-Host 'Done. Assign with: Set-Mailbox <id> -RetentionPolicy "Archive Retention Policy - EXO - Prod"; then Start-ManagedFolderAssistant <id>.' -ForegroundColor Cyan

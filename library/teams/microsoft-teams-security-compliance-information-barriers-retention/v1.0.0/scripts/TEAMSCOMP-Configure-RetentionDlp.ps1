<#
.SYNOPSIS
  Teams retention + Teams DLP config helper (dry-run / -WhatIf by default; writes only with -Commit).
.DESCRIPTION
  Creates a Teams-only retention policy + rule (compliance-defined duration and end-of-life action)
  and a Teams-location DLP policy + rule in a TEST mode referencing approved sensitive-information
  types. Safe by default: previews with -WhatIf and makes NO change unless -Commit is passed. Teams
  locations are kept in their own retention policy (they cannot be mixed with Exchange/SharePoint).
  DLP is created in test/audit mode (never blocking) — enforce is a separate, deliberate step.
  The duration, action, and content types are compliance's determination — this only implements them.
.EXAMPLE
  .\TEAMSCOMP-Configure-RetentionDlp.ps1 -RetentionDays 2555 -RetentionAction KeepAndDelete -PilotChatLocation "pilotgroup@contoso.com" -SensitiveInfoTypes "U.S. Social Security Number (SSN)","Credit Card Number"
  # dry-run (-WhatIf) — shows what would be created, changes nothing
.EXAMPLE
  .\TEAMSCOMP-Configure-RetentionDlp.ps1 -RetentionDays 2555 -RetentionAction KeepAndDelete -PilotChatLocation "pilotgroup@contoso.com" -SensitiveInfoTypes "Credit Card Number" -Commit
  # creates the Teams retention policy+rule and the Teams DLP policy+rule in TEST mode for real
  (PowerShell 5.1+/7+, ExchangeOnlineManagement; connect via Connect-IPPSSession)
.NOTES
  Expected results: with no -Commit, WhatIf preview lines only. With -Commit, one Teams retention
  policy+rule (Enabled) and one Teams DLP policy+rule in a Test mode (BlockAccess $false). Review the
  DLP audit gate before enabling enforce. White-label. No credentials in code.
#>
[CmdletBinding()]
param(
    [int]$RetentionDays = 2555,                                   # compliance-defined
    [ValidateSet('Keep','KeepAndDelete','Delete')][string]$RetentionAction = 'KeepAndDelete',
    [string]$PilotChatLocation = 'All',                           # narrow to a pilot group first
    [string]$PilotChannelLocation = 'All',
    [string[]]$SensitiveInfoTypes = @('Credit Card Number'),      # reuse approved Purview SITs
    [string]$Stage = 'Pilot',
    [switch]$Commit
)

$whatIf = -not $Commit
if ($whatIf) { Write-Host "DRY-RUN (-WhatIf): no changes will be made. Pass -Commit to apply." -ForegroundColor Yellow }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false -ErrorAction Stop

$retPolicy = "Retention Policy - Teams Chat+Channel - $Stage"
$retRule   = "Retention Rule - Teams ${RetentionDays}d - $Stage"
$dlpPolicy = "DLP Policy - Teams Sensitive - $Stage"
$dlpRule   = "DLP Rule - Teams PII - $Stage"

# --- Teams retention (own policy; Teams locations only) ------------------------
Write-Host "`n=== Configure Teams retention ===" -ForegroundColor Cyan
Write-Host ("  Policy : {0}" -f $retPolicy)
Write-Host ("  Rule   : {0}  ({1} days, {2})" -f $retRule, $RetentionDays, $RetentionAction)

if (-not (Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue | Where-Object Name -eq $retPolicy)) {
    New-RetentionCompliancePolicy -Name $retPolicy `
        -TeamsChatLocation $PilotChatLocation -TeamsChannelLocation $PilotChannelLocation -WhatIf:$whatIf
} else { Write-Host "  Retention policy already exists — skipping create." -ForegroundColor Gray }

if (-not (Get-RetentionComplianceRule -ErrorAction SilentlyContinue | Where-Object Name -eq $retRule)) {
    New-RetentionComplianceRule -Name $retRule -Policy $retPolicy `
        -RetentionDuration $RetentionDays -RetentionComplianceAction $RetentionAction -WhatIf:$whatIf
} else { Write-Host "  Retention rule already exists — skipping create." -ForegroundColor Gray }

# --- Teams DLP (test mode; never blocking here) --------------------------------
Write-Host "`n=== Configure Teams DLP (TEST mode — audit gate) ===" -ForegroundColor Cyan
Write-Host ("  Policy : {0}" -f $dlpPolicy)
Write-Host ("  Rule   : {0}  (SITs: {1})" -f $dlpRule, ($SensitiveInfoTypes -join ', '))

if (-not (Get-DlpCompliancePolicy -ErrorAction SilentlyContinue | Where-Object Name -eq $dlpPolicy)) {
    New-DlpCompliancePolicy -Name $dlpPolicy -TeamsLocation $PilotChatLocation -Mode TestWithoutNotifications -WhatIf:$whatIf
} else { Write-Host "  DLP policy already exists — skipping create." -ForegroundColor Gray }

if (-not (Get-DlpComplianceRule -ErrorAction SilentlyContinue | Where-Object Name -eq $dlpRule)) {
    $sit = @($SensitiveInfoTypes | ForEach-Object { @{ Name = $_ } })
    New-DlpComplianceRule -Name $dlpRule -Policy $dlpPolicy `
        -ContentContainsSensitiveInformation $sit -NotifyUser Owner -BlockAccess $false -WhatIf:$whatIf
} else { Write-Host "  DLP rule already exists — skipping create." -ForegroundColor Gray }

Write-Host "`n  Retention applied Enabled; DLP left in TEST mode (BlockAccess `$false)." -ForegroundColor Green
Write-Host "  After the audit gate passes: Set-DlpCompliancePolicy -Identity '$dlpPolicy' -Mode Enable" -ForegroundColor Green
Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

<#
.SYNOPSIS
    DLCEXO-Configure.ps1 — create/update the Purview retention + MRM cleanup policies, scoped to the pilot (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Builds the two Exchange lifecycle engines for the pilot ring: (1) a Purview retention policy scoped
        to Exchange + a retention rule (retain / keep-then-delete), and (2) an Exchange MRM cleanup policy
        with Deleted Items / Junk age-out tags and an optional MoveToArchive default tag. SAFE BY DEFAULT:
        prints the exact plan under -WhatIf and does nothing; applies only with -Commit. Supports retain-first
        (-Disposition Retain) so you can validate the "keep" behavior before ever adding a delete action.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with ExchangeOnlineManagement. Connect BOTH endpoints first:
          Connect-IPPSSession            # Purview retention policy/rule
          Connect-ExchangeOnline         # MRM tags/policy + mailbox assignment
          .\DLCEXO-Configure.ps1 -PilotGroup "SG-DLCEXO-Pilot" -RetainDays 2555 -Disposition Retain -WhatIf
          .\DLCEXO-Configure.ps1 -PilotGroup "SG-DLCEXO-Pilot" -RetainDays 2555 -Disposition KeepAndDelete -Commit
    EXPECTED RESULTS
        -WhatIf: the ordered plan (objects to create + scope) with NO changes. -Commit: policies/rules/tags
        created and the MRM policy assigned to pilot mailboxes; a summary of what was created.
.NOTES
    White-label tooling. Write actions gated behind -Commit; -WhatIf is the default. No credentials stored.
    Uses standard S&C PowerShell (New-RetentionCompliancePolicy/Rule) and Exchange Online cmdlets
    (New-RetentionPolicyTag/Policy, Set-Mailbox); none are invented. Durations/disposition come from your
    records schedule (R4). Does NOT enable Preservation Lock. -IncludeArchiveTag requires archive mailboxes.
#>
[CmdletBinding(DefaultParameterSetName = "WhatIf")]
param(
    [Parameter(Mandatory)][string]$PilotGroup,
    [Parameter(Mandatory)][int]$RetainDays,
    [ValidateSet("Retain","Delete","KeepAndDelete")][string]$Disposition = "Retain",
    [string]$PolicyName        = "DLCEXO-Retention-Exchange-Pilot",
    [string]$RuleName          = "DLCEXO-Rule-Exchange-Keep7yrThenDelete",
    [string]$MrmPolicyName     = "DLCEXO-MRM-Cleanup-Standard",
    [int]$DeletedItemsAgeDays  = 30,
    [int]$JunkEmailAgeDays     = 30,
    [int]$ArchiveAgeDays       = 730,
    [switch]$IncludeArchiveTag,
    [Parameter(ParameterSetName = "Commit")][switch]$Commit,
    [Parameter(ParameterSetName = "WhatIf")][switch]$WhatIf
)

$ErrorActionPreference = "Stop"
$apply = $Commit.IsPresent
$mode  = if ($apply) { "COMMIT" } else { "WHATIF (no changes)" }
Write-Host ("=== DLCEXO Configure — build lifecycle policies [{0}] ===" -f $mode) -ForegroundColor Cyan
if ($Disposition -ne "Retain") {
    Write-Host ("  WARNING: Disposition '{0}' adds a DELETE action — destructive and largely irreversible. Confirm the records-approved schedule (R4) and pilot scope (R7) before -Commit." -f $Disposition) -ForegroundColor Red
}

function Do-Step($desc, [scriptblock]$action) {
    if ($apply) {
        Write-Host ("  APPLY: {0}" -f $desc) -ForegroundColor Green
        try { & $action } catch { Write-Host ("    ERROR: {0}" -f $_.Exception.Message) -ForegroundColor Red }
    } else {
        Write-Host ("  WOULD: {0}" -f $desc) -ForegroundColor Yellow
    }
}

# --- Resolve pilot mailboxes (scope for the Purview policy ExchangeLocation) ---
$mailboxes = @()
try {
    $mailboxes = Get-DistributionGroupMember -Identity $PilotGroup -ResultSize Unlimited -ErrorAction Stop |
        Select-Object -ExpandProperty PrimarySmtpAddress
    Write-Host ("  Pilot scope '{0}' = {1} mailbox(es)." -f $PilotGroup, @($mailboxes).Count) -ForegroundColor Cyan
} catch {
    Write-Host ("  ERROR: cannot resolve pilot group '{0}': {1}" -f $PilotGroup, $_.Exception.Message) -ForegroundColor Red
    Write-Host "  Fix the pilot group before continuing. Aborting." -ForegroundColor Red
    return
}

# --- 1. Purview retention policy + rule (Security & Compliance PowerShell) ---
Write-Host "`n[1] Purview Data Lifecycle Management retention (Exchange)" -ForegroundColor Cyan
Do-Step ("Create retention policy '{0}' scoped to {1} pilot mailbox(es) (ExchangeLocation)" -f $PolicyName, @($mailboxes).Count) {
    New-RetentionCompliancePolicy -Name $PolicyName -ExchangeLocation $mailboxes -ErrorAction Stop | Out-Null
}
Do-Step ("Create rule '{0}': RetentionDuration={1}d, Action={2}, ExpiryBasis=CreationAgeInDays" -f $RuleName, $RetainDays, $Disposition) {
    New-RetentionComplianceRule -Name $RuleName -Policy $PolicyName `
        -RetentionDuration $RetainDays -RetentionComplianceAction $Disposition `
        -ExpirationDateOption CreationAgeInDays -ErrorAction Stop | Out-Null
}

# --- 2. Exchange MRM cleanup policy + tags (Exchange Online PowerShell) ---
Write-Host "`n[2] Exchange MRM cleanup (Deleted Items / Junk age-out; optional archive tier)" -ForegroundColor Cyan
$tagLinks = @("DLCEXO-Tag-DeletedItems-$($DeletedItemsAgeDays)d","DLCEXO-Tag-JunkEmail-$($JunkEmailAgeDays)d")
Do-Step ("Create RPT '{0}' (DeletedItems, PermanentlyDelete, {1}d)" -f $tagLinks[0], $DeletedItemsAgeDays) {
    New-RetentionPolicyTag -Name $tagLinks[0] -Type DeletedItems -RetentionEnabled $true `
        -AgeLimitForRetention $DeletedItemsAgeDays -RetentionAction PermanentlyDelete -ErrorAction Stop | Out-Null
}
Do-Step ("Create RPT '{0}' (JunkEmail, PermanentlyDelete, {1}d)" -f $tagLinks[1], $JunkEmailAgeDays) {
    New-RetentionPolicyTag -Name $tagLinks[1] -Type JunkEmail -RetentionEnabled $true `
        -AgeLimitForRetention $JunkEmailAgeDays -RetentionAction PermanentlyDelete -ErrorAction Stop | Out-Null
}
if ($IncludeArchiveTag) {
    $dpt = "DLCEXO-Tag-Default-MoveToArchive-$([math]::Round($ArchiveAgeDays/365,0))yr"
    $tagLinks += $dpt
    Do-Step ("Create DPT '{0}' (All, MoveToArchive, {1}d) — requires archive mailboxes enabled" -f $dpt, $ArchiveAgeDays) {
        New-RetentionPolicyTag -Name $dpt -Type All -RetentionEnabled $true `
            -AgeLimitForRetention $ArchiveAgeDays -RetentionAction MoveToArchive -ErrorAction Stop | Out-Null
    }
} else {
    Write-Host "  (Skipping MoveToArchive DPT — pass -IncludeArchiveTag and ensure archive mailboxes are enabled.)" -ForegroundColor DarkGray
}
Do-Step ("Create MRM policy '{0}' linking: {1}" -f $MrmPolicyName, ($tagLinks -join ", ")) {
    New-RetentionPolicy -Name $MrmPolicyName -RetentionPolicyTagLinks $tagLinks -ErrorAction Stop | Out-Null
}
foreach ($mb in $mailboxes) {
    Do-Step ("Assign MRM policy '{0}' to {1}" -f $MrmPolicyName, $mb) {
        Set-Mailbox -Identity $mb -RetentionPolicy $MrmPolicyName -ErrorAction Stop
    }
}

Write-Host "`n=== Plan complete ($mode) ===" -ForegroundColor Cyan
if (-not $apply) {
    Write-Host "No changes were made. Re-run with -Commit to apply. Retain-first: keep -Disposition Retain, validate, then re-run with KeepAndDelete." -ForegroundColor Yellow
} else {
    Write-Host "Applied. Run Start-ManagedFolderAssistant on a pilot mailbox, then DLCEXO-Report.ps1 and DLCEXO-Test-Readiness.ps1." -ForegroundColor Green
}

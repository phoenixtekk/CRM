<#
.SYNOPSIS
  Configuration helper to apply/tune the mail-hygiene baseline. SAFE BY DEFAULT: dry-run (-WhatIf)
  unless -Commit is explicitly passed.
.DESCRIPTION
  Scopes Microsoft's Standard preset security policy to a pilot group, OR (with -CustomPolicies)
  creates the named custom anti-spam and anti-malware policies + rules scoped to the pilot group,
  following the solution's naming convention. Without -Commit it only shows the intended actions
  (WhatIf) and changes nothing. Connect with Connect-ExchangeOnline first (modern auth; no stored
  credentials).
.EXAMPLE
  .\Set-MailHygieneBaseline.ps1 -PilotGroup "Hygiene-Pilot"            # dry-run: shows preset scoping
  .\Set-MailHygieneBaseline.ps1 -PilotGroup "Hygiene-Pilot" -Commit    # apply preset scope
  .\Set-MailHygieneBaseline.ps1 -PilotGroup "Hygiene-Pilot" -CustomPolicies   # dry-run custom policies
  # (PowerShell 5.1+/7+, ExchangeOnlineManagement module)
.NOTES
  Expected results: without -Commit, "[WhatIf]" lines describing each change and no modification.
  With -Commit, the preset is scoped (or the named custom policies are created) and confirmed.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$PilotGroup,
    [switch]$CustomPolicies,
    [ValidateSet('Standard','Strict')][string]$Preset = 'Standard',
    [switch]$Commit
)

# Safe-by-default: unless -Commit, force WhatIf on every change.
if (-not $Commit) { $WhatIfPreference = $true; Write-Host "DRY-RUN (no -Commit): no changes will be made." -ForegroundColor Yellow }

try { Get-OrganizationConfig -ErrorAction Stop | Out-Null }
catch { throw "Not connected. Run Connect-ExchangeOnline first." }

# Confirm the pilot group exists before doing anything.
try { Get-Recipient -Identity $PilotGroup -ErrorAction Stop | Out-Null }
catch { throw "Pilot group '$PilotGroup' not found. Create the mail-enabled security group first." }

$naming = @{
    AntiSpam    = "Anti-Spam - Inbound - Pilot"
    AntiMalware = "Anti-Malware - Inbound - Pilot"
}

if (-not $CustomPolicies) {
    Write-Host "Scoping the $Preset preset security policy to '$PilotGroup'..." -ForegroundColor Cyan
    # EOP protections
    $eopRule = Get-EOPProtectionPolicyRule -Identity "$Preset Preset Security Policy" -ErrorAction SilentlyContinue
    if ($eopRule) {
        if ($PSCmdlet.ShouldProcess("EOP $Preset preset", "add SentToMemberOf '$PilotGroup'")) {
            Set-EOPProtectionPolicyRule -Identity $eopRule.Identity -SentToMemberOf $PilotGroup
        }
    } else { Write-Warning "EOP $Preset preset rule not found - enable the preset in the Defender portal first." }
    # Defender for Office 365 protections (only if licensed / preset exists)
    $mdoRule = Get-ATPProtectionPolicyRule -Identity "$Preset Preset Security Policy" -ErrorAction SilentlyContinue
    if ($mdoRule) {
        if ($PSCmdlet.ShouldProcess("Defender for Office 365 $Preset preset", "add SentToMemberOf '$PilotGroup'")) {
            Set-ATPProtectionPolicyRule -Identity $mdoRule.Identity -SentToMemberOf $PilotGroup
        }
    } else { Write-Host "  (Defender for Office 365 preset not present - EOP-only tenant or not licensed. Skipping.)" -ForegroundColor DarkGray }
}
else {
    Write-Host "Creating custom baseline policies scoped to '$PilotGroup'..." -ForegroundColor Cyan
    # Anti-spam (hosted content filter)
    if (-not (Get-HostedContentFilterPolicy -Identity $naming.AntiSpam -ErrorAction SilentlyContinue)) {
        if ($PSCmdlet.ShouldProcess($naming.AntiSpam, "New-HostedContentFilterPolicy (HighConfidencePhish=Quarantine, BulkThreshold=7)")) {
            New-HostedContentFilterPolicy -Name $naming.AntiSpam `
                -HighConfidencePhishAction Quarantine -PhishSpamAction Quarantine `
                -SpamAction MoveToJmf -BulkThreshold 7
        }
    }
    if (-not (Get-HostedContentFilterRule -Identity $naming.AntiSpam -ErrorAction SilentlyContinue)) {
        if ($PSCmdlet.ShouldProcess("$($naming.AntiSpam) rule", "New-HostedContentFilterRule SentToMemberOf '$PilotGroup'")) {
            New-HostedContentFilterRule -Name $naming.AntiSpam -HostedContentFilterPolicy $naming.AntiSpam -SentToMemberOf $PilotGroup
        }
    }
    # Anti-malware
    if (-not (Get-MalwareFilterPolicy -Identity $naming.AntiMalware -ErrorAction SilentlyContinue)) {
        if ($PSCmdlet.ShouldProcess($naming.AntiMalware, "New-MalwareFilterPolicy (EnableFileFilter)")) {
            New-MalwareFilterPolicy -Name $naming.AntiMalware -EnableFileFilter $true
        }
    }
    if (-not (Get-MalwareFilterRule -Identity $naming.AntiMalware -ErrorAction SilentlyContinue)) {
        if ($PSCmdlet.ShouldProcess("$($naming.AntiMalware) rule", "New-MalwareFilterRule SentToMemberOf '$PilotGroup'")) {
            New-MalwareFilterRule -Name $naming.AntiMalware -MalwareFilterPolicy $naming.AntiMalware -SentToMemberOf $PilotGroup
        }
    }
}

Write-Host "Done. Validate with Test-MailHygienePolicy.ps1 before expanding." -ForegroundColor Cyan
if (-not $Commit) { Write-Host "This was a DRY-RUN. Re-run with -Commit to apply." -ForegroundColor Yellow }

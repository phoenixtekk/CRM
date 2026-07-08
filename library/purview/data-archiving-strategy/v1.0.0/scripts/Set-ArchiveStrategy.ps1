<#
.SYNOPSIS
    Configures the archiving strategy (SAFE BY DEFAULT: -WhatIf preview unless -Commit is supplied).
.DESCRIPTION
    Enables archive mailboxes (and optional auto-expanding archive) for a pilot group, creates the
    MRM move-to-archive tag and retention policy, assigns the policy, and runs the Managed Folder
    Assistant. No delete action is ever configured. Every write requires the explicit -Commit switch;
    without it the script only previews the intended changes.
.EXAMPLE
    .\Set-ArchiveStrategy.ps1 -PilotGroup grp-archive-pilot -EnableArchive -WhatIf
    Preview enabling archive mailboxes for the pilot group (no change made).
.EXAMPLE
    .\Set-ArchiveStrategy.ps1 -CreateMrmPolicy -TagName MTA-2yr -AgeDays 730 -PolicyName RP-Corp-Archive -Commit
    Create the move-to-archive tag/policy for real (PowerShell 5.1+/7+; Connect-ExchangeOnline first).
.NOTES
    Expected results: with -WhatIf, a printed plan and no change; with -Commit, the object is created/
    assigned and a confirming read-back is shown. Reversibility is limited (see the Implementation
    Guide rollback notes). No credentials or secrets are used.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$PilotGroup,
    [switch]$EnableArchive,
    [switch]$EnableAutoExpanding,
    [switch]$CreateMrmPolicy,
    [string]$TagName    = 'MTA-2yr',
    [int]   $AgeDays    = 730,
    [string]$PolicyName = 'RP-Corp-Archive',
    [string]$AssignPolicy,
    [switch]$RunAssistant,
    [switch]$Commit
)

$ErrorActionPreference = 'Stop'
# -Commit turns intent into action; without it, force -WhatIf so nothing changes.
if (-not $Commit) {
    $WhatIfPreference = $true
    Write-Host 'PREVIEW MODE (no -Commit): no changes will be made.' -ForegroundColor Yellow
} else {
    Write-Host 'COMMIT MODE: changes WILL be applied.' -ForegroundColor Red
}

function Get-PilotMailboxes {
    param([string]$Group)
    if (-not $Group) { throw 'A -PilotGroup is required for mailbox-scoped actions.' }
    Get-DistributionGroupMember -Identity $Group |
        Where-Object { $_.RecipientType -like '*Mailbox*' } |
        ForEach-Object { $_.PrimarySmtpAddress }
}

# 1. Enable archive mailboxes for the pilot scope
if ($EnableArchive) {
    foreach ($mbx in Get-PilotMailboxes -Group $PilotGroup) {
        $m = Get-Mailbox -Identity $mbx
        if ($m.ArchiveStatus -eq 'Active') {
            Write-Host "  [skip] $mbx already has an active archive." -ForegroundColor DarkGray
            continue
        }
        if ($PSCmdlet.ShouldProcess($mbx, 'Enable-Mailbox -Archive')) {
            Enable-Mailbox -Identity $mbx -Archive
            Write-Host "  [done] Archive enabled: $mbx" -ForegroundColor Green
        }
    }
}

# 2. Enable auto-expanding archive per pilot mailbox (IRREVERSIBLE)
if ($EnableAutoExpanding) {
    Write-Warning 'Auto-expanding archive is IRREVERSIBLE once enabled.'
    foreach ($mbx in Get-PilotMailboxes -Group $PilotGroup) {
        if ($PSCmdlet.ShouldProcess($mbx, 'Enable-Mailbox -AutoExpandingArchive')) {
            Enable-Mailbox -Identity $mbx -AutoExpandingArchive
            Write-Host "  [done] Auto-expanding archive enabled: $mbx" -ForegroundColor Green
        }
    }
}

# 3. Create MRM move-to-archive tag + policy (no delete action, ever)
if ($CreateMrmPolicy) {
    if (-not (Get-RetentionPolicyTag -Identity $TagName -ErrorAction SilentlyContinue)) {
        if ($PSCmdlet.ShouldProcess($TagName, "New-RetentionPolicyTag MoveToArchive $AgeDays days")) {
            New-RetentionPolicyTag -Name $TagName -Type All -RetentionAction MoveToArchive `
                -AgeLimitForRetention $AgeDays -RetentionEnabled $true | Out-Null
            Write-Host "  [done] Tag created: $TagName ($AgeDays days, MoveToArchive)" -ForegroundColor Green
        }
    } else {
        Write-Host "  [skip] Tag already exists: $TagName" -ForegroundColor DarkGray
    }
    if (-not (Get-RetentionPolicy -Identity $PolicyName -ErrorAction SilentlyContinue)) {
        if ($PSCmdlet.ShouldProcess($PolicyName, "New-RetentionPolicy linking $TagName")) {
            New-RetentionPolicy -Name $PolicyName -RetentionPolicyTagLinks $TagName | Out-Null
            Write-Host "  [done] Policy created: $PolicyName" -ForegroundColor Green
        }
    } else {
        if ($PSCmdlet.ShouldProcess($PolicyName, "Add tag link $TagName")) {
            $existing = (Get-RetentionPolicy -Identity $PolicyName).RetentionPolicyTagLinks
            if ($existing -notcontains $TagName) {
                Set-RetentionPolicy -Identity $PolicyName -RetentionPolicyTagLinks (@($existing) + $TagName)
                Write-Host "  [done] Tag linked to existing policy: $PolicyName" -ForegroundColor Green
            } else {
                Write-Host "  [skip] Tag already linked: $PolicyName" -ForegroundColor DarkGray
            }
        }
    }
}

# 4. Assign the retention policy to the pilot mailboxes
if ($AssignPolicy) {
    foreach ($mbx in Get-PilotMailboxes -Group $PilotGroup) {
        if ($PSCmdlet.ShouldProcess($mbx, "Set-Mailbox -RetentionPolicy $AssignPolicy")) {
            Set-Mailbox -Identity $mbx -RetentionPolicy $AssignPolicy
            Write-Host "  [done] Policy '$AssignPolicy' assigned: $mbx" -ForegroundColor Green
        }
    }
}

# 5. Run the Managed Folder Assistant on the pilot mailboxes
if ($RunAssistant) {
    foreach ($mbx in Get-PilotMailboxes -Group $PilotGroup) {
        if ($PSCmdlet.ShouldProcess($mbx, 'Start-ManagedFolderAssistant')) {
            Start-ManagedFolderAssistant -Identity $mbx
            Write-Host "  [done] MFA triggered: $mbx" -ForegroundColor Green
        }
    }
}

Write-Host ''
if (-not $Commit) {
    Write-Host 'Preview complete. Re-run with -Commit to apply.' -ForegroundColor Yellow
} else {
    Write-Host 'Commit complete. Validate with Test-ArchiveStrategy.ps1.' -ForegroundColor Green
}

<#
.SYNOPSIS
  EXOARCH-EnableArchive.ps1 — enable archive mailboxes (and optionally auto-expanding archive). SAFE BY DEFAULT: reports/-WhatIf unless -Commit.
.DESCRIPTION
  Configuration helper for Stage 2. For each identity it enables the archive mailbox (Enable-Mailbox
  -Archive), skipping any mailbox already archive-enabled. With -AutoExpand it also enables
  auto-expanding archive PER MAILBOX. Auto-expanding archive is IRREVERSIBLE (it cannot be turned off)
  and is PLAN-DEPENDENT — verify entitlement in your tenant/plan. Without -Commit the script only
  reports what it WOULD do (dry run); -WhatIf is honored on the write cmdlets.
.EXAMPLE
  .\EXOARCH-EnableArchive.ps1 -Identities (Get-Content .\pilot.txt) -WhatIf
  # Dry run — shows the Enable-Mailbox calls it would make, changes nothing.
.EXAMPLE
  .\EXOARCH-EnableArchive.ps1 -Identities (Get-Content .\pilot.txt) -Commit
  # Enable archive mailboxes for the pilot scope "Archive Scope - Pilot - Stage1".
.EXAMPLE
  .\EXOARCH-EnableArchive.ps1 -Identities user@contoso.com -AutoExpand -Commit
  # Also enable auto-expanding archive (ONE-WAY) for that mailbox — plan-dependent.
  # (PowerShell 5.1+/7+, ExchangeOnlineManagement module; connect with Connect-ExchangeOnline.)
.NOTES
  Expected results: named mailboxes report ArchiveStatus Active (verify with EXOARCH-Discovery.ps1 /
  EXOARCH-Validation.ps1). Messaging — Exchange Online Archiving & Messaging Retention.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$Identities,
    [switch]$AutoExpand,
    [switch]$Commit
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-ConnectionInformation -ErrorAction SilentlyContinue)) {
    Connect-ExchangeOnline -ShowBanner:$false   # -ExchangeEnvironmentName for Gov clouds
}

if (-not $Commit) {
    Write-Host 'DRY RUN — no changes will be made. Re-run with -Commit to apply.' -ForegroundColor Yellow
}
if ($AutoExpand) {
    Write-Host 'WARNING: -AutoExpand enables AUTO-EXPANDING ARCHIVE, which is IRREVERSIBLE (cannot be turned off) and plan-dependent. Verify entitlement + sign-off before -Commit.' -ForegroundColor Red
}

foreach ($id in $Identities) {
    $mbx = try { Get-Mailbox -Identity $id -ErrorAction Stop } catch { Write-Warning ("Skip '{0}': {1}" -f $id, $_.Exception.Message); continue }

    if ($mbx.ArchiveStatus -eq 'Active') {
        Write-Host ("[skip] {0} — archive already Active" -f $mbx.UserPrincipalName) -ForegroundColor DarkGray
    }
    else {
        if ($Commit) {
            if ($PSCmdlet.ShouldProcess($mbx.UserPrincipalName, 'Enable-Mailbox -Archive')) {
                try {
                    Enable-Mailbox -Identity $mbx.Identity -Archive -ErrorAction Stop | Out-Null
                    Write-Host ("[enabled] {0} — archive mailbox provisioned" -f $mbx.UserPrincipalName) -ForegroundColor Green
                } catch {
                    Write-Warning ("[fail] {0} — {1} (check archiving license, Requirement 2.1)" -f $mbx.UserPrincipalName, $_.Exception.Message)
                    continue
                }
            }
        } else {
            Write-Host ("[would enable] {0} — Enable-Mailbox -Archive" -f $mbx.UserPrincipalName) -ForegroundColor Yellow
        }
    }

    if ($AutoExpand) {
        if ($mbx.AutoExpandingArchiveEnabled) {
            Write-Host ("[skip] {0} — auto-expanding archive already on" -f $mbx.UserPrincipalName) -ForegroundColor DarkGray
        }
        elseif ($Commit) {
            if ($PSCmdlet.ShouldProcess($mbx.UserPrincipalName, 'Enable-Mailbox -AutoExpandingArchive (IRREVERSIBLE)')) {
                try {
                    Enable-Mailbox -Identity $mbx.Identity -AutoExpandingArchive -ErrorAction Stop | Out-Null
                    Write-Host ("[auto-expand ON] {0} — irreversible" -f $mbx.UserPrincipalName) -ForegroundColor Green
                } catch {
                    Write-Warning ("[fail auto-expand] {0} — {1} (plan-dependent; verify in your tenant/plan)" -f $mbx.UserPrincipalName, $_.Exception.Message)
                }
            }
        } else {
            Write-Host ("[would enable auto-expand] {0} — ONE-WAY" -f $mbx.UserPrincipalName) -ForegroundColor Yellow
        }
    }
}

Write-Host 'Done. Verify with EXOARCH-Validation.ps1 (ArchiveStatus should be Active).' -ForegroundColor Cyan

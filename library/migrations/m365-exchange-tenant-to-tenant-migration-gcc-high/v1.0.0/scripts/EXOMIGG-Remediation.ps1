<#
.SYNOPSIS
    EXOMIGG-Remediation.ps1 — Safe fixes for common GCC High tenant-to-tenant migration blockers (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Applies well-scoped fixes for the recurring blockers documented in 06-troubleshooting.md: clearing a
        mismatched previous ExchangeGUID on a target MailUser, resetting a source object's default address to the
        initial *.onmicrosoft.us domain during domain release, and re-stamping a source ExchangeGUID onto a target
        MailUser. It is SAFE BY DEFAULT: it runs in -WhatIf mode and changes nothing until you pass -Execute.
        Placeholders use plain text like your-admin-upn and your-identity.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\EXOMIGG-Remediation.ps1 -AdminUpn your-admin-upn -Action ClearPreviousMailboxInfo -Identity your-identity
        Apply (explicit):
          powershell -ExecutionPolicy Bypass -File .\EXOMIGG-Remediation.ps1 -AdminUpn your-admin-upn -Action ClearPreviousMailboxInfo -Identity your-identity -Execute
        (Connects with -ExchangeEnvironmentName O365USGovGCCHigh)
    EXPECTED RESULTS
        In preview: a description of what WOULD change, and nothing is modified. With -Execute: the change is applied
        and re-read for confirmation. PASS = intended state reached; FAIL = error surfaced with the troubleshooting ref.
.NOTES
    White-label — the repeatable way. Connects to EXO US Gov endpoints. Change-capable but DEFAULTS to -WhatIf.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)] [string] $AdminUpn,
    [Parameter(Mandatory = $true)]
    [ValidateSet('ClearPreviousMailboxInfo','ResetDefaultAddressToInitial','StampExchangeGuid')]
    [string] $Action,
    [Parameter(Mandatory = $true)]  [string] $Identity,
    [Parameter(Mandatory = $false)] [string] $InitialDomain,     # e.g. your-tenant.onmicrosoft.us  (for ResetDefaultAddressToInitial)
    [Parameter(Mandatory = $false)] [string] $SourceExchangeGuid,# for StampExchangeGuid
    [Parameter(Mandatory = $false)] [switch] $Execute            # must be present to make changes; otherwise -WhatIf
)

$ErrorActionPreference = 'Stop'

# Default posture is -WhatIf. Only -Execute turns it off.
if (-not $Execute) {
    $WhatIfPreference = $true
    Write-Host "RUNNING IN PREVIEW (-WhatIf) MODE — no changes will be made. Re-run with -Execute to apply." -ForegroundColor Yellow
} else {
    Write-Host "EXECUTE MODE — changes WILL be applied to '$Identity'." -ForegroundColor Red
}

Import-Module ExchangeOnlineManagement -ErrorAction Stop
try {
    Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh -UserPrincipalName $AdminUpn -ShowBanner:$false
} catch {
    Write-Host "FAIL: could not connect to GCC High Exchange Online (06-troubleshooting.md #1)." -ForegroundColor Red
    throw
}

switch ($Action) {

    'ClearPreviousMailboxInfo' {
        # Fixes: target gets a new empty mailbox due to mismatched previous ExchangeGUID (06-troubleshooting.md #4)
        Write-Host "Action: Set-User -PermanentlyClearPreviousMailboxInfo on '$Identity'" -ForegroundColor Cyan
        if ($PSCmdlet.ShouldProcess($Identity, "Set-User -PermanentlyClearPreviousMailboxInfo")) {
            Set-User -Identity $Identity -PermanentlyClearPreviousMailboxInfo -Confirm:$false
            Write-Host "Applied. Re-stamp the source ExchangeGUID next (Action StampExchangeGuid)." -ForegroundColor Green
        }
    }

    'ResetDefaultAddressToInitial' {
        # Fixes: domain won't release from source (06-troubleshooting.md #6). Sets primary to the *.onmicrosoft.us initial domain.
        if (-not $InitialDomain) { throw "InitialDomain is required (e.g. your-tenant.onmicrosoft.us)." }
        $local = (Get-Mailbox -Identity $Identity).Alias
        $newPrimary = "SMTP:$local@$InitialDomain"
        Write-Host "Action: set primary address of '$Identity' to $newPrimary" -ForegroundColor Cyan
        if ($PSCmdlet.ShouldProcess($Identity, "Set-Mailbox primary to $newPrimary")) {
            Set-Mailbox -Identity $Identity -EmailAddresses @{ Add = $newPrimary } -Confirm:$false
            Set-Mailbox -Identity $Identity -PrimarySmtpAddress "$local@$InitialDomain" -Confirm:$false
            Write-Host "Applied." -ForegroundColor Green
        }
    }

    'StampExchangeGuid' {
        # Prepares target MailUser to accept the move rather than provisioning a new mailbox (03-implementation.md Step 7A)
        if (-not $SourceExchangeGuid) { throw "SourceExchangeGuid is required (from the source mailbox)." }
        Write-Host "Action: stamp ExchangeGuid $SourceExchangeGuid onto MailUser '$Identity'" -ForegroundColor Cyan
        if ($PSCmdlet.ShouldProcess($Identity, "Set-MailUser -ExchangeGuid $SourceExchangeGuid")) {
            Set-MailUser -Identity $Identity -ExchangeGuid $SourceExchangeGuid -Confirm:$false
            Write-Host "Applied. Do NOT license this MailUser until after the GUID/proxies are confirmed (R3)." -ForegroundColor Green
        }
    }
}

# Confirmation read-back (best effort)
try {
    $obj = Get-Recipient -Identity $Identity -ErrorAction SilentlyContinue
    if ($obj) { $obj | Select-Object DisplayName, PrimarySmtpAddress, RecipientTypeDetails | Format-List }
} catch { }

Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue

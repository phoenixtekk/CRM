<#
.SYNOPSIS
  Enable or rotate Exchange Online DKIM signing for accepted domains — SAFE BY DEFAULT (dry-run /
  -WhatIf); makes changes only when -Commit is passed.
.DESCRIPTION
  For each target domain this reports the DKIM signing config, shows the exact Selector1/Selector2 CNAME
  targets to publish, and (with -Commit) enables signing (Set-DkimSigningConfig -Enabled $true) or, with
  -Rotate, triggers Rotate-DkimSigningConfig. Without -Commit it only previews the action (-WhatIf).
  No credentials are stored; connect first with Connect-ExchangeOnline.
.EXAMPLE
  .\Set-DkimSigning.ps1 -Domain contoso.com -WhatIf
  # dry-run: show the CNAME targets and the action that WOULD run, change nothing

.EXAMPLE
  .\Set-DkimSigning.ps1 -Domain contoso.com -Commit
  # enable DKIM signing (publish the shown CNAMEs in DNS first)

.EXAMPLE
  .\Set-DkimSigning.ps1 -Domain contoso.com -Rotate -Commit
  # rotate DKIM keys to the alternate selector
  (PowerShell 5.1+/7+, ExchangeOnlineManagement module; connect with Connect-ExchangeOnline)
.NOTES
  Expected results: with -WhatIf, "What if:" lines and the CNAME targets, no change. With -Commit,
  Get-DkimSigningConfig shows Enabled=True / Status=Valid after DNS propagates. PASS = Status : Valid.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)] [string[]] $Domain,
    [Parameter()] [switch] $Rotate,
    [Parameter()] [switch] $Commit,   # explicit apply gate; without it, dry-run only
    [Parameter()] [string] $ExchangeEnvironmentName = 'O365Default'
)

# Safe-by-default: unless -Commit is supplied, force -WhatIf behavior.
if (-not $Commit) { $WhatIfPreference = $true }

function Ensure-ExoConnected {
    param([string]$Environment)
    try { Get-AcceptedDomain -ErrorAction Stop | Out-Null; return }
    catch {
        Write-Host 'Connecting to Exchange Online...' -ForegroundColor Cyan
        Connect-ExchangeOnline -ExchangeEnvironmentName $Environment -ShowBanner:$false
    }
}

Ensure-ExoConnected -Environment $ExchangeEnvironmentName

foreach ($d in $Domain) {
    Write-Host "`n=== $d ===" -ForegroundColor Cyan
    $cfg = Get-DkimSigningConfig -Identity $d -ErrorAction SilentlyContinue

    if (-not $cfg) {
        Write-Host "No DKIM signing config exists for $d." -ForegroundColor Yellow
        if ($PSCmdlet.ShouldProcess($d, 'New-DkimSigningConfig -Enabled $true')) {
            $cfg = New-DkimSigningConfig -DomainName $d -Enabled $true -ErrorAction Stop
            Write-Host "Created DKIM signing config for $d." -ForegroundColor Green
        } else {
            Write-Host "[dry-run] Would create DKIM signing config for $d (generates CNAME targets)." -ForegroundColor DarkYellow
            continue
        }
    }

    Write-Host "Publish these two CNAME records in DNS for $d :" -ForegroundColor Cyan
    Write-Host ("  selector1._domainkey.$d  ->  {0}" -f $cfg.Selector1CNAME)
    Write-Host ("  selector2._domainkey.$d  ->  {0}" -f $cfg.Selector2CNAME)
    Write-Host ("  Current: Enabled={0}  Status={1}" -f $cfg.Enabled, $cfg.Status)

    if ($Rotate) {
        if ($PSCmdlet.ShouldProcess($d, 'Rotate-DkimSigningConfig')) {
            Rotate-DkimSigningConfig -Identity $d -ErrorAction Stop
            Write-Host "Rotated DKIM keys for $d." -ForegroundColor Green
        }
    }
    elseif (-not $cfg.Enabled) {
        if ($PSCmdlet.ShouldProcess($d, 'Set-DkimSigningConfig -Enabled $true')) {
            Set-DkimSigningConfig -Identity $d -Enabled $true -ErrorAction Stop
            Write-Host "Enabled DKIM signing for $d." -ForegroundColor Green
        }
    }
    else {
        Write-Host "DKIM already enabled for $d (Status=$($cfg.Status)). Nothing to do." -ForegroundColor Green
    }
}

if (-not $Commit) {
    Write-Host "`nDRY-RUN complete (no changes made). Re-run with -Commit to apply." -ForegroundColor Yellow
}

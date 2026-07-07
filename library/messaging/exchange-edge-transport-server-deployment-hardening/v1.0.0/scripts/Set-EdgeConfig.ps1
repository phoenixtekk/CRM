<#
.SYNOPSIS
  EdgeSync / connector setup helper — reports current state and stages changes with -WhatIf (safe by default).
.DESCRIPTION
  Assists the EdgeSync + connector configuration step. By default it is REPORT-ONLY: it shows the
  Edge Subscription, EdgeSync-created connectors, accepted domains, and (optionally) a designed
  partner mutual-TLS Send connector — and prints exactly what it WOULD create. Nothing is changed
  unless you pass -Commit; even then every write honors -WhatIf (dry-run). Run in the Exchange
  Management Shell on the INTERNAL Mailbox/Transport server (connectors/accepted domains are managed
  internally and replicate to the Edge via EdgeSync).
.EXAMPLE
  .\Set-EdgeConfig.ps1 -WhatIf
  # Report current EdgeSync/connector state and show what a partner TLS connector WOULD create. No changes.
.EXAMPLE
  .\Set-EdgeConfig.ps1 -PartnerDomain partner.example -Commit -WhatIf
  # Dry-run the create of 'Send - Partner TLS - Prod'; drop -WhatIf only to actually apply.
  (Exchange Management Shell on the internal Mailbox server; run Start-/Test-EdgeSynchronization after subscribing.)
.NOTES
  Expected results: a state report plus, when -PartnerDomain is given, the exact New-SendConnector it
  would run. Safe default = report-only; -Commit without -WhatIf is the only path that writes.
  Verify -TlsAuthLevel and all connector parameters for your Exchange version/CU.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$PartnerDomain,
    [string]$PartnerConnectorName = 'Send - Partner TLS - Prod',
    [switch]$Commit
)

if (-not (Get-Command Get-EdgeSubscription -ErrorAction SilentlyContinue)) {
    Write-Error 'Exchange Management Shell not detected. Run this on an internal Exchange Mailbox/Transport server.'
    return
}

Write-Host "Edge configuration helper — report-only unless -Commit is passed`n" -ForegroundColor Cyan

# --- Report: Edge Subscription ---
Write-Host '== Edge Subscription ==' -ForegroundColor Cyan
try { Get-EdgeSubscription -ErrorAction Stop | Format-Table Name, Site, Domain -AutoSize }
catch { Write-Warning $_.Exception.Message }

# --- Report: EdgeSync health ---
Write-Host '== EdgeSync status ==' -ForegroundColor Cyan
try { Test-EdgeSynchronization -ErrorAction Stop | Format-List Name, SyncStatus, LastSynchronized }
catch { Write-Warning "Test-EdgeSynchronization: $($_.Exception.Message)" }

# --- Report: connectors that EdgeSync auto-creates / manages ---
Write-Host '== Send connectors (EdgeSync-managed internet connector expected) ==' -ForegroundColor Cyan
try { Get-SendConnector -ErrorAction Stop | Format-Table Name, AddressSpaces, DNSRoutingEnabled, TlsAuthLevel, Enabled -AutoSize }
catch { Write-Warning $_.Exception.Message }

Write-Host '== Accepted domains (managed internally, replicate to Edge) ==' -ForegroundColor Cyan
try { Get-AcceptedDomain -ErrorAction Stop | Format-Table Name, DomainName, DomainType, Default -AutoSize }
catch { Write-Warning $_.Exception.Message }

# --- Optional: stage a designed partner mutual-TLS Send connector ---
if ($PartnerDomain) {
    $existing = Get-SendConnector -ErrorAction SilentlyContinue | Where-Object Name -eq $PartnerConnectorName
    if ($existing) {
        Write-Host "`nPartner connector '$PartnerConnectorName' already exists — no action." -ForegroundColor Green
        $existing | Format-List Name, AddressSpaces, TlsAuthLevel, Enabled
    }
    else {
        Write-Host "`nWould create partner mutual-TLS Send connector:" -ForegroundColor Yellow
        Write-Host "  New-SendConnector -Name '$PartnerConnectorName' -AddressSpaces '$PartnerDomain`:1' -DNSRoutingEnabled `$true -TlsAuthLevel DomainValidation -Enabled `$true"
        Write-Host "  (Verify -TlsAuthLevel / forced-TLS parameters for your Exchange version.)" -ForegroundColor DarkGray
        if ($Commit) {
            if ($PSCmdlet.ShouldProcess($PartnerConnectorName, "New-SendConnector for $PartnerDomain")) {
                New-SendConnector -Name $PartnerConnectorName -AddressSpaces "$PartnerDomain`:1" `
                    -DNSRoutingEnabled $true -TlsAuthLevel DomainValidation -Enabled $true
                Write-Host "Created '$PartnerConnectorName'. Run Start-EdgeSynchronization to replicate to the Edge." -ForegroundColor Green
            }
        }
        else {
            Write-Host 'Report-only (no -Commit). Re-run with -Commit -WhatIf to dry-run, then -Commit to apply.' -ForegroundColor DarkGray
        }
    }
}
else {
    Write-Host "`nTip: pass -PartnerDomain <domain> to stage a partner mutual-TLS Send connector." -ForegroundColor DarkGray
}

Write-Host "`nReminder: after any internal connector/accepted-domain change, run Start-EdgeSynchronization then Test-EdgeSynchronization (expect Normal = Gate B)." -ForegroundColor Yellow

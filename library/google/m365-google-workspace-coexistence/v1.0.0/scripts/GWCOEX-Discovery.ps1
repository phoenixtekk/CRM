<#
.SYNOPSIS
    GWCOEX-Discovery.ps1 — Coexistence-readiness discovery for M365 ↔ Google Workspace.
.DESCRIPTION
    PURPOSE
        Build the coexistence-readiness baseline from the Microsoft 365 side and the
        public DNS of the shared domain. Exports accepted-domain types (authoritative
        vs internal-relay), inbound/outbound connectors, mail contacts / mail users
        that represent Google-hosted recipients, and the domain's MX / SPF / DKIM /
        DMARC. This is the rollback baseline referenced by the runbook. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWCOEX-Discovery.ps1 -SharedDomain your-domain.com -OutputFolder .\discovery
        (Exchange Online module for mail flow; Microsoft Graph SDK optional for recipients.)
        Graph scopes if -UseGraph: Organization.Read.All, Directory.Read.All
    EXPECTED RESULTS
        Timestamped CSV/TXT files: accepted-domains, connectors, mail-contacts, and a
        dns-auth summary, plus a console readiness summary. PASS = accepted-domain type,
        connectors, and DNS auth are all captured for the shared domain. No changes made.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $SharedDomain,
    [string] $OutputFolder = ".\discovery",
    [string] $UserPrincipalName,
    [switch] $UseGraph      # also enumerate mail contacts/users via Microsoft Graph
)

$ErrorActionPreference = 'Stop'

function Connect-Exo {
    param([string] $Upn)
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        throw "ExchangeOnlineManagement module not found. Run: Install-Module ExchangeOnlineManagement"
    }
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    if (-not (Get-ConnectionInformation -ErrorAction SilentlyContinue)) {
        Write-Host "Connecting to Exchange Online..." -ForegroundColor Cyan
        if ($Upn) { Connect-ExchangeOnline -UserPrincipalName $Upn -ShowBanner:$false }
        else      { Connect-ExchangeOnline -ShowBanner:$false }
    }
}

function Resolve-DnsSafe {
    param([string] $Name, [string] $Type)
    try { return Resolve-DnsName -Name $Name -Type $Type -ErrorAction Stop } catch { return $null }
}

try {
    Connect-Exo -Upn $UserPrincipalName
    if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

    # ---- Accepted domains (authoritative vs internal relay) -------------------
    Write-Host "Enumerating accepted domains..." -ForegroundColor Cyan
    $accepted = Get-AcceptedDomain | Select-Object DomainName, DomainType, Default
    $accepted | Export-Csv (Join-Path $OutputFolder "accepted-domains-$stamp.csv") -NoTypeInformation -Encoding UTF8
    $sharedType = ($accepted | Where-Object { $_.DomainName -eq $SharedDomain }).DomainType

    # ---- Connectors (inbound + outbound) -------------------------------------
    Write-Host "Enumerating mail-flow connectors..." -ForegroundColor Cyan
    $connRows = @()
    $connRows += Get-OutboundConnector -ErrorAction SilentlyContinue |
        Select-Object @{n='Direction';e={'Outbound'}}, Name, Enabled,
                      @{n='SmartHosts';e={ ($_.SmartHosts) -join ';' }},
                      @{n='Recipient';e={ ($_.RecipientDomains) -join ';' }}, TlsSettings
    $connRows += Get-InboundConnector -ErrorAction SilentlyContinue |
        Select-Object @{n='Direction';e={'Inbound'}}, Name, Enabled,
                      @{n='SmartHosts';e={ ($_.SenderDomains) -join ';' }},
                      @{n='Recipient';e={''}}, @{n='TlsSettings';e={ $_.TlsSenderCertificateName }}
    $connRows | Export-Csv (Join-Path $OutputFolder "connectors-$stamp.csv") -NoTypeInformation -Encoding UTF8

    # ---- Mail contacts / mail users (Google-side representation) --------------
    Write-Host "Enumerating mail contacts / mail users..." -ForegroundColor Cyan
    $contacts = @()
    $contacts += Get-MailContact -ResultSize Unlimited -ErrorAction SilentlyContinue |
        Select-Object @{n='Type';e={'MailContact'}}, DisplayName, PrimarySmtpAddress, ExternalEmailAddress
    $contacts += Get-MailUser -ResultSize Unlimited -ErrorAction SilentlyContinue |
        Select-Object @{n='Type';e={'MailUser'}}, DisplayName, PrimarySmtpAddress, ExternalEmailAddress
    $contacts | Export-Csv (Join-Path $OutputFolder "mail-contacts-$stamp.csv") -NoTypeInformation -Encoding UTF8

    # ---- Optional Graph recipient count --------------------------------------
    if ($UseGraph) {
        try {
            Import-Module Microsoft.Graph.Users -ErrorAction Stop
            if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'Directory.Read.All','Organization.Read.All' -NoWelcome }
            $userCount = (Get-MgUser -All -ConsistencyLevel eventual -CountVariable c -Property Id | Measure-Object).Count
            Write-Host ("Graph user objects: {0}" -f $userCount) -ForegroundColor DarkCyan
        } catch { Write-Warning "Graph enumeration skipped: $_" }
    }

    # ---- DNS: MX / SPF / DKIM / DMARC ----------------------------------------
    Write-Host "Reading public DNS (MX / SPF / DKIM / DMARC) for $SharedDomain..." -ForegroundColor Cyan
    $mx    = Resolve-DnsSafe -Name $SharedDomain -Type MX
    $txt   = Resolve-DnsSafe -Name $SharedDomain -Type TXT
    $spf   = ($txt.Strings | Where-Object { $_ -like 'v=spf1*' }) -join ' '
    $dmarc = (Resolve-DnsSafe -Name "_dmarc.$SharedDomain" -Type TXT).Strings -join ' '
    $googleDkim = Resolve-DnsSafe -Name "google._domainkey.$SharedDomain" -Type TXT
    $m365Sel1   = Resolve-DnsSafe -Name "selector1._domainkey.$SharedDomain" -Type CNAME

    $mxPrimary = ($mx | Sort-Object Preference | Select-Object -First 1).NameExchange
    $mxIsGoogle = $mxPrimary -like '*google*'
    $mxIsM365   = $mxPrimary -like '*mail.protection.outlook.com'

    $dnsSummary = @(
        "Shared domain            : $SharedDomain"
        "Accepted-domain type     : $sharedType"
        "MX primary               : $mxPrimary"
        ("MX-primary platform      : {0}" -f ($(if ($mxIsGoogle) {'Google'} elseif ($mxIsM365) {'Microsoft 365'} else {'other/unknown — verify'})))
        "SPF                      : $spf"
        ("SPF authorizes Google    : {0}" -f ($spf -like '*_spf.google.com*'))
        ("SPF authorizes M365      : {0}" -f ($spf -like '*spf.protection.outlook.com*'))
        ("DKIM google selector     : {0}" -f ($(if ($googleDkim) {'present'} else {'MISSING'})))
        ("DKIM M365 selector1      : {0}" -f ($(if ($m365Sel1) {'present'} else {'MISSING'})))
        "DMARC                    : $dmarc"
    )
    $dnsSummary | Set-Content -Path (Join-Path $OutputFolder "dns-auth-$stamp.txt") -Encoding UTF8

    # ---- Summary -------------------------------------------------------------
    Write-Host ""
    Write-Host "==== COEXISTENCE READINESS SUMMARY ====" -ForegroundColor Green
    $dnsSummary | ForEach-Object { Write-Host "  $_" }
    Write-Host ("  Outbound connectors      : {0}" -f (($connRows | Where-Object Direction -eq 'Outbound') | Measure-Object).Count)
    Write-Host ("  Mail contacts / users    : {0}" -f ($contacts | Measure-Object).Count)
    if ($sharedType -ne 'InternalRelay') {
        Write-Host "  NOTE: shared domain is '$sharedType' — set to Internal relay before split delivery." -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "Baseline written to: $OutputFolder  (keep as rollback baseline)" -ForegroundColor Green
}
finally {
    if (Get-ConnectionInformation -ErrorAction SilentlyContinue) {
        Disconnect-ExchangeOnline -Confirm:$false | Out-Null
    }
}

<#
.SYNOPSIS
  Read-only discovery of Exchange Online / hybrid mail-flow topology: accepted domains (+ type),
  connectors (+ type/source), transport rules, remote domains, hybrid state, and public MX.
.DESCRIPTION
  Captures the current mail-flow baseline so routing changes are made against documented reality.
  Enumerates accepted domains and their DomainType (authoritative / internal relay / external relay),
  inbound/outbound connectors with their ConnectorType and ConnectorSource (HybridWizard vs manual),
  transport (mail-flow) rules, remote domains, the on-premises organization / hybrid config, and
  resolves public MX for each accepted domain. Makes NO changes. Run this before any implementation
  step and save the report as the baseline ("MailFlow Baseline - Tenant - Prod").
.EXAMPLE
  .\Invoke-MailFlowDiscovery.ps1 -OutputPath .\baseline   # read-only; writes a CSV/JSON report set
  (PowerShell 5.1+/7+, ExchangeOnlineManagement module; connect with Connect-ExchangeOnline)
.NOTES
  Expected results: a summary table on screen plus report files under -OutputPath. Any accepted domain
  that is Authoritative while recipients may live elsewhere is flagged as a silent-NDR risk to review.
#>

[CmdletBinding()]
param(
    [string]$OutputPath = ".\mailflow-discovery",
    [string]$AdminUpn
)

$ErrorActionPreference = 'Stop'

function Confirm-ExoConnected {
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        throw "ExchangeOnlineManagement (EXO V3) module not found. Install-Module ExchangeOnlineManagement."
    }
    try { Get-OrganizationConfig -ErrorAction Stop | Out-Null }
    catch {
        Write-Host "Not connected. Connecting with modern auth (no stored credentials)..." -ForegroundColor Yellow
        if ($AdminUpn) { Connect-ExchangeOnline -UserPrincipalName $AdminUpn -ShowBanner:$false }
        else { Connect-ExchangeOnline -ShowBanner:$false }
    }
}

Confirm-ExoConnected
if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath | Out-Null }

Write-Host "== Mail-flow discovery (read-only) ==" -ForegroundColor Cyan

# Accepted domains + type
$accepted = Get-AcceptedDomain | Select-Object Name, DomainName, DomainType, Default, MatchSubDomains
$accepted | Export-Csv (Join-Path $OutputPath 'accepted-domains.csv') -NoTypeInformation
Write-Host "`nAccepted domains:" -ForegroundColor Green
$accepted | Format-Table -AutoSize

# Connectors
$inbound  = Get-InboundConnector  | Select-Object Name, Enabled, ConnectorType, ConnectorSource, RequireTls, TlsSenderCertificateName, SenderIPAddresses, SenderDomains
$outbound = Get-OutboundConnector | Select-Object Name, Enabled, ConnectorType, ConnectorSource, RecipientDomains, SmartHosts, TlsSettings, TlsDomain
$inbound  | Export-Csv (Join-Path $OutputPath 'inbound-connectors.csv')  -NoTypeInformation
$outbound | Export-Csv (Join-Path $OutputPath 'outbound-connectors.csv') -NoTypeInformation
Write-Host "`nInbound connectors:"  -ForegroundColor Green; $inbound  | Format-Table Name, ConnectorType, ConnectorSource, RequireTls -AutoSize
Write-Host "Outbound connectors:"   -ForegroundColor Green; $outbound | Format-Table Name, ConnectorType, ConnectorSource, TlsSettings -AutoSize

# Transport (mail-flow) rules
$rules = Get-TransportRule | Select-Object Name, State, Priority, Mode, Description
$rules | Export-Csv (Join-Path $OutputPath 'transport-rules.csv') -NoTypeInformation
Write-Host "`nTransport rules:" -ForegroundColor Green; $rules | Format-Table Name, State, Priority -AutoSize

# Remote domains
Get-RemoteDomain | Select-Object Name, DomainName, IsInternal |
    Export-Csv (Join-Path $OutputPath 'remote-domains.csv') -NoTypeInformation

# Hybrid / on-prem organization state (present only in hybrid tenants)
try {
    $onprem = Get-OnPremisesOrganization -ErrorAction Stop |
        Select-Object Identity, HybridDomains, OrganizationRelationship
    $onprem | Export-Csv (Join-Path $OutputPath 'onpremises-organization.csv') -NoTypeInformation
    Write-Host "`nHybrid on-premises organization detected." -ForegroundColor Green
} catch {
    Write-Host "`nNo on-premises organization object found (pure-cloud tenant, or run HCW checks on-prem)." -ForegroundColor DarkYellow
}

# Public MX per accepted domain
Write-Host "`nResolving public MX for each accepted domain..." -ForegroundColor Cyan
$mx = foreach ($d in $accepted.DomainName) {
    try {
        Resolve-DnsName -Name $d -Type MX -ErrorAction Stop |
            Where-Object { $_.QueryType -eq 'MX' } |
            Select-Object @{n='Domain';e={$d}}, @{n='MX';e={$_.NameExchange}}, @{n='Pref';e={$_.Preference}}
    } catch {
        [pscustomobject]@{ Domain = $d; MX = "(lookup failed)"; Pref = $null }
    }
}
$mx | Export-Csv (Join-Path $OutputPath 'mx-records.csv') -NoTypeInformation
$mx | Format-Table -AutoSize

# Flag potential silent-NDR risks: authoritative domains (operator must confirm all recipients are in EXO)
$authRisk = $accepted | Where-Object { $_.DomainType -eq 'Authoritative' }
if ($authRisk) {
    Write-Host "`n[REVIEW] Authoritative domains below NDR unknown recipients. Confirm ALL recipients live in Exchange Online;" -ForegroundColor Yellow
    Write-Host "         if any are still on-prem/partner, this domain likely should be InternalRelay:" -ForegroundColor Yellow
    $authRisk | Format-Table Name, DomainName, DomainType -AutoSize
}

Write-Host "`nDiscovery complete. Baseline written to '$OutputPath'." -ForegroundColor Cyan

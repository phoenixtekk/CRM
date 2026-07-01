<#
.SYNOPSIS
    EXOMIG-Set-Coexistence.ps1 - Create the mail-flow coexistence connectors (and,
    optionally, the routing-domain accepted domain) for an Exchange Online
    tenant-to-tenant migration. Supports -WhatIf.

    PURPOSE:
        Stand up coexistence so mail reaches the correct mailbox while both tenants
        hold copies of users during the migration. Creates, on the side you connect to:
          - "Coexistence - Source->Target Connector"  (run against SOURCE, -Side Source)
          - "Coexistence - Target->Source Connector"  (run against TARGET, -Side Target)
        and optionally adds the routing/coexistence accepted domain.

        Run it twice - once per side - signing in to the matching tenant each time.

    HOW TO RUN:
        Preview the source-side connector:
            .\EXOMIG-Set-Coexistence.ps1 -Side Source -PartnerDomain target.onmicrosoft.com `
                -SmartHost target-com.mail.protection.outlook.com -WhatIf
        Create the target-side connector and add a routing accepted domain:
            .\EXOMIG-Set-Coexistence.ps1 -Side Target -PartnerDomain source.onmicrosoft.com `
                -SmartHost source-com.mail.protection.outlook.com `
                -AddRoutingDomain -RoutingDomain contoso-target.onmicrosoft.com

    EXPECTED RESULTS:
        The named connector exists (and the routing domain is accepted, if requested)
        on the connected tenant. With -WhatIf, only the intended actions are shown.

.NOTES
    Azure Solutions - creates mail-flow objects; supports -WhatIf for preview.
#>

[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory)][ValidateSet('Source','Target')][string] $Side,
    [Parameter(Mandatory)][string] $PartnerDomain,     # the OTHER tenant's domain mail is relayed to
    [Parameter(Mandatory)][string] $SmartHost,         # the OTHER tenant's MX endpoint (*-com.mail.protection.outlook.com)
    [string] $Upn,
    [switch] $AddRoutingDomain,
    [string] $RoutingDomain
)

$ErrorActionPreference = 'Stop'

$connectorName = if ($Side -eq 'Source') { 'Coexistence - Source->Target Connector' }
                 else                    { 'Coexistence - Target->Source Connector' }

Import-Module ExchangeOnlineManagement -ErrorAction Stop
Write-Host "Connecting to $Side tenant..." -ForegroundColor Cyan
if ($Upn) { Connect-ExchangeOnline -UserPrincipalName $Upn -ShowBanner:$false }
else      { Connect-ExchangeOnline -ShowBanner:$false }

try {
    # ---- Optional: routing/coexistence accepted domain -----------------------
    if ($AddRoutingDomain) {
        if (-not $RoutingDomain) { throw "-AddRoutingDomain requires -RoutingDomain." }
        $existing = Get-AcceptedDomain -ErrorAction SilentlyContinue | Where-Object DomainName -eq $RoutingDomain
        if ($existing) {
            Write-Host "Accepted domain '$RoutingDomain' already present - skipping." -ForegroundColor Yellow
        } elseif ($PSCmdlet.ShouldProcess($RoutingDomain, "Add internal-relay accepted domain")) {
            New-AcceptedDomain -Name $RoutingDomain -DomainName $RoutingDomain -DomainType InternalRelay | Out-Null
            Write-Host "Added accepted domain: $RoutingDomain" -ForegroundColor Green
        }
    }

    # ---- Coexistence outbound connector --------------------------------------
    $existingConn = Get-OutboundConnector -ErrorAction SilentlyContinue | Where-Object Name -eq $connectorName
    if ($existingConn) {
        Write-Host "Connector '$connectorName' already exists - skipping creation." -ForegroundColor Yellow
    } elseif ($PSCmdlet.ShouldProcess($connectorName, "Create outbound connector to $PartnerDomain via $SmartHost")) {
        New-OutboundConnector `
            -Name $connectorName `
            -ConnectorType Partner `
            -RecipientDomains $PartnerDomain `
            -SmartHosts $SmartHost `
            -TlsSettings DomainValidation `
            -UseMXRecord $false `
            -Comment "Created for Exchange Online tenant-to-tenant migration coexistence." `
            -Enabled $true | Out-Null
        Write-Host "Created connector: $connectorName  (-> $PartnerDomain via $SmartHost)" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "Coexistence setup for the $Side side complete." -ForegroundColor Green
    Write-Host "Remember to run this script again on the other side with -Side $(if($Side -eq 'Source'){'Target'}else{'Source'})." -ForegroundColor Cyan
}
finally {
    Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
}

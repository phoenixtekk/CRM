<#
.SYNOPSIS
  Create/adjust mail-flow artifacts (accepted-domain type, partner connectors, transport rule) with a
  SAFE default: dry-run/-WhatIf unless -Commit is passed. Exports a rollback baseline before any change.
.DESCRIPTION
  Configuration/remediation helper for the named artifacts in this solution. Supports three scoped
  actions selected by switch: set an accepted domain's DomainType (e.g. InternalRelay during
  coexistence), create a partner inbound/outbound connector with required TLS, or create a named
  transport (mail-flow) rule. Nothing is changed unless -Commit is supplied; -WhatIf previews the exact
  cmdlet. Before committing, the current state of the target object is exported for rollback. Never
  hand-edit HCW hybrid connectors with this tool (re-run HCW instead). No credentials are stored.
.EXAMPLE
  .\Set-MailFlowConfiguration.ps1 -SetAcceptedDomainType -Domain contoso.com -DomainType InternalRelay -WhatIf
  .\Set-MailFlowConfiguration.ps1 -PartnerConnector -PartnerDomain partner.example -TlsCertName "mail.partner.example" -Commit
  (PowerShell 5.1+/7+, ExchangeOnlineManagement module; connect with Connect-ExchangeOnline)
.NOTES
  Expected results: with no -Commit, prints the intended change only (safe). With -Commit, exports a
  rollback file under -BackupPath then applies the change and prints the resulting object.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    # Action selectors
    [switch]$SetAcceptedDomainType,
    [switch]$PartnerConnector,
    [switch]$TransportRule,

    # Accepted-domain-type params
    [string]$Domain,
    [ValidateSet('Authoritative','InternalRelay','ExternalRelay')]
    [string]$DomainType = 'InternalRelay',

    # Partner-connector params
    [string]$PartnerDomain,
    [string]$TlsCertName,          # cert subject for inbound validation / outbound domain validation
    [string[]]$SenderIPAddresses,  # alternative: authenticate partner by IP
    [string[]]$SmartHosts,         # outbound partner smart host(s)

    # Transport-rule params
    [string]$RuleName = 'Transport Rule - Partner TLS - Prod',
    [string]$RuleSenderDomainIs,
    [string]$RuleSetHeaderName,
    [string]$RuleSetHeaderValue,
    [int]$RulePriority = 0,

    # Safety / plumbing
    [switch]$Commit,
    [string]$BackupPath = ".\mailflow-config-backup",
    [string]$AdminUpn
)

$ErrorActionPreference = 'Stop'

function Confirm-ExoConnected {
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        throw "ExchangeOnlineManagement (EXO V3) module not found. Install-Module ExchangeOnlineManagement."
    }
    try { Get-OrganizationConfig -ErrorAction Stop | Out-Null }
    catch {
        Write-Host "Connecting with modern auth (no stored credentials)..." -ForegroundColor Yellow
        if ($AdminUpn) { Connect-ExchangeOnline -UserPrincipalName $AdminUpn -ShowBanner:$false }
        else { Connect-ExchangeOnline -ShowBanner:$false }
    }
}

function Save-Rollback {
    param([string]$Name, [object]$Object)
    if (-not (Test-Path $BackupPath)) { New-Item -ItemType Directory -Path $BackupPath | Out-Null }
    $file = Join-Path $BackupPath ("rollback-{0}-{1}.json" -f ($Name -replace '[^\w\-]','_'), (Get-Date -Format 'yyyyMMdd-HHmmss'))
    $Object | ConvertTo-Json -Depth 6 | Out-File $file -Encoding UTF8
    Write-Host "Rollback baseline saved: $file" -ForegroundColor DarkCyan
}

Confirm-ExoConnected

if (-not $Commit) {
    Write-Host "DRY-RUN mode (no -Commit): changes are previewed only. Add -Commit to apply." -ForegroundColor Yellow
}

# --- Action 1: accepted-domain type -----------------------------------------
if ($SetAcceptedDomainType) {
    if (-not $Domain) { throw "-Domain is required for -SetAcceptedDomainType." }
    $current = Get-AcceptedDomain -Identity $Domain
    Write-Host ("Accepted domain '{0}' current type: {1} -> target: {2}" -f $Domain, $current.DomainType, $DomainType) -ForegroundColor Cyan
    if ($Commit) {
        if ($PSCmdlet.ShouldProcess($Domain, "Set-AcceptedDomain DomainType=$DomainType")) {
            Save-Rollback -Name "accepteddomain-$Domain" -Object $current
            Set-AcceptedDomain -Identity $Domain -DomainType $DomainType
            Get-AcceptedDomain -Identity $Domain | Format-List Name, DomainName, DomainType
        }
    } else {
        Set-AcceptedDomain -Identity $Domain -DomainType $DomainType -WhatIf
    }
}

# --- Action 2: partner connectors -------------------------------------------
if ($PartnerConnector) {
    if (-not $PartnerDomain) { throw "-PartnerDomain is required for -PartnerConnector." }
    $inName  = 'Inbound Connector - Partner - Prod'
    $outName = 'Outbound Connector - Partner - Prod'

    # Inbound partner connector (require TLS by cert subject, or restrict by IP)
    $inParams = @{ Name = $inName; ConnectorType = 'Partner'; SenderDomains = $PartnerDomain; RequireTls = $true }
    if ($TlsCertName)       { $inParams['TlsSenderCertificateName'] = $TlsCertName }
    if ($SenderIPAddresses) { $inParams['SenderIPAddresses'] = $SenderIPAddresses; $inParams['RestrictDomainsToIPAddresses'] = $true }

    Write-Host "Inbound partner connector '$inName' for domain '$PartnerDomain' (RequireTls=`$true)" -ForegroundColor Cyan
    if ($Commit) {
        if ($PSCmdlet.ShouldProcess($inName, "New-InboundConnector")) {
            New-InboundConnector @inParams | Format-List Name, ConnectorType, RequireTls, TlsSenderCertificateName
        }
    } else {
        New-InboundConnector @inParams -WhatIf
    }

    # Outbound partner connector (only if a smart host was supplied)
    if ($SmartHosts) {
        $outParams = @{ Name = $outName; ConnectorType = 'Partner'; RecipientDomains = $PartnerDomain
                        SmartHosts = $SmartHosts; TlsSettings = 'DomainValidation'; UseMXRecord = $false }
        if ($TlsCertName) { $outParams['TlsDomain'] = $TlsCertName }
        Write-Host "Outbound partner connector '$outName' -> smart host(s): $($SmartHosts -join ', ')" -ForegroundColor Cyan
        if ($Commit) {
            if ($PSCmdlet.ShouldProcess($outName, "New-OutboundConnector")) {
                New-OutboundConnector @outParams | Format-List Name, ConnectorType, SmartHosts, TlsSettings
            }
        } else {
            New-OutboundConnector @outParams -WhatIf
        }
    }
}

# --- Action 3: transport (mail-flow) rule -----------------------------------
if ($TransportRule) {
    if (-not $RuleSenderDomainIs) { throw "-RuleSenderDomainIs is required for -TransportRule (scope the rule)." }
    $ruleParams = @{ Name = $RuleName; SenderDomainIs = $RuleSenderDomainIs; Priority = $RulePriority }
    if ($RuleSetHeaderName -and $RuleSetHeaderValue) {
        $ruleParams['SetHeaderName']  = $RuleSetHeaderName
        $ruleParams['SetHeaderValue'] = $RuleSetHeaderValue
    }
    Write-Host "Transport rule '$RuleName' (SenderDomainIs=$RuleSenderDomainIs, Priority=$RulePriority)" -ForegroundColor Cyan
    Write-Host "Reminder: scope tightly and avoid mutual redirects (loop risk)." -ForegroundColor DarkYellow
    if ($Commit) {
        if ($PSCmdlet.ShouldProcess($RuleName, "New-TransportRule")) {
            New-TransportRule @ruleParams | Format-List Name, State, Priority
        }
    } else {
        New-TransportRule @ruleParams -WhatIf
    }
}

if (-not ($SetAcceptedDomainType -or $PartnerConnector -or $TransportRule)) {
    Write-Host "No action switch supplied. Use -SetAcceptedDomainType, -PartnerConnector, or -TransportRule." -ForegroundColor Yellow
}

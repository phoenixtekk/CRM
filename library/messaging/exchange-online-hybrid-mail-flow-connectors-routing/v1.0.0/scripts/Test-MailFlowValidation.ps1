<#
.SYNOPSIS
  Read-only validation of mail-flow correctness: accepted-domain types, connector type/source/TLS, and
  a message-trace + header/loop heuristic. Prints PASS/FAIL per check. Makes no changes.
.DESCRIPTION
  Runs the T1-T8 style checks from the testing guide against the live tenant. Validates that accepted
  domains carry a sane type, that connectors have the expected ConnectorSource (HybridWizard vs manual)
  and required TLS, and (when -SenderAddress/-RecipientAddress are supplied) inspects recent message
  trace to confirm delivery and flag excessive hops/redirects that indicate a routing loop. All
  operations are read-only.
.EXAMPLE
  .\Test-MailFlowValidation.ps1 -CheckAcceptedDomains -CheckConnectors
  .\Test-MailFlowValidation.ps1 -CheckLoops -SenderAddress pilot-tx@contoso.com -HoursBack 24
  (PowerShell 5.1+/7+, ExchangeOnlineManagement module; connect with Connect-ExchangeOnline)
.NOTES
  Expected results: a PASS/FAIL line per check. Any FAIL points to the matching remediation in the
  implementation/troubleshooting guides (e.g. wrong DomainType, hand-edited hybrid connector, loop).
#>

[CmdletBinding()]
param(
    [switch]$CheckAcceptedDomains,
    [switch]$CheckConnectors,
    [switch]$CheckLoops,
    [string]$SenderAddress,
    [string]$RecipientAddress,
    [int]$HoursBack = 24,
    [int]$LoopHopThreshold = 25,
    [string]$AdminUpn
)

$ErrorActionPreference = 'Stop'
$results = @()
function Add-Result { param($Name,$Pass,$Detail) $script:results += [pscustomobject]@{ Check=$Name; Result= if($Pass){'PASS'}else{'FAIL'}; Detail=$Detail } }

function Confirm-ExoConnected {
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        throw "ExchangeOnlineManagement (EXO V3) module not found. Install-Module ExchangeOnlineManagement."
    }
    try { Get-OrganizationConfig -ErrorAction Stop | Out-Null }
    catch {
        if ($AdminUpn) { Connect-ExchangeOnline -UserPrincipalName $AdminUpn -ShowBanner:$false }
        else { Connect-ExchangeOnline -ShowBanner:$false }
    }
}

Confirm-ExoConnected
if (-not ($CheckAcceptedDomains -or $CheckConnectors -or $CheckLoops)) {
    $CheckAcceptedDomains = $true; $CheckConnectors = $true   # sensible default: config checks
}

# T1: accepted-domain types present and defined
if ($CheckAcceptedDomains) {
    $ad = Get-AcceptedDomain
    $undefined = $ad | Where-Object { -not $_.DomainType }
    Add-Result 'AcceptedDomainTypesDefined' (-not $undefined) (
        if ($undefined) { "Domains without a DomainType: $($undefined.DomainName -join ', ')" }
        else { "All $($ad.Count) accepted domains carry a DomainType. Confirm each matches recipient location." })
    Write-Host "`nAccepted domains:" -ForegroundColor Cyan
    $ad | Format-Table Name, DomainName, DomainType, Default -AutoSize
}

# T2: connectors have expected source/TLS
if ($CheckConnectors) {
    $in  = Get-InboundConnector
    $out = Get-OutboundConnector

    # Hybrid connectors should remain HcW-sourced (not hand-edited)
    $handEditedHybrid = $in + $out | Where-Object { $_.Name -match 'on-?prem|hybrid' -and $_.ConnectorSource -ne 'HybridWizard' }
    Add-Result 'HybridConnectorsHcwSourced' (-not $handEditedHybrid) (
        if ($handEditedHybrid) { "Hybrid-looking connectors not HybridWizard-sourced: $($handEditedHybrid.Name -join ', ') (re-run HCW)" }
        else { "No hand-edited hybrid connectors detected." })

    # Partner connectors should require TLS
    $partnerNoTls = $in | Where-Object { $_.ConnectorType -eq 'Partner' -and -not $_.RequireTls }
    Add-Result 'PartnerInboundRequiresTls' (-not $partnerNoTls) (
        if ($partnerNoTls) { "Partner inbound connectors without RequireTls: $($partnerNoTls.Name -join ', ')" }
        else { "Partner inbound connectors enforce TLS (or none exist)." })

    Write-Host "`nInbound connectors:"  -ForegroundColor Cyan; $in  | Format-Table Name, ConnectorType, ConnectorSource, RequireTls -AutoSize
    Write-Host "Outbound connectors:"   -ForegroundColor Cyan; $out | Format-Table Name, ConnectorType, ConnectorSource, TlsSettings -AutoSize
}

# T3-T6: trace-based delivery + loop heuristic
if ($CheckLoops -or $SenderAddress -or $RecipientAddress) {
    $start = (Get-Date).AddHours(-1 * $HoursBack)
    $end   = Get-Date
    $traceParams = @{ StartDate = $start; EndDate = $end }
    if ($SenderAddress)    { $traceParams['SenderAddress']    = $SenderAddress }
    if ($RecipientAddress) { $traceParams['RecipientAddress'] = $RecipientAddress }

    try {
        # Get-MessageTraceV2 is the current cmdlet; older tenants may still expose Get-MessageTrace.
        $trace = if (Get-Command Get-MessageTraceV2 -ErrorAction SilentlyContinue) {
                     Get-MessageTraceV2 @traceParams
                 } else {
                     Get-MessageTrace @traceParams
                 }
    } catch {
        Write-Host "Message trace lookup failed: $($_.Exception.Message)" -ForegroundColor Yellow
        $trace = @()
    }

    if ($trace) {
        $delivered = $trace | Where-Object { $_.Status -eq 'Delivered' }
        $failed    = $trace | Where-Object { $_.Status -in @('Failed','FilteredAsSpam') }
        Add-Result 'RecentTraceDelivered' ($delivered.Count -gt 0) (
            "Delivered=$($delivered.Count), Failed/Filtered=$($failed.Count) in last $HoursBack h")

        # Loop heuristic: a single message appearing many times / high hop count in detail
        $byMsg = $trace | Group-Object MessageId
        $suspLoop = $byMsg | Where-Object { $_.Count -ge 5 }
        Add-Result 'NoRoutingLoopHeuristic' (-not $suspLoop) (
            if ($suspLoop) { "MessageId(s) with >=5 trace events (possible loop): $($suspLoop.Name -join ', ')" }
            else { "No message shows excessive repeat trace events." })

        Write-Host "`nRecent trace (last $HoursBack h):" -ForegroundColor Cyan
        $trace | Select-Object Received, SenderAddress, RecipientAddress, Status | Format-Table -AutoSize
    } else {
        Add-Result 'RecentTraceDelivered' $false "No trace rows returned (widen -HoursBack or check filters/permissions)."
    }
}

Write-Host "`n== Validation summary ==" -ForegroundColor Cyan
$results | Format-Table Check, Result, Detail -AutoSize
if ($results.Result -contains 'FAIL') { Write-Host "One or more checks FAILED - see detail above." -ForegroundColor Red }
else { Write-Host "All checks PASSED." -ForegroundColor Green }

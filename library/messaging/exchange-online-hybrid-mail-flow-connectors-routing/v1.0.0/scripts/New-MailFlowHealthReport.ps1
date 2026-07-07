<#
.SYNOPSIS
  Read-only mail-flow health report: consolidates accepted domains, connectors, transport rules, and a
  recent trace summary into an HTML + CSV report for review against the approved design/baseline.
.DESCRIPTION
  Produces an operator-facing health report of the current mail-flow configuration so drift from the
  approved design (a new connector, a changed DomainType, a hand-edited hybrid connector, an unexpected
  transport rule) is easy to spot. Optionally summarizes recent message-trace delivery statistics. All
  read-only; makes no changes. Run after each pilot/expansion step and archive with the change record.
.EXAMPLE
  .\New-MailFlowHealthReport.ps1 -OutputPath .\report
  .\New-MailFlowHealthReport.ps1 -OutputPath .\report -IncludeTraceSummary -HoursBack 24
  (PowerShell 5.1+/7+, ExchangeOnlineManagement module; connect with Connect-ExchangeOnline)
.NOTES
  Expected results: report.html + supporting CSVs under -OutputPath summarizing every mail-flow artifact
  plus warnings for likely-misconfigured items (authoritative shared domains, non-HCW hybrid connectors,
  partner connectors without TLS).
#>

[CmdletBinding()]
param(
    [string]$OutputPath = ".\mailflow-health-report",
    [switch]$IncludeTraceSummary,
    [int]$HoursBack = 24,
    [string]$AdminUpn
)

$ErrorActionPreference = 'Stop'

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
if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath | Out-Null }

$accepted = Get-AcceptedDomain | Select-Object Name, DomainName, DomainType, Default
$inbound  = Get-InboundConnector  | Select-Object Name, Enabled, ConnectorType, ConnectorSource, RequireTls
$outbound = Get-OutboundConnector | Select-Object Name, Enabled, ConnectorType, ConnectorSource, TlsSettings
$rules    = Get-TransportRule | Select-Object Name, State, Priority

$accepted | Export-Csv (Join-Path $OutputPath 'accepted-domains.csv') -NoTypeInformation
$inbound  | Export-Csv (Join-Path $OutputPath 'inbound-connectors.csv') -NoTypeInformation
$outbound | Export-Csv (Join-Path $OutputPath 'outbound-connectors.csv') -NoTypeInformation
$rules    | Export-Csv (Join-Path $OutputPath 'transport-rules.csv') -NoTypeInformation

# Warnings (design-drift heuristics)
$warnings = New-Object System.Collections.Generic.List[string]
foreach ($d in ($accepted | Where-Object { $_.DomainType -eq 'Authoritative' })) {
    $warnings.Add("Authoritative domain '$($d.DomainName)' NDRs unknown recipients - confirm all recipients are in EXO.")
}
foreach ($c in ($inbound + $outbound | Where-Object { $_.Name -match 'on-?prem|hybrid' -and $_.ConnectorSource -ne 'HybridWizard' })) {
    $warnings.Add("Hybrid-looking connector '$($c.Name)' is not HybridWizard-sourced - possible manual edit; re-run HCW.")
}
foreach ($c in ($inbound | Where-Object { $_.ConnectorType -eq 'Partner' -and -not $_.RequireTls })) {
    $warnings.Add("Partner inbound connector '$($c.Name)' does not require TLS.")
}

$traceSummaryHtml = ""
if ($IncludeTraceSummary) {
    try {
        $tp = @{ StartDate = (Get-Date).AddHours(-1*$HoursBack); EndDate = (Get-Date) }
        $trace = if (Get-Command Get-MessageTraceV2 -ErrorAction SilentlyContinue) { Get-MessageTraceV2 @tp } else { Get-MessageTrace @tp }
        $summary = $trace | Group-Object Status | Select-Object Name, Count
        $summary | Export-Csv (Join-Path $OutputPath 'trace-summary.csv') -NoTypeInformation
        $traceSummaryHtml = ($summary | ConvertTo-Html -Fragment -PreContent "<h2>Message trace summary (last $HoursBack h)</h2>") -join "`n"
    } catch {
        $traceSummaryHtml = "<h2>Message trace summary</h2><p>Trace lookup failed: $($_.Exception.Message)</p>"
    }
}

$style = "<style>body{font-family:Segoe UI,Arial,sans-serif;margin:24px} table{border-collapse:collapse;margin-bottom:20px} th,td{border:1px solid #ccc;padding:6px 10px;font-size:13px} th{background:#f2f2f2;text-align:left} .warn{color:#a00}</style>"
$warnHtml = if ($warnings.Count) { "<h2 class='warn'>Warnings</h2><ul>" + ($warnings | ForEach-Object { "<li class='warn'>$_</li>" }) -join "" + "</ul>" } else { "<h2>Warnings</h2><p>None.</p>" }

$html = @()
$html += "<html><head><title>Mail-Flow Health Report</title>$style</head><body>"
$html += "<h1>Mail-Flow Health Report</h1><p>Generated: $(Get-Date -Format u)</p>"
$html += $warnHtml
$html += ($accepted | ConvertTo-Html -Fragment -PreContent "<h2>Accepted domains</h2>")
$html += ($inbound  | ConvertTo-Html -Fragment -PreContent "<h2>Inbound connectors</h2>")
$html += ($outbound | ConvertTo-Html -Fragment -PreContent "<h2>Outbound connectors</h2>")
$html += ($rules    | ConvertTo-Html -Fragment -PreContent "<h2>Transport rules</h2>")
$html += $traceSummaryHtml
$html += "</body></html>"

$reportFile = Join-Path $OutputPath 'report.html'
$html -join "`n" | Out-File $reportFile -Encoding UTF8

Write-Host "Health report written: $reportFile" -ForegroundColor Green
if ($warnings.Count) {
    Write-Host "`n$($warnings.Count) warning(s):" -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
} else {
    Write-Host "No warnings." -ForegroundColor Green
}

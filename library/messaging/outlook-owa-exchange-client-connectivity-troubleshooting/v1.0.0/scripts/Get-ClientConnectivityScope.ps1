<#
.SYNOPSIS
  Read-only scope/health helper: assess client-connectivity across a set of users and bucket the
  result to answer "how big is the blast radius" (node D0 of the Diagnostic Playbook).
.DESCRIPTION
  Runs a lightweight Get-CASMailbox protocol check across the supplied users (or an input CSV),
  buckets each as OK / Protocol-disabled / Not-found, and summarizes whether a fault looks
  per-mailbox (few affected) or systemic (many affected) so the technician enters the tree at the
  right layer. Optionally emits a CSV report for trend tracking. Purely read-only.
.EXAMPLE
  .\Get-ClientConnectivityScope.ps1 -Identity u1@contoso.com,u2@contoso.com
  # Scope check across two users.
.EXAMPLE
  .\Get-ClientConnectivityScope.ps1 -InputCsv .\users.csv -ReportPath .\scope-report.csv
  (PowerShell 5.1+/7+, ExchangeOnlineManagement module; connect with Connect-ExchangeOnline.
   InputCsv must have a 'PrimarySmtpAddress' or 'Identity' column.)
.NOTES
  Expected results: a per-user table plus a summary line (e.g. "12/50 affected"). A high affected
  ratio flags a systemic DNS/CA/service cause (skip client work); a single affected user flags a
  per-mailbox cause. This is a triage signal, not a full protocol test (use script #1 for that).
#>

[CmdletBinding(DefaultParameterSetName = 'List')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'List')]
    [string[]]$Identity,

    [Parameter(Mandatory = $true, ParameterSetName = 'Csv')]
    [string]$InputCsv,

    [Parameter()]
    [string]$ReportPath
)

function Ensure-ExoConnected {
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        throw "ExchangeOnlineManagement (EXO V3) module not found. Install-Module ExchangeOnlineManagement."
    }
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    try { Get-ConnectionInformation -ErrorAction Stop | Out-Null }
    catch {
        Write-Host "Connecting to Exchange Online (modern auth)..." -ForegroundColor Cyan
        Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop
    }
}

# Resolve the user list
$users = @()
if ($PSCmdlet.ParameterSetName -eq 'Csv') {
    if (-not (Test-Path $InputCsv)) { throw "InputCsv not found: $InputCsv" }
    $rows = Import-Csv -Path $InputCsv
    $users = $rows | ForEach-Object {
        if ($_.PSObject.Properties.Name -contains 'PrimarySmtpAddress') { $_.PrimarySmtpAddress }
        elseif ($_.PSObject.Properties.Name -contains 'Identity') { $_.Identity }
    } | Where-Object { $_ }
}
else { $users = $Identity }

if (-not $users) { throw "No users to assess." }

Ensure-ExoConnected

$rows = foreach ($u in $users) {
    try {
        $cas = Get-CASMailbox -Identity $u -ErrorAction Stop
        $disabled = @()
        if (-not $cas.MapiEnabled)       { $disabled += 'MAPI' }
        if (-not $cas.EwsEnabled)        { $disabled += 'EWS' }
        if (-not $cas.OWAEnabled)        { $disabled += 'OWA' }
        if (-not $cas.ActiveSyncEnabled) { $disabled += 'ActiveSync' }
        [pscustomobject]@{
            Identity        = $u
            Bucket          = if ($disabled.Count -eq 0) { 'OK' } else { 'Protocol-disabled' }
            DisabledProtocols = ($disabled -join ',')
        }
    }
    catch {
        [pscustomobject]@{ Identity = $u; Bucket = 'Not-found'; DisabledProtocols = $_.Exception.Message }
    }
}

$rows | Format-Table -AutoSize

$total    = $rows.Count
$affected = ($rows | Where-Object Bucket -ne 'OK').Count
$ratio    = if ($total) { [math]::Round(($affected / $total) * 100, 1) } else { 0 }

Write-Host ""
Write-Host "=== Scope summary ===" -ForegroundColor Cyan
Write-Host "Affected: $affected / $total  ($ratio%)"
if ($affected -eq 0)        { Write-Host "All OK - if a user still reports a fault, it is client-side (D4)." -ForegroundColor Green }
elseif ($affected -eq 1)    { Write-Host "Single user affected -> per-mailbox cause. Enter tree at D1->D2->D3." -ForegroundColor Yellow }
elseif ($ratio -ge 50)      { Write-Host "Widespread -> suspect systemic DNS/CA/service cause. Check D1(DNS) + D3(CA) + Service health; skip client work." -ForegroundColor Red }
else                        { Write-Host "Multiple but not all -> check for a shared attribute (site, plan, CA group)." -ForegroundColor Yellow }

if ($ReportPath) {
    $rows | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8
    Write-Host "Report written: $ReportPath" -ForegroundColor DarkGray
}

$rows

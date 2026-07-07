<#
.SYNOPSIS
  Read-only per-user Outlook/Exchange client-connectivity assessment (protocol enablement +
  server-side connectivity tests) compared against a known-good baseline mailbox.
.DESCRIPTION
  For each identity, reports Get-CASMailbox protocol enablement (MAPI/EWS/OWA/ActiveSync),
  the CAS mailbox plan defaults, and — where the cmdlets are available in your tenant/version —
  the results of Test-OutlookConnectivity and Test-OutlookWebServices. Purely read-only; makes
  no changes. Use it to populate the Protocol layer (D2) of the Diagnostic Playbook.
.EXAMPLE
  .\Get-ClientConnectivityAssessment.ps1 -Identity user@contoso.com
  # Assess one user against the default ConnTest baseline.
.EXAMPLE
  .\Get-ClientConnectivityAssessment.ps1 -Identity user@contoso.com -Baseline ConnTest@contoso.com
  (PowerShell 5.1+/7+, ExchangeOnlineManagement module; connect with Connect-ExchangeOnline)
.NOTES
  Expected results: one object per user showing each protocol True/False and PASS/FAIL for the
  connectivity tests; deviations from the baseline are the pass-fail signal for layer D2.
  Test-OutlookConnectivity / Test-OutlookWebServices availability is version-dependent — the
  script degrades gracefully (reports 'N/A - cmdlet unavailable') if a cmdlet is not present.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$Identity,

    [Parameter()]
    [string]$Baseline = 'ConnTest',

    [Parameter()]
    [switch]$IncludeConnectivityTests = $true
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

function Get-CasSnapshot {
    param([string]$Id)
    try {
        $cas = Get-CASMailbox -Identity $Id -ErrorAction Stop
        [pscustomobject]@{
            Identity        = $Id
            MapiEnabled     = $cas.MapiEnabled
            EwsEnabled      = $cas.EwsEnabled
            OWAEnabled      = $cas.OWAEnabled
            ActiveSyncEnabled = $cas.ActiveSyncEnabled
            PopEnabled      = $cas.PopEnabled
            ImapEnabled     = $cas.ImapEnabled
            Found           = $true
        }
    }
    catch {
        [pscustomobject]@{ Identity = $Id; Found = $false; Error = $_.Exception.Message }
    }
}

Ensure-ExoConnected

# Baseline snapshot (known-good reference)
$baselineSnap = Get-CasSnapshot -Id $Baseline
if ($baselineSnap.Found) {
    Write-Host "Baseline ($Baseline): MAPI=$($baselineSnap.MapiEnabled) EWS=$($baselineSnap.EwsEnabled) OWA=$($baselineSnap.OWAEnabled) EAS=$($baselineSnap.ActiveSyncEnabled)" -ForegroundColor Green
}
else {
    Write-Warning "Baseline mailbox '$Baseline' not found - comparison column will be blank."
}

$hasOutlookConn = [bool](Get-Command Test-OutlookConnectivity -ErrorAction SilentlyContinue)
$hasWebServices = [bool](Get-Command Test-OutlookWebServices -ErrorAction SilentlyContinue)

$results = foreach ($id in $Identity) {
    $snap = Get-CasSnapshot -Id $id
    if (-not $snap.Found) {
        Write-Warning "Mailbox '$id' not found: $($snap.Error)"
        continue
    }

    $outlookConn = 'Not run'
    $webServices = 'Not run'
    if ($IncludeConnectivityTests) {
        if ($hasOutlookConn) {
            try   { $r = Test-OutlookConnectivity -MailboxId $id -ErrorAction Stop
                    $outlookConn = ($r | Select-Object -First 1 -ExpandProperty Result -ErrorAction SilentlyContinue) }
            catch { $outlookConn = "FAIL: $($_.Exception.Message)" }
        } else { $outlookConn = 'N/A - cmdlet unavailable (verify version)' }

        if ($hasWebServices) {
            try   { $r = Test-OutlookWebServices -Identity $id -ErrorAction Stop
                    $webServices = ($r | Group-Object Result | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join '; ' }
            catch { $webServices = "FAIL: $($_.Exception.Message)" }
        } else { $webServices = 'N/A - cmdlet unavailable (verify version)' }
    }

    $matchesBaseline = if ($baselineSnap.Found) {
        ($snap.MapiEnabled -eq $baselineSnap.MapiEnabled) -and
        ($snap.EwsEnabled -eq $baselineSnap.EwsEnabled) -and
        ($snap.OWAEnabled -eq $baselineSnap.OWAEnabled) -and
        ($snap.ActiveSyncEnabled -eq $baselineSnap.ActiveSyncEnabled)
    } else { $null }

    [pscustomobject]@{
        Identity              = $snap.Identity
        MAPI                  = $snap.MapiEnabled
        EWS                   = $snap.EwsEnabled
        OWA                   = $snap.OWAEnabled
        ActiveSync            = $snap.ActiveSyncEnabled
        MatchesBaseline       = $matchesBaseline
        TestOutlookConnectivity = $outlookConn
        TestOutlookWebServices  = $webServices
    }
}

$results | Format-Table -AutoSize
$results

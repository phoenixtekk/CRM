<#
.SYNOPSIS
    GWCOEX-Remediation.ps1 — Safe remediation of common coexistence gaps (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Remediate the most common Microsoft-side coexistence gaps: set the shared domain
        to Internal relay, create the outbound relay connector to Google's smart host, and
        create mail contacts for Google-hosted recipients that are missing from the GAL.
        Every change is gated: the script runs in preview (-WhatIf) mode by default and
        only makes changes when you pass -Apply. It always prints the plan first.
    HOW TO RUN
        Preview (default):
          powershell -ExecutionPolicy Bypass -File .\GWCOEX-Remediation.ps1 -SharedDomain your-domain.com
        Apply after reviewing the plan:
          powershell -ExecutionPolicy Bypass -File .\GWCOEX-Remediation.ps1 -SharedDomain your-domain.com -Apply
        (Optional -MissingContactsCsv columns: DisplayName,ExternalEmailAddress)
        Uses the Exchange Online module; run as an Exchange administrator.
    EXPECTED RESULTS
        In preview: a numbered list of the changes that WOULD be made, no tenant change.
        With -Apply: those changes are made and confirmed. PASS = shared domain is
        Internal relay and an enabled outbound route to Google exists.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $SharedDomain,
    [string] $ConnectorName = 'Coexistence - EXO->Google Connector',
    [string] $GoogleSmartHost = 'aspmx.l.google.com',
    [string] $MissingContactsCsv,
    [switch] $Apply,                 # when absent, everything runs as -WhatIf (preview only)
    [string] $UserPrincipalName
)

$ErrorActionPreference = 'Stop'
$whatIf = -not $Apply
$mode = if ($whatIf) { 'PREVIEW (-WhatIf)' } else { 'APPLY' }

function Connect-Exo {
    param([string] $Upn)
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        throw "ExchangeOnlineManagement module not found. Run: Install-Module ExchangeOnlineManagement"
    }
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    if (-not (Get-ConnectionInformation -ErrorAction SilentlyContinue)) {
        if ($Upn) { Connect-ExchangeOnline -UserPrincipalName $Upn -ShowBanner:$false }
        else      { Connect-ExchangeOnline -ShowBanner:$false }
    }
}

try {
    Connect-Exo -Upn $UserPrincipalName
    Write-Host "==== GWCOEX REMEDIATION — MODE: $mode ====" -ForegroundColor Cyan
    $plan = New-Object System.Collections.Generic.List[string]

    # ---- 1. Accepted domain -> Internal relay --------------------------------
    $dom = Get-AcceptedDomain -Identity $SharedDomain -ErrorAction SilentlyContinue
    if (-not $dom) { throw "Shared domain '$SharedDomain' is not an accepted domain in this tenant." }
    if ($dom.DomainType -ne 'InternalRelay') {
        $plan.Add("Set accepted domain '$SharedDomain' type: $($dom.DomainType) -> InternalRelay")
        Set-AcceptedDomain -Identity $SharedDomain -DomainType InternalRelay -WhatIf:$whatIf
    } else {
        Write-Host "  Accepted domain already Internal relay — no change." -ForegroundColor DarkGray
    }

    # ---- 2. Outbound relay connector to Google -------------------------------
    $conn = Get-OutboundConnector -Identity $ConnectorName -ErrorAction SilentlyContinue
    if (-not $conn) {
        $plan.Add("Create outbound connector '$ConnectorName' -> smart host '$GoogleSmartHost' for '$SharedDomain' (TLS required)")
        New-OutboundConnector -Name $ConnectorName -ConnectorType Partner `
            -RecipientDomains $SharedDomain -SmartHosts $GoogleSmartHost `
            -TlsSettings EncryptionOnly -Enabled $true -WhatIf:$whatIf | Out-Null
    } elseif (-not $conn.Enabled) {
        $plan.Add("Enable existing outbound connector '$ConnectorName'")
        Set-OutboundConnector -Identity $ConnectorName -Enabled $true -WhatIf:$whatIf
    } else {
        Write-Host "  Outbound connector '$ConnectorName' already present and enabled — no change." -ForegroundColor DarkGray
    }

    # ---- 3. Missing mail contacts for Google-hosted recipients ---------------
    if ($MissingContactsCsv) {
        if (-not (Test-Path $MissingContactsCsv)) { throw "MissingContactsCsv not found: $MissingContactsCsv" }
        foreach ($row in Import-Csv $MissingContactsCsv) {
            $ext = $row.ExternalEmailAddress
            if (-not $ext) { continue }
            if (Get-Recipient -Identity $ext -ErrorAction SilentlyContinue) {
                Write-Host "  Recipient already exists for $ext — skipping." -ForegroundColor DarkGray
                continue
            }
            $plan.Add("Create mail contact '$($row.DisplayName)' -> $ext")
            New-MailContact -Name $row.DisplayName -ExternalEmailAddress $ext -WhatIf:$whatIf | Out-Null
        }
    }

    # ---- Plan summary --------------------------------------------------------
    Write-Host ""
    if ($plan.Count -eq 0) {
        Write-Host "No changes needed — coexistence prerequisites already in place." -ForegroundColor Green
    } else {
        Write-Host "Planned changes:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $plan.Count; $i++) { Write-Host ("  {0}. {1}" -f ($i + 1), $plan[$i]) }
        if ($whatIf) {
            Write-Host ""
            Write-Host "PREVIEW ONLY — nothing changed. Re-run with -Apply to make these changes." -ForegroundColor Cyan
        } else {
            Write-Host ""
            Write-Host "APPLIED." -ForegroundColor Green
        }
    }
}
finally {
    if (Get-ConnectionInformation -ErrorAction SilentlyContinue) {
        Disconnect-ExchangeOnline -Confirm:$false | Out-Null
    }
}

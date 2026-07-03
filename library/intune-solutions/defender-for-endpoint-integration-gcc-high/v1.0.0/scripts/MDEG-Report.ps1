<#
.SYNOPSIS
    MDEG-Report.ps1 — report device onboarding, machine risk, and Intune compliance on a GCC High tenant.
.DESCRIPTION
    PURPOSE
        Read-only reporting for your per-wave evidence record: lists managed Windows devices,
        their Intune compliance state, and (where surfaced) the Defender machine risk that
        drives compliance. Connects to the US Government Microsoft Graph. Pass -OutputCsv to
        keep an audit artifact; replace your-output-path only if you set it.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDEG-Report.ps1 -OutputCsv .\mde-gcc-high-report.csv
        (Graph scopes: DeviceManagementManagedDevices.Read.All; connects with -Environment USGov)
    EXPECTED RESULTS
        A per-device table (name, OS, compliance, risk) and a rollup summary. PASS = onboarded
        devices show a risk value and a compliance state consistent with your threshold.
        FAIL = no risk visible means the connector is off or risk is not wired into compliance
        (see 06-troubleshooting.md, D).
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string] $TenantId,
    [string] $OutputCsv
)

$ErrorActionPreference = 'Stop'

function Connect-UsGovGraph {
    param([string] $TenantId)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $p = @{ Environment = 'USGov'; Scopes = @('DeviceManagementManagedDevices.Read.All') }
    if ($TenantId) { $p.TenantId = $TenantId }
    Connect-MgGraph @p | Out-Null
    $ctx = Get-MgContext
    if ($ctx.Environment -ne 'USGov') {
        Write-Warning "Graph environment is '$($ctx.Environment)', not 'USGov'. On GCC High this is the wrong cloud."
    }
}

function Invoke-GovGraph {
    param([string] $RelativeUrl)
    Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.us/beta/{0}" -f $RelativeUrl) -ErrorAction Stop
}

try {
    Connect-UsGovGraph -TenantId $TenantId

    Write-Host "Collecting managed device + risk data (US Gov)..." -ForegroundColor Cyan
    # partnerReportedThreatState / exchangeAccessState surface risk-derived signals on managedDevice.
    $select = 'deviceName,operatingSystem,osVersion,complianceState,partnerReportedThreatState,lastSyncDateTime,azureADDeviceId'
    $md = Invoke-GovGraph ("deviceManagement/managedDevices?`$select={0}" -f $select)

    $rows = @($md.value) | Where-Object { $_.operatingSystem -match 'Windows' } | ForEach-Object {
        [pscustomobject]@{
            DeviceName          = $_.deviceName
            OS                  = $_.operatingSystem
            OSVersion           = $_.osVersion
            ComplianceState     = $_.complianceState
            MdeThreatState      = $_.partnerReportedThreatState   # secured / lowSeverity / mediumSeverity / highSeverity / unknown
            LastSync            = $_.lastSyncDateTime
            AadDeviceId         = $_.azureADDeviceId
        }
    }

    if (-not $rows) {
        Write-Warning "No Windows managed devices returned. Confirm US Gov cloud connection and that devices are enrolled (02-requirements.md R5)."
        return
    }

    Write-Host "`n=== MDE onboarding + risk + compliance (GCC High) ===" -ForegroundColor Yellow
    $rows | Sort-Object DeviceName | Format-Table -AutoSize

    $withRisk = @($rows | Where-Object { $_.MdeThreatState -and $_.MdeThreatState -ne 'unknown' })
    $noncompliant = @($rows | Where-Object { $_.ComplianceState -ne 'compliant' })

    Write-Host "`n=== Summary ===" -ForegroundColor Yellow
    Write-Host ("Windows devices reported       : {0}" -f $rows.Count)
    Write-Host ("Devices with an MDE risk signal: {0}" -f $withRisk.Count)
    Write-Host ("Noncompliant devices           : {0}" -f $noncompliant.Count)

    if ($withRisk.Count -eq 0) {
        Write-Warning "No device shows an MDE risk signal. If devices are onboarded in security.microsoft.us but risk is absent here, the connector may be off or risk is not wired into CP-Windows-MDE-Risk (06-troubleshooting.md, D)."
    }

    if ($OutputCsv) {
        $rows | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
        Write-Host ("`nSaved report to {0} (keep as your per-wave evidence record)." -f $OutputCsv) -ForegroundColor Green
    }
}
catch {
    Write-Error ("Reporting failed: {0}" -f $_.Exception.Message)
    Write-Host "If this is an authority error you may be on the Commercial cloud — Disconnect-MgGraph and retry (uses -Environment USGov)." -ForegroundColor Yellow
    exit 1
}
finally {
    if (Get-MgContext -ErrorAction SilentlyContinue) { Disconnect-MgGraph | Out-Null }
}

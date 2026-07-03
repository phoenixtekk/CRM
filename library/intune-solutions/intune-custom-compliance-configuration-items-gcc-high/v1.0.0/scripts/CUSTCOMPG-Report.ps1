<#
.SYNOPSIS
    CUSTCOMPG-Report.ps1 — Report per-device custom-compliance status for the GCC High policy via US Gov Graph.
.DESCRIPTION
    PURPOSE
        Read-only reporting for the Government (GCC High) edition of Intune Custom Compliance.
        Pulls the device compliance state for the named custom-compliance policy and writes a
        per-device summary (Compliant / NonCompliant / not evaluated) to the console and an
        optional CSV. 'Not evaluated' rows are highlighted because on GCC High they usually
        mean results never returned (commonly a TLS-inspecting proxy on manage.microsoft.us).
        Point -PolicyName at your policy, e.g. 'CUSTCOMPG-Compliance-Baseline'.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CUSTCOMPG-Report.ps1 -PolicyName "CUSTCOMPG-Compliance-Baseline" -CsvPath .\custcompg-report.csv
        (Graph scopes: DeviceManagementConfiguration.Read.All, DeviceManagementManagedDevices.Read.All; -Environment USGov)
    EXPECTED RESULTS
        A table of devices with their compliance state for the policy, plus counts. Pass = the
        expected devices report Compliant/NonCompliant; investigate any 'not evaluated' rows.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $PolicyName,
    [string] $CsvPath
)

$ErrorActionPreference = 'Stop'

function Connect-UsGovGraph {
    param([string[]] $Scopes)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph PowerShell SDK not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = Get-MgContext
    if (-not $ctx -or $ctx.Environment -ne 'USGov') {
        Write-Host "Connecting to Microsoft Graph US Gov (GCC High) — Environment USGov..." -ForegroundColor Cyan
        Connect-MgGraph -Environment USGov -Scopes $Scopes | Out-Null
    }
    if ((Get-MgContext).Environment -ne 'USGov') {
        throw "Connected environment is not 'USGov'. Reconnect with: Connect-MgGraph -Environment USGov"
    }
    Write-Host "Connected. Environment=USGov" -ForegroundColor Green
}

function Get-AllUsGov {
    param([string] $RelativeUri)
    $items = @()
    $uri = "https://graph.microsoft.us/beta/$RelativeUri"
    while ($uri) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $uri
        if ($resp.value) { $items += $resp.value }
        $uri = $resp.'@odata.nextLink'
    }
    return $items
}

Connect-UsGovGraph -Scopes @('DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All')

# Resolve the policy by display name
$policies = Get-AllUsGov -RelativeUri "deviceManagement/deviceCompliancePolicies"
$policy = $policies | Where-Object { $_.displayName -eq $PolicyName } | Select-Object -First 1
if (-not $policy) { throw "Compliance policy '$PolicyName' not found in the GCC High tenant." }
Write-Host "Policy '$PolicyName' id=$($policy.id)" -ForegroundColor Cyan

# Per-device status for this policy
$statuses = Get-AllUsGov -RelativeUri "deviceManagement/deviceCompliancePolicies/$($policy.id)/deviceStatuses"

$rows = foreach ($s in $statuses) {
    [pscustomobject]@{
        DeviceName = $s.deviceDisplayName
        User       = $s.userPrincipalName
        Status     = $s.status              # compliant / noncompliant / notApplicable / unknown / error / conflict
        LastReport = $s.lastReportedDateTime
    }
}

Write-Host "`n=== Custom compliance status — $PolicyName ===" -ForegroundColor Yellow
$rows | Sort-Object Status, DeviceName | Format-Table -AutoSize

$compliant    = ($rows | Where-Object Status -eq 'compliant').Count
$nonCompliant = ($rows | Where-Object Status -eq 'noncompliant').Count
$unevaluated  = ($rows | Where-Object { $_.Status -in @('unknown','notApplicable','error','conflict') }).Count

Write-Host ("`nSummary: Compliant={0}  NonCompliant={1}  NotEvaluated/Other={2}" -f $compliant,$nonCompliant,$unevaluated) -ForegroundColor Cyan
if ($unevaluated -gt 0) {
    Write-Host "  NOTE: $unevaluated device(s) not cleanly evaluated. On GCC High this often means results never" -ForegroundColor DarkYellow
    Write-Host "        returned — check for SSL inspection on *.manage.microsoft.us (see 06-troubleshooting.md)." -ForegroundColor DarkYellow
}

if ($CsvPath) {
    $rows | Sort-Object Status, DeviceName | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "CSV written to $CsvPath" -ForegroundColor Green
}

Write-Host "`nReport complete. This was read-only." -ForegroundColor Cyan

<#
.SYNOPSIS
    HYBIDG-Report.ps1 — read-only health/state report for hybrid identity on a GCC High tenant.
.DESCRIPTION
    PURPOSE
        Produces a shareable report of the hybrid identity state on a Microsoft 365 U.S. Government
        GCC High tenant: tenant/domain summary, directory-sync status and last sync time, sign-in
        method per domain, and synced-user counts. Read-only — no changes are made.
        Run it at the Validate gate, on a schedule, and after any change.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\HYBIDG-Report.ps1
        (Graph scopes: Directory.Read.All, Domain.Read.All, Organization.Read.All; -Environment USGov)
    EXPECTED RESULTS
        A text/CSV report saved to the output path plus an on-screen summary. Keep it with your
        change record. Green summary = healthy; investigate any warning lines.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [ValidateSet('USGov','USGovDoD')]
    [string]$Environment = 'USGov',

    [string]$OutputPath = ".\HYBIDG-Report.txt",
    [string]$CsvPath    = ".\HYBIDG-Report.csv"
)

$ErrorActionPreference = 'Stop'
$lines = New-Object System.Collections.Generic.List[string]
function Line { param([string]$t) $lines.Add($t); Write-Host $t }

Write-Host "=== HYBIDG Report (Government / GCC High) — Environment: $Environment ===" -ForegroundColor Cyan

try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Environment $Environment `
        -Scopes 'Directory.Read.All','Domain.Read.All','Organization.Read.All' -NoWelcome

    $ctx = Get-MgContext
    Line "Generated : $(Get-Date -Format 'u')"
    Line "Graph env : $($ctx.Environment)"
    Line "Tenant    : $($ctx.TenantId)"
    Line ""

    $org = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/organization').value[0]
    Line "Organization        : $($org.displayName)"
    Line "Sync enabled        : $($org.onPremisesSyncEnabled)"
    Line "Last on-prem sync   : $($org.onPremisesLastSyncDateTime)"
    Line ""

    Line "Domains:"
    $domains = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/domains').value
    foreach ($d in $domains) {
        Line ("  {0,-40} verified={1,-5} auth={2}" -f $d.id, $d.isVerified, $d.authenticationType)
    }
    Line ""

    # Synced vs cloud-only user counts (advanced query).
    $headers = @{ ConsistencyLevel = 'eventual' }
    $syncedResp = Invoke-MgGraphRequest -Method GET -Headers $headers `
        -Uri "/v1.0/users?`$count=true&`$filter=onPremisesSyncEnabled eq true&`$top=1"
    $syncedCount = $syncedResp.'@odata.count'
    $totalResp = Invoke-MgGraphRequest -Method GET -Headers $headers `
        -Uri "/v1.0/users?`$count=true&`$top=1"
    $totalCount = $totalResp.'@odata.count'
    Line "Users (total)       : $totalCount"
    Line "Users (synced)      : $syncedCount"
    Line "Users (cloud-only)  : $([int]$totalCount - [int]$syncedCount)"

    $summary = [pscustomobject]@{
        Generated       = (Get-Date -Format 'u')
        GraphEnvironment = $ctx.Environment
        TenantId        = $ctx.TenantId
        SyncEnabled     = $org.onPremisesSyncEnabled
        LastSync        = $org.onPremisesLastSyncDateTime
        UsersTotal      = $totalCount
        UsersSynced     = $syncedCount
        UsersCloudOnly  = ([int]$totalCount - [int]$syncedCount)
    }
    $summary | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8

    Disconnect-MgGraph | Out-Null
} catch {
    Line "ERROR: $($_.Exception.Message)"
    $lines | Out-File -FilePath $OutputPath -Encoding UTF8
    exit 1
}

$lines | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "`nReport written to $OutputPath and $CsvPath" -ForegroundColor Cyan
exit 0

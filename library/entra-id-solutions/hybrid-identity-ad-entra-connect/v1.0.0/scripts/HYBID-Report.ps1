<#
.SYNOPSIS
    HYBID-Report.ps1 — synchronization health and object-coverage report.
.DESCRIPTION
    PURPOSE
        Read-only report of hybrid-identity health and coverage. From ADSync it reports the
        connectors and the last run-profile results (errors/aborts). From Microsoft Graph it reports
        how many users are on-premises-synced vs. cloud-only, and how many devices are hybrid-joined,
        so you can confirm coverage before and after expansion.
    HOW TO RUN
        On the Connect host, elevated:
        powershell -ExecutionPolicy Bypass -File .\HYBID-Report.ps1
        ADSync cmdlets require the Microsoft Entra Connect role. The Graph section needs the Microsoft
        Graph SDK and Directory.Read.All / Device.Read.All.
    EXPECTED RESULTS
        Connector list, recent run results with any error counts, and synced vs. cloud-only user and
        hybrid-joined device counts. No changes are made.
.NOTES
    Workplace Marketplace — Entra ID Solutions. Read-only.
#>
[CmdletBinding()] param()

Write-Host "`n=== Hybrid Identity Report — $(Get-Date -Format s) ===" -ForegroundColor Cyan

# ADSync engine health
if (Get-Module -ListAvailable -Name ADSync) {
    Import-Module ADSync -ErrorAction Stop
    Write-Host "`n-- Connectors --" -ForegroundColor Cyan
    Get-ADSyncConnector | ForEach-Object { Write-Host ("  {0}  ({1})" -f $_.Name, $_.Type) }

    Write-Host "`n-- Recent run results --" -ForegroundColor Cyan
    $runs = Get-ADSyncRunProfileResult -NumberRequested 10 -ErrorAction SilentlyContinue
    foreach ($r in $runs) {
        $color = $(if ($r.Result -eq 'success') { 'Green' } else { 'Yellow' })
        Write-Host ("  {0,-22} {1,-26} {2}" -f $r.ConnectorName, $r.RunProfileName, $r.Result) -ForegroundColor $color
    }
    if (-not $runs) { Write-Host "  No run results found." -ForegroundColor Yellow }
} else {
    Write-Host "ADSync module not found — run on the Microsoft Entra Connect host for engine health." -ForegroundColor Yellow
}

# Tenant coverage via Graph
if (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication) {
    try {
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        Connect-MgGraph -Scopes 'Directory.Read.All', 'Device.Read.All' -NoWelcome
        function Count-Uri($uri) { (Invoke-MgGraphRequest -Method GET -Uri "$uri&`$count=true&`$top=1" -Headers @{ ConsistencyLevel = 'eventual' }).'@odata.count' }
        $synced = Count-Uri '/v1.0/users?$filter=onPremisesSyncEnabled eq true'
        $cloud  = Count-Uri '/v1.0/users?$filter=onPremisesSyncEnabled ne true'
        $hybrid = Count-Uri "/v1.0/devices?`$filter=trustType eq 'ServerAd'"
        Write-Host "`n-- Coverage --" -ForegroundColor Cyan
        Write-Host ("  Users synced from AD : {0}" -f $synced)
        Write-Host ("  Users cloud-only     : {0}" -f $cloud)
        Write-Host ("  Hybrid-joined devices: {0}" -f $hybrid)
        Disconnect-MgGraph | Out-Null
    } catch { Write-Host "Graph coverage skipped: $($_.Exception.Message)" -ForegroundColor Yellow }
} else {
    Write-Host "`nMicrosoft Graph SDK not present — skipping tenant coverage." -ForegroundColor Yellow
}

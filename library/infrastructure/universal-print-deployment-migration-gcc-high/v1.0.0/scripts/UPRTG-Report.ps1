<#
.SYNOPSIS
    UPRTG-Report.ps1 — read-only evidence report of Universal Print state on GCC High.
.DESCRIPTION
    PURPOSE
        Produces a dated HTML and CSV report of the Universal Print footprint on a GCC High
        tenant: printers, printer shares (with granted groups), and connectors. Read-only: it
        writes report files but changes no tenant state. Use it at the Validate gate for
        sign-off evidence and monthly for lifecycle review.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\UPRTG-Report.ps1
        (Graph scopes: Printer.Read.All, PrinterShare.Read.All, PrintConnector.Read.All; -Environment USGov)
        Optional: -OutputPath 'your-report-folder' (defaults to the current folder).
    EXPECTED RESULTS
        Sign-in opens login.microsoftonline.us. The script writes UPRTG-Report-<timestamp>.html
        and matching CSVs, and prints the output paths. Open the HTML for a readable snapshot.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string]$OutputPath = "."
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Warning "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    return
}

try {
    Connect-MgGraph -Environment USGov -Scopes "Printer.Read.All","PrinterShare.Read.All","PrintConnector.Read.All","Group.Read.All" -NoWelcome
    $ctx = Get-MgContext
    if ($ctx.Environment -ne 'USGov') { Write-Warning "Graph environment is '$($ctx.Environment)', not 'USGov' (GCC High)." }
    Write-Host "Connected as $($ctx.Account) ($($ctx.Environment))" -ForegroundColor Green
}
catch {
    Write-Warning "Graph sign-in failed: $($_.Exception.Message)"
    return
}

function Get-Value([string]$Uri) {
    try { return @((Invoke-MgGraphRequest -Method GET -Uri $Uri).value) } catch { return @() }
}

Write-Host "Collecting Universal Print state (GCC High)..." -ForegroundColor Yellow
$printers   = Get-Value "/v1.0/print/printers"
$shares     = Get-Value "/v1.0/print/shares"
$connectors = Get-Value "/v1.0/print/connectors"

# Build share-with-groups view
$shareRows = foreach ($s in $shares) {
    $groups = Get-Value ("/v1.0/print/shares/{0}/allowedGroups" -f $s.id)
    [pscustomobject]@{
        ShareName    = $s.displayName
        AllowedGroups = (($groups | ForEach-Object { $_.displayName }) -join '; ')
    }
}

$printerRows   = $printers   | Select-Object @{n='Printer';e={$_.displayName}}, @{n='Id';e={$_.id}}
$connectorRows = $connectors | Select-Object @{n='Connector';e={$_.displayName}}, @{n='Registered';e={$_.registeredDateTime}}

if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

# CSV outputs
$printerRows   | Export-Csv (Join-Path $OutputPath "UPRTG-Report-printers-$stamp.csv")   -NoTypeInformation
$shareRows     | Export-Csv (Join-Path $OutputPath "UPRTG-Report-shares-$stamp.csv")     -NoTypeInformation
$connectorRows | Export-Csv (Join-Path $OutputPath "UPRTG-Report-connectors-$stamp.csv") -NoTypeInformation

# HTML report
$style = @"
<style>
body{font-family:Segoe UI,Arial,sans-serif;margin:24px;color:#222}
h1{font-size:20px} h2{font-size:15px;margin-top:24px;border-bottom:1px solid #ccc;padding-bottom:4px}
table{border-collapse:collapse;width:100%;margin-top:8px} th,td{border:1px solid #ccc;padding:6px 8px;text-align:left;font-size:13px}
th{background:#f0f4f8} .meta{color:#555;font-size:12px}
</style>
"@
$header = "<h1>Universal Print — GCC High state report</h1>" +
          "<p class='meta'>Tenant account: $($ctx.Account) &middot; Graph environment: $($ctx.Environment) &middot; Generated: $(Get-Date -Format u)</p>" +
          "<p class='meta'>Printers: $($printers.Count) &middot; Shares: $($shares.Count) &middot; Connectors: $($connectors.Count)</p>"

$body  = $header
$body += "<h2>Printers</h2>"   + ($printerRows   | ConvertTo-Html -Fragment)
$body += "<h2>Shares & targeting</h2>" + ($shareRows | ConvertTo-Html -Fragment)
$body += "<h2>Connectors</h2>" + ($connectorRows | ConvertTo-Html -Fragment)

$htmlPath = Join-Path $OutputPath "UPRTG-Report-$stamp.html"
ConvertTo-Html -Head $style -Body $body | Out-File -FilePath $htmlPath -Encoding UTF8

Write-Host ""
Write-Host "Report written:" -ForegroundColor Green
Write-Host ("  HTML: {0}" -f $htmlPath)
Write-Host ("  CSVs: UPRTG-Report-printers/shares/connectors-{0}.csv in {1}" -f $stamp, $OutputPath)

Disconnect-MgGraph | Out-Null

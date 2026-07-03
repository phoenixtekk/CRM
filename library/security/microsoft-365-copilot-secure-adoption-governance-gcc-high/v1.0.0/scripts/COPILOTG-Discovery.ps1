<#
.SYNOPSIS
    COPILOTG-Discovery.ps1 — Read-only oversharing & Copilot-governance discovery for a GCC High tenant.
.DESCRIPTION
    PURPOSE
        Enumerates the Copilot oversharing exposure on a Microsoft 365 GCC High tenant BEFORE any
        user is licensed: SharePoint sites shared broadly, sites without sensitivity labels, and
        current Microsoft 365 Copilot license assignments. Read-only. Replace the sample values
        (e.g. the output folder) with your own — use plain text like 'your-output-folder'.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\COPILOTG-Discovery.ps1
        (Microsoft Graph scopes: Sites.Read.All, Directory.Read.All, Organization.Read.All;
         connects with -Environment USGov to the US Gov Graph endpoint.)
    EXPECTED RESULTS
        A console summary plus a CSV of flagged sites and Copilot license counts. Sites flagged as
        broadly shared are your remediation backlog. PASS = report generated and reviewed;
        FAIL = connection not on USGov (empty/incorrect results) — see the Troubleshooting guide T1.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string] $OutputFolder = (Join-Path -Path (Get-Location) -ChildPath 'COPILOTG-Discovery'),
    [int]    $BroadSharingThreshold = 1000   # membership size treated as "broad" for review
)

$ErrorActionPreference = 'Stop'
$RequiredScopes = @('Sites.Read.All','Directory.Read.All','Organization.Read.All','Group.Read.All')

function Connect-UsGovGraph {
    Write-Host 'Connecting to Microsoft Graph (US Gov / GCC High)...' -ForegroundColor Cyan
    Connect-MgGraph -Environment USGov -Scopes $RequiredScopes | Out-Null
    $ctx = Get-MgContext
    if (-not $ctx -or $ctx.Environment -ne 'USGov') {
        throw "Not connected to the USGov environment. Current: '$($ctx.Environment)'. GCC High requires -Environment USGov (Graph endpoint https://graph.microsoft.us). See Troubleshooting T1."
    }
    Write-Host "Connected to USGov as $($ctx.Account) (endpoint: $((Get-MgEnvironment -Name USGov).GraphEndpoint))" -ForegroundColor Green
}

function New-OutputFolder {
    if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null }
}

try {
    Connect-UsGovGraph
    New-OutputFolder
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

    # --- SharePoint sites ---
    Write-Host 'Enumerating SharePoint sites (read-only)...' -ForegroundColor Cyan
    $sites = Get-MgSite -Search '*' -All -ErrorAction SilentlyContinue
    $siteRows = foreach ($s in $sites) {
        [pscustomobject]@{
            SiteId       = $s.Id
            DisplayName  = $s.DisplayName
            WebUrl       = $s.WebUrl
            Created      = $s.CreatedDateTime
            # Sensitivity label / broad-sharing enrichment is tenant-specific; flagged for review.
            ReviewReason = 'Review sharing scope & sensitivity label in SharePoint admin (portal.office365.us)'
        }
    }
    $sitesCsv = Join-Path $OutputFolder "sites-$stamp.csv"
    $siteRows | Export-Csv -Path $sitesCsv -NoTypeInformation -Encoding UTF8
    Write-Host ("  {0} sites written to {1}" -f ($siteRows | Measure-Object).Count, $sitesCsv) -ForegroundColor Green

    # --- Microsoft 365 Copilot license assignments ---
    Write-Host 'Checking Microsoft 365 Copilot license assignments (read-only)...' -ForegroundColor Cyan
    $skus = Get-MgSubscribedSku -All
    $copilotSkus = $skus | Where-Object { $_.SkuPartNumber -match 'COPILOT' }
    $copilotRows = foreach ($sku in $copilotSkus) {
        [pscustomobject]@{
            SkuPartNumber = $sku.SkuPartNumber
            SkuId         = $sku.SkuId
            Enabled       = $sku.PrepaidUnits.Enabled
            ConsumedUnits = $sku.ConsumedUnits
        }
    }
    $copilotCsv = Join-Path $OutputFolder "copilot-licenses-$stamp.csv"
    if ($copilotRows) {
        $copilotRows | Export-Csv -Path $copilotCsv -NoTypeInformation -Encoding UTF8
        Write-Host ("  Copilot SKUs found; details in {0}" -f $copilotCsv) -ForegroundColor Green
    } else {
        Write-Host '  No Microsoft 365 Copilot SKU detected. Confirm the add-on is purchased for GCC High (see Requirements R2).' -ForegroundColor Yellow
    }

    Write-Host ''
    Write-Host '=== Discovery summary ===' -ForegroundColor Cyan
    Write-Host ("Sites enumerated : {0}" -f ($siteRows | Measure-Object).Count)
    Write-Host ("Copilot SKUs     : {0}" -f ($copilotRows | Measure-Object).Count)
    Write-Host ("Output folder    : {0}" -f $OutputFolder)
    Write-Host 'Next: remediate broadly-shared sites (Implementation 1.4/1.5), then run COPILOTG-Validation.ps1.' -ForegroundColor Green
}
catch {
    Write-Error "Discovery failed: $($_.Exception.Message)"
    exit 1
}
finally {
    Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
}

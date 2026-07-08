<#
.SYNOPSIS
    DLPASSESS-DataScan.ps1 — read-only sensitive-data discovery (data at rest) via Purview Content Explorer.
.DESCRIPTION
    PURPOSE
        Builds the data-at-rest half of the sensitive-data map: for each sensitive information type (or
        label) you name, it exports what Content Explorer has detected — item counts and locations
        across Exchange, SharePoint, OneDrive, and Teams. This is the evidence for "where does each
        sensitive-data category actually rest?" Read-only — uses Export-ContentExplorerData only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLPASSESS-DataScan.ps1 `
            -Tags 'Credit Card Number','U.S. Social Security Number (SSN)' -CsvPath .\DLPASSESS-DataMap.csv
        Requires Security & Compliance PowerShell (Connect-IPPSSession) AND the Content Explorer
        List/Content Viewer roles. Content Explorer is licensing-dependent — verify your tenant.
.EXAMPLE
    .\DLPASSESS-DataScan.ps1 -Tags 'Credit Card Number' -TagType SensitiveInformationType
    Reports where the Credit Card Number SIT is detected, per workload.
.EXAMPLE
    .\DLPASSESS-DataScan.ps1 -Tags 'Confidential' -TagType RetentionLabel -CsvPath .\map.csv
    Reports where the 'Confidential' label is applied and exports the map.
.NOTES
    Purview — Enterprise DLP Assessment & Strategy. Read-only. Requires Content Explorer viewer roles
    (they expose item content — grant deliberately). EXPECTED RESULTS: per-tag, per-workload item
    counts and a CSV data map. PASS signal: each candidate category resolves to a location profile, or
    is recorded as a detector gap (no matching SIT).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$Tags,

    [ValidateSet('SensitiveInformationType','RetentionLabel','Sensitivity')]
    [string]$TagType = 'SensitiveInformationType',

    [string]$CsvPath,
    [string]$UserPrincipalName,
    [int]$PageSize = 100
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Export-ContentExplorerData -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}
if (-not (Get-Command Export-ContentExplorerData -ErrorAction SilentlyContinue)) {
    Write-Host 'Export-ContentExplorerData is not available — confirm the Content Explorer viewer roles and licensing (verify your tenant).' -ForegroundColor Yellow
    return
}

Write-Host '=== Sensitive-data discovery: Content Explorer (data at rest, read-only) ===' -ForegroundColor Cyan
Write-Host ("TagType: {0}   Tags: {1}" -f $TagType, ($Tags -join ', ')) -ForegroundColor Cyan

$all = @()
foreach ($tag in $Tags) {
    Write-Host ("--- Scanning: {0} ---" -f $tag) -ForegroundColor Cyan
    $items = @()
    try {
        # Export-ContentExplorerData is paged; PageCookie drives the next page.
        $cookie = $null
        do {
            $resp = Export-ContentExplorerData -TagName $tag -TagType $TagType -PageSize $PageSize -PageCookie $cookie -ErrorAction Stop
            if ($resp) {
                $items += $resp
                # The cmdlet surfaces the continuation cookie on the returned objects; stop when absent.
                $cookie = ($resp | Select-Object -Last 1).PageCookie
            } else { $cookie = $null }
        } while ($cookie)
    } catch {
        Write-Host ("   Could not scan '{0}': {1}" -f $tag, $_.Exception.Message) -ForegroundColor Yellow
        Write-Host "   If this tag has no matching SIT, record it as a DETECTOR GAP for the roadmap." -ForegroundColor Yellow
        continue
    }

    if (-not $items -or $items.Count -eq 0) {
        Write-Host ("   No items detected for '{0}' (genuine zero, or not yet classified — note in the map)." -f $tag) -ForegroundColor Yellow
        continue
    }

    # Summarise by workload/location. Field names vary by tenant/version — fall back gracefully.
    $byWorkload = $items | Group-Object { $_.Workload } | Sort-Object Count -Descending
    $byWorkload | Select-Object @{n='Workload';e={ if ($_.Name) { $_.Name } else { '(unknown)' } }}, Count | Format-Table -AutoSize
    Write-Host ("   Total detected items for '{0}': {1}" -f $tag, $items.Count) -ForegroundColor Green

    foreach ($i in $items) {
        $all += [pscustomobject]@{
            Tag       = $tag
            TagType   = $TagType
            Workload  = $i.Workload
            Location  = $i.Location
            ItemName  = $i.Name
            Sensitive = $i.SensitiveInformationType
        }
    }
}

if ($CsvPath -and $all.Count -gt 0) {
    $all | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Data-at-rest map exported to {0} ({1} rows). This is the 'where it rests' evidence." -f $CsvPath, $all.Count) -ForegroundColor Green
} elseif ($CsvPath) {
    Write-Host 'No items to export — either genuine zero, a detector gap, or content not yet classified.' -ForegroundColor Yellow
}

Write-Host 'Done. Data-at-rest mapped — next: DLPASSESS-Baseline.ps1 (simulation) to measure movement.' -ForegroundColor Cyan

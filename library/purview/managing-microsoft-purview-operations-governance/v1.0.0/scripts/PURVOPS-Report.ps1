<#
.SYNOPSIS
    PURVOPS-Report.ps1 — read-only alert/incident rollup across DLP, insider risk, information-protection, and audit from the Microsoft Graph security API. Makes no changes.
.DESCRIPTION
    PURPOSE
        Produces the periodic "Alert Rollup - Purview - Report": triggered alerts pulled from Microsoft
        Graph (/security/alerts_v2), grouped by CATEGORY (DLP / insider-risk / information-protection /
        audit-other), SEVERITY, and STATUS, with mean time-to-resolve where timestamps allow — the input to
        the weekly triage review and the alert-volume/triage-time KPIs. Read-only.
    HOW TO RUN
        Connect-MgGraph -Scopes 'SecurityAlert.Read.All'     # or SecurityEvents.Read.All; no secrets in code
        .\PURVOPS-Report.ps1 -Days 7
        .\PURVOPS-Report.ps1 -Days 30 -CsvPath .\Alert-Rollup.csv
        PowerShell 5.1+/7+; requires Microsoft.Graph PowerShell. Alert surfaces evolve — reconcile the totals
        against the Purview/Defender portal for the same window.
    EXPECTED RESULTS
        A rollup table by category/severity/status plus counts and mean resolve time. An empty window (no
        alerts) reports cleanly and is a valid pass.
.NOTES
    Purview — Operations & Governance. Read-only. Insider-risk/communication-compliance alert CONTENT is
    role-separated and privacy-sensitive; this rollup reports COUNTS/metadata for operations, not case
    outcomes (deferred to HR/legal). Verify licensing/tenant for the alerting surfaces in scope.
#>
[CmdletBinding()]
param(
    [int]$Days = 7,
    [string]$CsvPath
)

if (-not (Get-Command Invoke-MgGraphRequest -ErrorAction SilentlyContinue)) {
    Write-Error "Microsoft.Graph not available. Install-Module Microsoft.Graph and Connect-MgGraph -Scopes 'SecurityAlert.Read.All' first."
    return
}
try { $null = Get-MgContext -ErrorAction Stop } catch {}
if (-not (Get-MgContext)) {
    Write-Error "Not connected to Graph. Run: Connect-MgGraph -Scopes 'SecurityAlert.Read.All'"
    return
}

$since = (Get-Date).ToUniversalTime().AddDays(-1 * [math]::Abs($Days)).ToString('yyyy-MM-ddTHH:mm:ssZ')
Write-Host ("=== Alert Rollup - Purview - Report (last {0} days) ===" -f $Days) -ForegroundColor Cyan

# Categorize an alert into an operating bucket from its source/title/category fields (best-effort; surfaces evolve).
function Get-OpsCategory {
    param($a)
    $svc = ("{0} {1} {2}" -f $a.serviceSource, $a.detectionSource, $a.category)
    $txt = ("{0} {1}" -f $a.title, $a.description)
    switch -Regex ("$svc $txt") {
        'DLP|data\s*loss|dlpRule'            { return 'DLP' }
        'InsiderRisk|insider\s*risk'         { return 'InsiderRisk' }
        'Label|Sensitivity|InformationProtection|MIP' { return 'InformationProtection' }
        'Audit|UnifiedAudit'                 { return 'Audit' }
        default                              { return 'Other' }
    }
}

$alerts = New-Object System.Collections.Generic.List[object]
$uri = "/v1.0/security/alerts_v2?`$filter=createdDateTime ge $since&`$top=100"
try {
    do {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
        foreach ($a in $resp.value) {
            $created  = if ($a.createdDateTime) { [datetime]$a.createdDateTime } else { $null }
            $resolved = if ($a.PSObject.Properties.Name -contains 'resolvedDateTime' -and $a.resolvedDateTime) { [datetime]$a.resolvedDateTime } else { $null }
            $ttrHours = if ($created -and $resolved) { [math]::Round(($resolved - $created).TotalHours, 1) } else { $null }
            $alerts.Add([pscustomobject]@{
                Category    = Get-OpsCategory $a
                Severity    = $a.severity
                Status      = $a.status
                Title       = $a.title
                Created     = $created
                ResolveHrs  = $ttrHours
            })
        }
        $uri = $resp.'@odata.nextLink'
    } while ($uri)
} catch {
    Write-Warning ("Could not read /security/alerts_v2 ({0}). Confirm the SecurityAlert.Read.All scope and that the alerting surface is enabled for your tenant." -f $_.Exception.Message)
}

if ($alerts.Count -eq 0) {
    Write-Host "No alerts in the window (clean rollup). PASS." -ForegroundColor Green
    return
}

Write-Host "`n--- By category / severity / status ---" -ForegroundColor Cyan
$alerts | Group-Object Category, Severity, Status |
    Select-Object @{n='Category';e={($_.Name -split ', ')[0]}},
                  @{n='Severity';e={($_.Name -split ', ')[1]}},
                  @{n='Status';e={($_.Name -split ', ')[2]}},
                  Count |
    Sort-Object Category, Severity | Format-Table -AutoSize

$resolved = @($alerts | Where-Object { $_.ResolveHrs -ne $null })
if ($resolved.Count -gt 0) {
    $mean = [math]::Round((($resolved | Measure-Object ResolveHrs -Average).Average), 1)
    Write-Host ("Mean time-to-resolve: {0} hours across {1} resolved alerts (compare to your SLA)." -f $mean, $resolved.Count) -ForegroundColor Cyan
}
Write-Host ("Total alerts: {0}" -f $alerts.Count) -ForegroundColor Green

if ($CsvPath) {
    $alerts | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved rollup CSV to {0}" -f $CsvPath) -ForegroundColor Green
}

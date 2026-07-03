<#
.SYNOPSIS
    COPILOTG-Report.ps1 — Read-only consolidated evidence report for Copilot governance on GCC High.
.DESCRIPTION
    PURPOSE
        Produces a single evidence report (HTML + CSV) combining posture and validation signals for
        the change record and leadership sign-off: tenant/environment, Copilot license counts, site
        count, and governance checklist status. Read-only. Replace sample values (e.g. output path)
        with your own — plain text like 'your-report-folder'.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\COPILOTG-Report.ps1
        (Graph scopes: Sites.Read.All, Group.Read.All, Directory.Read.All, Organization.Read.All;
         connects with -Environment USGov.)
    EXPECTED RESULTS
        An HTML report and CSV in the output folder. PASS = report generated; attach it to the change
        ticket. FAIL = connection not on USGov — see Troubleshooting T1.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string] $OutputFolder = (Join-Path -Path (Get-Location) -ChildPath 'COPILOTG-Report')
)

$ErrorActionPreference = 'Stop'
$RequiredScopes = @('Sites.Read.All','Group.Read.All','Directory.Read.All','Organization.Read.All')

try {
    Connect-MgGraph -Environment USGov -Scopes $RequiredScopes | Out-Null
    $ctx = Get-MgContext
    if ($ctx.Environment -ne 'USGov') { throw "Not on USGov (Environment=$($ctx.Environment)). See Troubleshooting T1." }

    if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

    $org      = Get-MgOrganization | Select-Object -First 1
    $sites    = Get-MgSite -Search '*' -All -ErrorAction SilentlyContinue
    $copilot  = Get-MgSubscribedSku -All | Where-Object { $_.SkuPartNumber -match 'COPILOT' }

    $summary = [pscustomobject]@{
        GeneratedUtc     = (Get-Date).ToUniversalTime().ToString('u')
        Environment      = $ctx.Environment
        GraphEndpoint    = (Get-MgEnvironment -Name USGov).GraphEndpoint
        Tenant           = $org.DisplayName
        TenantId         = $org.Id
        SiteCount        = ($sites | Measure-Object).Count
        CopilotSkuCount  = ($copilot | Measure-Object).Count
        CopilotConsumed  = ($copilot | Measure-Object -Property ConsumedUnits -Sum).Sum
    }

    $csv = Join-Path $OutputFolder "report-summary-$stamp.csv"
    $summary | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8

    $checklist = @(
        'Restricted SharePoint Search enabled & scoped (verify in portal.office365.us; RSS may lag in GCC High)',
        'CUI sensitivity label published to pilot group (compliance.microsoft.us)',
        'DLP policy DLP-COPILOTG-CUI enforced (not simulation)',
        'Copilot licenses scoped to SG-COPILOTG-Pilot only',
        'No broadly-shared site remains in the RSS allow-list',
        'Web grounding decision recorded (OFF by default in GCC High)'
    )

    $html = @"
<html><head><meta charset='utf-8'><title>COPILOTG Governance Evidence Report</title></head><body>
<h1>Microsoft 365 Copilot Secure Adoption &amp; Governance — GCC High</h1>
<h2>Evidence Report</h2>
<p><b>Generated (UTC):</b> $($summary.GeneratedUtc)<br>
<b>Environment:</b> $($summary.Environment) ($($summary.GraphEndpoint))<br>
<b>Tenant:</b> $($summary.Tenant) ($($summary.TenantId))</p>
<h3>Posture</h3>
<ul>
<li>SharePoint sites enumerated: $($summary.SiteCount)</li>
<li>Copilot SKUs: $($summary.CopilotSkuCount) — consumed units: $($summary.CopilotConsumed)</li>
</ul>
<h3>Governance checklist (confirm before expand)</h3>
<ul>
$([string]::Join("`n", ($checklist | ForEach-Object { "<li>$_</li>" })))
</ul>
<p><i>White-label evidence report. Read-only against Microsoft Graph US Gov endpoints.</i></p>
</body></html>
"@
    $htmlPath = Join-Path $OutputFolder "report-$stamp.html"
    $html | Out-File -FilePath $htmlPath -Encoding UTF8

    Write-Host '=== Report generated ===' -ForegroundColor Green
    Write-Host ("HTML : {0}" -f $htmlPath)
    Write-Host ("CSV  : {0}" -f $csv)
    Write-Host 'Attach the HTML report to your change ticket for sign-off.' -ForegroundColor Cyan
}
catch {
    Write-Error "Report failed: $($_.Exception.Message)"
    exit 1
}
finally {
    Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
}

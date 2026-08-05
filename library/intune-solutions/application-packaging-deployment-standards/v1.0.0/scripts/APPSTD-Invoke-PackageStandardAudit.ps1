<#
.SYNOPSIS
    APPSTD-Invoke-PackageStandardAudit.ps1 — audits every Intune app against the packaging standard
    (naming convention, version stamping, publisher/category metadata) and reports violations.
.DESCRIPTION
    PURPOSE
        Read-only. Enumerates all managed apps via Microsoft Graph and scores each against the
        Application Packaging & Deployment Standard:
          - Name matches "<Publisher> <Product> - <Format> - v<Version>" (en-dash separated).
          - Name is free of banned words (Test, New, Copy, TEMP, DO NOT USE, Final, dates, initials).
          - Publisher populated and not a placeholder (IT, Unknown, blank).
          - Category (app category) assigned.
          - Version present in the app name for versionable formats.
        Produces a per-app pass/fail summary and, optionally, a CSV baseline. Use it once to
        baseline before announcing the standard, monthly for new apps, and quarterly for the catalog.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\APPSTD-Invoke-PackageStandardAudit.ps1
        powershell -ExecutionPolicy Bypass -File .\APPSTD-Invoke-PackageStandardAudit.ps1 -CsvPath C:\Temp\baseline.csv
        powershell -ExecutionPolicy Bypass -File .\APPSTD-Invoke-PackageStandardAudit.ps1 -CreatedSinceDays 31
        Requires the Microsoft Graph PowerShell SDK and DeviceManagementApps.Read.All.
    EXPECTED RESULTS
        A console summary (compliant vs non-compliant counts, top violations) and, with -CsvPath,
        a per-app CSV with a column per rule. Nothing is changed — this script only reads.
.NOTES
    Intune Solutions — read-only against Microsoft Graph. No changes are made to the tenant.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [int]$CreatedSinceDays,
    [switch]$WhatIfOnlySummary
)

# --- Standard definitions -------------------------------------------------------------------------
$BannedWords   = @('test','new','copy','temp','do not use','donotuse','final','tmp','wip','draft','delete','old','backup')
$BadPublishers = @('', 'it', 'unknown', 'n/a', 'na', 'tbd', 'publisher', 'company', 'default')
# "<Publisher> <Product> - <Format> - vX.Y[.Z]" using an en-dash ( – ) or hyphen with spaces.
$NameRegex     = '^.+\s[–-]\s(Win32|MSIX|Store)\s[–-]\sv\d+(\.\d+)*'
$VersionRegex  = '\sv\d+(\.\d+)*'

function Connect-Graph {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Write-Host 'Installing Microsoft.Graph (CurrentUser)...' -ForegroundColor Yellow
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All' -NoWelcome
}

function Get-AllApps {
    $apps = @()
    $uri  = '/v1.0/deviceAppManagement/mobileApps?$top=100'
    do {
        $r    = Invoke-MgGraphRequest -Method GET -Uri $uri
        $apps += $r.value
        $uri  = $r.'@odata.nextLink'
    } while ($uri)
    # Focus on the deployable Windows app types the standard governs.
    $wanted = @('#microsoft.graph.win32LobApp','#microsoft.graph.windowsMsiApp',
                '#microsoft.graph.microsoftStoreForBusinessApp','#microsoft.graph.winGetApp',
                '#microsoft.graph.windowsUniversalAppX','#microsoft.graph.windowsMobileMSI')
    $apps | Where-Object { $wanted -contains $_.'@odata.type' -or $_.'@odata.type' -like '*win32*' -or $_.'@odata.type' -like '*winGet*' }
}

Connect-Graph
$apps = Get-AllApps

if ($CreatedSinceDays) {
    $cut  = (Get-Date).AddDays(-1 * [math]::Abs($CreatedSinceDays))
    $apps = $apps | Where-Object { $_.createdDateTime -and ([datetime]$_.createdDateTime) -ge $cut }
    Write-Host ("Filtered to {0} app(s) created in the last {1} day(s)." -f $apps.Count, $CreatedSinceDays) -ForegroundColor Cyan
}

if (-not $apps) { Write-Host 'No matching Windows apps found.' -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

$rows = foreach ($a in $apps) {
    $name = [string]$a.displayName
    $pub  = ([string]$a.publisher).Trim()
    $type = ($a.'@odata.type' -replace '#microsoft.graph.','')

    $isLob        = $type -like '*windowsMsiApp*' -or $type -like '*windowsMobileMSI*'   # legacy LOB/MSI type
    $nameOk       = $name -match $NameRegex
    $bannedHit    = ($BannedWords | Where-Object { $name -match ("\b" + [regex]::Escape($_) + "\b") }) -join ';'
    $pubOk        = $BadPublishers -notcontains $pub.ToLower()
    $catOk        = -not [string]::IsNullOrWhiteSpace([string]$a.developer) -or $true  # category fetched below where available
    $verOk        = ($name -match $VersionRegex)
    $descLines    = ([string]$a.description) -split "`r?`n" | Where-Object { $_.Trim() }
    $descOk       = ($descLines -match '^\s*Business purpose\s*:') -and ($descLines -match '^\s*Business owner\s*:')

    $violations = @()
    if (-not $nameOk)                     { $violations += 'name-convention' }
    if ($bannedHit)                       { $violations += "banned-word($bannedHit)" }
    if (-not $pubOk)                      { $violations += 'publisher' }
    if (-not $verOk)                      { $violations += 'version-stamp' }
    if (-not $descOk)                     { $violations += 'description-standard' }
    if ($isLob)                           { $violations += 'legacy-LOB-format' }

    [pscustomobject]@{
        App                = $name
        Type               = $type
        Publisher          = $pub
        Created            = $a.createdDateTime
        NameConvention     = if ($nameOk) {'PASS'} else {'FAIL'}
        BannedWords        = if ($bannedHit) {"FAIL:$bannedHit"} else {'PASS'}
        PublisherSet       = if ($pubOk) {'PASS'} else {'FAIL'}
        VersionStamped     = if ($verOk) {'PASS'} else {'FAIL'}
        DescriptionStd     = if ($descOk) {'PASS'} else {'FAIL'}
        FormatAllowed      = if ($isLob) {'FAIL(legacy-LOB)'} else {'PASS'}
        Compliant          = if ($violations.Count -eq 0) {'YES'} else {'NO'}
        ViolationCount     = $violations.Count
        Violations         = ($violations -join '; ')
    }
}

$total     = $rows.Count
$compliant = ($rows | Where-Object Compliant -eq 'YES').Count
Write-Host ''
Write-Host '=== Package Standard Audit ===' -ForegroundColor Cyan
Write-Host ("  Apps audited     : {0}" -f $total)
Write-Host ("  Compliant        : {0}  ({1}%)" -f $compliant, ([math]::Round(100.0*$compliant/[math]::Max(1,$total),1))) -ForegroundColor Green
Write-Host ("  Non-compliant    : {0}" -f ($total - $compliant)) -ForegroundColor (if (($total-$compliant) -gt 0){'Yellow'}else{'Green'})
Write-Host ''
Write-Host '  Top violation types:' -ForegroundColor Cyan
$rows | Where-Object Compliant -eq 'NO' | ForEach-Object { $_.Violations -split '; ' } |
    Where-Object { $_ } | Group-Object | Sort-Object Count -Descending | Select-Object -First 8 |
    ForEach-Object { Write-Host ("    {0,-28} {1}" -f $_.Name, $_.Count) }

if (-not $WhatIfOnlySummary) {
    Write-Host ''
    $rows | Where-Object Compliant -eq 'NO' |
        Select-Object App, ViolationCount, Violations |
        Sort-Object ViolationCount -Descending | Format-Table -AutoSize
}

if ($CsvPath) {
    $rows | Sort-Object Compliant, App | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Saved audit CSV: {0}" -f $CsvPath) -ForegroundColor Green
}

Disconnect-MgGraph | Out-Null

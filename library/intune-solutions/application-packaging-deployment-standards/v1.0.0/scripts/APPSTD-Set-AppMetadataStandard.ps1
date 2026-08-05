<#
.SYNOPSIS
    APPSTD-Set-AppMetadataStandard.ps1 — normalises app metadata (publisher, category, and the
    standardised description block) toward the packaging specification. PREVIEW BY DEFAULT: makes NO
    changes unless -Apply is passed.
.DESCRIPTION
    PURPOSE
        The only write-capable script in this package, and it changes nothing until you explicitly
        pass -Apply. It supports -WhatIf. It normalises the mechanical, low-risk metadata gaps the
        audit finds:
          - Trims/repairs the Publisher field when a mapping is supplied.
          - Assigns an app category when supplied.
          - Rebuilds the three-line standardised Description (Business purpose / Business owner /
            Package record) from supplied values, PRESERVING any existing free-text below a marker.
        It does NOT touch detection rules, commands, assignments, or supersedence — those are
        deliberate, reviewed changes, never bulk-normalised.
        Input is a CSV you author (or the metadata report annotated with target values). Each row:
          AppName,Publisher,Category,BusinessPurpose,BusinessOwner,PackageRecord
        Blank cells are skipped (that field is left unchanged).
    HOW TO RUN
        # 1) Preview (default — safe, no changes):
        powershell -ExecutionPolicy Bypass -File .\APPSTD-Set-AppMetadataStandard.ps1 -CsvPath .\fixes.csv
        # 2) Preview a single app inline:
        powershell -ExecutionPolicy Bypass -File .\APPSTD-Set-AppMetadataStandard.ps1 -AppName "Acme ..." -Publisher "Acme Software Ltd." -Category "Business – Finance"
        # 3) Apply, after the preview has been reviewed:
        powershell -ExecutionPolicy Bypass -File .\APPSTD-Set-AppMetadataStandard.ps1 -CsvPath .\fixes.csv -Apply
        Requires the Microsoft Graph PowerShell SDK, DeviceManagementApps.ReadWrite.All (for -Apply).
    EXPECTED RESULTS
        Default: a table of the exact changes that WOULD be made (old -> new), nothing altered.
        With -Apply: the same table, then each change PATCHed to Graph with a per-app success line.
.NOTES
    Intune Solutions — write-capable but PREVIEW BY DEFAULT (-WhatIf supported; -Apply required to
    change anything). Only metadata is touched; detection, commands, and assignments are never changed.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$CsvPath,
    [string]$AppName,
    [string]$Publisher,
    [string]$Category,
    [string]$BusinessPurpose,
    [string]$BusinessOwner,
    [string]$PackageRecord,
    [switch]$Apply
)

$DescMarker = '<!-- free-text below this line is preserved -->'

function Connect-Graph {
    param([switch]$Write)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Write-Host 'Installing Microsoft.Graph (CurrentUser)...' -ForegroundColor Yellow
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $scopes = if ($Write) { @('DeviceManagementApps.ReadWrite.All') } else { @('DeviceManagementApps.Read.All') }
    Connect-MgGraph -Scopes $scopes -NoWelcome
}

# Build the work list from CSV and/or inline params.
$targets = @()
if ($CsvPath) {
    if (-not (Test-Path $CsvPath)) { throw "CSV not found: $CsvPath" }
    $targets += Import-Csv -Path $CsvPath
}
if ($AppName) {
    $targets += [pscustomobject]@{
        AppName=$AppName; Publisher=$Publisher; Category=$Category
        BusinessPurpose=$BusinessPurpose; BusinessOwner=$BusinessOwner; PackageRecord=$PackageRecord
    }
}
if (-not $targets) { throw 'Provide -CsvPath and/or -AppName with values.' }

if ($Apply) {
    Write-Host 'APPLY MODE: changes WILL be written after preview.' -ForegroundColor Yellow
    Connect-Graph -Write
} else {
    Write-Host 'PREVIEW MODE (default): no changes will be made. Re-run with -Apply to write.' -ForegroundColor Cyan
    Connect-Graph
}

# Resolve categories once (name -> id).
$catMap = @{}
try {
    $c = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/deviceAppManagement/mobileAppCategories'
    foreach ($x in $c.value) { $catMap[$x.displayName.ToLower()] = $x.id }
} catch { }

function Build-Description {
    param($existing, $purpose, $owner, $record)
    $preserved = ''
    if ($existing -and $existing.Contains($DescMarker)) {
        $preserved = ($existing -split [regex]::Escape($DescMarker),2)[1]
    }
    $lines = @()
    if ($purpose) { $lines += "Business purpose: $purpose" }
    if ($owner)   { $lines += "Business owner: $owner" }
    if ($record)  { $lines += "Package record: $record" }
    if ($lines.Count -eq 0) { return $null }
    ($lines -join "`n") + "`n" + $DescMarker + $preserved
}

$changes = @()
foreach ($t in $targets) {
    $name = ([string]$t.AppName).Trim()
    if (-not $name) { continue }
    $enc  = [uri]::EscapeDataString($name)
    $resp = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileApps?`$filter=displayName eq '$enc'"
    $app  = $resp.value | Select-Object -First 1
    if (-not $app) { Write-Host ("  ! not found: {0}" -f $name) -ForegroundColor Yellow; continue }

    $body = @{}
    $diff = @()

    if ($t.Publisher -and ($t.Publisher.Trim() -ne [string]$app.publisher)) {
        $body.publisher = $t.Publisher.Trim()
        $diff += "publisher: '$($app.publisher)' -> '$($t.Publisher.Trim())'"
    }
    $newDesc = Build-Description -existing $app.description -purpose $t.BusinessPurpose -owner $t.BusinessOwner -record $t.PackageRecord
    if ($newDesc -and $newDesc -ne [string]$app.description) {
        $body.description = $newDesc
        $diff += "description: standardised 3-line block"
    }

    # Category is a relationship, set via a separate POST; record intent for the preview.
    $catIntent = $null
    if ($t.Category) {
        $cid = $catMap[$t.Category.Trim().ToLower()]
        if ($cid) { $catIntent = @{ Name=$t.Category.Trim(); Id=$cid } ; $diff += "category: + '$($t.Category.Trim())'" }
        else { Write-Host ("  ! category not found in tenant: {0}" -f $t.Category) -ForegroundColor Yellow }
    }

    if ($diff.Count -eq 0) { continue }
    $changes += [pscustomobject]@{ App=$name; Id=$app.id; Body=$body; CatIntent=$catIntent; Diff=($diff -join ' | ') }
}

Write-Host ''
Write-Host ("=== Proposed metadata changes: {0} app(s) ===" -f $changes.Count) -ForegroundColor Cyan
$changes | Select-Object App, Diff | Format-Table -AutoSize -Wrap

if (-not $Apply) {
    Write-Host ''
    Write-Host 'Preview only. Re-run with -Apply to write these changes.' -ForegroundColor Cyan
    Disconnect-MgGraph | Out-Null
    return
}

foreach ($chg in $changes) {
    $desc = "Update metadata for '$($chg.App)'"
    if ($PSCmdlet.ShouldProcess($chg.App, $desc)) {
        try {
            if ($chg.Body.Keys.Count -gt 0) {
                $chg.Body.'@odata.type' = ([string](Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileApps/$($chg.Id)").'@odata.type')
                Invoke-MgGraphRequest -Method PATCH -Uri "/v1.0/deviceAppManagement/mobileApps/$($chg.Id)" -Body ($chg.Body | ConvertTo-Json -Depth 5)
            }
            if ($chg.CatIntent) {
                $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileAppCategories/$($chg.CatIntent.Id)" }
                Invoke-MgGraphRequest -Method POST -Uri "/v1.0/deviceAppManagement/mobileApps/$($chg.Id)/categories/`$ref" -Body ($ref | ConvertTo-Json)
            }
            Write-Host ("  OK  {0}" -f $chg.App) -ForegroundColor Green
        } catch {
            Write-Host ("  ERR {0}: {1}" -f $chg.App, $_.Exception.Message) -ForegroundColor Red
        }
    }
}

Disconnect-MgGraph | Out-Null

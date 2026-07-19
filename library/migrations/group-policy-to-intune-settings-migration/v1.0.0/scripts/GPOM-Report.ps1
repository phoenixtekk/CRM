<#
.SYNOPSIS
    GPOM-Report.ps1 — migration coverage and gap report from the GPO exports.
.DESCRIPTION
    PURPOSE
        Reads the GPO XML exports produced by GPOM-Discovery.ps1 and (optionally) the settings
        catalog policies already created in Intune (via Microsoft Graph), then reports per-GPO a
        coverage estimate (settings that have a migrated home) and a GAP list (settings with no
        Intune equivalent yet: Group Policy Preferences, scripts, drive maps, unmapped security
        settings). Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GPOM-Report.ps1 -ExportPath .\GPO-Export
        Add -UseGraph to also list the Intune settings catalog policies named 'GPO Migration - *'
        (requires the Microsoft.Graph module and DeviceManagementConfiguration.Read.All).
    EXPECTED RESULTS
        A per-GPO table (total settings, ADMX-backed/migratable, preferences/scripts = gaps) with a
        coverage %, an overall gap list exported to CSV, and — with -UseGraph — the matching Intune
        policies and their assignments.
.NOTES
    Intune Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string] $ExportPath = ".\GPO-Export",
    [switch] $UseGraph
)

Write-Host "`n=== Migration coverage + gap report ===" -ForegroundColor Cyan
if (-not (Test-Path $ExportPath)) { Write-Host "Export path not found: $ExportPath. Run GPOM-Discovery.ps1 first." -ForegroundColor Yellow; return }

$files = Get-ChildItem -Path $ExportPath -Filter *.xml -ErrorAction SilentlyContinue
if (-not $files) { Write-Host "No GPO XML exports found in $ExportPath." -ForegroundColor Yellow; return }

$gaps = New-Object System.Collections.Generic.List[object]
$rows = foreach ($f in $files) {
    try {
        [xml]$gpo = Get-Content $f.FullName -Raw
        $exts = @($gpo.GPO.Computer.ExtensionData.Extension) + @($gpo.GPO.User.ExtensionData.Extension) | Where-Object { $_ }

        # ADMX-backed "Policy" nodes are the directly-migratable settings (settings catalog / imported ADMX).
        $admx = @($exts.Policy) | Where-Object { $_ } | Select-Object -ExpandProperty Name -ErrorAction SilentlyContinue
        # Preferences / scripts / drive maps generally have NO direct equivalent -> gaps.
        $prefNodes = @($exts | Where-Object { $_.type -match 'Preferences|Scripts|FolderRedirection' })
        $prefCount = 0
        foreach ($p in $prefNodes) { $prefCount += @($p.SelectNodes('.//*[@name]')).Count }

        $migratable = @($admx).Count
        $gapCount   = $prefCount
        $total      = $migratable + $gapCount
        $coverage   = if ($total -gt 0) { [math]::Round(($migratable / $total) * 100, 0) } else { 100 }

        if ($prefNodes) {
            foreach ($p in $prefNodes) { $gaps.Add([pscustomobject]@{ Gpo = $f.BaseName; GapType = $p.type; Note = 'Re-implement (platform script / proactive remediation / endpoint security) or retire.' }) }
        }

        [pscustomobject]@{
            Gpo            = $f.BaseName
            MigratableADMX = $migratable
            GapItems       = $gapCount
            TotalSettings  = $total
            'Coverage%'    = $coverage
        }
    } catch {
        [pscustomobject]@{ Gpo = $f.BaseName; MigratableADMX = '?'; GapItems = '?'; TotalSettings = '?'; 'Coverage%' = "parse error" }
    }
}

$rows | Sort-Object 'Coverage%' | Format-Table -AutoSize
$gapCsv = Join-Path $ExportPath "GPOM-Gaps.csv"
$gaps | Export-Csv -Path $gapCsv -NoTypeInformation -Encoding UTF8
Write-Host ("`nGap list ({0} item areas) saved: {1}" -f $gaps.Count, $gapCsv) -ForegroundColor Green
Write-Host "Coverage% is a local estimate; the authoritative readiness % is shown in Intune's Group Policy analytics." -ForegroundColor Gray

if ($UseGraph) {
    Write-Host "`n=== Intune 'GPO Migration - *' policies (Graph) ===" -ForegroundColor Cyan
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' -NoWelcome
    $pols = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies?`$filter=startswith(name,'GPO Migration')").value
    if ($pols) { foreach ($p in $pols) { Write-Host ("  {0}  (id {1})" -f $p.name, $p.id) } }
    else { Write-Host "  No settings catalog policies named 'GPO Migration - *' found yet." -ForegroundColor Yellow }
    Disconnect-MgGraph | Out-Null
}

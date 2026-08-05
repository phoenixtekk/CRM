<#
.SYNOPSIS
    APPASMT-Install-Health.ps1 — install-failure and version-drift baseline (READ-ONLY).
.DESCRIPTION
    PURPOSE
        Evidences dimensions D4 (Patching & Version Currency) and D7 (Monitoring & Reporting) by
        baselining, per app, the install success / failure / pending / not-applicable counts from
        Intune's app install status, and the VERSION SPREAD per app title (how many distinct versions
        of the same product are live at once — the classic modernization red flag). READ-ONLY: it
        reads Graph reporting/status endpoints with .Read.All scopes only.
    HOW TO RUN
        Connect-MgGraph -Scopes "DeviceManagementApps.Read.All"
        #   GCC High: add -Environment USGov
        powershell -ExecutionPolicy Bypass -File .\APPASMT-Install-Health.ps1 -OutDir .\APPASMT-EvidencePack
    EXPECTED RESULTS
        Console summary plus:
          APPASMT-Install-Health.csv     (per-app install success/failure/pending + failure rate)
          APPASMT-Version-Drift.csv       (app titles with >1 live version)
          APPASMT-InstallHealth-Summary.json
.NOTES
    Intune Solutions — application management assessment. READ-ONLY (reporting/analysis; no tenant writes).
    Least-privilege: Intune "Read Only Operator" + Graph *.Read.All. Government: -Environment USGov
    (GCC High) / USGovDoD (DoD); verify GCC High reporting parity where uncertain.
#>
[CmdletBinding()]
param([string]$OutDir = ".\APPASMT-EvidencePack")

$ctx = Get-MgContext -ErrorAction SilentlyContinue
if (-not $ctx) { throw "Not connected. Run Connect-MgGraph with read-only scopes first (see .NOTES)." }
Write-Host ("Connected as {0} | Environment: {1}" -f $ctx.Account, $ctx.Environment) -ForegroundColor Cyan
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

Write-Host "Reading apps and per-app install summaries (paged) ..." -ForegroundColor Cyan
$apps = @()
$uri = "https://graph.microsoft.com/v1.0/deviceManagement/mobileApps?`$top=50"
while ($uri) { $p = Invoke-MgGraphRequest -Method GET -Uri $uri; $apps += $p.value; $uri = $p.'@odata.nextLink' }

$health = New-Object System.Collections.Generic.List[object]
$titleVersions = @{}   # normalized title -> hashset of versions

foreach ($a in $apps) {
    # Install status summary (beta exposes installSummary; fall back to counts of 0 if unavailable).
    $succeeded = 0; $failed = 0; $pending = 0; $notApplicable = 0
    try {
        $sum = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($a.id)/installSummary"
        $succeeded     = [int]$sum.installedDeviceCount + [int]$sum.installedUserCount
        $failed        = [int]$sum.failedDeviceCount    + [int]$sum.failedUserCount
        $pending       = [int]$sum.pendingInstallDeviceCount + [int]$sum.pendingInstallUserCount
        $notApplicable = [int]$sum.notApplicableDeviceCount  + [int]$sum.notApplicableUserCount
    } catch { }

    $attempted = $succeeded + $failed
    $failRate  = if ($attempted -gt 0) { [Math]::Round(($failed / $attempted) * 100, 1) } else { 0 }

    $health.Add([pscustomobject]@{
        App=$a.displayName; Version=$a.displayVersion; Succeeded=$succeeded; Failed=$failed;
        Pending=$pending; NotApplicable=$notApplicable; FailureRatePct=$failRate
    })

    # Version drift: group by a normalized title (strip trailing version-ish tokens).
    $norm = ($a.displayName -replace '\s*\d+(\.\d+)+.*$','').Trim().ToLower()
    if ($a.displayVersion) {
        if (-not $titleVersions.ContainsKey($norm)) { $titleVersions[$norm] = New-Object System.Collections.Generic.HashSet[string] }
        [void]$titleVersions[$norm].Add([string]$a.displayVersion)
    }
}

$drift = foreach ($k in $titleVersions.Keys) {
    if ($titleVersions[$k].Count -gt 1) {
        [pscustomobject]@{ Title=$k; DistinctVersions=$titleVersions[$k].Count; Versions=(($titleVersions[$k]) -join ', ') }
    }
}
$drift = @($drift | Sort-Object DistinctVersions -Descending)

$highFail = @($health | Where-Object { $_.FailureRatePct -ge 10 -and ($_.Succeeded + $_.Failed) -ge 5 })

Write-Host ("`n=== APPASMT Install Health — {0} apps ===" -f $apps.Count) -ForegroundColor Cyan
Write-Host ("  Apps with failure rate >=10%% (D7): {0}" -f $highFail.Count)
Write-Host ("  App titles with >1 live version (D4 drift): {0}" -f $drift.Count)
if ($drift.Count) { $drift | Select-Object -First 8 | ForEach-Object { Write-Host ("    {0}: {1} versions [{2}]" -f $_.Title, $_.DistinctVersions, $_.Versions) } }

$summary = [ordered]@{
    generatedUtc        = (Get-Date).ToUniversalTime().ToString('o')
    appsScanned         = $apps.Count
    highFailureApps     = $highFail.Count
    titlesWithVersionDrift = $drift.Count
    maxVersionsOnATitle = ($drift | Measure-Object DistinctVersions -Maximum).Maximum
}
$health | Sort-Object FailureRatePct -Descending | Export-Csv (Join-Path $OutDir 'APPASMT-Install-Health.csv') -NoTypeInformation -Encoding UTF8
$drift  | Export-Csv (Join-Path $OutDir 'APPASMT-Version-Drift.csv') -NoTypeInformation -Encoding UTF8
$summary | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $OutDir 'APPASMT-InstallHealth-Summary.json') -Encoding UTF8
Write-Host ("`nWrote install-health, version-drift, and summary to {0}" -f $OutDir) -ForegroundColor Green
Write-Host "Read-only complete. No tenant changes were made." -ForegroundColor Green

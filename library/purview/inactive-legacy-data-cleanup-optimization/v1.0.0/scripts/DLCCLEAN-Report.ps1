<#
.SYNOPSIS
    DLCCLEAN-Report.ps1 — read-only storage-savings / candidate-ROT / disposition report for review (safe: read-only).
.DESCRIPTION
    PURPOSE
        Produces the sized ROT / stale-data candidate list and storage picture the records/storage owners review
        before signing off cleanup. In the default StaleData mode it uses Microsoft Graph usage reports
        (SharePoint site, OneDrive account, mailbox usage detail) to list locations with no activity beyond
        -StaleDays and the storage they consume — the candidate list and the savings estimate. In
        DispositionPreview mode it reports a named policy's distribution/status (Get-RetentionCompliancePolicy
        -DistributionDetail) so you can see where it is deployed before it acts. Read-only — queries reports
        only; deletes nothing.
    HOW TO RUN
        # Sized stale-data candidates + storage (needs Graph Reports.Read.All):
        powershell -ExecutionPolicy Bypass -File .\DLCCLEAN-Report.ps1 -StaleDays 365 -CsvPath .\DLCCLEAN-ROT-Candidates.csv
        # Disposition/deployment preview for a pilot policy:
        powershell -File .\DLCCLEAN-Report.ps1 -PolicyName 'DLC - Delete Inactive Content - Pilot' -Mode DispositionPreview
        Requires Microsoft Graph (Connect-MgGraph -Scopes 'Reports.Read.All') and/or S&C PowerShell (Connect-IPPSSession).
.EXAMPLE
    .\DLCCLEAN-Report.ps1 -StaleDays 365 -CsvPath .\DLCCLEAN-ROT-Candidates.csv
    Lists stale sites/OneDrives/mailboxes (last activity > 365d) with storage GB and exports the sized candidate CSV.
.NOTES
    Purview — Inactive & Legacy Data Cleanup. Read-only reporting from Graph usage reports / retention distribution. No changes made.
    Expected results: a named, sized ROT candidate list (StaleData) or a deployment/disposition picture (DispositionPreview) for review.
#>
[CmdletBinding()]
param(
    [ValidateSet('StaleData','DispositionPreview')][string]$Mode = 'StaleData',
    [int]$StaleDays = 365,
    [string]$PolicyName,
    [string]$CsvPath,
    [string]$UserPrincipalName
)

# ============================ DispositionPreview mode ============================
if ($Mode -eq 'DispositionPreview') {
    if (-not $PolicyName) { Write-Host 'DispositionPreview needs -PolicyName.' -ForegroundColor Yellow; return }
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    if (-not (Get-Command Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue)) {
        if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
    }
    Write-Host ("=== Disposition/deployment preview: '{0}' (read-only) ===" -f $PolicyName) -ForegroundColor Cyan
    $p = Get-RetentionCompliancePolicy -Identity $PolicyName -DistributionDetail -ErrorAction Stop
    Write-Host ("Enabled={0}  Mode={1}  DistributionStatus={2}" -f $p.Enabled, $p.Mode, $p.DistributionStatus)
    foreach ($loc in 'ExchangeLocation','SharePointLocation','OneDriveLocation','ModernGroupLocation','AdaptiveScopeLocation') {
        $v = @($p.$loc); if ($v.Count) { Write-Host ("  {0}: {1}" -f $loc, ($v -join ', ')) }
    }
    Write-Host 'This shows WHERE the policy is deployed — no items are deleted by this report. Approve disposition in Purview → Records management → Disposition.' -ForegroundColor Yellow
    return
}

# ============================ StaleData mode (Graph usage reports) ============================
if (-not (Get-Command Invoke-MgGraphRequest -ErrorAction SilentlyContinue)) {
    Write-Host 'Microsoft.Graph not available. Install: Install-Module Microsoft.Graph -Scope CurrentUser; then Connect-MgGraph -Scopes Reports.Read.All' -ForegroundColor Yellow
    return
}
try { $null = Get-MgContext } catch {}
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'Reports.Read.All' -NoWelcome }

$cutoff = (Get-Date).AddDays(-$StaleDays)
Write-Host ("=== Stale-data / ROT candidates: no activity since {0:yyyy-MM-dd} ({1} days) ===" -f $cutoff, $StaleDays) -ForegroundColor Cyan

function Get-GraphReportCsv {
    param([string]$Uri)
    # Usage report endpoints return CSV text; parse to objects.
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("dlcclean-{0}.csv" -f ([guid]::NewGuid().ToString('N')))
    try {
        Invoke-MgGraphRequest -Method GET -Uri $Uri -OutputFilePath $tmp -ErrorAction Stop
        if (Test-Path $tmp) { return Import-Csv -Path $tmp }
    } catch { Write-Host ("  report query failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
    finally { if (Test-Path $tmp) { Remove-Item $tmp -Force -ErrorAction SilentlyContinue } }
    return @()
}

$candidates = @()

# --- SharePoint sites: last content-modified beyond cutoff ---
Write-Host '--- Stale SharePoint sites ---' -ForegroundColor Cyan
foreach ($r in Get-GraphReportCsv "https://graph.microsoft.com/v1.0/reports/getSharePointSiteUsageDetail(period='D180')") {
    $last = $r.'Last Activity Date'
    $lastDate = $null; [void][datetime]::TryParse($last, [ref]$lastDate)
    if (-not $last -or ($lastDate -and $lastDate -lt $cutoff)) {
        $candidates += [pscustomobject]@{
            Type='SharePointSite'; Identity=$r.'Site URL'; Owner=$r.'Owner Display Name'
            LastActivity=$last; StorageGB=[math]::Round(([double]($r.'Storage Used (Byte)')/1GB),2)
        }
    }
}

# --- OneDrive accounts ---
Write-Host '--- Stale OneDrive accounts ---' -ForegroundColor Cyan
foreach ($r in Get-GraphReportCsv "https://graph.microsoft.com/v1.0/reports/getOneDriveUsageAccountDetail(period='D180')") {
    $last = $r.'Last Activity Date'
    $lastDate = $null; [void][datetime]::TryParse($last, [ref]$lastDate)
    if (-not $last -or ($lastDate -and $lastDate -lt $cutoff)) {
        $candidates += [pscustomobject]@{
            Type='OneDrive'; Identity=$r.'Owner Principal Name'; Owner=$r.'Owner Display Name'
            LastActivity=$last; StorageGB=[math]::Round(([double]($r.'Storage Used (Byte)')/1GB),2)
        }
    }
}

# --- Mailboxes ---
Write-Host '--- Stale mailboxes ---' -ForegroundColor Cyan
foreach ($r in Get-GraphReportCsv "https://graph.microsoft.com/v1.0/reports/getMailboxUsageDetail(period='D180')") {
    $last = $r.'Last Activity Date'
    $lastDate = $null; [void][datetime]::TryParse($last, [ref]$lastDate)
    if (-not $last -or ($lastDate -and $lastDate -lt $cutoff)) {
        $candidates += [pscustomobject]@{
            Type='Mailbox'; Identity=$r.'User Principal Name'; Owner=$r.'Display Name'
            LastActivity=$last; StorageGB=[math]::Round(([double]($r.'Storage Used (Byte)')/1GB),2)
        }
    }
}

if ($candidates.Count -eq 0) {
    Write-Host 'No stale candidates found for the window (or reports unavailable). Widen -StaleDays or verify Reports.Read.All.' -ForegroundColor Yellow
    return
}

$totalGB = [math]::Round((($candidates | Measure-Object StorageGB -Sum).Sum),2)
$candidates | Group-Object Type | ForEach-Object {
    $gb = [math]::Round((($_.Group | Measure-Object StorageGB -Sum).Sum),2)
    Write-Host ("  {0}: {1} candidate(s), {2} GB" -f $_.Name, $_.Count, $gb)
}
Write-Host ("TOTAL ROT candidates: {0}  Reclaimable storage (est.): {1} GB" -f $candidates.Count, $totalGB) -ForegroundColor Green
Write-Host 'These are CANDIDATES for records review — not a delete list. Deletion is a records-authorized, hold-checked action.' -ForegroundColor Yellow

if ($CsvPath) {
    $candidates | Sort-Object StorageGB -Descending | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Sized candidate list exported to {0} — hand to records/storage owners for review." -f $CsvPath) -ForegroundColor Green
}

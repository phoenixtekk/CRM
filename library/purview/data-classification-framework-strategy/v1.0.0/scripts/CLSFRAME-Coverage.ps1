<#
.SYNOPSIS
    CLSFRAME-Coverage.ps1 — scope/health helper: health-check the framework artifacts and (where licensed) report how content is classifying per tier via Activity Explorer (read-only).
.DESCRIPTION
    Two read-only functions. First, a health check confirming the framework's artifacts are present and
    the label/retention publish policies exist. Second — where licensed (Activity Explorer / content
    explorer is E5-tier, verify your licensing/tenant) — it pulls recent label-applied activity with
    Export-ActivityExplorerData and summarizes counts per tier label, so you can see whether pilot
    content is landing in sensible tiers before enforcing. Read-only — makes no changes.
.EXAMPLE
    .\CLSFRAME-Coverage.ps1
    Runs the framework health check only (no Activity Explorer call).
.EXAMPLE
    .\CLSFRAME-Coverage.ps1 -IncludeActivity -Days 7
    Also queries the last 7 days of label activity and summarizes per-tier counts (E5-tier feature).
.NOTES
    Requires PowerShell 5.1+/7+ and the ExchangeOnlineManagement module (Connect-IPPSSession).
    Role (read): Compliance Administrator / Information Protection Reader. Activity Explorer requires
    E5 / E5 Compliance — verify your licensing/tenant.
    Expected results: PASS = health check shows the tier labels, DLP baseline (Test), and retention
    labels present; with -IncludeActivity, a per-tier count of label activity. FAIL = missing artifacts
    or Export-ActivityExplorerData unavailable (licensing) — reported, not fatal to the health check.
#>
[CmdletBinding()]
param(
    [switch]$IncludeActivity,
    [int]$Days = 7,
    [string[]]$Tiers = @('Public','Internal','Confidential','Restricted'),
    [string]$DlpBaselineName = 'CLS DLP – Tier2-3 – Test'
)

function Connect-SCC {
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        Write-Warning 'ExchangeOnlineManagement module not found. Install-Module ExchangeOnlineManagement -Scope CurrentUser'
        throw 'Module missing.'
    }
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) {
        Write-Host 'Connecting to Security & Compliance PowerShell...' -ForegroundColor Cyan
        Connect-IPPSSession -ShowBanner:$false
    }
}

Connect-SCC
Write-Host '=== CLSFRAME coverage & health (read-only) ===' -ForegroundColor Cyan

# --- Framework health check ---
Write-Host "`n--- Framework artifact health ---" -ForegroundColor Cyan
$labels = Get-Label -ErrorAction SilentlyContinue
$tags   = Get-ComplianceTag -ErrorAction SilentlyContinue
$dlp    = Get-DlpCompliancePolicy -ErrorAction SilentlyContinue

foreach ($t in $Tiers) {
    $hasLabel = [bool]($labels | Where-Object { $_.DisplayName -eq $t })
    $hasTag   = [bool]($tags   | Where-Object { $_.Name -like "*$t*" })
    $status   = if ($hasLabel -and $hasTag) { 'OK' } else { 'INCOMPLETE' }
    $color    = if ($status -eq 'OK') { 'Green' } else { 'Yellow' }
    Write-Host ("  Tier {0,-13} label={1,-5} retention={2,-5} -> {3}" -f $t, $hasLabel, $hasTag, $status) -ForegroundColor $color
}
$dlpPolicy = $dlp | Where-Object { $_.Name -eq $DlpBaselineName } | Select-Object -First 1
if ($dlpPolicy) {
    Write-Host ("  DLP baseline '{0}' present, Mode={1}" -f $DlpBaselineName, $dlpPolicy.Mode) -ForegroundColor Green
} else {
    Write-Host ("  DLP baseline '{0}' NOT found" -f $DlpBaselineName) -ForegroundColor Yellow
}

# --- Optional: per-tier label activity via Activity Explorer (E5-tier) ---
if ($IncludeActivity) {
    Write-Host "`n--- Per-tier label activity (last $Days days; Activity Explorer, E5-tier) ---" -ForegroundColor Cyan
    if (-not (Get-Command Export-ActivityExplorerData -ErrorAction SilentlyContinue)) {
        Write-Host '  Export-ActivityExplorerData not available — verify your licensing/tenant (E5 / E5 Compliance).' -ForegroundColor Yellow
    } else {
        $start = (Get-Date).AddDays(-1 * [math]::Abs($Days)).ToString('yyyy-MM-ddT00:00:00')
        $end   = (Get-Date).ToString('yyyy-MM-ddT23:59:59')
        try {
            $activity = Export-ActivityExplorerData -StartTime $start -EndTime $end -Filter1 'Activity:LabelApplied' -PageSize 1000 -ErrorAction Stop
            $rows = $activity.ResultData | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($rows) {
                foreach ($t in $Tiers) {
                    $count = ($rows | Where-Object { $_.SensitivityLabelId -or ($_.Label -eq $t) -or ($_.Tags -match $t) }).Count
                    Write-Host ("  Tier {0,-13} label-applied events ~ {1}" -f $t, $count) -ForegroundColor DarkCyan
                }
                Write-Host '  NOTE: Activity Explorer field names vary by tenant/version — review raw ResultData and adjust the match if needed.' -ForegroundColor DarkGray
            } else {
                Write-Host '  No label activity returned for the window (or content not yet labeled).' -ForegroundColor DarkGray
            }
        } catch {
            Write-Host ("  Activity Explorer query failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
            Write-Host '  This is non-fatal — verify licensing/tenant and permissions for Activity Explorer.' -ForegroundColor DarkGray
        }
    }
}

Write-Host "`n=== Coverage & health complete (no changes made) ===" -ForegroundColor Green

<#
.SYNOPSIS
    CPLTSHARE-Validate.ps1 - Confirm the pilot oversharing is reduced and controls are in the expected state (READ-ONLY).
.DESCRIPTION
    PURPOSE:  Re-measure the oversharing signal on the pilot sites and compare to the discovery baseline,
              confirm Restricted Access Control / Restricted Content Discovery / Restricted SharePoint
              Search state, and confirm auditing is on. Writes "Copilot Permission Verification - Pilot -
              Validate". This script provides the technical evidence; the DECISIVE check is the manual
              Copilot-side test (a user who should NOT have access cannot surface the content, and a
              legitimate user still can) - see the Testing guide.
    HOW TO RUN:
              1. Connect-MgGraph -Scopes "Sites.Read.All","Directory.Read.All"
              2. .\CPLTSHARE-Validate.ps1 -BaselineCsv ".\Oversharing Discovery - Estate - Assess.csv" `
                     -PilotUrls @("https://contoso.sharepoint.com/sites/Finance")
    EXPECTED RESULTS:
              PASS: pilot oversharing signal is LOWER than baseline; controls in expected state; auditing on.
              FAIL: signal unchanged / controls missing / auditing off.
.NOTES
    White-label. Read-only - changes nothing. Allow for Copilot/search re-indexing latency before trusting
    a negative Copilot-side test. Requires Microsoft.Graph.
#>

[CmdletBinding()]
param(
    [string]$BaselineCsv,
    [string[]]$PilotUrls,
    [string]$OutDir = ".",
    [string]$ArtifactName = "Copilot Permission Verification - Pilot - Validate"
)

$ErrorActionPreference = "Stop"
function Write-Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }

try { $ctx = Get-MgContext -ErrorAction Stop } catch { $ctx = $null }
if (-not $ctx) { Write-Error "Connect-MgGraph -Scopes 'Sites.Read.All','Directory.Read.All' is required."; return }

# --- Baseline ---
$baseline = @{}
if ($BaselineCsv -and (Test-Path $BaselineCsv)) {
    Import-Csv $BaselineCsv | ForEach-Object { if ($_.WebUrl) { $baseline[$_.WebUrl] = $_.OversharingSignal } }
    Write-Host "Baseline loaded: $($baseline.Count) sites." -ForegroundColor Green
} else {
    Write-Warning "No -BaselineCsv provided; will report current state without a before/after delta."
}

if (-not $PilotUrls) {
    $PilotUrls = $baseline.Keys
    Write-Warning "No -PilotUrls provided; validating all baseline sites."
}

Write-Section "Re-measuring pilot oversharing (read-only)"
$rows = @()
foreach ($url in ($PilotUrls | Where-Object { $_ })) {
    $now = "review"; $note = ""
    try {
        $site = Get-MgSite -SiteId $url.Replace("https://","").Replace("/",":/",1) -ErrorAction Stop
        $perms = Get-MgSitePermission -SiteId $site.Id -ErrorAction Stop
        $broad = $perms | Where-Object {
            ($_.GrantedToV2.SiteGroup.DisplayName -match 'Everyone') -or
            ($_.GrantedToIdentitiesV2.DisplayName -match 'Everyone except external users|Everyone')
        }
        $now = if ($broad) { "broad-access (EEEU/org-wide) - STILL PRESENT" } else { "scoped (no broad grant detected)" }
    } catch { $note = "read unavailable: $($_.Exception.Message)" }
    $before = if ($baseline.ContainsKey($url)) { $baseline[$url] } else { "n/a" }
    $improved = ($before -match 'PRIORITY|Everyone|EEEU|org-wide') -and ($now -notmatch 'STILL PRESENT|Everyone|EEEU')
    $rows += [pscustomobject]@{
        SiteUrl = $url; Before = $before; After = $now
        Improved = $(if ($improved) { "YES" } elseif ($note) { "unknown" } else { "no-change" })
        Note = $note
    }
}
$rows | Format-Table SiteUrl, Before, After, Improved -AutoSize | Out-Host

# --- Control-state reminders (portal-verified) ---
Write-Section "Control-state checklist (verify in portal / SPO shell)"
Write-Host "  RAC (Restricted Access Control): confirm agreed sites limited to a named group." -ForegroundColor DarkGray
Write-Host "  RCD (Restricted Content Discovery): confirm on interim-fenced sensitive sites." -ForegroundColor DarkGray
Write-Host "  RSS (Restricted SharePoint Search): Get-SPOTenantRestrictedSearchMode to confirm state." -ForegroundColor DarkGray
Write-Host "  Auditing: confirm Purview Audit is recording (Search-UnifiedAuditLog returns events)." -ForegroundColor DarkGray

$improvedCount = @($rows | Where-Object { $_.Improved -eq "YES" }).Count
$stillBroad    = @($rows | Where-Object { $_.After -match 'STILL PRESENT' }).Count
$summary = [ordered]@{
    Artifact         = $ArtifactName
    GeneratedUtc     = (Get-Date).ToUniversalTime().ToString("s") + "Z"
    SitesValidated   = $rows.Count
    ImprovedSites    = $improvedCount
    StillBroadSites  = $stillBroad
    ManualCopilotTest= "REQUIRED: unauthorized user cannot surface remediated content via Copilot/search; legitimate user access intact (record outcome + test time)."
    Detail           = $rows
}
$null = New-Item -ItemType Directory -Force -Path $OutDir
$safe = ($ArtifactName -replace '[^\w\-]+','_')
$json = Join-Path $OutDir "$safe.json"
$summary | ConvertTo-Json -Depth 6 | Out-File -FilePath $json -Encoding UTF8
Write-Host "`nWrote $json" -ForegroundColor Green
if ($stillBroad -gt 0) { Write-Warning "$stillBroad pilot site(s) still show broad access - remediate before expanding." }
Write-Host "Reminder: complete the manual Copilot-side test before the pilot gate is considered passed." -ForegroundColor Yellow

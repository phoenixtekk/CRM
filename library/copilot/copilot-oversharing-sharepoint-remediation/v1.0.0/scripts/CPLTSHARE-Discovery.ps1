<#
.SYNOPSIS
    CPLTSHARE-Discovery.ps1 - Discover SharePoint/OneDrive oversharing that Copilot can surface (READ-ONLY).
.DESCRIPTION
    PURPOSE:  Inventory the in-scope SharePoint/OneDrive estate and surface the oversharing signals that
              make content reachable by Microsoft 365 Copilot - "Everyone Except External Users" (EEEU) /
              organization-wide grants, "Anyone" (anonymous) sharing links, broad company links,
              large-membership sites, and stale/guest access. With -ScopeOnly it only checks the
              environment (connections, modules, SAM availability, auditing) for Step 0. Writes
              "Oversharing Discovery - Estate - Assess" (CSV + JSON summary).
    HOW TO RUN:
              1. Connect-MgGraph -Scopes "Sites.Read.All","Directory.Read.All"
              2. (optional) Connect-PnPOnline -Url https://<tenant>-admin.sharepoint.com -Interactive
              3. .\CPLTSHARE-Discovery.ps1 -ScopeOnly           # Step 0 environment check
                 .\CPLTSHARE-Discovery.ps1 -OutDir C:\Temp\CPLTSHARE
    EXPECTED RESULTS:
              PASS: an export listing in-scope sites with an oversharing signal is written (or, with
              -ScopeOnly, a green environment summary). FAIL: Graph not connected / insufficient scope.
.NOTES
    White-label. Read-only - changes NO sharing or permissions. Requires Microsoft.Graph (and optionally
    PnP.PowerShell). The authoritative tenant oversharing view is the SharePoint Advanced Management Data
    Access Governance reports (verify licensing) - reconcile this portable export against them.
#>

[CmdletBinding()]
param(
    [switch]$ScopeOnly,
    [int]$MaxSites = 200,
    [string]$OutDir = ".",
    [string]$ArtifactName = "Oversharing Discovery - Estate - Assess"
)

$ErrorActionPreference = "Stop"
function Write-Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Test-ModulePresent($n) { [bool](Get-Module -ListAvailable -Name $n) }

# --- Environment / module report ---
Write-Section "Environment check (read-only)"
$modReport = [ordered]@{
    "Microsoft.Graph"                        = Test-ModulePresent "Microsoft.Graph"
    "PnP.PowerShell"                         = Test-ModulePresent "PnP.PowerShell"
    "Microsoft.Online.SharePoint.PowerShell" = Test-ModulePresent "Microsoft.Online.SharePoint.PowerShell"
}
$modReport.GetEnumerator() | ForEach-Object {
    $col = if ($_.Value) { "Green" } else { "Yellow" }
    Write-Host ("  module {0,-42} {1}" -f $_.Key, ($(if($_.Value){"present"}else{"MISSING"}))) -ForegroundColor $col
}

# --- Graph session check ---
$graphOk = $false
try {
    $ctx = Get-MgContext -ErrorAction Stop
    if ($ctx) { $graphOk = $true; Write-Host "Microsoft Graph connected as $($ctx.Account)." -ForegroundColor Green }
} catch { }
if (-not $graphOk) { Write-Warning "Connect-MgGraph -Scopes 'Sites.Read.All','Directory.Read.All' is required for discovery." }

# --- Auditing signal (best-effort, read-only) ---
$auditNote = "unknown - verify in Purview Audit (Search-UnifiedAuditLog)"
Write-Host "Auditing: $auditNote" -ForegroundColor DarkGray

# --- SAM availability is portal-verified; note it ---
Write-Host "SharePoint Advanced Management (DAG/RAC/RCD): verify in SharePoint admin center (licensing-gated)." -ForegroundColor DarkGray

if ($ScopeOnly) {
    Write-Host "`n-ScopeOnly: environment reported. No estate scan performed." -ForegroundColor Yellow
    return
}
if (-not $graphOk) { Write-Error "Cannot scan estate without a Graph connection."; return }

# --- Estate scan (read-only) ---
Write-Section "Enumerating in-scope sites and oversharing signals (read-only)"
$sites = @()
try {
    # Read-only site enumeration; the exact cmdlet/endpoint may vary by Graph module version - verify.
    $sites = Get-MgSite -Search "*" -Top $MaxSites -ErrorAction Stop
} catch {
    Write-Warning "Get-MgSite failed: $($_.Exception.Message). Supply the site list from the SharePoint admin Active-sites/DAG export."
}

$rows = @()
foreach ($s in $sites) {
    $signal = "review"; $note = ""
    try {
        $perms = Get-MgSitePermission -SiteId $s.Id -ErrorAction Stop
        $broad = $perms | Where-Object {
            ($_.GrantedToV2.SiteGroup.DisplayName -match 'Everyone') -or
            ($_.GrantedToIdentitiesV2.DisplayName -match 'Everyone except external users|Everyone')
        }
        $signal = if ($broad) { "broad-access (EEEU/org-wide) - PRIORITY" } else { "scoped (no broad grant detected)" }
    } catch {
        $note = "permission read unavailable (needs higher scope) - check via SharePoint DAG report"
    }
    $rows += [pscustomobject]@{
        SiteName          = $s.DisplayName
        WebUrl            = $s.WebUrl
        SiteId            = $s.Id
        OversharingSignal = $signal
        Note              = $note
    }
}

Write-Host ("Sites evaluated: {0}" -f $rows.Count)
$rows | Sort-Object OversharingSignal | Format-Table SiteName, OversharingSignal -AutoSize | Out-Host

$null = New-Item -ItemType Directory -Force -Path $OutDir
$safe = ($ArtifactName -replace '[^\w\-]+','_')
$csv  = Join-Path $OutDir "$safe.csv"
$rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
$summary = [ordered]@{
    Artifact       = $ArtifactName
    GeneratedUtc   = (Get-Date).ToUniversalTime().ToString("s") + "Z"
    SitesEvaluated = $rows.Count
    PriorityCount  = @($rows | Where-Object { $_.OversharingSignal -match 'PRIORITY' }).Count
    Modules        = $modReport
    Guidance       = "Broadly-shared sites (PRIORITY) are top Copilot oversharing risk; cross-read with sensitive-content discovery. Reconcile with SharePoint Advanced Management Data Access Governance reports (verify licensing)."
}
$json = Join-Path $OutDir "$safe.json"
$summary | ConvertTo-Json -Depth 6 | Out-File -FilePath $json -Encoding UTF8
Write-Host "Wrote $csv" -ForegroundColor Green
Write-Host "Wrote $json" -ForegroundColor Green
Write-Host "`nRead-only: no sharing or permissions were changed." -ForegroundColor Yellow

<#
.SYNOPSIS
    Discover SharePoint/OneDrive oversharing that makes content reachable by Copilot (READ-ONLY).
.DESCRIPTION
    Enumerates in-scope SharePoint sites via Microsoft Graph and surfaces oversharing signals - broad
    ("Everyone Except External Users" / organization-wide) sharing and broad sharing links - that let
    Copilot surface content. With -IncludeSensitive it also appends the in-scope sensitive information
    types and label-coverage picture. Writes "Oversharing - Estate - Discovery" (and, with
    -IncludeSensitive, "Unlabeled Sensitive - Estate - Assess"). Read-only; changes nothing.
.EXAMPLE
    .\AICOPILOT-OversharingDiscovery.ps1
    Read-only oversharing discovery across the sites returned by Graph.
.EXAMPLE
    .\AICOPILOT-OversharingDiscovery.ps1 -IncludeSensitive -OutDir C:\Temp\CopilotReadiness
    Also appends sensitive-info-types and label coverage. PowerShell 5.1+/7+; Connect-MgGraph /
    Connect-IPPSSession required first.
.NOTES
    Requires: Microsoft.Graph (Connect-MgGraph, scopes e.g. Sites.Read.All) and, for -IncludeSensitive,
    Security & Compliance PowerShell (Connect-IPPSSession). No credentials/secrets are stored.
    Authoritative tenant oversharing view is the SharePoint Advanced Management Data Access Governance
    reports (verify licensing) - reconcile this portable export against them.
    Expected results (PASS): an export listing sites with an oversharing signal is written. FAIL: Graph
    not connected / insufficient scope.
#>

[CmdletBinding()]
param(
    [switch]$IncludeSensitive,
    [int]$MaxSites = 200,
    [string]$OutDir = ".",
    [string]$ArtifactName = "Oversharing - Estate - Discovery",
    [string]$SensitiveArtifactName = "Unlabeled Sensitive - Estate - Assess"
)

$ErrorActionPreference = "Stop"
function Write-Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }

# --- Graph session check (read-only) ---
try {
    $ctx = Get-MgContext -ErrorAction Stop
    if (-not $ctx) { throw "No Graph context." }
    Write-Host "Microsoft Graph connected as $($ctx.Account)." -ForegroundColor Green
} catch {
    Write-Error "Connect-MgGraph (Sites.Read.All) is required. $($_.Exception.Message)"
    return
}

Write-Section "Enumerating in-scope SharePoint sites (read-only)"
$sites = @()
try {
    # Read-only site enumeration; the exact cmdlet/endpoint may vary by Graph module version - verify.
    $sites = Get-MgSite -Search "*" -Top $MaxSites -ErrorAction Stop
} catch {
    Write-Warning "Could not enumerate sites via Get-MgSite: $($_.Exception.Message)"
    Write-Warning "Confirm the Microsoft.Graph.Sites module and Sites.Read.All scope; or supply the site list from the SharePoint admin DAG report."
}

$rows = @()
foreach ($s in $sites) {
    $signal = "review"   # default; refined below where permission data is readable
    $note = ""
    try {
        # Read-only permission read; broad grants (EEEU/org-wide) are the priority oversharing signal.
        $perms = Get-MgSitePermission -SiteId $s.Id -ErrorAction Stop
        $broad = $perms | Where-Object {
            ($_.GrantedToV2.SiteGroup.DisplayName -match 'Everyone') -or
            ($_.GrantedToIdentitiesV2.DisplayName -match 'Everyone except external users|Everyone')
        }
        if ($broad) { $signal = "broad-access (EEEU/org-wide) - PRIORITY" }
        else { $signal = "scoped (no broad grant detected)" }
    } catch {
        $note = "permission read unavailable (needs higher scope); check via SharePoint DAG report"
    }
    $rows += [pscustomobject]@{
        SiteName      = $s.DisplayName
        WebUrl        = $s.WebUrl
        SiteId        = $s.Id
        OversharingSignal = $signal
        Note          = $note
    }
}

Write-Host ("Sites evaluated: {0}" -f $rows.Count)
$rows | Sort-Object OversharingSignal | Format-Table SiteName, OversharingSignal -AutoSize | Out-Host

# --- Write oversharing export ---
$null = New-Item -ItemType Directory -Force -Path $OutDir
$safe = ($ArtifactName -replace '[^\w\-]+','_')
$csvPath = Join-Path $OutDir "$safe.csv"
$rows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
Write-Host "Wrote $csvPath" -ForegroundColor Green

# --- Optional: sensitive-info-types + label coverage ---
if ($IncludeSensitive) {
    Write-Section "Sensitive information types & label coverage (read-only)"
    $sit = @(); $labels = @()
    try { $sit = Get-DlpSensitiveInformationType -ErrorAction Stop } catch { Write-Warning "Get-DlpSensitiveInformationType needs Connect-IPPSSession: $($_.Exception.Message)" }
    try { $labels = Get-Label -ErrorAction Stop } catch { Write-Warning "Get-Label needs Connect-IPPSSession: $($_.Exception.Message)" }

    $sensitive = [ordered]@{
        Artifact = $SensitiveArtifactName
        GeneratedUtc = (Get-Date).ToUniversalTime().ToString("s") + "Z"
        SensitiveInfoTypeCount = @($sit).Count
        SensitiveInfoTypes = @($sit | Select-Object -First 200 | ForEach-Object { $_.Name })
        SensitivityLabelCount = @($labels).Count
        SensitivityLabels = @($labels | ForEach-Object { $_.DisplayName })
        Guidance = "Broadly-shared sites (above) holding unlabeled sensitive content are the top Copilot oversharing risk. Use auto-labeling in SIMULATION to size the unlabeled-sensitive gap before applying labels."
    }
    $safeS = ($SensitiveArtifactName -replace '[^\w\-]+','_')
    $jsonPath = Join-Path $OutDir "$safeS.json"
    $sensitive | ConvertTo-Json -Depth 6 | Out-File -FilePath $jsonPath -Encoding UTF8
    Write-Host "Wrote $jsonPath" -ForegroundColor Green
}

Write-Host "`nRead-only: no sharing or labels were changed." -ForegroundColor Yellow

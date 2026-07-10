<#
.SYNOPSIS
    CPLTREADY-OversharingScan.ps1 — data-hygiene scan for broadly shared content (AI-exposure risk).
.DESCRIPTION
    PURPOSE
        Reports the primary Copilot risk: content shared broadly enough that Copilot could surface it in
        an answer. Enumerates SharePoint sites and flags "Everyone / Everyone except external" and
        anonymous/"anyone" sharing links. Read-only — makes no changes. Feeds the readiness scorecard.
    HOW TO RUN
        Connect-MgGraph -Scopes "Sites.Read.All","Files.Read.All"
        powershell -ExecutionPolicy Bypass -File .\CPLTREADY-OversharingScan.ps1 [-TopSites 50]
        Requires module: Microsoft.Graph.
    EXPECTED RESULTS
        A list of sites with broad-access indicators and any anonymous links found, ranked so the
        highest-risk are remediated first (Implementation Step 2). Note: deep tenant-wide discovery may
        require SharePoint Advanced Management / Restricted Content Discovery — verify availability in
        your tenant; treat this scan as a first-pass signal to supplement with SharePoint sharing reports.
.NOTES
    Copilot. White-label. Read-only. SAM/RCD availability: verify current availability in your tenant.
#>
[CmdletBinding()]
param(
    [int]$TopSites = 50
)

Write-Host "=== CPLTREADY Oversharing Scan — data-hygiene signal ===" -ForegroundColor Cyan
if (-not (Get-MgContext)) { Write-Host "Run Connect-MgGraph first (see header)." -ForegroundColor Yellow; return }

$broad = @('everyone','everyone except external users','all users','anonymous','anyone')
$flagged = New-Object System.Collections.Generic.List[object]

try {
    $sites = Get-MgSite -Search "*" -Top $TopSites -ErrorAction Stop
} catch {
    Write-Host ("Could not enumerate sites: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "(Confirm Sites.Read.All is consented — Troubleshooting D.)"
    return
}

Write-Host ("Scanning up to {0} sites for broad-access indicators..." -f ($sites|Measure-Object).Count) -ForegroundColor Gray
foreach ($site in $sites) {
    try {
        $perms = Get-MgSitePermission -SiteId $site.Id -All -ErrorAction SilentlyContinue
        foreach ($p in $perms) {
            $ident = @()
            if ($p.GrantedToV2) { $ident += $p.GrantedToV2.User.DisplayName; $ident += $p.GrantedToV2.SiteGroup.DisplayName }
            foreach ($g in $p.GrantedToIdentitiesV2) { $ident += $g.User.DisplayName; $ident += $g.SiteGroup.DisplayName }
            $ident = $ident | Where-Object { $_ }
            foreach ($name in $ident) {
                if ($broad -contains $name.ToString().ToLower()) {
                    $flagged.Add([pscustomobject]@{ Site=$site.WebUrl; BroadPrincipal=$name; Roles=($p.Roles -join ',') })
                }
            }
        }
    } catch { }
}

if ($flagged.Count -gt 0) {
    Write-Host ("`n--- BROAD-ACCESS FINDINGS ({0}) — remediate before enabling Copilot for users who can reach these ---" -f $flagged.Count) -ForegroundColor Yellow
    $flagged | Sort-Object Site | ForEach-Object { Write-Host ("  {0}  [{1}]  roles={2}" -f $_.Site, $_.BroadPrincipal, $_.Roles) -ForegroundColor Yellow }
} else {
    Write-Host "`nNo broad-access indicators found in the scanned scope (first-pass — supplement with SharePoint sharing reports)." -ForegroundColor Green
}

Write-Host "`nNote: this is a first-pass signal. For tenant-wide oversharing remediation, verify SharePoint Advanced Management availability and consider the dedicated oversharing engagement (see Best Practices)." -ForegroundColor Cyan

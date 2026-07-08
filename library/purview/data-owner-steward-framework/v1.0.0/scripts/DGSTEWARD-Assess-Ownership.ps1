<#
.SYNOPSIS
    DGSTEWARD-Assess-Ownership.ps1 — read-only inventory of in-scope Purview controls and their recorded owner/steward (no changes).
.DESCRIPTION
    PURPOSE
        Builds the ownership-coverage baseline for the data-owner/steward framework: inventories the
        in-scope Purview controls (sensitivity labels, DLP policies, retention policies) via Security &
        Compliance PowerShell, and — where the Data Governance data-plane is available in your tenant —
        governance domains via Microsoft Graph, reporting for each whether an owner and steward are
        recorded in its comment/metadata. Read-only — makes no changes. Writes the export
        "Data Ownership Inventory - Steward - Assess".
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DGSTEWARD-Assess-Ownership.ps1 -CsvPath .\OwnershipInventory.csv
        PowerShell 5.1+ or 7+. Requires ExchangeOnlineManagement (Connect-IPPSSession); optional Microsoft
        Graph SDK for governance domains. Graph read scopes (optional): Organization.Read.All.
    EXPECTED RESULTS
        A console + optional CSV inventory of each control with Owner/Steward = recorded or (unowned).
        PASS = you can state a coverage number per surface and a named list of gaps to close.
.NOTES
    Purview — Data-Owner & Steward Framework. Read-only. No secrets in code. Owner/steward convention:
    a tag written to the object comment as "Owner=<name>; Steward=<name>; Reviewed=<date>; ReviewBy=<date>".
    The Unified Catalog / Data Governance experience is evolving and partly in preview — the governance-domain
    read is attempted only if you supply -DataGovernanceUri and is flagged, never assumed. Verify in your tenant.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [string]$DataGovernanceUri,   # optional Graph data-governance endpoint if available in your tenant; skipped if omitted
    [string]$ReportName = 'Data Ownership Inventory - Steward - Assess'
)

Write-Host ("=== {0} ===" -f $ReportName) -ForegroundColor Cyan

# --- Connect Security & Compliance PowerShell (read-only) ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

# --- Helper: parse an Owner=/Steward= tag out of an object's comment/description ---
function Get-OwnershipTag {
    param([string]$Text)
    $owner = $null; $steward = $null; $reviewed = $null; $reviewBy = $null
    if ($Text) {
        if ($Text -match 'Owner\s*=\s*([^;]+)')    { $owner    = $Matches[1].Trim() }
        if ($Text -match 'Steward\s*=\s*([^;]+)')  { $steward  = $Matches[1].Trim() }
        if ($Text -match 'Reviewed\s*=\s*([^;]+)') { $reviewed = $Matches[1].Trim() }
        if ($Text -match 'ReviewBy\s*=\s*([^;]+)') { $reviewBy = $Matches[1].Trim() }
    }
    [pscustomobject]@{ Owner = $owner; Steward = $steward; Reviewed = $reviewed; ReviewBy = $reviewBy }
}

$rows = New-Object System.Collections.Generic.List[object]

# --- Sensitivity labels ---
Write-Host '--- Sensitivity labels ---' -ForegroundColor Cyan
foreach ($l in (Get-Label -ErrorAction SilentlyContinue)) {
    $tag = Get-OwnershipTag -Text ($l.Comment)
    $rows.Add([pscustomobject]@{ ControlType='SensitivityLabel'; Name=$l.DisplayName; Identity=$l.Name;
        Owner=$tag.Owner; Steward=$tag.Steward; Reviewed=$tag.Reviewed; ReviewBy=$tag.ReviewBy;
        Status=$(if ($tag.Owner -and $tag.Steward) {'Owned'} elseif ($tag.Owner -or $tag.Steward) {'Partial'} else {'Unowned'}) })
}

# --- DLP policies ---
Write-Host '--- DLP policies ---' -ForegroundColor Cyan
foreach ($p in (Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    $tag = Get-OwnershipTag -Text ($p.Comment)
    $rows.Add([pscustomobject]@{ ControlType='DlpPolicy'; Name=$p.Name; Identity=$p.Guid;
        Owner=$tag.Owner; Steward=$tag.Steward; Reviewed=$tag.Reviewed; ReviewBy=$tag.ReviewBy;
        Status=$(if ($tag.Owner -and $tag.Steward) {'Owned'} elseif ($tag.Owner -or $tag.Steward) {'Partial'} else {'Unowned'}) })
}

# --- Retention policies ---
Write-Host '--- Retention policies ---' -ForegroundColor Cyan
foreach ($r in (Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue)) {
    $tag = Get-OwnershipTag -Text ($r.Comment)
    $rows.Add([pscustomobject]@{ ControlType='RetentionPolicy'; Name=$r.Name; Identity=$r.Guid;
        Owner=$tag.Owner; Steward=$tag.Steward; Reviewed=$tag.Reviewed; ReviewBy=$tag.ReviewBy;
        Status=$(if ($tag.Owner -and $tag.Steward) {'Owned'} elseif ($tag.Owner -or $tag.Steward) {'Partial'} else {'Unowned'}) })
}

# --- Governance domains (optional, only if the data-plane URI was supplied and available) ---
if ($DataGovernanceUri) {
    Write-Host '--- Governance domains (Unified Catalog — verify API availability in your tenant) ---' -ForegroundColor Yellow
    try {
        if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
            Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
        }
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        Connect-MgGraph -Scopes 'Organization.Read.All' -NoWelcome
        $domains = (Invoke-MgGraphRequest -Method GET -Uri $DataGovernanceUri -ErrorAction Stop).value
        foreach ($d in $domains) {
            $rows.Add([pscustomobject]@{ ControlType='GovernanceDomain'; Name=$d.name; Identity=$d.id;
                Owner=$d.owner; Steward=$d.steward; Reviewed=$null; ReviewBy=$null;
                Status=$(if ($d.owner) {'Owned'} else {'Unowned'}) })
        }
        Disconnect-MgGraph | Out-Null
    } catch {
        Write-Warning ("Governance-domain read skipped — the Data Governance API was not reachable at the supplied URI: {0}" -f $_.Exception.Message)
        Write-Warning 'Verify the current Unified Catalog data-plane API/path in your tenant; assign governance-domain owners in the portal if the API is unavailable.'
    }
} else {
    Write-Host 'Governance-domain inventory skipped (no -DataGovernanceUri supplied). Assign/verify domain owners in the Purview portal.' -ForegroundColor DarkGray
}

# --- Coverage summary ---
$total   = $rows.Count
$owned   = @($rows | Where-Object { $_.Status -eq 'Owned' }).Count
$partial = @($rows | Where-Object { $_.Status -eq 'Partial' }).Count
$unowned = @($rows | Where-Object { $_.Status -eq 'Unowned' }).Count
Write-Host '--- Ownership coverage ---' -ForegroundColor Cyan
$rows | Format-Table ControlType, Name, Owner, Steward, Status -AutoSize
Write-Host ("Coverage: {0}/{1} owned, {2} partial, {3} unowned" -f $owned, $total, $partial, $unowned) -ForegroundColor $(if ($unowned -eq 0 -and $partial -eq 0) {'Green'} else {'Yellow'})

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved '{0}' to {1}" -f $ReportName, $CsvPath) -ForegroundColor Green
}

Disconnect-ExchangeOnline -Confirm:$false | Out-Null
Write-Host 'Ownership assessment complete (read-only).' -ForegroundColor Green

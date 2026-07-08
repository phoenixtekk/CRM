<#
.SYNOPSIS
    OPSTRAIN-Readiness.ps1 — training environment readiness/health check: connectivity, scope, and Purview feature visibility (read-only).
.DESCRIPTION
    PURPOSE
        The scope/health helper for the Purview Administrator Training curriculum. Confirms the training
        workstation is connected to Security & Compliance PowerShell (and, if available, Microsoft Graph),
        reports the connected tenant and the readable role context, checks whether the training scope group
        (default TRAIN-Pilot-Users) exists, and probes which Purview feature areas are READABLE (labels,
        DLP, retention, auto-labeling, audit) — warning where a feature is not readable (very often
        LICENSING, which means that lab runs as a read-only walkthrough). Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession); Microsoft Graph
        optional for the scope-group check:
          Connect-IPPSSession
          Connect-MgGraph -Scopes "Group.Read.All"   # optional, enables the scope-group check
          .\OPSTRAIN-Readiness.ps1
          .\OPSTRAIN-Readiness.ps1 -ScopeGroup "TRAIN-Pilot-Users"
    EXPECTED RESULTS
        A readiness summary to the console and to .\OPSTRAIN-Readiness.csv. PASS = connected, scope status
        reported, and the feature areas your curriculum covers are listed READABLE. Any WARN feature is
        planned as a walkthrough, not a failure.
.NOTES
    White-label Microsoft Purview training tooling. Read-only. No credentials stored. Cmdlets are standard
    Security & Compliance PowerShell / Microsoft Graph; none are invented. Feature availability is
    licensing-dependent — the script WARNS where a feature is not readable rather than assuming it exists.
#>
[CmdletBinding()]
param(
    [string]$ScopeGroup = "TRAIN-Pilot-Users",
    [string]$OutPath    = ".\OPSTRAIN-Readiness.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== OPSTRAIN Readiness — training environment health (read-only) ===" -ForegroundColor Cyan

$rows = [System.Collections.Generic.List[object]]::new()
function Add-Check($area, $status, $detail) {
    $rows.Add([pscustomobject]@{ Area = $area; Status = $status; Detail = $detail })
    $color = switch ($status) { "PASS" { "Green" } "WARN" { "Yellow" } default { "Red" } }
    Write-Host ("  [{0}] {1} — {2}" -f $status, $area, $detail) -ForegroundColor $color
}

# --- Security & Compliance PowerShell connectivity (labels are the canonical read probe) ---
try {
    Get-Label -ErrorAction Stop | Out-Null
    Add-Check "S&C PowerShell" "PASS" "Connected (Get-Label succeeded)"
} catch {
    Add-Check "S&C PowerShell" "FAIL" "Not connected — run Connect-IPPSSession first (GR §3). $($_.Exception.Message)"
    $rows | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8
    Write-Host "`nStop: connect to Security & Compliance PowerShell and re-run." -ForegroundColor Red
    return
}

# --- Microsoft Graph (optional) + connected tenant / role context ---
$graphOk = $false
try {
    $ctx = Get-MgContext -ErrorAction Stop
    if ($ctx) {
        $graphOk = $true
        Add-Check "Microsoft Graph" "PASS" ("Connected — Tenant={0}; Account={1}" -f $ctx.TenantId, $ctx.Account)
    } else {
        Add-Check "Microsoft Graph" "WARN" "Not connected — Connect-MgGraph to enable the scope-group check"
    }
} catch {
    Add-Check "Microsoft Graph" "WARN" "Not connected/unavailable — Connect-MgGraph to enable the scope-group check"
}

# --- Training scope group presence (Graph) ---
if ($graphOk) {
    try {
        $grp = Get-MgGroup -Filter "displayName eq '$ScopeGroup'" -ErrorAction Stop
        if ($grp) {
            $memberCount = 0
            try { $memberCount = (Get-MgGroupMember -GroupId $grp.Id -All -ErrorAction Stop | Measure-Object).Count } catch {}
            Add-Check "Training scope group" "PASS" ("'{0}' present (Id={1}; members={2}) — confirm these are TEST accounts only" -f $ScopeGroup, $grp.Id, $memberCount)
        } else {
            Add-Check "Training scope group" "WARN" ("'{0}' not found — create it (OPSTRAIN-LabScope.ps1 -Commit) before the labs" -f $ScopeGroup)
        }
    } catch {
        Add-Check "Training scope group" "WARN" ("Could not query '{0}' (needs Group.Read.All): {1}" -f $ScopeGroup, $_.Exception.Message)
    }
} else {
    Add-Check "Training scope group" "WARN" ("Skipped — connect Graph to check '{0}'" -f $ScopeGroup)
}

# --- Purview feature-area readability probes (read-only; WARN = likely unlicensed → walkthrough) ---
$featureProbes = @(
    @{ Area = "Sensitivity labels (Module 1)"; Probe = { Get-Label -ErrorAction Stop } },
    @{ Area = "Label policies (Module 1)";     Probe = { Get-LabelPolicy -ErrorAction Stop } },
    @{ Area = "DLP (Module 2)";                Probe = { Get-DlpCompliancePolicy -ErrorAction Stop } },
    @{ Area = "Auto-labeling (Module 4)";      Probe = { Get-AutoSensitivityLabelPolicy -ErrorAction Stop } },
    @{ Area = "Retention (Module 3)";          Probe = { Get-RetentionCompliancePolicy -ErrorAction Stop } }
)
foreach ($f in $featureProbes) {
    try {
        $items = & $f.Probe
        Add-Check $f.Area "PASS" ("readable ({0} object(s))" -f @($items).Count)
    } catch {
        Add-Check $f.Area "WARN" ("not readable — likely unlicensed; run this lab as a walkthrough. {0}" -f $_.Exception.Message)
    }
}

# --- Audit readability (short, bounded probe) ---
try {
    Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-1) -EndDate (Get-Date) -ResultSize 1 -ErrorAction Stop | Out-Null
    Add-Check "Audit search (Module 7)" "PASS" "Search-UnifiedAuditLog readable"
} catch {
    Add-Check "Audit search (Module 7)" "WARN" ("not readable — check auditing is on / licensing. {0}" -f $_.Exception.Message)
}

$rows | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8
$fail = @($rows | Where-Object Status -eq "FAIL").Count
$warn = @($rows | Where-Object Status -eq "WARN").Count
Write-Host ("`nReadiness written to {0}  (FAIL={1}, WARN={2})" -f $OutPath, $fail, $warn) -ForegroundColor Green
Write-Host "Next: OPSTRAIN-LabScope.ps1 (create the training scope), then OPSTRAIN-LabBaseline.ps1 (snapshot)." -ForegroundColor Cyan

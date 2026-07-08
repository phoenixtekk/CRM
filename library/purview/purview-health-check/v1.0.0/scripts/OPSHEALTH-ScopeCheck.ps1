<#
.SYNOPSIS
    OPSHEALTH-ScopeCheck.ps1 — coverage-per-workload map + least-privilege role review (read-only).
.DESCRIPTION
    PURPOSE
        The scope/health helper for the health check. Reads each DLP / retention / label policy and maps
        which WORKLOADS it actually reaches (Exchange / SharePoint / OneDrive / Teams / endpoints) so the
        Coverage (C) domain can be scored against the in-scope map (R3), and runs the least-privilege
        ROLE review (R) — compliance role-group membership plus, via Microsoft Graph, Global Admin count,
        single-member (SPOF) and empty role groups. Read-only — changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\OPSHEALTH-ScopeCheck.ps1
        powershell -ExecutionPolicy Bypass -File .\OPSHEALTH-ScopeCheck.ps1 -CsvPath .\opshealth-coverage.csv

        Prereqs: ExchangeOnlineManagement (Connect-IPPSSession) and Microsoft.Graph (Connect-MgGraph,
        Directory.Read.All / RoleManagement.Read.Directory) with an MFA-capable admin holding read access.
        Verify capability availability against your licensing/tenant.
    EXPECTED RESULTS
        A per-workload coverage table for DLP/retention/label policies (Coverage domain) and a role
        review (Global Admin count, single-member/empty role groups). PASS = coverage maps to the R3
        in-scope map and the role review is clean; blind spots and role drift are recorded as findings.
.NOTES
    White-label. Read-only. Security & Compliance PowerShell + Microsoft Graph. No credentials in code.
#>
[CmdletBinding()]
param(
    [int]    $GlobalAdminThreshold = 5,
    [string] $CsvPath
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }
$findings = New-Object System.Collections.Generic.List[object]
function Add-Finding($Domain, $Rating, $Detail) { $findings.Add([pscustomobject]@{ Domain = $Domain; Rating = $Rating; Detail = $Detail }) }

# --- Connect: Security & Compliance PowerShell ------------------------------------------------------
try {
    Write-Section 'Connecting to Security & Compliance PowerShell'
    if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) { Connect-IPPSSession | Out-Null }
    Write-Host 'Connected.' -ForegroundColor Green
}
catch { Write-Error ("Failed to connect: {0}" -f $_.Exception.Message); return }

# --- Coverage: map each policy to the workloads it reaches ------------------------------------------
Write-Section 'Coverage (C) — workloads reached per policy'
function Show-Coverage($items, $label) {
    if (-not $items -or $items.Count -eq 0) { Write-Host ("  No {0} found." -f $label) -ForegroundColor Yellow; return }
    foreach ($p in $items) {
        $wl = $p.Workload
        if (-not $wl) { $wl = '(workload not reported — confirm locations in the portal)' }
        Write-Host ("  [{0}] {1}  ->  {2}" -f $label, $p.Name, $wl)
        # Heuristic blind-spot flag: email-only DLP is a common partial-coverage pattern.
        if ($label -eq 'DLP' -and $wl -match 'Exchange' -and $wl -notmatch 'SharePoint|OneDrive|Teams|EndpointDevices') {
            Add-Finding 'C' 'At Risk' ("DLP '{0}' appears to cover Exchange only — confirm intended SharePoint/OneDrive/Teams/endpoint coverage (R3)." -f $p.Name)
        }
    }
}
try { Show-Coverage @(Get-DlpCompliancePolicy -ErrorAction Stop) 'DLP' }              catch { Add-Finding 'C' 'At Risk' 'DLP coverage unreadable — read-access finding.' }
try { Show-Coverage @(Get-RetentionCompliancePolicy -ErrorAction Stop) 'Retention' } catch { Add-Finding 'C' 'At Risk' 'Retention coverage unreadable — read-access finding.' }
try {
    $labelPolicies = @(Get-LabelPolicy -ErrorAction Stop)
    if ($labelPolicies.Count -eq 0) { Write-Host '  No label policies — labels (if any) are unpublished.' -ForegroundColor Yellow; Add-Finding 'C' 'Gap' 'No label policy publishes any label.' }
    else { $labelPolicies | Select-Object Name, Enabled | Format-Table -AutoSize }
} catch { Add-Finding 'C' 'At Risk' 'Label policies unreadable — read-access finding.' }
Write-Host 'NOTE: map the above against your R3 in-scope workload map — an intended-but-uncovered workload is a Coverage Gap.' -ForegroundColor DarkYellow

# --- Roles: compliance role groups (S&C) -----------------------------------------------------------
Write-Section 'Roles (R) — compliance role-group least-privilege review'
try {
    $rg = @(Get-RoleGroup -ErrorAction Stop)
    Write-Host ("  Compliance role groups: {0}" -f $rg.Count)
    foreach ($g in $rg) {
        $members = @(Get-RoleGroupMember -Identity $g.Name -ErrorAction SilentlyContinue)
        if ($members.Count -eq 0)      { Add-Finding 'R' 'At Risk' ("Role group '{0}' is EMPTY (Gap if critical)." -f $g.Name) }
        elseif ($members.Count -eq 1)  { Add-Finding 'R' 'At Risk' ("Role group '{0}' has a SINGLE member (SPOF)." -f $g.Name) }
    }
}
catch { Write-Warning ("Could not read compliance role groups: {0}" -f $_.Exception.Message); Add-Finding 'R' 'At Risk' 'Compliance role groups unreadable — read-access finding.' }

# --- Roles: Global Administrator sprawl (Microsoft Graph) -------------------------------------------
Write-Section 'Roles (R) — Global Administrator sprawl (Microsoft Graph)'
try {
    if (-not (Get-Command Get-MgDirectoryRole -ErrorAction SilentlyContinue)) {
        Import-Module Microsoft.Graph.Identity.DirectoryManagement -ErrorAction Stop
    }
    if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'RoleManagement.Read.Directory','Directory.Read.All' -NoWelcome }
    $gaRole = Get-MgDirectoryRole -All -ErrorAction Stop | Where-Object { $_.DisplayName -eq 'Global Administrator' } | Select-Object -First 1
    if ($gaRole) {
        $gaMembers = @(Get-MgDirectoryRoleMember -DirectoryRoleId $gaRole.Id -All -ErrorAction SilentlyContinue)
        Write-Host ("  Global Administrators: {0} (threshold {1})" -f $gaMembers.Count, $GlobalAdminThreshold)
        if ($gaMembers.Count -gt $GlobalAdminThreshold) {
            Add-Finding 'R' 'Gap' ("Global Administrator sprawl: {0} GAs exceeds threshold {1} — reduce to least privilege." -f $gaMembers.Count, $GlobalAdminThreshold)
        }
    } else { Write-Host '  Global Administrator role not activated/returned — confirm via Graph read access.' -ForegroundColor Yellow }
}
catch {
    Write-Warning ("Could not read directory roles via Graph: {0}" -f $_.Exception.Message)
    Add-Finding 'R' 'At Risk' 'Global Admin count unreadable — confirm Graph RoleManagement.Read.Directory. Verify in tenant.'
}

# --- Summary ----------------------------------------------------------------------------------------
Write-Section 'Coverage + role review complete'
if ($findings.Count -gt 0) {
    Write-Host ("Findings for scoring ({0}):" -f $findings.Count) -ForegroundColor Yellow
    $findings | Format-Table -AutoSize
    if ($CsvPath) { $findings | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host ("Written to {0}" -f $CsvPath) -ForegroundColor Green }
} else { Write-Host 'No coverage/role findings from the heuristics — score against your R3 map and R4 baseline.' -ForegroundColor Green }
Write-Host 'Next: score P/C/R, build the Remediation Register, then OPSHEALTH-Report.ps1.'

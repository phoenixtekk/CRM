<#
.SYNOPSIS
    EDREADY-Reporting.ps1 — read-only readiness scorecard / gap register / evidence pack.
.DESCRIPTION
    Renders the readiness scorecard (Roles/Holds/Scope/Process scored Not Ready/Partial/Ready) from
    the live signals it can read, lists the readiness-proof artifacts and their status (case, hold,
    search statistics), and can export the scorecard + gap register to CSV for the deliverable
    evidence pack. Makes NO changes. Domain scores for Scope and Process that are interview-based are
    passed in as parameters; the tool fills technical R/H signals automatically.
.EXAMPLE
    .\EDREADY-Reporting.ps1
    Print the scorecard and proof status to the console.
.EXAMPLE
    .\EDREADY-Reporting.ps1 -ScopeScore Partial -ProcessScore NotReady -OutDir .\edready-evidence
    Include interview-based S/P scores and write scorecard.csv + gap-register.csv to a folder.
.NOTES
    Expected results: a scorecard table, proof artifact status, and (with -OutDir) CSV evidence files.
    White-label. Read-only. Uses Get-RoleGroupMember / Get-AdminAuditLogConfig / Get-ComplianceCase /
    Get-CaseHoldPolicy / Get-ComplianceSearch. Proof names match 03-implementation.md.
#>
[CmdletBinding()]
param(
    [ValidateSet('NotReady','Partial','Ready')] [string]$ScopeScore   = 'Partial',
    [ValidateSet('NotReady','Partial','Ready')] [string]$ProcessScore = 'Partial',
    [string]$ProofCase       = 'eDiscovery Readiness – Proof – Pilot',
    [string]$ProofHoldPolicy = 'Readiness Hold Policy – Proof – Pilot',
    [string]$ProofSearch     = 'Readiness Search – Proof – Pilot',
    [string]$OutDir
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host "`n=== eDiscovery Readiness — scorecard & evidence pack (read-only) ===" -ForegroundColor Cyan

# --- Technical signals for R and H ---
$mgr = @(Get-RoleGroupMember -Identity 'eDiscovery Manager' -ErrorAction SilentlyContinue).Count
$adm = @(Get-RoleGroupMember -Identity 'eDiscovery Administrator' -ErrorAction SilentlyContinue).Count
$ga  = @(Get-RoleGroupMember -Identity 'Organization Management' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
$eDiscNames = @(Get-RoleGroupMember -Identity 'eDiscovery Manager' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name) +
              @(Get-RoleGroupMember -Identity 'eDiscovery Administrator' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
$gaOverlap = @($eDiscNames | Where-Object { $ga -contains $_ } | Select-Object -Unique).Count
$auditOn = $false
try { $auditOn = [bool](Get-AdminAuditLogConfig -ErrorAction Stop).UnifiedAuditLogIngestionEnabled } catch {}

$rScore = if (($mgr -ge 2) -and ($gaOverlap -eq 0)) { 'Ready' } elseif ($mgr -ge 1) { 'Partial' } else { 'NotReady' }
$hScore = if ($auditOn) { 'Ready' } else { 'NotReady' }

# --- Scorecard ---
$scorecard = @(
    [pscustomobject]@{ Domain='R - Roles & least privilege'; Score=$rScore;       Evidence=("Managers={0}, Admins={1}, GlobalAdmin-overlap={2}" -f $mgr,$adm,$gaOverlap) }
    [pscustomobject]@{ Domain='H - Holds & preservation';    Score=$hScore;       Evidence=("Unified audit log on = {0}; prove hold via readiness proof" -f $auditOn) }
    [pscustomobject]@{ Domain='S - Data-source scope';        Score=$ScopeScore;   Evidence='From EDREADY-Scope.ps1 + scope note (Teams/M365 Groups/inactive)' }
    [pscustomobject]@{ Domain='P - Process & defensibility';  Score=$ProcessScore; Evidence='Intake + legal sign-off, naming, change control, evidence pack' }
)
Write-Host "`n--- Readiness scorecard ---" -ForegroundColor Cyan
$scorecard | Format-Table -AutoSize

# --- Gap register (below-Ready domains) ---
$sevMap = @{ 'R - Roles & least privilege'='High'; 'H - Holds & preservation'='High'; 'S - Data-source scope'='Medium'; 'P - Process & defensibility'='Medium' }
$gaps = $scorecard | Where-Object { $_.Score -ne 'Ready' } | ForEach-Object {
    [pscustomobject]@{ Domain=$_.Domain; Severity=$sevMap[$_.Domain]; Finding=("Score={0}" -f $_.Score); Evidence=$_.Evidence; Owner='<assign>'; Action='<remediation>' }
}
Write-Host "`n--- Gap register (below-Ready domains) ---" -ForegroundColor Cyan
if ($gaps) { $gaps | Format-Table -AutoSize } else { Write-Host "  No gaps — all domains Ready." -ForegroundColor Green }

# --- Readiness-proof artifact status ---
Write-Host "`n--- Readiness-proof artifacts ---" -ForegroundColor Cyan
$case = Get-ComplianceCase -Identity $ProofCase -ErrorAction SilentlyContinue
Write-Host ("  Case   '{0}': {1}" -f $ProofCase, $(if($case){'present ('+$case.Status+')'}else{'absent'}))
$hold = Get-CaseHoldPolicy -Identity $ProofHoldPolicy -ErrorAction SilentlyContinue
Write-Host ("  Hold   '{0}': {1}" -f $ProofHoldPolicy, $(if($hold){'present (Enabled='+$hold.Enabled+')'}else{'absent (removed = good post-cleanup)'}))
$srch = Get-ComplianceSearch -Identity $ProofSearch -ErrorAction SilentlyContinue
if ($srch) { Write-Host ("  Search '{0}': status={1}, items={2}, size={3}" -f $ProofSearch, $srch.Status, $srch.Items, $srch.Size) }
else { Write-Host ("  Search '{0}': absent" -f $ProofSearch) }

# --- Optional CSV export ---
if ($OutDir) {
    if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }
    $scorecard | Export-Csv -NoTypeInformation -Path (Join-Path $OutDir 'scorecard.csv')
    if ($gaps) { $gaps | Export-Csv -NoTypeInformation -Path (Join-Path $OutDir 'gap-register.csv') }
    Write-Host ("`n  Wrote evidence pack to: {0}" -f $OutDir) -ForegroundColor Green
}

Write-Host "`nReporting complete. Premium tier is E5-gated — record actual tier honestly (verify in your tenant)." -ForegroundColor Green
Disconnect-ExchangeOnline -Confirm:$false | Out-Null

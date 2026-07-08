<#
.SYNOPSIS
    PURVIMP-Report-ComplianceBaseline.ps1 — read-only compliance-signal baseline snapshot (Secure Score + audit + role posture) alongside the portal Compliance Manager score.
.DESCRIPTION
    PURPOSE
        Captures a dated baseline of the tenant's compliance posture so future improvement is
        measurable. Pulls Microsoft Secure Score via Graph (security/secureScores), the unified-audit
        status, and the foundation role-group posture, and records them next to the Compliance Manager
        score you supply from the portal. Read-only — makes no changes. Writes the export
        "Purview Compliance Baseline - Report".
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVIMP-Report-ComplianceBaseline.ps1 -ComplianceScore 47 -CsvPath .\PurviewBaseline.csv
        PowerShell 5.1+/7+. Requires the Microsoft Graph SDK (scopes: SecurityEvents.Read.All,
        Directory.Read.All) and ExchangeOnlineManagement. Provide -ComplianceScore from Purview portal ->
        Compliance Manager (its assessments have no fully GA PowerShell/Graph write surface — export the
        assessment from the portal: Assessments -> Export).
    EXPECTED RESULTS
        Console + CSV with the Compliance Manager score, current Secure Score (and max), audit status,
        and populated-role-group count, timestamped UTC. PASS = a dated baseline artifact is stored.
.NOTES
    Purview — Implementing Microsoft Purview: Foundation, Roles & Onboarding. Read-only. Which
    regulations/assessments apply is the compliance team's determination — this captures the baseline,
    not the target. Verify Compliance Manager / Graph availability against your tenant. No secrets in code.
#>
[CmdletBinding()]
param(
    [double]$ComplianceScore = -1,     # from Purview portal -> Compliance Manager (percentage/points)
    [string]$CsvPath,
    [string]$ReportName = 'Purview Compliance Baseline - Report'
)

Write-Host ("=== {0} ===" -f $ReportName) -ForegroundColor Cyan

# --- Secure Score (Microsoft Graph, read-only) ---
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'SecurityEvents.Read.All','Directory.Read.All' -NoWelcome

$secureScore = $null; $maxScore = $null; $scoreDate = $null
try {
    $ss = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/security/secureScores?$top=1').value | Select-Object -First 1
    if ($ss) {
        $secureScore = $ss.currentScore
        $maxScore    = $ss.maxScore
        $scoreDate   = $ss.createdDateTime
    }
} catch {
    Write-Host ("  [WARN] Secure Score unavailable: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}
Write-Host ("Secure Score: {0} / {1}  (as of {2})" -f $secureScore, $maxScore, $scoreDate) -ForegroundColor Cyan

# --- Unified audit status + role posture (Exchange Online / S&C PowerShell) ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-ExchangeOnline -ShowBanner:$false
$cfg = Get-AdminAuditLogConfig -ErrorAction SilentlyContinue
$auditOn = $false
if ($cfg -and ($cfg.PSObject.Properties.Name -contains 'UnifiedAuditLogIngestionEnabled')) {
    $auditOn = [bool]$cfg.UnifiedAuditLogIngestionEnabled
}

Connect-IPPSSession -ShowBanner:$false
$foundation = @('Compliance Administrator','Compliance Data Administrator','Records Management',
    'Insider Risk Management','eDiscovery Manager','Audit Manager','Content Explorer Content Viewer',
    'Communication Compliance')
$populated = 0
foreach ($rgName in $foundation) {
    $m = @(Get-RoleGroupMember -Identity $rgName -ErrorAction SilentlyContinue)
    if ($m.Count -gt 0) { $populated++ }
}

$baseline = [pscustomobject]@{
    CapturedUtc               = (Get-Date).ToUniversalTime().ToString('u')
    ComplianceManagerScore    = $(if ($ComplianceScore -ge 0) { $ComplianceScore } else { 'NOT SUPPLIED — enter from portal' })
    SecureScoreCurrent        = $secureScore
    SecureScoreMax            = $maxScore
    SecureScoreAsOf           = $scoreDate
    UnifiedAuditLogEnabled    = $auditOn
    FoundationRoleGroupsWithMembers = ("{0} of {1}" -f $populated, $foundation.Count)
}
Write-Host '--- Compliance baseline snapshot ---' -ForegroundColor Cyan
$baseline | Format-List

if ($ComplianceScore -lt 0) {
    Write-Host "  [NOTE] Compliance Manager score not supplied. Open Purview portal -> Compliance Manager, read the score, export the assessment (Assessments -> Export), and re-run with -ComplianceScore <value>." -ForegroundColor Yellow
}
if ($CsvPath) {
    $baseline | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved '{0}' to {1}" -f $ReportName, $CsvPath) -ForegroundColor Green
}

Disconnect-ExchangeOnline -Confirm:$false | Out-Null
Disconnect-MgGraph | Out-Null
Write-Host 'Baseline capture complete (read-only).' -ForegroundColor Green

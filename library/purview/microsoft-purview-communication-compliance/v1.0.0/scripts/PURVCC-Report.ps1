<#
.SYNOPSIS
    PURVCC-Report.ps1 — read-only alert/review ROLLUP report: policy/rule inventory, reviewer assignments, role membership, and CC activity.
.DESCRIPTION
    PURPOSE
        Produces the "Comms Review Rollup - Report": every Communication Compliance policy with its
        reviewers and its rule's scope/classifiers/conditions/sampling, the current role-group
        membership (separation evidence), and — from the unified audit log — recent Communication
        Compliance activity for oversight. Read-only — makes no changes. The authoritative alert
        and review metrics live in the Communication Compliance area of the Purview portal; this
        rolls up the configuration + activity that PowerShell can read.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVCC-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\PURVCC-Report.ps1 -DaysBack 30 -CsvPath C:\Temp\PURVCC-Rollup.csv
        Requires ExchangeOnlineManagement; connects with Connect-IPPSSession. Audit-log search
        requires unified auditing enabled in the tenant.
    EXPECTED RESULTS
        A console rollup of policies (reviewers + rule detail), role-group membership, and a count
        of recent CC audit activity. Optional CSV of the policy inventory.
.NOTES
    Purview — Microsoft Purview Communication Compliance. Read-only. No credentials stored. Verify
    capability/portal availability against your own licensing and tenant.
#>
[CmdletBinding()]
param(
    [int]$DaysBack = 30,
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Connect-IPPSSession -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null }
catch { Write-Error "Connect-IPPSSession failed: $($_.Exception.Message)."; return }

Write-Host '=== Comms Review Rollup - Report ===' -ForegroundColor Cyan

# --- Policy + rule inventory ---
$inventory = @()
try {
    $policies = @(Get-SupervisoryReviewPolicyV2 -ErrorAction Stop)
    if ($policies.Count -eq 0) {
        Write-Host '  (no Communication Compliance policies found)' -ForegroundColor DarkGray
    }
    foreach ($p in $policies) {
        Write-Host ("`n--- Policy: {0} ---" -f $p.Name) -ForegroundColor Cyan
        Write-Host ("    Reviewers : {0}" -f (@($p.Reviewers) -join ', '))
        $rules = @(Get-SupervisoryReviewRule -Policy $p.Name -ErrorAction SilentlyContinue)
        foreach ($r in $rules) {
            $classifiers = @($r.Classifiers) -join ', '
            $sits        = @($r.ContentContainsSensitiveInformation.Name) -join ', '
            Write-Host ("    Rule      : {0}" -f $r.Name)
            Write-Host ("    Supervised: {0}" -f (@($r.SupervisedGroups) -join ', '))
            Write-Host ("    Excluded  : {0}" -f ((@($r.ExcludedGroups) -join ', ') -replace '^$','(none)'))
            Write-Host ("    Classifier: {0}" -f ($classifiers -replace '^$','(none)'))
            Write-Host ("    SITs      : {0}" -f ($sits -replace '^$','(none)'))
            Write-Host ("    Sampling  : {0}" -f $r.SamplingRate)
            $inventory += [pscustomobject]@{
                Policy = $p.Name; Rule = $r.Name
                Reviewers = (@($p.Reviewers) -join '; ')
                Supervised = (@($r.SupervisedGroups) -join '; ')
                Excluded = (@($r.ExcludedGroups) -join '; ')
                Classifiers = $classifiers; SensitiveInfoTypes = $sits
                SamplingRate = $r.SamplingRate
            }
        }
    }
} catch {
    Write-Host ("  Could not enumerate policies: {0}" -f $_.Exception.Message) -ForegroundColor DarkYellow
}

# --- Role-group membership (separation evidence) ---
Write-Host "`n--- Role-group membership (separation evidence) ---" -ForegroundColor Cyan
foreach ($g in 'Communication Compliance Admin','Communication Compliance Analysts','Communication Compliance Investigators','Communication Compliance Viewers') {
    $members = @(Get-RoleGroupMember -Identity $g -ErrorAction SilentlyContinue | ForEach-Object { $_.PrimarySmtpAddress ?? $_.Name })
    Write-Host ("    {0}: {1}" -f $g, ((($members -join ', ')) -replace '^$','(empty)'))
}

# --- Recent Communication Compliance activity from the unified audit log ---
Write-Host "`n--- Communication Compliance activity (last $DaysBack days) ---" -ForegroundColor Cyan
try {
    $start = (Get-Date).AddDays(-$DaysBack)
    $end   = Get-Date
    # Supervisory-review / Communication Compliance activity is recorded under this record type.
    $events = @(Search-UnifiedAuditLog -StartDate $start -EndDate $end -RecordType ComplianceSupervisionExchange -ResultSize 500 -ErrorAction Stop)
    Write-Host ("    {0} Communication Compliance audit event(s) found." -f $events.Count)
    if ($events.Count -gt 0) {
        $events | Group-Object Operations | Sort-Object Count -Descending |
            Select-Object -First 10 | ForEach-Object { Write-Host ("      {0} : {1}" -f $_.Name, $_.Count) }
    }
} catch {
    Write-Host ("    Audit-log search unavailable: {0}" -f $_.Exception.Message) -ForegroundColor DarkYellow
    Write-Host '    Confirm unified auditing is enabled; the authoritative review metrics are in the Purview portal.' -ForegroundColor DarkGray
}

if ($CsvPath -and $inventory.Count) {
    try { $inventory | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host ("`nPolicy inventory written to {0}" -f $CsvPath) -ForegroundColor Green }
    catch { Write-Warning "Could not write CSV: $($_.Exception.Message)" }
}

Write-Host "`nRollup complete (read-only). For live alert/review metrics use Communication Compliance in the Purview portal." -ForegroundColor Cyan

<#
.SYNOPSIS
    CLSCUSTOM-Report.ps1 — read-only inventory + "where-used" report for a custom sensitive information type.
.DESCRIPTION
    PURPOSE
        Reports a custom SIT's definition (patterns, confidence levels, recommended confidence) and,
        crucially, WHERE IT IS USED — every DLP compliance policy/rule that references it — so you can
        see the blast radius before enforcing and keep reuse evidence current. Read-only — makes no
        changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CLSCUSTOM-Report.ps1 -SitName 'Custom SIT - Employee ID - Pilot'
        powershell -ExecutionPolicy Bypass -File .\CLSCUSTOM-Report.ps1 -SitName 'Custom SIT - Employee ID - Pilot' -CsvPath C:\Temp\CustomSIT-WhereUsed.csv
        Requires ExchangeOnlineManagement; connects with Connect-IPPSSession. Sign in with a compliance
        role that can read sensitive info types and DLP policies.
    EXPECTED RESULTS
        Console: the SIT's definition, then the DLP policies/rules that reference it (name + mode:
        Enable / TestWithNotifications / TestWithoutNotifications / Disable) — so simulation vs enforce
        is visible. Optional CSV of the where-used list.
.NOTES
    Purview — Custom Sensitive Information Types. Read-only. No credentials stored. Auto-labeling and
    other consuming policy types have their own cmdlets; this report covers DLP compliance policies —
    verify additional consumers in the portal. Portal/cmdlets evolve — verify against your tenant.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SitName,   # e.g. 'Custom SIT - Employee ID - Pilot'
    [string]$CsvPath
)

# --- Connect ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Connect-IPPSSession -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null }
catch { Write-Error "Connect-IPPSSession failed: $($_.Exception.Message)."; return }

# --- SIT definition ---
Write-Host ("=== Custom SIT definition : {0} ===" -f $SitName) -ForegroundColor Cyan
$sit = Get-DlpSensitiveInformationType -Identity $SitName -ErrorAction SilentlyContinue
if (-not $sit) {
    Write-Warning "SIT '$SitName' not found. Check the exact name with CLSCUSTOM-Discovery.ps1."
    return
}
Write-Host ("  Name        : {0}" -f $sit.Name)
Write-Host ("  Publisher   : {0}" -f $sit.Publisher)
Write-Host ("  Id          : {0}" -f $sit.Id)
if ($sit.RecommendedConfidence) { Write-Host ("  Recommended : {0}" -f $sit.RecommendedConfidence) }
if ($sit.Description)           { Write-Host ("  Description : {0}" -f $sit.Description) }

# --- Where used: DLP compliance policies/rules that reference the SIT ---
Write-Host ''
Write-Host '=== Where used (DLP compliance rules referencing this SIT) ===' -ForegroundColor Cyan
$whereUsed = @()
try {
    $rules = @(Get-DlpComplianceRule -ErrorAction Stop)
    foreach ($rule in $rules) {
        # ContentContainsSensitiveInformation holds the SIT references for the rule.
        $sits = @()
        if ($rule.ContentContainsSensitiveInformation) {
            $sits = @($rule.ContentContainsSensitiveInformation | ForEach-Object { $_.Name })
        }
        if ($sits -contains $SitName) {
            $policy = Get-DlpCompliancePolicy -Identity $rule.ParentPolicyName -ErrorAction SilentlyContinue
            $mode = if ($policy) { $policy.Mode } else { '(unknown)' }
            $whereUsed += [pscustomobject]@{
                Policy = $rule.ParentPolicyName; Rule = $rule.Name; Mode = $mode
            }
        }
    }
} catch {
    Write-Host ("  Could not enumerate DLP rules: {0}" -f $_.Exception.Message) -ForegroundColor DarkYellow
}

if ($whereUsed.Count -eq 0) {
    Write-Host '  (not referenced by any DLP compliance policy yet)' -ForegroundColor DarkGray
    Write-Host '  If you have piloted it, confirm the policy references this exact SIT name.' -ForegroundColor DarkGray
} else {
    foreach ($u in $whereUsed) {
        # Mode: TestWithNotifications / TestWithoutNotifications = SIMULATION; Enable = ENFORCE.
        $sim = $u.Mode -like 'Test*' -or $u.Mode -eq 'Disable'
        $tag = if ($sim) { 'SIMULATION/disabled' } else { 'ENFORCE' }
        $color = if ($sim) { 'Green' } else { 'Yellow' }
        Write-Host ("  - policy '{0}'  rule '{1}'  mode={2}  [{3}]" -f $u.Policy, $u.Rule, $u.Mode, $tag) -ForegroundColor $color
    }
    if ($whereUsed | Where-Object { $_.Mode -notlike 'Test*' -and $_.Mode -ne 'Disable' }) {
        Write-Host '  NOTE: this SIT is referenced by an ENFORCING policy — confirm it passed validation + simulation first.' -ForegroundColor Yellow
    }
}

Write-Host ''
Write-Host 'NOTE: auto-labeling and other consumers use separate cmdlets — verify those in the Purview portal too.' -ForegroundColor DarkGray

if ($CsvPath) {
    try { $whereUsed | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
          Write-Host ("`nWhere-used list written to {0}" -f $CsvPath) -ForegroundColor Green }
    catch { Write-Warning "Could not write CSV: $($_.Exception.Message)" }
}

<#
.SYNOPSIS
    OPSADOPT-KpiReport.ps1 — read-only adoption KPI dashboard + WAVE-GATE verdict: composes labeling coverage, DLP override rate, champion coverage, and comms reach from live signal plus a comms-reach CSV, and reports each KPI against its threshold. Makes no changes.
.DESCRIPTION
    PURPOSE
        Composes the program-health dashboard that decides whether a ring is ready to expand or enforce.
        Pulls the live adoption signal (via OPSADOPT-Report.ps1 style audit-log reads), champion coverage
        (via the champions/ring groups), and comms reach (from a CSV you export from your comms tooling),
        compares each KPI to its threshold, and prints the WAVE-GATE verdict: CLEAR (ready to expand /
        introduce enforce) or HOLD. Read-only.
    HOW TO RUN
        Connect-IPPSSession                                  # for live labeling/DLP signal
        Connect-MgGraph -Scopes 'Group.Read.All','User.Read.All'   # for champion coverage
        .\OPSADOPT-KpiReport.ps1 -CommsCsv .\Comms-Reach.csv -RingGroup "Adoption Ring - Purview - Wave1" `
            -ChampionsGroup "Champions - Purview - Adoption" -RosterCsv .\Champions-Roster.csv
        Comms CSV columns: Wave, Sent, Reached  (Reached = opened/attended count)
        PowerShell 5.1+/7+; ExchangeOnlineManagement + Microsoft.Graph. Read-only.
    EXPECTED RESULTS
        A KPI table (value vs threshold vs pass/fail) for labeling coverage %, DLP override rate %, champion
        coverage %, comms reach %, and the overall WAVE-GATE verdict. All KPIs at/above threshold = CLEAR.
.NOTES
    Purview — Adoption Program. Read-only. Compliance Manager and comms tooling have no single public API for
    this — comms reach is CSV-in by design. KPIs are AGGREGATE (privacy-by-design). Thresholds below are
    defaults; agree your own. Verify audit availability/licensing for your tenant.
#>
[CmdletBinding()]
param(
    [int]$Days = 14,
    [string]$RingGroup,
    [string]$ChampionsGroup,
    [string]$RosterCsv,
    [string]$CommsCsv,
    # Wave-gate thresholds (percent). Agree your own with compliance/leadership.
    [double]$MinLabelingCoverage = 70,
    [double]$MaxDlpOverrideRate  = 15,
    [double]$MinChampionCoverage = 100,
    [double]$MinCommsReach       = 80,
    [string]$CsvPath
)

$kpis = New-Object System.Collections.Generic.List[object]
function Add-Kpi { param($Name,$Value,$Threshold,$Direction)
    $pass = if ($null -eq $Value) { $null }
            elseif ($Direction -eq 'min') { $Value -ge $Threshold }
            else { $Value -le $Threshold }
    $kpis.Add([pscustomobject]@{ KPI=$Name; Value=$(if($null -eq $Value){'n/a'}else{$Value}); Threshold=("{0} {1}" -f $(if($Direction -eq 'min'){'>='}else{'<='}),$Threshold); Status=$(if($null -eq $pass){'n/a'}elseif($pass){'PASS'}else{'FAIL'}) })
    return $pass
}

Write-Host "=== KPI Dashboard - Purview - Adoption ===" -ForegroundColor Cyan

# --- 1) Labeling coverage + DLP override rate (live audit signal) ---
$coverage = $null; $overrideRate = $null
if (Get-Command Search-UnifiedAuditLog -ErrorAction SilentlyContinue) {
    $start = (Get-Date).AddDays(-[math]::Abs($Days)); $end = Get-Date
    try {
        $applied = @(Search-UnifiedAuditLog -StartDate $start -EndDate $end -Operations 'SensitivityLabelApplied','FileSensitivityLabelApplied','SensitivityLabelUpdated','FileSensitivityLabelChanged' -ResultSize 5000 -ErrorAction Stop).Count
        $removed = @(Search-UnifiedAuditLog -StartDate $start -EndDate $end -Operations 'SensitivityLabelRemoved','FileSensitivityLabelRemoved' -ResultSize 5000 -ErrorAction Stop).Count
        if (($applied + $removed) -gt 0) { $coverage = [math]::Round(100.0 * $applied / ($applied + $removed), 1) }
        $match    = @(Search-UnifiedAuditLog -StartDate $start -EndDate $end -Operations 'DLPRuleMatch','DLPPolicyMatch' -ResultSize 5000 -ErrorAction Stop).Count
        $override = @(Search-UnifiedAuditLog -StartDate $start -EndDate $end -Operations 'DLPRuleUndo' -ResultSize 5000 -ErrorAction Stop).Count
        if ($match -gt 0) { $overrideRate = [math]::Round(100.0 * $override / $match, 1) }
    } catch { Write-Warning ("Live signal unavailable ({0}); labeling/DLP KPIs = n/a. Verify audit availability/role." -f $_.Exception.Message) }
} else { Write-Warning "Not connected to audit search (Connect-IPPSSession); labeling/DLP KPIs = n/a." }

# --- 2) Champion coverage (Graph groups vs roster) ---
$champCoverage = $null
if ($RosterCsv -and $ChampionsGroup -and (Get-Command Get-MgGroup -ErrorAction SilentlyContinue) -and (Test-Path $RosterCsv)) {
    try {
        $g = Get-MgGroup -Filter "displayName eq '$ChampionsGroup'" -ErrorAction Stop | Select-Object -First 1
        if ($g) {
            $champUpns = @(Get-MgGroupMember -GroupId $g.Id -All | ForEach-Object { $_.AdditionalProperties.userPrincipalName })
            $roster = Import-Csv $RosterCsv
            $covered = @($roster | Where-Object { $_.ChampionUpn -and $champUpns -contains $_.ChampionUpn }).Count
            if (@($roster).Count -gt 0) { $champCoverage = [math]::Round(100.0 * $covered / @($roster).Count, 1) }
        }
    } catch { Write-Warning ("Champion coverage unavailable ({0}); KPI = n/a." -f $_.Exception.Message) }
} else { Write-Warning "Champion coverage skipped (need -RosterCsv, -ChampionsGroup, Microsoft.Graph)." }

# --- 3) Comms reach (CSV in) ---
$commsReach = $null
if ($CommsCsv -and (Test-Path $CommsCsv)) {
    try {
        $c = Import-Csv $CommsCsv
        $sent = ($c | Measure-Object -Property Sent -Sum).Sum
        $reach= ($c | Measure-Object -Property Reached -Sum).Sum
        if ($sent -gt 0) { $commsReach = [math]::Round(100.0 * $reach / $sent, 1) }
        else { Write-Warning "Comms CSV parsed but Sent total is 0. Columns found: $(($c | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name) -join ', ')" }
    } catch { Write-Warning ("Comms CSV would not parse ({0}); reach KPI = n/a. Expected columns: Wave, Sent, Reached." -f $_.Exception.Message) }
} else { Write-Warning "Comms reach skipped (no -CommsCsv). Expected columns: Wave, Sent, Reached." }

# --- Compose + gate ---
$p1 = Add-Kpi -Name 'Labeling coverage %'      -Value $coverage      -Threshold $MinLabelingCoverage -Direction 'min'
$p2 = Add-Kpi -Name 'DLP override rate %'       -Value $overrideRate  -Threshold $MaxDlpOverrideRate  -Direction 'max'
$p3 = Add-Kpi -Name 'Champion coverage %'       -Value $champCoverage -Threshold $MinChampionCoverage -Direction 'min'
$p4 = Add-Kpi -Name 'Comms reach %'             -Value $commsReach    -Threshold $MinCommsReach       -Direction 'min'

$kpis | Format-Table -AutoSize

$verdicts = @($p1,$p2,$p3,$p4)
if ($verdicts -contains $null) {
    Write-Host "WAVE GATE: INCONCLUSIVE — one or more KPIs are n/a. Resolve data availability before gating." -ForegroundColor Yellow
} elseif ($verdicts -notcontains $false) {
    Write-Host "WAVE GATE: CLEAR — ring meets adoption thresholds. Approve expanding the next wave / introducing enforce (under change control)." -ForegroundColor Green
} else {
    Write-Host "WAVE GATE: HOLD — one or more KPIs below threshold. Reinforce comms, tune friction, re-measure. Do NOT expand or enforce cold." -ForegroundColor Red
}

if ($CsvPath) { $kpis | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host ("Saved KPI dashboard to {0}" -f $CsvPath) -ForegroundColor Green }

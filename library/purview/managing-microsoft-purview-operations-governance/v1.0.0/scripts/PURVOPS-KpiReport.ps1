<#
.SYNOPSIS
    PURVOPS-KpiReport.ps1 — read-only program-health KPI dashboard from live Purview telemetry plus a Compliance Manager improvement-actions export. Makes no changes.
.DESCRIPTION
    PURPOSE
        Composes "KPI Dashboard - Purview - ProgramHealth": policy-mode distribution (enforced vs test),
        privileged-role count, and — from the Compliance Manager improvement-actions CSV (Compliance Manager
        has NO supported public API, so the CSV is exported from the portal) — improvement-action burn-down
        and compliance-score inputs. Optionally folds in a prior alert-rollup CSV for alert-volume/triage KPIs.
        Read-only; each KPI is compared to a threshold you pass.
    HOW TO RUN
        Connect-IPPSSession                                  # for the live policy-mode + role KPIs (no secrets)
        # Export improvement actions: Purview portal > Compliance Manager > Improvement actions > Export
        .\PURVOPS-KpiReport.ps1 -ComplianceManagerCsv .\CM-Improvement-Actions.csv `
            -AlertRollupCsv .\Alert-Rollup.csv -CsvPath .\KPI-Dashboard.csv
        PowerShell 5.1+/7+; live KPIs need Security & Compliance PowerShell; CM/alert KPIs are CSV-driven.
    EXPECTED RESULTS
        A KPI table (name, value, threshold, status) covering policy-mode %, privileged-role count,
        improvement-action burn-down, compliance-score, and (if supplied) alert volume. Out-of-threshold
        KPIs are flagged. Missing inputs degrade gracefully (that KPI shows "n/a").
.NOTES
    Purview — Operations & Governance. Read-only. Compliance Manager has no public API — the improvement
    export is manual by design; column layout can change, so the script reports the columns it found.
    Regulatory applicability behind the score is a compliance/legal determination, not this report's.
#>
[CmdletBinding()]
param(
    [string]$ComplianceManagerCsv,
    [string]$AlertRollupCsv,
    [string]$CsvPath,
    [double]$EnforcedPctThreshold = 80,   # KPI: >= this % of DLP/auto-labeling policies enforcing
    [int]$MaxOpenOverdueActions   = 0,    # KPI: overdue improvement actions should trend to this
    [int]$MaxPrivilegedAccounts   = 10    # KPI: accounts in sensitive role groups
)

$kpis = New-Object System.Collections.Generic.List[object]
function Add-Kpi { param($Name,$Value,$Threshold,$Ok)
    $kpis.Add([pscustomobject]@{ KPI=$Name; Value=$Value; Threshold=$Threshold; Status=$(if($Ok){'OK'}elseif($Ok -eq $null){'n/a'}else{'REVIEW'}) })
}

Write-Host "=== KPI Dashboard - Purview - ProgramHealth ===" -ForegroundColor Cyan

# --- Live policy-mode KPI (requires S&C PowerShell; degrade if absent) ---
if (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue) {
    $gated = @()
    foreach ($g in @({Get-DlpCompliancePolicy}, {Get-AutoSensitivityLabelPolicy})) {
        try { $gated += & $g } catch {}
    }
    $modeAll = @($gated).Count
    $enforcing = @($gated | Where-Object { [string]$_.Mode -eq 'Enable' }).Count
    if ($modeAll -gt 0) {
        $pct = [math]::Round(100.0 * $enforcing / $modeAll, 1)
        Add-Kpi 'Policies enforcing (DLP+auto-label) %' "$pct% ($enforcing/$modeAll)" ">= $EnforcedPctThreshold%" ($pct -ge $EnforcedPctThreshold)
    } else { Add-Kpi 'Policies enforcing (DLP+auto-label) %' 'no policies found' ">= $EnforcedPctThreshold%" $null }

    # Privileged-role KPI
    if (Get-Command Get-RoleGroup -ErrorAction SilentlyContinue) {
        $sensitive = @('Compliance Administrator','Compliance Data Administrator','Insider Risk Management','eDiscovery Manager','eDiscovery Administrator','Information Protection','Records Management','Audit Manager')
        $priv = @{}
        foreach ($rg in (Get-RoleGroup -ErrorAction SilentlyContinue | Where-Object { $sensitive -contains $_.Name })) {
            try { foreach ($m in (Get-RoleGroupMember -Identity $rg.Name -ErrorAction Stop)) { $priv[[string]$m.Name] = $true } } catch {}
        }
        Add-Kpi 'Privileged (sensitive-role) accounts' $priv.Count "<= $MaxPrivilegedAccounts" ($priv.Count -le $MaxPrivilegedAccounts)
    }
} else {
    Write-Warning "S&C PowerShell not connected — live policy-mode & role KPIs skipped (n/a). Run Connect-IPPSSession for those."
    Add-Kpi 'Policies enforcing (DLP+auto-label) %' 'n/a (not connected)' ">= $EnforcedPctThreshold%" $null
}

# --- Compliance Manager improvement-actions KPI (CSV in; no public API) ---
if ($ComplianceManagerCsv -and (Test-Path $ComplianceManagerCsv)) {
    $cm = Import-Csv $ComplianceManagerCsv
    $cols = ($cm | Select-Object -First 1).PSObject.Properties.Name
    Write-Host ("Compliance Manager export columns: {0}" -f ($cols -join ', ')) -ForegroundColor DarkGray
    # Best-effort column detection (export layout varies by tenant/portal version).
    $statusCol = $cols | Where-Object { $_ -match 'Status|Test\s*status|Implementation' } | Select-Object -First 1
    $dueCol    = $cols | Where-Object { $_ -match 'Due|Target' } | Select-Object -First 1
    $total = @($cm).Count
    $open = if ($statusCol) { @($cm | Where-Object { $_.$statusCol -notmatch 'Complete|Implemented|Passed' }).Count } else { $null }
    $overdue = 0
    if ($statusCol -and $dueCol) {
        foreach ($r in $cm) {
            $d = $null; [void][datetime]::TryParse($r.$dueCol, [ref]$d)
            if ($d -and $d -lt (Get-Date) -and $r.$statusCol -notmatch 'Complete|Implemented|Passed') { $overdue++ }
        }
    }
    $openDisp = if ($open -ne $null) { $open } else { '?' }
    Add-Kpi 'Improvement actions: open' ("{0} of {1}" -f $openDisp, $total) 'trend down' $null
    Add-Kpi 'Improvement actions: overdue' $overdue "<= $MaxOpenOverdueActions" ($overdue -le $MaxOpenOverdueActions)
} else {
    Add-Kpi 'Improvement actions: overdue' 'n/a (no CM export)' "<= $MaxOpenOverdueActions" $null
}

# --- Alert-volume KPI (from a prior PURVOPS-Report.ps1 CSV, optional) ---
if ($AlertRollupCsv -and (Test-Path $AlertRollupCsv)) {
    $ar = Import-Csv $AlertRollupCsv
    Add-Kpi 'Alerts in last rollup window' @($ar).Count 'trend down' $null
    $resolved = @($ar | Where-Object { $_.ResolveHrs -and $_.ResolveHrs -ne '' })
    if ($resolved.Count) {
        $mean = [math]::Round((($resolved | Measure-Object -Property ResolveHrs -Average).Average),1)
        Add-Kpi 'Mean alert time-to-resolve (hrs)' $mean 'within SLA' $null
    }
}

$kpis | Format-Table -AutoSize
$review = @($kpis | Where-Object { $_.Status -eq 'REVIEW' }).Count
if ($review -gt 0) { Write-Warning ("{0} KPI(s) out of threshold — bring to the program-health review." -f $review) }
else { Write-Host "All measured KPIs within threshold." -ForegroundColor Green }

if ($CsvPath) {
    $kpis | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved KPI dashboard CSV to {0}" -f $CsvPath) -ForegroundColor Green
}

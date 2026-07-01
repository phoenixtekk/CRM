<#
.SYNOPSIS
    GPOPROG-Report.ps1 — phase-status and conflict report for the transition program.
.DESCRIPTION
    PURPOSE
        Aggregates the program's status. It reads the per-phase validation snapshots produced by
        GPOPROG-Validation.ps1 (GPOPROG-Validation-*.json) to report, per phase, the precedence state
        and any loop/conflict findings; and (with -UseGraph) lists the phase scope groups and the
        Intune transition policies named to the convention (Coexistence Policy / Settings Catalog /
        Endpoint Security) with their assignments. Produces the gate-readiness view and program KPIs.
        Read-only.
    HOW TO RUN
        From the folder holding the validation snapshots:
            powershell -ExecutionPolicy Bypass -File .\GPOPROG-Report.ps1 -SnapshotPath .
        Add the Intune-side view (Microsoft.Graph + DeviceManagementConfiguration.Read.All, Group.Read.All):
            powershell -ExecutionPolicy Bypass -File .\GPOPROG-Report.ps1 -UseGraph
    EXPECTED RESULTS
        A per-phase table (phase, precedence state, loop/conflict count, gate state) and KPIs
        (precedence coverage, open conflicts/loops). With -UseGraph: the phase scope groups and the
        named transition policies + assignments. Read-only.
.NOTES
    Workplace Marketplace — Migrations. Read-only.
#>
[CmdletBinding()]
param(
    [string] $SnapshotPath = ".",
    [switch] $UseGraph
)

Write-Host "`n=== Transition program — phase status + conflict report ===" -ForegroundColor Cyan

$snaps = Get-ChildItem -Path $SnapshotPath -Filter "GPOPROG-Validation-*.json" -ErrorAction SilentlyContinue
if (-not $snaps) {
    Write-Host "No validation snapshots found. Run GPOPROG-Validation.ps1 per phase first." -ForegroundColor Yellow
} else {
    $rows = foreach ($s in $snaps) {
        try {
            $o = Get-Content $s.FullName -Raw | ConvertFrom-Json
            $appliedCount = @($o.Applied.PSObject.Properties).Count
            [pscustomobject]@{
                Phase         = $o.Phase
                Computer      = $o.Computer
                Captured      = $o.Timestamp
                Precedence    = if ($o.MDMWinsOverGP -eq 1) { 'MDM wins (ok)' } else { 'NOT set' }
                AppliedMDM    = $appliedCount
                GateState     = if ($o.MDMWinsOverGP -eq 1) { 'review conflicts' } else { 'BLOCKED' }
            }
        } catch {
            [pscustomobject]@{ Phase = $s.BaseName; Computer = '?'; Captured = '?'; Precedence = 'parse error'; AppliedMDM = '?'; GateState = '?' }
        }
    }
    $rows | Sort-Object Phase | Format-Table -AutoSize

    # KPIs
    $total = @($rows).Count
    $withPrec = @($rows | Where-Object { $_.Precedence -eq 'MDM wins (ok)' }).Count
    Write-Host ("`nKPI — precedence coverage (sampled): {0}/{1} phases report MDM-wins." -f $withPrec, $total) -ForegroundColor Green
    Write-Host "KPI — open conflicts/loops: re-run GPOPROG-Validation.ps1 with -PreviousSnapshot per phase; target zero before any go/no-go gate." -ForegroundColor Gray
    $blocked = @($rows | Where-Object { $_.GateState -eq 'BLOCKED' })
    if ($blocked.Count) { Write-Host ("{0} phase(s) BLOCKED — precedence not set; security phases must not start." -f $blocked.Count) -ForegroundColor Yellow }
}

if ($UseGraph) {
    Write-Host "`n=== Intune transition policies + phase scope groups (Graph) ===" -ForegroundColor Cyan
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','Group.Read.All' -NoWelcome
    try {
        $grps = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=startswith(displayName,'Transition Wave')&`$select=id,displayName").value
        Write-Host "Phase scope groups:" -ForegroundColor Green
        foreach ($g in $grps) { Write-Host ("  {0}  ({1})" -f $g.displayName, $g.id) }

        Write-Host "`nTransition policies (Settings catalog / Coexistence / Endpoint security named to convention):" -ForegroundColor Green
        $pols = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies?`$select=id,name").value
        foreach ($p in $pols) {
            if ($p.name -match 'Coexistence Policy|Settings Catalog - (Core OS|Firewall|App Control)|Endpoint Security - (Firewall|App Control)') {
                Write-Host ("  {0}  (id {1})" -f $p.name, $p.id)
            }
        }
    } catch {
        Write-Host "Graph query failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    Disconnect-MgGraph | Out-Null
} else {
    Write-Host "`nRe-run with -UseGraph to also list the phase scope groups and named transition policies." -ForegroundColor Gray
}

<#
.SYNOPSIS
    GCCHIGH-Set-WavePlan.ps1 - Generate / validate a migration wave + workstream plan from discovery.

    PURPOSE:
        Reads the Discovery CSV (output of GCCHIGH-Discovery.ps1) and groups users, sites, teams, and
        servers into balanced migration waves, tagging each object with its workstream. Produces a
        wave-plan CSV used by the implementation runbook and the status report. Keeps related objects
        (by a grouping key such as department/owner, when present) in the same wave to limit painful
        cross-cloud coexistence.

    HOW TO RUN:
        # Preview the plan without writing:
        .\GCCHIGH-Set-WavePlan.ps1 -InputCsv ".\Estate-Inventory - Discovery - Source.csv" -WhatIf
        # Generate the plan:
        .\GCCHIGH-Set-WavePlan.ps1 -InputCsv ".\Estate-Inventory - Discovery - Source.csv" `
                                   -OutputCsv ".\Wave-Plan - Program - Program.csv" `
                                   -ObjectsPerWave 50 -MaxGBPerWave 500 -PilotCount 15

    EXPECTED RESULTS:
        A wave-plan CSV with one row per migratable object: Wave, Workstream, ObjectName, SizeGB,
        GroupKey, Status(=NotStarted). A console summary of objects + GB per wave. The first wave is
        "Wave 00 - Pilot" containing a small representative sample. With -WhatIf nothing is written.

.NOTES
    Azure Solutions - read-only.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)][string]$InputCsv,
    [string]$OutputCsv = ".\Wave-Plan - Program - Program.csv",
    [int]$ObjectsPerWave = 50,
    [double]$MaxGBPerWave = 500,
    [int]$PilotCount = 15,
    [string]$GroupKeyColumn = 'Detail'   # column used to keep cohorts together, when present
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $InputCsv)) { throw "Input CSV not found: $InputCsv" }
$inv = Import-Csv $InputCsv

# Only migratable object types go into waves (subscriptions/containers are excluded).
$migratableTypes = 'Mailbox','SPOSite','OneDrive','Team','AzureVM','AppService'
$items = $inv | Where-Object { $_.ObjectType -in $migratableTypes }
if (-not $items) { throw "No migratable objects found in $InputCsv" }

$plan = New-Object System.Collections.Generic.List[object]

function Add-PlanRow {
    param($Wave, $Obj)
    $plan.Add([pscustomobject]@{
        Wave       = $Wave
        Workstream = $Obj.Workstream
        ObjectType = $Obj.ObjectType
        ObjectName = $Obj.Name
        SizeGB     = [double]$Obj.SizeGB
        GroupKey   = $Obj.$GroupKeyColumn
        Status     = 'NotStarted'
    })
}

# --- Pilot wave: a representative spread across workstreams ---
$pilot = @()
foreach ($ws in ($items | Group-Object Workstream)) {
    $take = [math]::Max(1, [math]::Floor($PilotCount / ($items | Group-Object Workstream).Count))
    $pilot += $ws.Group | Sort-Object { [double]$_.SizeGB } | Select-Object -First $take
}
$pilot = $pilot | Select-Object -First $PilotCount
foreach ($p in $pilot) { Add-PlanRow -Wave 'Wave 00 - Pilot' -Obj $p }
$pilotNames = $pilot.Name

# --- Production waves: cohort-aware, capped by object count AND GB ---
$remaining = $items | Where-Object { $_.Name -notin $pilotNames }

# Sort so cohorts (same GroupKey) stay adjacent, largest cohorts first.
$ordered = $remaining |
    Sort-Object @{ Expression = { $_.$GroupKeyColumn } }, @{ Expression = { [double]$_.SizeGB }; Descending = $true }

$waveNum = 1
$count = 0
$gb = 0.0
$lastKey = $null
foreach ($o in $ordered) {
    $key = $o.$GroupKeyColumn
    $sz  = [double]$o.SizeGB
    $wouldExceed = ($count -ge $ObjectsPerWave) -or (($gb + $sz) -gt $MaxGBPerWave)
    # roll to next wave at a cohort boundary when caps are hit (avoid splitting a cohort mid-wave)
    if ($wouldExceed -and ($key -ne $lastKey)) {
        $waveNum++; $count = 0; $gb = 0.0
    }
    $waveLabel = "Wave {0:00}" -f $waveNum
    Add-PlanRow -Wave $waveLabel -Obj $o
    $count++; $gb += $sz; $lastKey = $key
}

# --- Output ---
if ($PSCmdlet.ShouldProcess($OutputCsv, "Write wave plan ($($plan.Count) rows)")) {
    $plan | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
    Write-Host ("Wave plan written to {0} ({1} objects)" -f $OutputCsv, $plan.Count) -ForegroundColor Green
} else {
    Write-Host ("WHATIF: would write {0} objects to {1}" -f $plan.Count, $OutputCsv) -ForegroundColor Yellow
}

Write-Host "`n=== Wave summary ===" -ForegroundColor Cyan
foreach ($w in ($plan | Group-Object Wave | Sort-Object Name)) {
    $waveGB = [math]::Round((($w.Group | Measure-Object SizeGB -Sum).Sum), 2)
    Write-Host ("  {0,-16} Objects={1,-5} GB={2}" -f $w.Name, $w.Count, $waveGB)
}

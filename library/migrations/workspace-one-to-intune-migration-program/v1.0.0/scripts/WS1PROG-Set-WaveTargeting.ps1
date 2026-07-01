<#
.SYNOPSIS
    WS1PROG-Set-WaveTargeting.ps1 - Build the migration wave plan and the Entra targeting groups.

    PURPOSE:
        Reads the Discovery / source device CSV and groups devices into balanced, cohort-aware migration
        waves, tagging each with its platform scope. Produces the wave-plan CSV used by the runbook,
        validation, and report scripts. Optionally (with -Apply) creates the Entra security groups that
        drive Intune assignment and adds members to them:
          - Wave 00 Devices - All - Pilot              (a representative spread across all platforms)
          - Wave NN Devices - <Scope> - Wave NN        (production waves, per platform/cohort)

    HOW TO RUN:
        1. Install the Microsoft Graph PowerShell SDK (run once, only needed for -Apply):
             Install-Module Microsoft.Graph -Scope CurrentUser
        2. Preview the plan only (no groups created, nothing written with -WhatIf):
             .\WS1PROG-Set-WaveTargeting.ps1 -InputCsv ".\Estate-Inventory - Discovery - Source.csv" -WhatIf
        3. Generate the plan CSV (no Entra changes):
             .\WS1PROG-Set-WaveTargeting.ps1 -InputCsv ".\Estate-Inventory - Discovery - Source.csv" `
                                             -OutputCsv ".\Wave-Plan - Program - Program.csv" `
                                             -DevicesPerWave 100 -PilotCount 20
        4. Also create + populate the Entra groups (requires Graph; safe-by-default, -Apply to act):
             .\WS1PROG-Set-WaveTargeting.ps1 -InputCsv ".\Estate-Inventory - Discovery - Source.csv" -CreateGroups -Apply

    EXPECTED RESULTS:
        A wave-plan CSV with one row per device: Wave, Scope(platform), ObjectName(device), UserPrincipalName,
        GroupKey, Status(=NotStarted), plus a console wave summary. The first wave is "Wave 00 - Pilot".
        With -CreateGroups -Apply, the Entra wave groups are created (if missing) and members added.
        Without -Apply (or with -WhatIf) nothing is written or created.

    INPUT CSV (from Discovery / WS1 export reconciled by UPN). Expected columns (case-insensitive):
        Platform (Windows|iOS|Android|macOS), DeviceName, UserPrincipalName, [Department or GroupKey].

.NOTES
    Migrations - safe-by-default (-WhatIf). Entra group creation via Microsoft Graph PowerShell.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)][string]$InputCsv,
    [string]$OutputCsv = ".\Wave-Plan - Program - Program.csv",
    [int]$DevicesPerWave = 100,
    [int]$PilotCount = 20,
    [string]$GroupKeyColumn = 'Department',
    [switch]$CreateGroups,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $InputCsv)) { throw "Input CSV not found: $InputCsv" }
$inv = Import-Csv $InputCsv
if (-not $inv) { throw "Input CSV is empty: $InputCsv" }
if (-not $Apply) { $WhatIfPreference = $true }

# Normalize platform scope.
function Get-Scope {
    param([string]$Platform)
    switch -Wildcard ($Platform) {
        'Win*'      { 'Windows' } 'Windows*' { 'Windows' }
        'iOS*'      { 'iOS' } 'iPad*' { 'iOS' } 'Apple*' { 'iOS' }
        'Android*'  { 'Android' }
        'mac*'      { 'macOS' } 'OS X*' { 'macOS' }
        default     { if ($Platform) { $Platform } else { 'Unknown' } }
    }
}

$devices = $inv | ForEach-Object {
    [pscustomobject]@{
        Scope             = Get-Scope $_.Platform
        DeviceName        = $_.DeviceName
        UserPrincipalName = $_.UserPrincipalName
        GroupKey          = if ($_.PSObject.Properties.Name -contains $GroupKeyColumn -and $_.$GroupKeyColumn) { $_.$GroupKeyColumn } else { 'Unassigned' }
    }
} | Where-Object { $_.DeviceName }

$plan = New-Object System.Collections.Generic.List[object]
function Add-PlanRow {
    param($Wave, $Dev)
    $plan.Add([pscustomobject]@{
        Wave              = $Wave
        Scope             = $Dev.Scope
        ObjectName        = $Dev.DeviceName
        UserPrincipalName = $Dev.UserPrincipalName
        GroupKey          = $Dev.GroupKey
        Status            = 'NotStarted'
    })
}

# --- Pilot wave: representative spread across every platform + both no-wipe and reset cohorts ---
$pilot = @()
$byScope = $devices | Group-Object Scope
$perScope = [math]::Max(1, [math]::Floor($PilotCount / [math]::Max(1, $byScope.Count)))
foreach ($s in $byScope) { $pilot += $s.Group | Select-Object -First $perScope }
$pilot = $pilot | Select-Object -First $PilotCount
foreach ($p in $pilot) { Add-PlanRow -Wave 'Wave 00 - Pilot' -Dev $p }
$pilotNames = $pilot.DeviceName

# --- Production waves: per platform, cohort-aware, capped by device count ---
$remaining = $devices | Where-Object { $_.DeviceName -notin $pilotNames }
foreach ($s in ($remaining | Group-Object Scope | Sort-Object Name)) {
    $ordered = $s.Group | Sort-Object GroupKey, DeviceName
    $waveNum = 1; $count = 0; $lastKey = $null
    foreach ($d in $ordered) {
        if ($count -ge $DevicesPerWave -and $d.GroupKey -ne $lastKey) { $waveNum++; $count = 0 }
        $waveLabel = "Wave {0:00}" -f $waveNum
        Add-PlanRow -Wave $waveLabel -Dev $d
        $count++; $lastKey = $d.GroupKey
    }
}

# --- Write the plan ---
if ($PSCmdlet.ShouldProcess($OutputCsv, "Write wave plan ($($plan.Count) rows)")) {
    $plan | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
    Write-Host ("Wave plan written to {0} ({1} devices)" -f $OutputCsv, $plan.Count) -ForegroundColor Green
} else {
    Write-Host ("WHATIF: would write {0} devices to {1}" -f $plan.Count, $OutputCsv) -ForegroundColor Yellow
}

Write-Host "`n=== Wave summary (Wave x Scope) ===" -ForegroundColor Cyan
foreach ($w in ($plan | Group-Object Wave, Scope | Sort-Object Name)) {
    Write-Host ("  {0,-30} Devices={1}" -f $w.Name, $w.Count)
}

# --- Optionally create + populate the Entra groups ---
if ($CreateGroups) {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Write-Host "`nConnecting to Microsoft Graph to create/populate wave groups..." -ForegroundColor Cyan
    Connect-MgGraph -Scopes "Group.ReadWrite.All","Device.Read.All","User.Read.All","Directory.Read.All" -NoWelcome
    Import-Module Microsoft.Graph.Groups -ErrorAction Stop
    Import-Module Microsoft.Graph.Identity.DirectoryManagement -ErrorAction Stop

    # Build the group name per wave row: Pilot -> "Wave 00 Devices - All - Pilot"; else "Wave NN Devices - <Scope> - Wave NN".
    function Get-WaveGroupName {
        param($Wave, $Scope)
        if ($Wave -eq 'Wave 00 - Pilot') { return 'Wave 00 Devices - All - Pilot' }
        $nn = ($Wave -replace '[^\d]', '')
        return ("Wave {0} Devices - {1} - Wave {0}" -f $nn, $Scope)
    }

    $groupRows = $plan | ForEach-Object { $_ | Add-Member -NotePropertyName GroupName -NotePropertyValue (Get-WaveGroupName $_.Wave $_.Scope) -PassThru }

    foreach ($g in ($groupRows | Group-Object GroupName | Sort-Object Name)) {
        $gName = $g.Name
        $existing = Get-MgGroup -Filter "displayName eq '$gName'" -Top 1
        $groupId = $existing.Id
        if (-not $existing) {
            if ($PSCmdlet.ShouldProcess($gName, "Create Entra security group")) {
                $mailNick = ($gName -replace '[^a-zA-Z0-9]', '')
                $new = New-MgGroup -DisplayName $gName -MailEnabled:$false -MailNickname $mailNick -SecurityEnabled:$true -ErrorAction Stop
                $groupId = $new.Id
                Write-Host ("CREATED group: {0}" -f $gName) -ForegroundColor Green
            } else {
                Write-Host ("WOULD CREATE group: {0}" -f $gName) -ForegroundColor Yellow
                continue
            }
        }
        foreach ($row in $g.Group) {
            $member = Get-MgDevice -Filter "displayName eq '$($row.ObjectName)'" -Top 1
            if (-not $member -and $row.UserPrincipalName) { $member = Get-MgUser -Filter "userPrincipalName eq '$($row.UserPrincipalName)'" -Top 1 }
            if (-not $member) { Write-Host ("  SKIP member (not found): {0}" -f $row.ObjectName) -ForegroundColor Yellow; continue }
            if ($PSCmdlet.ShouldProcess(("{0} -> {1}" -f $row.ObjectName, $gName), "Add member to wave group")) {
                try { New-MgGroupMember -GroupId $groupId -DirectoryObjectId $member.Id -ErrorAction Stop }
                catch { if ($_.Exception.Message -notmatch 'already exist') { Write-Host ("  FAILED add {0}: {1}" -f $row.ObjectName, $_.Exception.Message) -ForegroundColor Red } }
            } else {
                Write-Host ("  WOULD ADD {0} -> {1}" -f $row.ObjectName, $gName) -ForegroundColor Yellow
            }
        }
    }
    Disconnect-MgGraph | Out-Null
}

if (-not $Apply) { Write-Host "`nPreview only. Re-run with -Apply (and -CreateGroups to build Entra groups) to act." -ForegroundColor Yellow }

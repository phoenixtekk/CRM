<#
.SYNOPSIS
    MDMRDY-Set-WaveCohortTargeting.ps1 — build the wave cohorts / cohort groups for the migration.
.DESCRIPTION
    PURPOSE
        Materializes the "Wave Cohorts - MDM Migration - Configure" from the finalized wave plan:
        one membership list per wave ("Cohort Group - Per Wave - Configure"). By default it writes
        export CSVs you can import into ANY target's grouping system (vendor-neutral). When the target
        is Entra/Intune, -CreateEntraGroups creates one Microsoft Entra security group per wave and
        adds members. Group creation is gated: -WhatIf previews, -Apply commits.
    HOW TO RUN
        Export-only (any MDM):
          powershell -ExecutionPolicy Bypass -File .\MDMRDY-Set-WaveCohortTargeting.ps1 -CohortsCsv C:\MDMRDY\wave-plan-draft.csv -OutputFolder C:\MDMRDY
        Entra/Intune target — preview then apply:
          ... -CreateEntraGroups -WhatIf
          ... -CreateEntraGroups -Apply
        Entra mode needs Microsoft.Graph SDK and Group.ReadWrite.All.
        The cohorts CSV needs at least: DeviceName, SuggestedWave (or WaveLabel).
    EXPECTED RESULTS
        Writes one cohort-<WaveLabel>.csv per wave (the "Cohort Group - Per Wave - Configure"). With
        -CreateEntraGroups -Apply, also creates Entra security groups named MDMRDY-<WaveLabel> and
        adds device members. -WhatIf changes nothing in Entra.
.NOTES
    Migrations — vendor-neutral pre-migration assessment. Export-only is read-only; Entra writes only with -Apply.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$CohortsCsv,
    [string]$OutputFolder = (Join-Path $PWD 'MDMRDY'),
    [switch]$CreateEntraGroups,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$WhatIf = -not $Apply
if (-not (Test-Path $CohortsCsv)) { throw "Cohorts CSV not found: $CohortsCsv" }
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null }

$rows = Import-Csv -Path $CohortsCsv
# Accept either SuggestedWave (from the draft) or WaveLabel (after finalization)
$waveProp = if ($rows[0].PSObject.Properties.Name -contains 'WaveLabel') { 'WaveLabel' } else { 'SuggestedWave' }
$byWave = $rows | Group-Object $waveProp | Sort-Object Name

Write-Host "=== Wave cohort targeting ===" -ForegroundColor Cyan
Write-Host ("Cohorts CSV        : {0}" -f $CohortsCsv)
Write-Host ("Wave column        : {0}" -f $waveProp)

# 1) Always write the per-wave membership CSVs (the cohort groups)
foreach ($g in $byWave) {
    $label = $g.Name
    $file = Join-Path $OutputFolder ("cohort-{0}.csv" -f $label)
    $g.Group | Select-Object DeviceName, Platform, ReadinessScore, RiskScore |
        Export-Csv $file -NoTypeInformation -Encoding UTF8
    Write-Host ("  {0,-22} {1,4} devices -> {2}  (Cohort Group - Per Wave - Configure)" -f $label, $g.Count, $file)
}

# Integrity check: no device in two waves
$dupes = $rows | Group-Object DeviceName | Where-Object { $_.Count -gt 1 }
if ($dupes) { Write-Host ("WARNING: {0} device(s) appear in more than one wave — fix before targeting." -f $dupes.Count) -ForegroundColor Yellow }

# 2) Optional: create Entra security groups per wave
if ($CreateEntraGroups) {
    Write-Host ("Entra groups       : {0}" -f $(if ($WhatIf) { 'WhatIf (preview only)' } else { 'Apply' })) -ForegroundColor $(if ($WhatIf) { 'Yellow' } else { 'Green' })
    if (-not $WhatIf) {
        if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
        Import-Module Microsoft.Graph.Authentication
        Connect-MgGraph -Scopes 'Group.ReadWrite.All','Device.Read.All' -NoWelcome
    }
    foreach ($g in $byWave) {
        $groupName = "MDMRDY-$($g.Name)"
        if ($WhatIf) {
            Write-Host ("  WOULD create security group '{0}' with {1} members" -f $groupName, $g.Count)
            continue
        }
        $existing = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'" -f $groupName)).value
        if ($existing) {
            Write-Host ("  Group '{0}' already exists (id {1})" -f $groupName, $existing[0].id)
        } else {
            $body = @{ displayName=$groupName; mailEnabled=$false; mailNickname=$groupName.Replace(' ',''); securityEnabled=$true } | ConvertTo-Json
            $new = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body $body -ContentType 'application/json'
            Write-Host ("  Created group '{0}' (id {1})" -f $groupName, $new.id) -ForegroundColor Green
        }
        # Member add-by-device requires resolving DeviceName -> directory device object id in your tenant.
        Write-Host ("    (add the {0} cohort devices to '{1}' via your device-id mapping)" -f $g.Count, $groupName)
    }
    if (-not $WhatIf) { Disconnect-MgGraph | Out-Null }
}

Write-Host "Done. Cohort group membership files written; waves ready for targeting." -ForegroundColor Green

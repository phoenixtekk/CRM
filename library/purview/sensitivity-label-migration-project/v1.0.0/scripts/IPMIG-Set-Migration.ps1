<#
.SYNOPSIS
    IPMIG-Set-Migration.ps1 — reclassification config/remediation helper: create auto-labeling policies that map a detection SIT to a target label, IN SIMULATION first (-WhatIf by default; writes require -Commit).
.DESCRIPTION
    From a mapping CSV (LegacyValue -> TargetLabel -> detection SitName -> Locations), creates one
    service-side auto-labeling policy + rule per mapping IN SIMULATION (TestWithoutNotifications) so the
    reclassification is scanned and reported without labeling any content. Separate switches then
    enforce-from-simulation (Enable), return a policy to simulation, add locations, or remove a policy.
    Every write is gated: it previews (-WhatIf, no changes) unless -Commit is supplied; enforcement
    additionally requires -EnforceFromSimulation. It only REFERENCES detection SITs and target labels —
    it does not create them (author SITs in the portal, and the target taxonomy in its own solution). No
    credentials are stored in the script.
.EXAMPLE
    .\IPMIG-Set-Migration.ps1 -MappingCsv .\mapping.csv -PilotSites "https://contoso.sharepoint.com/sites/pilot" -WhatIf
    Previews the New-AutoSensitivityLabelPolicy/Rule calls (simulation) for each mapping — no changes.
.EXAMPLE
    .\IPMIG-Set-Migration.ps1 -MappingCsv .\mapping.csv -PilotSites "https://contoso.sharepoint.com/sites/pilot" -Commit
    Creates the reclassification policies IN SIMULATION, scoped to the pilot site(s).
.EXAMPLE
    .\IPMIG-Set-Migration.ps1 -PolicyName "Reclassify Sim - Confidential - Locations" -EnforceFromSimulation -Commit
    Flips an accepted simulation policy to Enable (reclassifies). Use ONLY after precision sign-off (Testing Test 6).
.EXAMPLE
    .\IPMIG-Set-Migration.ps1 -PolicyName "Reclassify Sim - Confidential - Locations" -ReturnToSimulation -Commit
    Returns an enforcing policy to simulation (stops further labeling).
.EXAMPLE
    .\IPMIG-Set-Migration.ps1 -PolicyName "Reclassify Sim - Confidential - Locations" -RemovePolicy -Commit
    Deletes a simulation policy (rollback; no content was touched while in simulation).
.NOTES
    Requires PowerShell 5.1+/7+ and ExchangeOnlineManagement (Connect-IPPSSession).
    Role: Information Protection Admin. Service-side auto-labeling is licensing-gated (verify your licensing/tenant, typically E5).
    Mapping CSV columns: LegacyValue, TargetLabel, SitName. Optional: Locations (';'-separated SPO/ODB URLs or 'All').
    Placeholders (contoso.sharepoint.com, label/SIT names) are EXAMPLES — replace with your signed-off matrix values.
    Expected results: PASS = -WhatIf prints intended changes; -Commit creates SIMULATION policies; Get-AutoSensitivityLabelPolicy shows them in a Test* mode.
    FAIL = a referenced SIT or target label does not exist, or a cmdlet is unavailable (licensing).
#>
[CmdletBinding(DefaultParameterSetName='Create')]
param(
    [Parameter(ParameterSetName='Create', Mandatory)][string]$MappingCsv,
    [Parameter(ParameterSetName='Create')][string[]]$PilotSites,

    [Parameter(ParameterSetName='Enforce', Mandatory)][Parameter(ParameterSetName='Return', Mandatory)]
    [Parameter(ParameterSetName='AddLoc', Mandatory)][Parameter(ParameterSetName='Remove', Mandatory)]
    [string]$PolicyName,

    [Parameter(ParameterSetName='Enforce')][switch]$EnforceFromSimulation,
    [Parameter(ParameterSetName='Return')][switch]$ReturnToSimulation,
    [Parameter(ParameterSetName='AddLoc')][switch]$AddSitesSwitch,
    [Parameter(ParameterSetName='AddLoc')][string[]]$AddSites,
    [Parameter(ParameterSetName='Remove')][switch]$RemovePolicy,

    # -WhatIf is the default posture; -Commit is the explicit apply switch.
    [switch]$Commit
)
$doIt = [bool]$Commit
function Show-Action([string]$desc, [scriptblock]$action) {
    if ($doIt) { Write-Host ("APPLY : {0}" -f $desc) -ForegroundColor Green; & $action }
    else       { Write-Host ("WhatIf: {0}" -f $desc) -ForegroundColor Yellow }
}

# --- Connect ---
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) { Connect-IPPSSession -ShowBanner:$false }

# ================= MODE: create reclassification policies in SIMULATION =================
if ($PSCmdlet.ParameterSetName -eq 'Create') {
    if (-not (Test-Path $MappingCsv)) { throw "Mapping CSV not found: $MappingCsv" }
    $mappings = Import-Csv $MappingCsv
    $existingLabels = @((Get-Label -ErrorAction SilentlyContinue) | ForEach-Object { $_.DisplayName; $_.Name })
    $existingSits   = @((Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue) | ForEach-Object { $_.Name })

    Write-Host '=== Create reclassification auto-labeling policies (SIMULATION) ===' -ForegroundColor Cyan
    foreach ($m in $mappings) {
        if (-not $m.TargetLabel -or -not $m.SitName) { Write-Warning ("skip row (missing TargetLabel/SitName): {0}" -f $m.LegacyValue); continue }

        # Guard: referenced target label and detection SIT must already exist.
        if ($existingLabels -notcontains $m.TargetLabel) { Write-Warning ("target label not found: '{0}' (create/publish it first, Req 2.2) — skipping" -f $m.TargetLabel); continue }
        if ($existingSits   -notcontains $m.SitName)     { Write-Warning ("detection SIT not found: '{0}' (author it in the portal, Step 2) — skipping" -f $m.SitName); continue }

        $polName = "Reclassify Sim - {0} - Locations" -f $m.TargetLabel
        $locs = if ($m.Locations) { $m.Locations -split ';' } elseif ($PilotSites) { $PilotSites } else { @('All') }
        $useAll = ($locs -contains 'All')

        $desc1 = "New-AutoSensitivityLabelPolicy -Name '{0}' -ApplySensitivityLabel '{1}' -Mode TestWithoutNotifications -SharePointLocation {2} -OneDriveLocation {2}" -f `
                 $polName, $m.TargetLabel, $(if($useAll){'All'}else{"($($locs -join ','))"})
        Show-Action $desc1 {
            if ($useAll) {
                New-AutoSensitivityLabelPolicy -Name $polName -ApplySensitivityLabel $m.TargetLabel `
                    -Mode TestWithoutNotifications -SharePointLocation All -OneDriveLocation All -ErrorAction Stop | Out-Null
            } else {
                New-AutoSensitivityLabelPolicy -Name $polName -ApplySensitivityLabel $m.TargetLabel `
                    -Mode TestWithoutNotifications -SharePointLocation $locs -ErrorAction Stop | Out-Null
            }
        }
        $desc2 = "New-AutoSensitivityLabelRule -Policy '{0}' -ContentContainsSensitiveInformation (SIT '{1}')  # detects legacy '{2}'" -f $polName, $m.SitName, $m.LegacyValue
        Show-Action $desc2 {
            New-AutoSensitivityLabelRule -Policy $polName -Name ("{0} - rule" -f $polName) `
                -ContentContainsSensitiveInformation @(@{ Name = $m.SitName }) -ErrorAction Stop | Out-Null
        }
    }
    if (-not $doIt) { Write-Host "`n(-WhatIf preview — re-run with -Commit. Policies are created in SIMULATION only; nothing is labeled.)" -ForegroundColor Yellow }
    return
}

# ================= MODE: enforce from simulation (RECLASSIFY) =================
if ($EnforceFromSimulation) {
    Write-Host "=== ENFORCE reclassification from simulation: $PolicyName ===" -ForegroundColor Cyan
    Write-Host 'Enforce ONLY after simulation precision is signed off by the data owner (Testing Guide Test 6).' -ForegroundColor Yellow
    Show-Action "Set-AutoSensitivityLabelPolicy -Identity '$PolicyName' -Mode Enable" {
        Set-AutoSensitivityLabelPolicy -Identity $PolicyName -Mode Enable -ErrorAction Stop | Out-Null
    }
    if (-not $doIt) { Write-Host "(-WhatIf — re-run with -Commit to enforce. Rollback: -ReturnToSimulation)" -ForegroundColor Yellow }
    return
}

# ================= MODE: return to simulation =================
if ($ReturnToSimulation) {
    Write-Host "=== Return policy to simulation: $PolicyName ===" -ForegroundColor Cyan
    Show-Action "Set-AutoSensitivityLabelPolicy -Identity '$PolicyName' -Mode TestWithoutNotifications" {
        Set-AutoSensitivityLabelPolicy -Identity $PolicyName -Mode TestWithoutNotifications -ErrorAction Stop | Out-Null
    }
    return
}

# ================= MODE: add locations =================
if ($PSCmdlet.ParameterSetName -eq 'AddLoc') {
    if (-not $AddSites) { throw 'Provide -AddSites (one or more SharePoint site URLs to add).' }
    Write-Host "=== Add locations to policy: $PolicyName ===" -ForegroundColor Cyan
    Show-Action ("Set-AutoSensitivityLabelPolicy -Identity '{0}' -AddSharePointLocation {1}" -f $PolicyName, ($AddSites -join ',')) {
        Set-AutoSensitivityLabelPolicy -Identity $PolicyName -AddSharePointLocation $AddSites -ErrorAction Stop | Out-Null
    }
    if (-not $doIt) { Write-Host "(-WhatIf — re-run with -Commit. Re-simulate if a new location introduces new content patterns.)" -ForegroundColor Yellow }
    return
}

# ================= MODE: remove policy (rollback) =================
if ($RemovePolicy) {
    Write-Host "=== Remove policy: $PolicyName ===" -ForegroundColor Cyan
    Show-Action "Remove-AutoSensitivityLabelPolicy -Identity '$PolicyName'" {
        Remove-AutoSensitivityLabelPolicy -Identity $PolicyName -Confirm:$false -ErrorAction Stop | Out-Null
    }
    if (-not $doIt) { Write-Host "(-WhatIf — re-run with -Commit to delete. Safe while in simulation — no content was labeled.)" -ForegroundColor Yellow }
    return
}

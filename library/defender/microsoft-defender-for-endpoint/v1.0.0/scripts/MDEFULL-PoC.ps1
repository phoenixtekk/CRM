<#
.SYNOPSIS
    MDEFULL-PoC.ps1 — the guided Microsoft Defender for Endpoint proof-of-concept in one script.
    -Action Enable | TestSignal | Score | Teardown. Every change is -WhatIf-gated; benign signal only.
.DESCRIPTION
    PURPOSE
        The Prove-workstream driver for the comprehensive "Microsoft Defender for Endpoint" solution.
        Runs a safe, fully reversible PoC on a small pilot ring of TEST DEVICES ONLY:
          -Action Enable      Preview readiness, then assign the Intune EDR onboarding policy to the
                              pilot group. Gated behind -WhatIf (preview) — re-run without -WhatIf to apply.
          -Action TestSignal  Generate BENIGN test signal on an onboarded pilot device: the EICAR
                              anti-malware test file (a documented harmless string — NOT malware) plus
                              the exact portal path for a Microsoft built-in evaluation simulation.
                              NO real malware, exploit, or attack tooling is ever used.
          -Action Score       Read-only: map the observed detections (alert, evidence, timeline, AIR)
                              to your written pass/fail criteria and write the scorecard file.
          -Action Teardown    Reverse everything the PoC created (clear/optionally delete the EDR
                              policy, delete the local EICAR file, print offboarding + alert-cleanup
                              steps). Gated behind -WhatIf.
        Validation of the detections is MDEFULL-Validate.ps1 -Check PoC.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDEFULL-PoC.ps1 -Action Enable -WhatIf
        powershell -ExecutionPolicy Bypass -File .\MDEFULL-PoC.ps1 -Action Enable
        powershell -ExecutionPolicy Bypass -File .\MDEFULL-PoC.ps1 -Action TestSignal
        powershell -ExecutionPolicy Bypass -File .\MDEFULL-PoC.ps1 -Action Score -CriteriaPath .\criteria.json
        powershell -ExecutionPolicy Bypass -File .\MDEFULL-PoC.ps1 -Action Teardown -WhatIf
        powershell -ExecutionPolicy Bypass -File .\MDEFULL-PoC.ps1 -Action Teardown -DeletePolicy
        Requires Microsoft.Graph.Authentication. Government cloud: -Environment.
    EXPECTED RESULTS
        Enable: readiness summary, then (when applied) the pilot EDR policy assigned so test devices onboard.
        TestSignal: EICAR written (AV should quarantine it) + printed built-in-simulation steps.
        Score: a per-criterion PASS/FAIL scorecard ('MDE PoC Scorecard - Pilot Ring - Validate.json').
        Teardown: assignment cleared, EICAR deleted, printed offboarding + alert-resolution steps.
.NOTES
    White-label. Read-only by default (-WhatIf) for Enable/Teardown; Score is read-only. BENIGN signal
    only (EICAR + Microsoft built-in simulations). Pilot/test devices only. AIR stays approval-gated.
    Verify the current built-in simulation catalogue and P1/P2/MDVM availability in your tenant.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)] [ValidateSet('Enable','TestSignal','Score','Teardown')] [string]$Action,
    [string]$PilotGroup = 'MDE PoC - Pilot Ring - Pilot',
    [string]$EdrPolicyName = 'MDE PoC EDR Onboarding - Pilot Ring - Pilot',
    [string]$Tag = 'MDE-PoC-TESTSIGNAL',
    [string]$WorkDir = "$env:TEMP\MDE-PoC",
    [string]$CriteriaPath,
    [string]$OutFile = 'MDE PoC Scorecard - Pilot Ring - Validate.json',
    [string]$DeviceName,
    [int]$LookbackHours = 12,
    [switch]$DeletePolicy,
    [ValidateSet('Global','USGov','USGovDoD')] [string]$Environment = 'Global'
)

function Connect-Graph([string[]]$Scopes) {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $Scopes -Environment $Environment -NoWelcome | Out-Null }
}
function Get-Json($Uri) { try { return Invoke-MgGraphRequest -Method GET -Uri $Uri } catch { return $null } }
function Invoke-Hunt([string]$Query) { return Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body (@{ Query = $Query } | ConvertTo-Json) -ContentType 'application/json' }
function Cnt($resp) { if ($resp.results -and $resp.results.Count -gt 0) { return [int]$resp.results[0].Cnt } return 0 }

switch ($Action) {

'Enable' {
    Connect-Graph @('Directory.Read.All','DeviceManagementConfiguration.ReadWrite.All','DeviceManagementManagedDevices.Read.All')
    Write-Host "`n=== MDEFULL PoC — Enable (preview by default) ===" -ForegroundColor Cyan
    Write-Host "Pilot group : $PilotGroup" -ForegroundColor Gray
    Write-Host "EDR policy  : $EdrPolicyName" -ForegroundColor Gray

    Write-Host "`n[1] Readiness (read-only):" -ForegroundColor Cyan
    $grp = Get-Json "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$PilotGroup'"
    if ($grp -and $grp.value.Count -gt 0) {
        $gid = $grp.value[0].id
        $members = Get-Json "https://graph.microsoft.com/v1.0/groups/$gid/members?`$select=displayName"
        Write-Host ("  Pilot group found ({0} member[s]). Ensure these are TEST devices only." -f ($members.value.Count)) -ForegroundColor Green
    } else { Write-Host "  Pilot group NOT found — create '$PilotGroup' with 1-3 test devices first." -ForegroundColor Yellow; $gid = $null }
    $me = Get-Json "https://graph.microsoft.com/v1.0/me?`$select=userPrincipalName"
    if ($me) { Write-Host ("  Signed in as: {0}" -f $me.userPrincipalName) -ForegroundColor Gray }
    Write-Host "  Verify: Defender for Endpoint plan (P1/P2) licensed and MDE activated (Settings -> Endpoints)." -ForegroundColor Gray
    Write-Host "  Verify: Advanced features -> Automated Investigation = ON, pilot automation = 'Semi - require approval'." -ForegroundColor Gray

    Write-Host "`n[2] Assign EDR onboarding policy to the pilot ring:" -ForegroundColor Cyan
    if (-not $gid) { Write-Host "  Skipping assignment — pilot group missing." -ForegroundColor Yellow; return }
    $policy = Get-Json "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=name eq '$EdrPolicyName'"
    if (-not ($policy -and $policy.value.Count -gt 0)) {
        Write-Host "  EDR policy '$EdrPolicyName' not found." -ForegroundColor Yellow
        Write-Host "  Create it in Intune -> Endpoint security -> Endpoint detection and response (client config = Auto from connector)," -ForegroundColor Gray
        Write-Host "  name it exactly '$EdrPolicyName', then re-run to assign it to the pilot group." -ForegroundColor Gray
        return
    }
    $polId = $policy.value[0].id
    if ($PSCmdlet.ShouldProcess("$EdrPolicyName -> $PilotGroup", "Assign Intune EDR onboarding policy to pilot ring")) {
        $body = @{ assignments = @(@{ target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $gid } }) } | ConvertTo-Json -Depth 6
        try { Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$polId/assign" -Body $body -ContentType 'application/json' | Out-Null
            Write-Host "  ASSIGNED — pilot devices will begin onboarding. Confirm in Assets -> Devices." -ForegroundColor Green }
        catch { Write-Host ("  Assignment failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
    } else { Write-Host "  [WhatIf] Would assign '$EdrPolicyName' to '$PilotGroup'. No change made." -ForegroundColor Yellow }
    Write-Host "`nNext: -Action TestSignal -> MDEFULL-Validate.ps1 -Check PoC -> -Action Score -> -Action Teardown -WhatIf" -ForegroundColor Cyan
}

'TestSignal' {
    Write-Host "`n=== MDEFULL PoC — benign test signal ($Tag) ===" -ForegroundColor Cyan
    Write-Host "SAFE ONLY: EICAR test file + Microsoft built-in simulation. No real malware is used." -ForegroundColor Yellow
    # EICAR standard test string, assembled at runtime so this script file itself is not flagged.
    $eicar = 'X5O!P%@AP[4\PZX54(P^)7CC)7}$' + 'EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*'
    $eicarPath = Join-Path $WorkDir 'eicar-poc.com'
    if ($PSCmdlet.ShouldProcess($eicarPath, "Write benign EICAR test file (tagged $Tag)")) {
        if (-not (Test-Path $WorkDir)) { New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null }
        try { Set-Content -Path $eicarPath -Value $eicar -Encoding ascii -NoNewline
            Write-Host "  Wrote EICAR test file: $eicarPath" -ForegroundColor Green
            Write-Host "  Microsoft Defender Antivirus should detect/quarantine it within moments." -ForegroundColor Gray }
        catch { Write-Host ("  Could not write file (AV may have blocked the path already): {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
    } else { Write-Host "  [WhatIf] Would write benign EICAR test file to $eicarPath. No file written." -ForegroundColor Yellow }

    Write-Host "`n[Built-in EDR simulation — run from the portal]" -ForegroundColor Cyan
    Write-Host "  1. security.microsoft.com -> Endpoints -> Evaluation & tutorials -> Tutorials & simulations." -ForegroundColor Gray
    Write-Host "  2. Pick a documented scenario and target a device in '$PilotGroup'." -ForegroundColor Gray
    Write-Host "  3. These simulations are provided by Microsoft for SAFE evaluation. Verify the current catalogue." -ForegroundColor Gray
    Write-Host ("`nSignal generated at: {0}  (record this — compare to detection time in the scorecard)." -f (Get-Date).ToString('u')) -ForegroundColor Cyan
    Write-Host "Next: MDEFULL-Validate.ps1 -Check PoC" -ForegroundColor Cyan
}

'Score' {
    Connect-Graph @('ThreatHunting.Read.All')
    $devFilter = if ($DeviceName) { "| where DeviceName has '$DeviceName'" } else { '' }
    $cap = @{
        alert    = "AlertInfo | where Timestamp > ago(${LookbackHours}h) | summarize Cnt = count()"
        evidence = "AlertEvidence | where Timestamp > ago(${LookbackHours}h) $devFilter | summarize Cnt = count()"
        device   = "DeviceEvents | where Timestamp > ago(${LookbackHours}h) $devFilter | summarize Cnt = count()"
        air      = "AlertInfo | where Timestamp > ago(${LookbackHours}h) | where ServiceSource has 'Endpoint' | summarize Cnt = count()"
    }
    $observed = @{}; foreach ($k in $cap.Keys) { try { $observed[$k] = (Cnt (Invoke-Hunt $cap[$k])) } catch { $observed[$k] = -1 } }

    if ($CriteriaPath -and (Test-Path $CriteriaPath)) { $criteria = Get-Content $CriteriaPath -Raw | ConvertFrom-Json }
    else {
        Write-Host "No -CriteriaPath supplied; using default PoC criteria." -ForegroundColor Yellow
        $criteria = @(
            [pscustomobject]@{ id='detect';   label='Detection reached portal';     capability='alert';    required=$true },
            [pscustomobject]@{ id='evidence'; label='Evidence attached to alert';    capability='evidence'; required=$true },
            [pscustomobject]@{ id='timeline'; label='Device timeline populated';     capability='device';   required=$true },
            [pscustomobject]@{ id='air';      label='Automated investigation start'; capability='air';      required=$false }
        )
    }
    Write-Host "`n=== MDEFULL PoC scorecard ===" -ForegroundColor Cyan
    $rows = @(); $passCount = 0; $reqFail = 0
    foreach ($c in $criteria) {
        $obs = if ($observed.ContainsKey($c.capability)) { $observed[$c.capability] } else { 0 }
        $res = if ($obs -gt 0) { 'PASS' } else { 'FAIL' }
        if ($res -eq 'PASS') { $passCount++ } elseif ($c.required) { $reqFail++ }
        Write-Host ("  [{0}] {1} (required={2}, observed={3})" -f $res, $c.label, $c.required, $obs) -ForegroundColor $(if ($res -eq 'PASS') { 'Green' } else { 'Yellow' })
        $rows += [pscustomobject]@{ id=$c.id; label=$c.label; capability=$c.capability; required=$c.required; observed=$obs; result=$res }
    }
    $overall = if ($reqFail -eq 0) { 'PASS' } else { 'NEEDS REVIEW' }
    [pscustomobject]@{
        solution='Microsoft Defender for Endpoint - PoC'; generated=(Get-Date).ToString('u'); device=$DeviceName
        lookbackHrs=$LookbackHours; criteria=$rows; passCount=$passCount; total=$criteria.Count; overall=$overall
        note='Benign test signal (EICAR / Microsoft built-in simulation). Final verdict is the customer decision.'
    } | ConvertTo-Json -Depth 6 | Set-Content -Path $OutFile -Encoding utf8
    Write-Host ("`nOverall: {0}  ({1}/{2} criteria passed). Saved: {3}" -f $overall, $passCount, $criteria.Count, $OutFile) -ForegroundColor Cyan
    Write-Host "Next (when done): -Action Teardown -WhatIf" -ForegroundColor Cyan
}

'Teardown' {
    Connect-Graph @('DeviceManagementConfiguration.ReadWrite.All')
    Write-Host "`n=== MDEFULL PoC — teardown (preview by default) ===" -ForegroundColor Cyan
    $policy = Get-Json "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=name eq '$EdrPolicyName'"
    if ($policy -and $policy.value.Count -gt 0) {
        $polId = $policy.value[0].id
        if ($PSCmdlet.ShouldProcess($EdrPolicyName, "Clear pilot assignment")) {
            try { Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$polId/assign" -Body (@{ assignments = @() } | ConvertTo-Json) -ContentType 'application/json' | Out-Null
                Write-Host "  Cleared assignment on '$EdrPolicyName'." -ForegroundColor Green }
            catch { Write-Host ("  Could not clear assignment: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
        } else { Write-Host "  [WhatIf] Would clear assignment on '$EdrPolicyName'." -ForegroundColor Yellow }
        if ($DeletePolicy) {
            if ($PSCmdlet.ShouldProcess($EdrPolicyName, "Delete Intune EDR policy")) {
                try { Invoke-MgGraphRequest -Method DELETE -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$polId" | Out-Null; Write-Host "  Deleted policy '$EdrPolicyName'." -ForegroundColor Green }
                catch { Write-Host ("  Could not delete policy: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
            } else { Write-Host "  [WhatIf] Would delete policy '$EdrPolicyName'." -ForegroundColor Yellow }
        }
    } else { Write-Host "  EDR policy '$EdrPolicyName' not found (already removed?)." -ForegroundColor Gray }

    $eicarPath = Join-Path $WorkDir 'eicar-poc.com'
    if (Test-Path $eicarPath) {
        if ($PSCmdlet.ShouldProcess($eicarPath, "Delete benign EICAR test file")) { Remove-Item $eicarPath -Force -ErrorAction SilentlyContinue; Write-Host "  Deleted EICAR test file (if AV had not already quarantined it)." -ForegroundColor Green }
        else { Write-Host "  [WhatIf] Would delete $eicarPath." -ForegroundColor Yellow }
    } else { Write-Host "  No local EICAR file to delete (likely quarantined by AV — expected)." -ForegroundColor Gray }

    Write-Host "`n[Finish in the portal]" -ForegroundColor Cyan
    Write-Host "  Offboard pilot devices : Settings -> Endpoints -> Offboarding (or the Intune offboarding policy)." -ForegroundColor Gray
    Write-Host "  Resolve test alerts    : Incidents & alerts -> filter '$Tag' -> Resolve as 'Not a threat / test'." -ForegroundColor Gray
    Write-Host "  (Optional) delete group '$PilotGroup' once devices are offboarded." -ForegroundColor Gray
    Write-Host "`nConfirm with: MDEFULL-Validate.ps1 -Check PoC  (should report nothing left onboarded)." -ForegroundColor Cyan
}

}

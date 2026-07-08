<#
.SYNOPSIS
    DLCSPO-Validate.ps1 — Validate the retention policy exists, covers the intended locations, matches the
    period, and has no unintended delete action (read-only).
.DESCRIPTION
    PURPOSE
        The pilot/expansion gate. Confirms PASS/FAIL that 'SPO-OneDrive Retention - Policy' exists and is
        enabled, covers SharePoint/OneDrive as intended, its rule retains for the expected period, and — for
        the pilot — that NO unintended delete action is enabled. Read-only. Run on the pilot before enabling
        deletion or expanding.
    HOW TO RUN
        .\DLCSPO-Validate.ps1 -ExpectDelete:$false -ExpectRetainDays 2555
        PowerShell 5.1+/7+. Connect first with Connect-IPPSSession. No secret is stored in the script.
    EXPECTED RESULTS
        A PASS/FAIL line per gate; overall PASS only when the policy matches the intended design. During the
        pilot, a delete action being present FAILS the "no unintended deletion" gate.
.NOTES
    Purview — SharePoint & OneDrive Lifecycle Policies. Read-only gate. Verify your licensing/tenant;
    property/action names vary by module version.
#>
[CmdletBinding()]
param(
    [string]$PolicyName = 'SPO-OneDrive Retention - Policy',
    [int]$ExpectRetainDays = 2555,
    [bool]$ExpectDelete = $false      # pilot expects retain-only ($false); after approval set $true
)

function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
$fail = 0
function Gate([string]$Name, [bool]$Ok, [string]$Detail) {
    if ($Ok) { Write-Host ("PASS  {0} — {1}" -f $Name, $Detail) -ForegroundColor Green }
    else     { Write-Host ("FAIL  {0} — {1}" -f $Name, $Detail) -ForegroundColor Red; $script:fail++ }
}

Write-Host "`n=== SharePoint & OneDrive Lifecycle — validation gate (read-only) ===" -ForegroundColor Cyan
if (-not (Test-Command 'Get-RetentionCompliancePolicy')) { Write-Host "Run Connect-IPPSSession first." -ForegroundColor Yellow; return }

$policy = Get-RetentionCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
Gate ("Policy exists: {0}" -f $PolicyName) ([bool]$policy) $(if($policy){'found'}else{'not found — create it (Implementation Step 3)'})
if (-not $policy) { Write-Host "`nOVERALL: FAIL — policy missing." -ForegroundColor Red; return }

Gate 'Policy enabled' ([bool]$policy.Enabled) ("Enabled = {0}" -f $policy.Enabled)

$spo = ($policy.PSObject.Properties.Name -contains 'SharePointLocation' -and $policy.SharePointLocation)
$od  = ($policy.PSObject.Properties.Name -contains 'OneDriveLocation'   -and $policy.OneDriveLocation)
Gate 'Covers SharePoint/OneDrive' ($spo -or $od) $(if($spo -or $od){("SPO={0}; OneDrive={1}" -f [bool]$spo, [bool]$od)}else{'no SPO/OneDrive location set'})

$rules = @(Get-RetentionComplianceRule -Policy $PolicyName -ErrorAction SilentlyContinue)
Gate 'Rule exists' ($rules.Count -gt 0) ("{0} rule(s)" -f $rules.Count)

foreach ($r in $rules) {
    $isDelete = ("{0}" -f $r.RetentionComplianceAction) -match 'Delete'
    if ($ExpectDelete) {
        Gate ("  Rule action (expect retain-then-delete): {0}" -f $r.Name) $isDelete ("action = {0}" -f $r.RetentionComplianceAction)
    } else {
        Gate ("  No unintended deletion (pilot): {0}" -f $r.Name) (-not $isDelete) ("action = {0}" -f $r.RetentionComplianceAction)
    }
    $periodOk = ("{0}" -f $r.RetentionDuration) -match ([string]$ExpectRetainDays)
    Gate ("  Period matches design: {0}" -f $r.Name) $periodOk ("duration = {0} (expected {1})" -f $r.RetentionDuration, $ExpectRetainDays)
}

Write-Host ""
if ($fail -eq 0) { Write-Host "OVERALL: PASS — policy matches the intended design. Safe to proceed/expand." -ForegroundColor Green }
else             { Write-Host ("OVERALL: FAIL — {0} gate(s) failed. Remediate before enabling deletion or expanding." -f $fail) -ForegroundColor Red }

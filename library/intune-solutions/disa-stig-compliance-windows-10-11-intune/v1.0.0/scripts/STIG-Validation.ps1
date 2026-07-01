<#
.SYNOPSIS
    STIG-Validation.ps1 — per-device DISA STIG compliance check against the expected baseline.
.DESCRIPTION
    PURPOSE
        Checks this device's effective settings against a set of expected DISA STIG values supplied
        in a baseline file, and reports per-rule PASS/DRIFT with the rule's CAT severity. The baseline
        file is YOUR exported expected values (illustrative samples are used if none is supplied).
        Read-only — it does not change settings. This complements, and does not replace, a SCAP /
        STIG Viewer scan (the authority for full rule coverage).
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\STIG-Validation.ps1 -BaselinePath .\stig-baseline.json
        Baseline JSON format (array):
          [ { "RuleId":"SV-...", "Name":"...", "Cat":"CAT II", "Path":"HKLM:\\...", "Property":"...", "Expected":1 } ]
        (RuleId/Cat/Expected values and paths come from the DISA STIG / STIG Viewer you obtained.)
    EXPECTED RESULTS
        A per-rule PASS/DRIFT table (with CAT) and "DEVICE COMPLIANT" when no drift is found.
.NOTES
    Intune Solutions — DISA STIG Win10/11. Read-only. Rule IDs/paths/values are deferred to the STIG.
#>
[CmdletBinding()] param([string]$BaselinePath)

Write-Host "=== DISA STIG Win10/11 Validation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan

if ($BaselinePath -and (Test-Path $BaselinePath)) {
    $baseline = Get-Content $BaselinePath -Raw | ConvertFrom-Json
} else {
    Write-Host "  No -BaselinePath supplied — using ILLUSTRATIVE sample rules (replace with your STIG export)." -ForegroundColor Yellow
    $baseline = @(
        # ILLUSTRATIVE EXAMPLES ONLY — confirm real Rule IDs and values against the DISA Windows STIG / STIG Viewer.
        [pscustomobject]@{ RuleId='EXAMPLE-0001'; Name='Limit blank-password use (example)'; Cat='CAT II'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'; Property='LimitBlankPasswordUse'; Expected=1 },
        [pscustomobject]@{ RuleId='EXAMPLE-0002'; Name='SMBv1 client disabled (example)';   Cat='CAT I';  Path='HKLM:\SYSTEM\CurrentControlSet\Services\mrxsmb10'; Property='Start'; Expected=4 }
    )
}

$drift = 0
foreach ($c in $baseline) {
    $actual = (Get-ItemProperty -Path $c.Path -Name $c.Property -ErrorAction SilentlyContinue).$($c.Property)
    $ok = "$actual" -eq "$($c.Expected)"
    if (-not $ok) { $drift++ }
    $status = if ($ok) { 'PASS' } else { 'DRIFT' }
    $color  = if ($ok) { 'Green' } else { 'Yellow' }
    Write-Host ("  [{0}] [{1}] {2}  (expected={3}, actual={4})" -f $status, $c.Cat, $c.Name, $c.Expected, $(if($null -ne $actual){$actual}else{'<missing>'})) -ForegroundColor $color
}

if ($drift -eq 0) { Write-Host "`nResult: DEVICE COMPLIANT" -ForegroundColor Green; exit 0 }
else { Write-Host ("`nResult: {0} rule(s) DRIFTED — run STIG-Remediation.ps1 to reapply." -f $drift) -ForegroundColor Yellow; exit 1 }

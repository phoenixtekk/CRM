<#
.SYNOPSIS
    CIS11-Validation.ps1 — per-device CIS-compliance check against the expected baseline.
.DESCRIPTION
    PURPOSE
        Checks this device's effective settings against a small set of expected CIS Windows 11
        baseline values supplied in a baseline file, and reports per-control PASS/DRIFT. The baseline
        file is YOUR exported expected values (illustrative samples are used if none is supplied).
        Read-only — it does not change settings.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\CIS11-Validation.ps1 -BaselinePath .\cis-baseline.json
        Baseline JSON format (array): [ { "Name":"...", "Path":"HKLM:\\...", "Property":"...", "Expected":1 } ]
        ("Expected" values and paths come from the CIS Benchmark / Build Kit you obtained.)
    EXPECTED RESULTS
        A per-control PASS/DRIFT table and "DEVICE COMPLIANT" when no drift is found.
.NOTES
    Intune Solutions — CIS Win11. Read-only. Control paths/values are deferred to the CIS Benchmark.
#>
[CmdletBinding()] param([string]$BaselinePath)

Write-Host "=== CIS Win11 Validation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan

if ($BaselinePath -and (Test-Path $BaselinePath)) {
    $baseline = Get-Content $BaselinePath -Raw | ConvertFrom-Json
} else {
    Write-Host "  No -BaselinePath supplied — using ILLUSTRATIVE sample controls (replace with your CIS export)." -ForegroundColor Yellow
    $baseline = @(
        # ILLUSTRATIVE EXAMPLES ONLY — confirm real values against the CIS Windows 11 Benchmark.
        [pscustomobject]@{ Name='Limit blank-password use (example)'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'; Property='LimitBlankPasswordUse'; Expected=1 },
        [pscustomobject]@{ Name='SMBv1 client disabled (example)';   Path='HKLM:\SYSTEM\CurrentControlSet\Services\mrxsmb10'; Property='Start'; Expected=4 }
    )
}

$drift = 0
foreach ($c in $baseline) {
    $actual = (Get-ItemProperty -Path $c.Path -Name $c.Property -ErrorAction SilentlyContinue).$($c.Property)
    $ok = "$actual" -eq "$($c.Expected)"
    if (-not $ok) { $drift++ }
    $status = if ($ok) { 'PASS' } else { 'DRIFT' }
    $color  = if ($ok) { 'Green' } else { 'Yellow' }
    Write-Host ("  [{0}] {1}  (expected={2}, actual={3})" -f $status, $c.Name, $c.Expected, $(if($null -ne $actual){$actual}else{'<missing>'})) -ForegroundColor $color
}

if ($drift -eq 0) { Write-Host "`nResult: DEVICE COMPLIANT" -ForegroundColor Green; exit 0 }
else { Write-Host ("`nResult: {0} control(s) DRIFTED — run CIS11-Remediation.ps1 to reapply." -f $drift) -ForegroundColor Yellow; exit 1 }

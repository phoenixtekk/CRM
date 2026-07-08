<#
.SYNOPSIS
    IPPBI-Validate.ps1 — Validate the analytics labels exist and are published, and print the tenant-setting
    gates to confirm (read-only).
.DESCRIPTION
    PURPOSE
        The pilot/expansion gate. Confirms PASS/FAIL that each intended sensitivity label exists and is
        published in 'Analytics Labels - Policy' to the intended creators, then prints the information-
        protection tenant-setting gates to confirm in the Power BI/Fabric admin portal (not readable here).
        Read-only — makes no change. Run on the pilot before expanding, and after each expansion wave.
    HOW TO RUN
        .\IPPBI-Validate.ps1
        PowerShell 5.1+/7+. Connect first with Connect-IPPSSession. No secret is stored in the script.
    EXPECTED RESULTS
        A PASS/FAIL line per scriptable gate plus the printed tenant-setting gates; a final overall PASS
        only when every intended label exists and is published. Any FAIL names the specific missing object.
.NOTES
    Purview — Sensitivity Labeling for Power BI & Fabric. Read-only gate. Verify your licensing/tenant:
    the tenant settings are confirmed in the admin portal; policy property names vary by module version.
#>
[CmdletBinding()]
param(
    [string]$PolicyName = 'Analytics Labels - Policy',
    [string[]]$ExpectedLabels = @('General','Confidential','Highly Confidential')
)

function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
$fail = 0
function Gate([string]$Name, [bool]$Ok, [string]$Detail) {
    if ($Ok) { Write-Host ("PASS  {0} — {1}" -f $Name, $Detail) -ForegroundColor Green }
    else     { Write-Host ("FAIL  {0} — {1}" -f $Name, $Detail) -ForegroundColor Red; $script:fail++ }
}

Write-Host "`n=== Power BI/Fabric labeling — validation gate (read-only) ===" -ForegroundColor Cyan
if (-not (Test-Command 'Get-Label')) { Write-Host "Run Connect-IPPSSession first." -ForegroundColor Yellow; return }

$labels = @(Get-Label -ErrorAction SilentlyContinue)
foreach ($name in $ExpectedLabels) {
    $l = $labels | Where-Object { $_.DisplayName -eq $name } | Select-Object -First 1
    Gate ("Label exists: {0}" -f $name) ([bool]$l) $(if($l){'found'}else{'not found — publish your sensitivity labels'})
}

$policy = Get-LabelPolicy -Identity $PolicyName -ErrorAction SilentlyContinue
Gate ("Policy exists: {0}" -f $PolicyName) ([bool]$policy) $(if($policy){'found'}else{'not found — publish it (Implementation Step 3)'})
if ($policy) {
    $attached = @()
    foreach ($prop in 'Labels','ScopedLabels') {
        if ($policy.PSObject.Properties.Name -contains $prop -and $policy.$prop) { $attached += @($policy.$prop) }
    }
    foreach ($name in $ExpectedLabels) {
        $isIn = ($attached -join ' ') -match [regex]::Escape($name)
        Gate ("  Published in policy: {0}" -f $name) $isIn $(if($isIn){'listed on the policy'}else{'not detected — verify in the portal / add with Set-LabelPolicy -AddLabel'})
    }
}

Write-Host "`nConfirm these tenant-setting gates in the Power BI/Fabric admin portal (not readable here):" -ForegroundColor Cyan
@(
    'Allow users to apply sensitivity labels for content = ON for BI Labeling - Enabled Users',
    'Apply sensitivity labels from data sources (source inheritance) = ON',
    'Export protection so Excel/PowerPoint/PDF exports inherit the label + encryption = configured',
    'Mandatory label policy = OFF during pilot (ON only after validation)'
) | ForEach-Object { Write-Host ("  [ ] {0}" -f $_) -ForegroundColor DarkGray }

Write-Host ""
if ($fail -eq 0) { Write-Host "OVERALL: PASS (scriptable gates) — labels present and published. Confirm the tenant-setting gates above, then proceed/expand." -ForegroundColor Green }
else             { Write-Host ("OVERALL: FAIL — {0} gate(s) failed. Remediate before expanding." -f $fail) -ForegroundColor Red }

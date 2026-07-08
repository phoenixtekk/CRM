<#
.SYNOPSIS
    DGSTEWARD-Test-Framework.ps1 — read-only validation that every in-scope control has a recorded owner and steward (no changes).
.DESCRIPTION
    PURPOSE
        The pass/fail gate for the framework: re-reads the in-scope Purview controls (sensitivity labels,
        DLP policies, retention policies) via Security & Compliance PowerShell, confirms each carries an
        Owner and a Steward tag, and reports any gap. Optionally cross-checks named owners/stewards against
        an expected assignment CSV. Read-only — makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DGSTEWARD-Test-Framework.ps1
        With expected matrix:
        powershell -ExecutionPolicy Bypass -File .\DGSTEWARD-Test-Framework.ps1 -MatrixPath .\Purview-Stewardship-Matrix.csv
        PowerShell 5.1+/7+. Requires ExchangeOnlineManagement (Connect-IPPSSession).
    EXPECTED RESULTS
        A per-control PASS/FAIL table and an overall gate result. PASS = zero unowned in-scope controls
        (or every gap is a named, expected exception).
.NOTES
    Purview — Data-Owner & Steward Framework. Read-only. No secrets in code. Owner/steward are read from the
    object comment tag written by DGSTEWARD-Set-Stewardship.ps1.
#>
[CmdletBinding()]
param(
    [string]$MatrixPath,
    [string]$CsvPath
)

Write-Host '=== Data-Owner & Steward Framework — validation (read-only) ===' -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

function Get-OwnershipTag {
    param([string]$Text)
    $o=$null;$s=$null
    if ($Text -match 'Owner\s*=\s*([^;]+)')   { $o=$Matches[1].Trim() }
    if ($Text -match 'Steward\s*=\s*([^;]+)') { $s=$Matches[1].Trim() }
    [pscustomobject]@{ Owner=$o; Steward=$s }
}

$expected = @{}
if ($MatrixPath -and (Test-Path $MatrixPath)) {
    foreach ($r in (Import-Csv -Path $MatrixPath)) { $expected["$($r.ControlType)|$($r.Name)"] = $r }
}

$results = New-Object System.Collections.Generic.List[object]

$controls = @()
$controls += (Get-Label -ErrorAction SilentlyContinue                 | ForEach-Object { [pscustomobject]@{ Type='SensitivityLabel'; Name=$_.DisplayName; Comment=$_.Comment } })
$controls += (Get-DlpCompliancePolicy -ErrorAction SilentlyContinue   | ForEach-Object { [pscustomobject]@{ Type='DlpPolicy';        Name=$_.Name;        Comment=$_.Comment } })
$controls += (Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue | ForEach-Object { [pscustomobject]@{ Type='RetentionPolicy'; Name=$_.Name;     Comment=$_.Comment } })

foreach ($c in $controls) {
    $tag = Get-OwnershipTag -Text $c.Comment
    $hasOwner   = [bool]$tag.Owner
    $hasSteward = [bool]$tag.Steward
    $pass = $hasOwner -and $hasSteward

    $mismatch = $null
    $key = "$($c.Type)|$($c.Name)"
    if ($expected.ContainsKey($key)) {
        $exp = $expected[$key]
        if ($exp.Owner   -and $tag.Owner   -and ($exp.Owner   -ne $tag.Owner))   { $mismatch = "Owner expected '$($exp.Owner)' got '$($tag.Owner)'" }
        if ($exp.Steward -and $tag.Steward -and ($exp.Steward -ne $tag.Steward)) { $mismatch = (@($mismatch, "Steward expected '$($exp.Steward)' got '$($tag.Steward)'") -ne $null -join '; ') }
    }

    $results.Add([pscustomobject]@{ ControlType=$c.Type; Name=$c.Name; Owner=$tag.Owner; Steward=$tag.Steward;
        Result=$(if ($pass) {'PASS'} else {'FAIL'}); Note=$(if (-not $hasOwner) {'no owner'} elseif (-not $hasSteward) {'no steward'} elseif ($mismatch) {$mismatch} else {'ok'}) })
}

$results | Format-Table ControlType, Name, Owner, Steward, Result, Note -AutoSize

$fail = @($results | Where-Object { $_.Result -eq 'FAIL' }).Count
$total = $results.Count
Write-Host ('--- Gate ---') -ForegroundColor Cyan
if ($fail -eq 0) {
    Write-Host ("PASS — all {0} in-scope control(s) have a recorded Owner and Steward." -f $total) -ForegroundColor Green
} else {
    Write-Host ("FAIL — {0} of {1} control(s) are missing an Owner or Steward. Close each gap or record it as a named exception." -f $fail, $total) -ForegroundColor Red
}

if ($CsvPath) { $results | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host ("Saved results to {0}" -f $CsvPath) -ForegroundColor Green }

Disconnect-ExchangeOnline -Confirm:$false | Out-Null
Write-Host 'Validation complete (read-only).' -ForegroundColor Green

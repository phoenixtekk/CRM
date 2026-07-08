<#
.SYNOPSIS
    DLPCJIS-Discovery.ps1 — read-only assessment of existing DLP policies/rules and available sensitive-info-types for CJI DLP planning. Makes no changes.
.DESCRIPTION
    PURPOSE
        Builds the assessment baseline for the CJIS DLP pack: inventories every existing DLP policy with its
        MODE (Enable / TestWithNotifications / TestWithoutNotifications / Disable) and workload scope, lists
        the available sensitive information types, and flags any CJI-related classification already present so
        you build on what exists and avoid overlapping policies. Optionally saves a known-good baseline
        (-SaveBaseline) and compares live state to it (-CompareBaseline) to report DRIFT. Read-only; uses
        Security & Compliance PowerShell.
    HOW TO RUN
        Connect-IPPSSession                                   # modern-auth admin sign-in (no secrets in code)
        .\DLPCJIS-Discovery.ps1                                # inventory to console (+ optional -CsvPath)
        .\DLPCJIS-Discovery.ps1 -SaveBaseline -BaselinePath .\Policy-Baseline-CJISDLP.json
        .\DLPCJIS-Discovery.ps1 -CompareBaseline -BaselinePath .\Policy-Baseline-CJISDLP.json
        PowerShell 5.1+/7+; requires the ExchangeOnlineManagement module (Connect-IPPSSession).
    EXPECTED RESULTS
        A per-policy table (Name, Mode, Workloads) + a sensitive-info-type list with any CJI-related type
        highlighted. With -CompareBaseline: a DRIFT report (Added / Removed / ModeChanged). Zero drift = pass.
.NOTES
    CJIS DLP Pack — read-only. Verify capability/licensing for your tenant; advanced DLP surfaces
    (Endpoint DLP, EDM, trainable classifiers) require E5 / E5 Compliance. Whether data IS CJI is a
    determination for your CSO/TAC / compliance authority — this script assesses the technical estate only.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [string]$BaselinePath = '.\Policy-Baseline-CJISDLP.json',
    [string[]]$CjiKeyword = @('CJI','CJIS','CHRI','criminal','NCIC','III'),
    [switch]$SaveBaseline,
    [switch]$CompareBaseline
)

function Test-IPPSConnected {
    if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
        Write-Error "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first."
        return $false
    }
    return $true
}
if (-not (Test-IPPSConnected)) { return }

# --- DLP policy inventory (read-only) ---
Write-Host "=== Existing DLP policies (Policy Register - CJIS DLP) ===" -ForegroundColor Cyan
$inventory = New-Object System.Collections.Generic.List[object]
try {
    $policies = Get-DlpCompliancePolicy -ErrorAction Stop
} catch {
    Write-Warning ("Could not read DLP policies (role/licensing?): {0}" -f $_.Exception.Message)
    $policies = @()
}
foreach ($p in $policies) {
    # Build a compact workload-scope string from the *Location properties that are populated.
    $workloads = @()
    foreach ($w in 'ExchangeLocation','SharePointLocation','OneDriveLocation','TeamsLocation','EndpointDlpLocation') {
        if ($p.PSObject.Properties.Name -contains $w -and $p.$w) { $workloads += ($w -replace 'Location$','') }
    }
    $inventory.Add([pscustomobject]@{
        Name      = $p.Name
        Mode      = [string]$p.Mode
        Workloads = ($workloads -join ',')
        Enabled   = [string]$p.Enabled
    })
}
$inventory | Sort-Object Name | Format-Table -AutoSize
Write-Host ("Total DLP policies: {0}" -f $inventory.Count) -ForegroundColor Green

# Flag any policy that already looks CJI-related.
$cjiPolicies = @($inventory | Where-Object { $n = $_.Name; ($CjiKeyword | Where-Object { $n -match $_ }) })
if ($cjiPolicies.Count -gt 0) {
    Write-Host "`nExisting CJI-related DLP policies detected (build on / reconcile with these):" -ForegroundColor Yellow
    $cjiPolicies | Format-Table -AutoSize
} else {
    Write-Host "`nNo existing CJI-related DLP policy found — this pack will create one in test mode." -ForegroundColor Cyan
}

# Mode health summary.
$enforce = @($inventory | Where-Object { $_.Mode -eq 'Enable' }).Count
$testish = @($inventory | Where-Object { $_.Mode -match 'Test' }).Count
Write-Host ("Modes -> Enforcing: {0} | In test/simulation: {1}" -f $enforce, $testish) -ForegroundColor Cyan

# --- Available sensitive information types (read-only) ---
Write-Host "`n=== Available sensitive information types ===" -ForegroundColor Cyan
try {
    $sits = Get-DlpSensitiveInformationType -ErrorAction Stop
    $cjiSits = @($sits | Where-Object { $s = "$($_.Name) $($_.Description)"; ($CjiKeyword | Where-Object { $s -match $_ }) })
    Write-Host ("Total SITs available: {0}" -f $sits.Count) -ForegroundColor Green
    if ($cjiSits.Count -gt 0) {
        Write-Host "CJI-related sensitive info types present:" -ForegroundColor Yellow
        $cjiSits | Select-Object Name, Publisher | Format-Table -AutoSize
    } else {
        Write-Host "No CJI-specific SIT found — author 'CJI Sensitive Info Type - CHRI - Custom' (see guide Step 2)." -ForegroundColor Cyan
    }
} catch {
    Write-Warning ("Could not read sensitive info types: {0}" -f $_.Exception.Message)
    $sits = @()
}

if ($CsvPath) {
    $inventory | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("`nSaved policy inventory CSV to {0}" -f $CsvPath) -ForegroundColor Green
}

# --- Baseline save ---
if ($SaveBaseline) {
    $inventory | ConvertTo-Json -Depth 4 | Set-Content -Path $BaselinePath -Encoding UTF8
    Write-Host ("Baseline saved to {0} ({1} policies). Re-baseline only after an APPROVED change set." -f $BaselinePath, $inventory.Count) -ForegroundColor Green
}

# --- Drift comparison ---
if ($CompareBaseline) {
    if (-not (Test-Path $BaselinePath)) {
        Write-Error "Baseline not found at $BaselinePath. Run with -SaveBaseline first."
        return
    }
    $base = Get-Content $BaselinePath -Raw | ConvertFrom-Json
    $baseMap = @{}; foreach ($b in $base) { $baseMap[$b.Name] = $b }
    $liveMap = @{}; foreach ($l in $inventory) { $liveMap[$l.Name] = $l }

    $drift = New-Object System.Collections.Generic.List[object]
    foreach ($k in $liveMap.Keys) {
        if (-not $baseMap.ContainsKey($k)) {
            $drift.Add([pscustomobject]@{ Change='Added'; Policy=$k; From=''; To=$liveMap[$k].Mode })
        } elseif ($baseMap[$k].Mode -ne $liveMap[$k].Mode) {
            $drift.Add([pscustomobject]@{ Change='ModeChanged'; Policy=$k; From=$baseMap[$k].Mode; To=$liveMap[$k].Mode })
        }
    }
    foreach ($k in $baseMap.Keys) {
        if (-not $liveMap.ContainsKey($k)) {
            $drift.Add([pscustomobject]@{ Change='Removed'; Policy=$k; From=$baseMap[$k].Mode; To='' })
        }
    }

    Write-Host "`n=== DRIFT vs baseline ===" -ForegroundColor Yellow
    if ($drift.Count -eq 0) {
        Write-Host "No drift. Live estate matches the baseline. (PASS)" -ForegroundColor Green
    } else {
        $drift | Sort-Object Change, Policy | Format-Table -AutoSize
        Write-Warning ("{0} drift item(s). An unexplained mode change on the CJI policy is a change-control event." -f $drift.Count)
    }
}

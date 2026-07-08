<#
.SYNOPSIS
    PURVOPS-Discovery.ps1 — read-only Purview policy inventory + drift/health assessment across DLP, sensitivity labels, auto-labeling, and retention. Makes no changes.
.DESCRIPTION
    PURPOSE
        Builds the authoritative policy register for the operating model: every DLP, sensitivity-label,
        label-policy, auto-labeling, and retention policy with its current MODE (Enable / Test / Disable).
        Optionally saves a known-good baseline (-SaveBaseline) and, on later runs, compares live state to
        that baseline (-CompareBaseline) to report DRIFT — new, removed, or mode-changed policies since the
        last review. Read-only; uses Security & Compliance PowerShell.
    HOW TO RUN
        Connect-IPPSSession                                  # modern-auth admin sign-in (no secrets in code)
        .\PURVOPS-Discovery.ps1                               # inventory only, to console + optional CSV
        .\PURVOPS-Discovery.ps1 -SaveBaseline -BaselinePath .\Policy-Baseline.json
        .\PURVOPS-Discovery.ps1 -CompareBaseline -BaselinePath .\Policy-Baseline.json
        PowerShell 5.1+/7+; requires the ExchangeOnlineManagement module (Connect-IPPSSession).
    EXPECTED RESULTS
        A per-policy table (Family, Name, Mode, Enabled) and, with -CompareBaseline, a DRIFT report listing
        Added / Removed / ModeChanged policies. Zero drift against an unchanged tenant = pass.
.NOTES
    Purview — Operations & Governance. Read-only. Verify capability availability/licensing for your tenant;
    cmdlet availability depends on the compliance plan (E5 / E5 Compliance for advanced DLP/auto-labeling).
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [string]$BaselinePath = '.\Policy-Baseline.json',
    [switch]$SaveBaseline,
    [switch]$CompareBaseline
)

function Test-IPPSConnected {
    # Get-DlpCompliancePolicy is only available inside a Connect-IPPSSession context.
    if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
        Write-Error "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first."
        return $false
    }
    return $true
}
if (-not (Test-IPPSConnected)) { return }

Write-Host "=== Policy Register - Purview - Governance ===" -ForegroundColor Cyan
$inventory = New-Object System.Collections.Generic.List[object]

function Add-Policies {
    param([string]$Family, [scriptblock]$Getter, [string]$ModeProp = 'Mode', [string]$EnabledProp = 'Enabled')
    try {
        $items = & $Getter
    } catch {
        Write-Warning ("{0}: not available in this tenant/role ({1})" -f $Family, $_.Exception.Message)
        return
    }
    foreach ($p in $items) {
        $mode = if ($p.PSObject.Properties.Name -contains $ModeProp) { [string]$p.$ModeProp } else { '' }
        $enabled = if ($p.PSObject.Properties.Name -contains $EnabledProp) { [string]$p.$EnabledProp } else { '' }
        $inventory.Add([pscustomobject]@{
            Family  = $Family
            Name    = $p.Name
            Mode    = $mode
            Enabled = $enabled
        })
    }
}

# --- Enumerate each policy family (read-only) ---
Add-Policies -Family 'DLP'            -Getter { Get-DlpCompliancePolicy }
Add-Policies -Family 'Label'         -Getter { Get-Label }             -ModeProp 'DisplayName' # labels have no Mode; show display name
Add-Policies -Family 'LabelPolicy'   -Getter { Get-LabelPolicy }
Add-Policies -Family 'AutoLabeling'  -Getter { Get-AutoSensitivityLabelPolicy }
Add-Policies -Family 'Retention'     -Getter { Get-RetentionCompliancePolicy }

$inventory | Sort-Object Family, Name | Format-Table -AutoSize
Write-Host ("Total policies inventoried: {0}" -f $inventory.Count) -ForegroundColor Green

# Simple health summary: how many DLP/auto-labeling policies are still in test vs enforcing.
$testish = @($inventory | Where-Object { $_.Mode -match 'Test' }).Count
$enforce = @($inventory | Where-Object { $_.Mode -eq 'Enable' }).Count
Write-Host ("Modes -> Enforcing (Enable): {0}  |  In test/simulation: {1}" -f $enforce, $testish) -ForegroundColor Cyan

if ($CsvPath) {
    $inventory | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved inventory CSV to {0}" -f $CsvPath) -ForegroundColor Green
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
    $key = { param($o) "{0}|{1}" -f $o.Family, $o.Name }
    $baseMap = @{}; foreach ($b in $base) { $baseMap[(& $key $b)] = $b }
    $liveMap = @{}; foreach ($l in $inventory) { $liveMap[(& $key $l)] = $l }

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
        Write-Warning ("{0} drift item(s). Each unexplained change is a change-control event — investigate before re-baselining." -f $drift.Count)
    }
}

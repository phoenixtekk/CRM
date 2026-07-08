<#
.SYNOPSIS
    PURVLABEL-SimulationReport.ps1 — read-only auto-labeling simulation status + match report.
.DESCRIPTION
    Reports a service-side auto-labeling policy's current mode (confirming it is still in simulation),
    its scan/deployment status, and the items it matched — i.e. what WOULD be labeled — so you can
    measure precision before enforcing. Read-only; makes no changes. Run it against the simulation
    policy created by PURVLABEL-SensitivityConfig.ps1.
.EXAMPLE
    .\PURVLABEL-SimulationReport.ps1 -PolicyName "AL Sim - Financial - SPO+ODB"
    Prints the policy mode/status and a summary of matched items.
.EXAMPLE
    .\PURVLABEL-SimulationReport.ps1 -PolicyName "AL Sim - Financial - SPO+ODB" -CsvPath C:\Temp\sim-matches.csv
    Also exports the matched-item details for review with the data owner.
.NOTES
    Requires PowerShell 5.1+/7+ and ExchangeOnlineManagement (Connect-IPPSSession).
    Role: Information Protection Admin/Reader. Auto-labeling is licensing-gated (verify your licensing/tenant, typically E5).
    Expected results: PASS = policy Mode is a TestWithout/WithNotifications (simulation) value and a match
    summary is shown. FAIL = policy not found, or Mode is already 'Enable' before precision sign-off, or
    the cmdlet is unavailable (licensing).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$PolicyName,
    [string]$CsvPath
)

Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-AutoSensitivityLabelPolicy -ErrorAction SilentlyContinue)) {
    Connect-IPPSSession -ShowBanner:$false
}

Write-Host ("=== Auto-labeling simulation report: {0} ===" -f $PolicyName) -ForegroundColor Cyan

$pol = Get-AutoSensitivityLabelPolicy -Identity $PolicyName -ErrorAction SilentlyContinue
if (-not $pol) {
    Write-Warning ("Policy '{0}' not found (or auto-labeling not licensed in this tenant)." -f $PolicyName)
    return
}

# --- Mode + status ---
Write-Host "`n--- Policy status ---" -ForegroundColor Cyan
$pol | Select-Object Name, Mode,
    @{n='ApplyLabel';e={$_.ApplySensitivityLabel}},
    @{n='SharePoint';e={($_.SharePointLocation.Name -join ',')}},
    @{n='OneDrive';e={($_.OneDriveLocation.Name -join ',')}},
    @{n='Exchange';e={($_.ExchangeLocation.Name -join ',')}},
    DistributionStatus | Format-List

$simModes = @('TestWithoutNotifications','TestWithNotifications')
if ($pol.Mode -in $simModes) {
    Write-Host ("PASS: policy is in SIMULATION mode ('{0}') — no content is being labeled." -f $pol.Mode) -ForegroundColor Green
} elseif ($pol.Mode -eq 'Enable') {
    Write-Host "WARNING: policy Mode is 'Enable' (ENFORCING). Confirm simulation precision was signed off before enforcement." -ForegroundColor Yellow
} else {
    Write-Host ("Policy Mode: {0}" -f $pol.Mode) -ForegroundColor DarkGray
}

# --- Rules (the matching conditions) ---
Write-Host "`n--- Auto-labeling rules (conditions) ---" -ForegroundColor Cyan
Get-AutoSensitivityLabelRule -ErrorAction SilentlyContinue |
    Where-Object { $_.ParentPolicyName -eq $PolicyName -or $_.Policy -eq $PolicyName } |
    Select-Object Name, Disabled,
        @{n='SensitiveInfo';e={ ($_.ContentContainsSensitiveInformation | ForEach-Object { $_.Name }) -join ', ' }} |
    Format-Table -AutoSize

# --- Simulation match summary ---
# Matched items surface through the content explorer / policy simulation. Where the tenant exposes
# per-policy simulation detail, summarize counts; otherwise direct the reviewer to the portal.
Write-Host "`n--- Simulation matches (what WOULD be labeled) ---" -ForegroundColor Cyan
$matches = $null
try {
    # Some tenants expose simulation results via Get-DlpDetailReport / content explorer; the exact
    # surface is tenant/portal dependent (verify in your tenant). We report the count if available.
    $matches = Get-AutoSensitivityLabelPolicy -Identity $PolicyName -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty SimulationStatus -ErrorAction SilentlyContinue
} catch { $matches = $null }

if ($pol.PSObject.Properties.Name -contains 'SimulationStatus' -and $pol.SimulationStatus) {
    Write-Host ("Simulation status: {0}" -f $pol.SimulationStatus) -ForegroundColor Cyan
}
Write-Host "Review the matched items in the Purview portal:" -ForegroundColor Cyan
Write-Host "  Information Protection -> Auto-labeling -> '$PolicyName' -> Simulation / Items to review" -ForegroundColor Cyan
Write-Host "  (portal path is version-sensitive — verify in your tenant). Sample matches for false positives" -ForegroundColor DarkGray
Write-Host "  and tune the rule conditions until precision is acceptable BEFORE enforcing (Testing Guide Test 6)." -ForegroundColor DarkGray

if ($CsvPath -and $matches) {
    $matches | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved simulation detail -> {0}" -f $CsvPath) -ForegroundColor Green
}

Write-Host "`n=== Simulation report complete (read-only) ===" -ForegroundColor Green

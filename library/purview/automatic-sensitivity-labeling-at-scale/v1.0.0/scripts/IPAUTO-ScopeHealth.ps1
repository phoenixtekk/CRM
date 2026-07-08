<#
.SYNOPSIS
    IPAUTO-ScopeHealth.ps1 — read-only scope/location + service-readiness health for auto-labeling; changes nothing.
.DESCRIPTION
    PURPOSE
        Read-only health check for a Purview auto-labeling policy's SCOPE and readiness: which SharePoint
        sites / OneDrive accounts / Exchange (mailbox) locations the policy targets, whether it is scoped to
        a pilot subset or All, whether adaptive scopes are in use, and READINESS flags (label present +
        published, policy mode, cmdlet/role availability that stands in for licensing/service readiness).
        Helps confirm you enforce on the intended locations only. It NEVER writes.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with the ExchangeOnlineManagement module, then Connect-IPPSSession.
        .\IPAUTO-ScopeHealth.ps1 -PolicyName "AutoLabel Sim - Confidential - SPO+ODB"
        Export the scope map:  add  -OutPath .\AutoLabel-ScopeHealth.csv
    EXAMPLE
        .\IPAUTO-ScopeHealth.ps1 -PolicyName "AutoLabel Sim - Confidential - SPO+ODB" -OutPath .\AutoLabel-ScopeHealth.csv
    .NOTES
        White-label Microsoft Purview tooling. Read-only. No credentials stored.
        Expected results: a per-location scope map + readiness flags, optionally to CSV
        (AutoLabel ScopeHealth - Estate - Report). PASS = the policy's locations resolve to the INTENDED
        scope (pilot subset, or All after expansion), with no unintended inclusions and readiness flags green.
        VERIFY IN YOUR TENANT: auto-labeling is E5/E5 Compliance and evolving; the LOCATION parameter names
        (SharePoint/OneDrive/Exchange, adaptive scope) vary by tenant/version — this reports what is exposed
        and flags anything it cannot resolve rather than asserting availability.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PolicyName,
    [string]$OutPath
)

$ErrorActionPreference = "Stop"
Write-Host "=== IPAUTO ScopeHealth — auto-labeling scope + readiness (read-only) ===" -ForegroundColor Cyan

if (-not (Get-Command Get-AutoSensitivityLabelPolicy -ErrorAction SilentlyContinue)) {
    Write-Host "Get-AutoSensitivityLabelPolicy not available. Run Connect-IPPSSession; check licensing/role (Req 2.2/2.3)." -ForegroundColor Red
    return
}

$pol = @(Get-AutoSensitivityLabelPolicy -ErrorAction SilentlyContinue) | Where-Object { $_.Name -eq $PolicyName } | Select-Object -First 1
if (-not $pol) { Write-Host ("Policy '{0}' not found." -f $PolicyName) -ForegroundColor Red; return }

$rows = New-Object System.Collections.Generic.List[object]
function Add-Row($category, $item, $value, $flag) {
    $rows.Add([pscustomobject]@{ Category = $category; Item = $item; Value = $value; Flag = $flag })
}

# --- Readiness flags ---
Write-Host "`n[Readiness]" -ForegroundColor Cyan
$modeStr = "$($pol.Mode)"
$isSim = @('TestWithoutNotifications', 'TestWithNotifications') -contains $modeStr
Add-Row "Readiness" "Policy mode" $modeStr ($(if ($isSim) { 'SIMULATION (safe)' } else { 'ENFORCED — confirm sign-off' }))
Write-Host ("  Mode: {0} ({1})" -f $modeStr, $(if ($isSim) { 'simulation' } else { 'enforced' })) -ForegroundColor Gray

$labelName = "$($pol.ApplySensitivityLabel)"
$labelObj = $null
if (Get-Command Get-Label -ErrorAction SilentlyContinue) {
    $labelObj = @(Get-Label -ErrorAction SilentlyContinue) | Where-Object { $_.Name -eq $labelName -or $_.DisplayName -eq $labelName -or $_.Guid -eq $labelName } | Select-Object -First 1
}
Add-Row "Readiness" "Applied label present" $labelName ($(if ($labelObj) { 'PRESENT' } else { 'NOT RESOLVED — verify label exists/published (Req 2.1)' }))
Write-Host ("  Applied label '{0}': {1}" -f $labelName, $(if ($labelObj) { 'present' } else { 'NOT resolved — check Req 2.1' })) -ForegroundColor $(if ($labelObj) { 'Green' } else { 'Yellow' })

foreach ($cmd in 'New-AutoSensitivityLabelPolicy', 'Set-AutoSensitivityLabelPolicy', 'New-AutoSensitivityLabelRule') {
    $avail = [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
    Add-Row "Readiness" "Cmdlet available: $cmd" $avail ($(if ($avail) { 'OK' } else { 'MISSING — check licensing/role (Req 2.2/2.3)' }))
}

# --- Location / scope map (property names vary by version — surface what is exposed) ---
Write-Host "`n[Scope / locations]" -ForegroundColor Cyan
$locProps = $pol.PSObject.Properties | Where-Object {
    $_.Name -match "(?i)sharepoint|onedrive|exchange|location|site|scope|adaptive"
}
if (@($locProps).Count -eq 0) {
    Write-Host "  No location/scope properties surfaced on the policy object — VERIFY the current location parameters in your tenant." -ForegroundColor Yellow
    Add-Row "Scope" "(none surfaced)" "" "VERIFY location parameters in tenant"
} else {
    foreach ($p in $locProps) {
        $val = "$($p.Value)"
        if ([string]::IsNullOrWhiteSpace($val)) { $val = "(empty)" }
        $flag = if ($val -match "(?i)\bAll\b") { 'ALL — tenant-wide' } elseif ($val -eq "(empty)") { 'empty — no target on this workload' } else { 'scoped subset' }
        Add-Row "Scope" $p.Name $val $flag
        Write-Host ("  {0}: {1}  [{2}]" -f $p.Name, $val, $flag) -ForegroundColor Gray
    }
    $anyAll = @($locProps | Where-Object { "$($_.Value)" -match "(?i)\bAll\b" }).Count -gt 0
    if ($anyAll -and $isSim) {
        Write-Host "  NOTE: scope includes ALL while still in simulation — fine for a full simulation scan; ensure you ENFORCE on a PILOT subset first (Implementation Step 7)." -ForegroundColor Yellow
    } elseif ($anyAll -and -not $isSim) {
        Write-Host "  NOTE: policy is ENFORCED tenant-wide (All). Confirm this is the intended expanded scope (Implementation Step 8)." -ForegroundColor Yellow
    }
}

if ($OutPath) {
    $rows | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`n{0} row(s) -> {1}  (AutoLabel ScopeHealth - Estate - Report)" -f $rows.Count, $OutPath) -ForegroundColor Green
}
Write-Host "`nPASS when locations resolve to the INTENDED scope (pilot subset, or All after expansion) and readiness flags are green." -ForegroundColor Cyan

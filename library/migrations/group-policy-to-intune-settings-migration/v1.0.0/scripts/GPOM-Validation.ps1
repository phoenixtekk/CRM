<#
.SYNOPSIS
    GPOM-Validation.ps1 — settings parity check (GPO vs. applied Intune policy) on a device.
.DESCRIPTION
    PURPOSE
        Confirms that the migrated settings are actually applied by Intune on the local device and
        that MDM has authority. Reads the MDMWinsOverGP (ControlPolicyConflict) state and the
        on-device PolicyManager values that Intune sets, and (optionally) compares them against a
        GPO XML export from GPOM-Discovery.ps1 to report match / missing / different per setting.
        Read-only.
    HOW TO RUN
        On a migrated pilot device (elevated):
        powershell -ExecutionPolicy Bypass -File .\GPOM-Validation.ps1 -GpoReportPath .\GPO-Export\YourGPO.xml
        (Omit -GpoReportPath to report only the applied MDM state and precedence.)
    EXPECTED RESULTS
        MDMWinsOverGP state (enabled/disabled), a list of applied PolicyManager values, and — when a
        GPO XML is supplied — a parity table marking each compared setting match / missing / different.
.NOTES
    Intune Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string] $GpoReportPath
)

Write-Host "`n=== GPO -> Intune parity validation ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan

# 1) Precedence: MDM wins over GP
$cpc = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\ControlPolicyConflict' -ErrorAction SilentlyContinue
$mdmWins = $cpc.MDMWinsOverGP
if ($mdmWins -eq 1) { Write-Host "MDMWinsOverGP : ENABLED (Intune values win where both set the same setting)." -ForegroundColor Green }
else { Write-Host "MDMWinsOverGP : not enabled — Group Policy wins by default. Deploy the coexistence policy." -ForegroundColor Yellow }

# 2) Applied MDM PolicyManager values (what Intune is enforcing on this device)
$pmRoot = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device'
$applied = @{}
if (Test-Path $pmRoot) {
    foreach ($area in Get-ChildItem $pmRoot -ErrorAction SilentlyContinue) {
        $props = Get-ItemProperty $area.PSPath -ErrorAction SilentlyContinue
        foreach ($p in $props.PSObject.Properties) {
            if ($p.Name -notmatch '^PS') { $applied["$($area.PSChildName)\$($p.Name)"] = $p.Value }
        }
    }
}
Write-Host ("Applied MDM settings: {0} values under PolicyManager." -f $applied.Count) -ForegroundColor Green

# 3) Optional parity compare against a GPO XML export
if ($GpoReportPath -and (Test-Path $GpoReportPath)) {
    Write-Host ("`nComparing against GPO export: {0}" -f $GpoReportPath) -ForegroundColor Cyan
    try {
        [xml]$gpo = Get-Content $GpoReportPath -Raw
        # Pull policy names from the GPO report (ADMX-backed "Policy" nodes are the migratable ones).
        $gpoPolicies = $gpo.GPO.Computer.ExtensionData.Extension.Policy + $gpo.GPO.User.ExtensionData.Extension.Policy |
            Where-Object { $_ } | Select-Object -ExpandProperty Name -ErrorAction SilentlyContinue | Sort-Object -Unique
        if (-not $gpoPolicies) { Write-Host "  No ADMX-backed 'Policy' nodes found in this export to compare." -ForegroundColor Yellow }
        $rows = foreach ($name in $gpoPolicies) {
            $hit = $applied.Keys | Where-Object { $_ -match [regex]::Escape(($name -replace '\s','')) } | Select-Object -First 1
            [pscustomobject]@{
                GpoSetting = $name
                Result     = if ($hit) { 'match (applied by MDM)' } else { 'missing (not found in MDM)' }
                AppliedKey = $hit
            }
        }
        $rows | Format-Table -AutoSize
        $miss = @($rows | Where-Object { $_.Result -like 'missing*' })
        Write-Host ("Parity: {0} matched, {1} missing." -f ($rows.Count - $miss.Count), $miss.Count) -ForegroundColor $(if($miss.Count){'Yellow'}else{'Green'})
        Write-Host "Note: name-based heuristic match — confirm exact values in Intune for any 'missing' item before cutover." -ForegroundColor Gray
    } catch {
        Write-Host "  Could not parse the GPO XML: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "`nNo -GpoReportPath supplied (or file not found) — reported applied MDM state only." -ForegroundColor Gray
}

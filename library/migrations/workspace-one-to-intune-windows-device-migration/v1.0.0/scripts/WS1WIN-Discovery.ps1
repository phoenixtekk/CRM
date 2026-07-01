<#
.SYNOPSIS
    WS1WIN-Discovery.ps1 — Workspace ONE to Intune Windows migration readiness (read-only).
.DESCRIPTION
    PURPOSE
        Reports the device's OS build, Entra join state, and current MDM enrollment(s). Flags a
        remaining Workspace ONE (AirWatch) MDM provider and any dual enrollment alongside Intune —
        the #1 blocker to a clean migration. Read-only: changes nothing.
    HOW TO RUN
        Elevated on the device:
        powershell -ExecutionPolicy Bypass -File .\WS1WIN-Discovery.ps1
    EXPECTED RESULTS
        OS build, Entra/MDM join state (dsregcmd), the list of MDM enrollments with their provider,
        and a WARNING if Workspace ONE is still present or the device is dual- or un-managed.
.NOTES
    Workplace Marketplace — Migrations. Read-only. Workspace ONE unenroll is a VMware-owned action.
#>
[CmdletBinding()] param()

Write-Host "`n=== WS1->Intune migration readiness ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan

# OS build
$ci = Get-ComputerInfo -Property WindowsProductName,OsBuildNumber,WindowsVersion -ErrorAction SilentlyContinue
Write-Host ("OS               : {0}  (build {1}, {2})" -f $ci.WindowsProductName, $ci.OsBuildNumber, $ci.WindowsVersion)

# Entra join + MDM state via dsregcmd
$dsreg = (dsregcmd /status) 2>$null
function Field([string]$name){ ($dsreg | Select-String -SimpleMatch $name | Select-Object -First 1) -replace '.*:\s*','' }
Write-Host ("AzureAdJoined    : {0}" -f (Field 'AzureAdJoined'))
Write-Host ("DomainJoined     : {0}" -f (Field 'DomainJoined'))
Write-Host ("MDM Url          : {0}" -f (Field 'MdmUrl'))

# Enrollments under HKLM\SOFTWARE\Microsoft\Enrollments
$enrollRoot = 'HKLM:\SOFTWARE\Microsoft\Enrollments'
$found = @()
if (Test-Path $enrollRoot) {
    Get-ChildItem $enrollRoot -ErrorAction SilentlyContinue | ForEach-Object {
        $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
        if ($p.ProviderID -or $p.UPN -or $p.DiscoveryServiceFullURL) {
            $found += [pscustomobject]@{
                ProviderID = $p.ProviderID
                UPN        = $p.UPN
                Discovery  = $p.DiscoveryServiceFullURL
            }
        }
    }
}
Write-Host "`n--- MDM enrollments ---" -ForegroundColor Cyan
if ($found.Count -eq 0) {
    Write-Host "  (no MDM enrollment found — device may be UNMANAGED)" -ForegroundColor Yellow
} else {
    $found | ForEach-Object { Write-Host ("  Provider={0}  UPN={1}  Discovery={2}" -f $_.ProviderID, $_.UPN, $_.Discovery) }
}

# Heuristics for Workspace ONE (AirWatch) and Intune
$isWs1   = @($found | Where-Object { ($_.ProviderID -match 'AirWatch') -or ($_.Discovery -match 'awmdm|airwatch|workspaceone') }).Count -gt 0
$isIntune= @($found | Where-Object { ($_.ProviderID -match 'MS DM Server') -or ($_.Discovery -match 'manage.microsoft.com|enrollment.manage') }).Count -gt 0

Write-Host "`n--- Migration flags ---" -ForegroundColor Cyan
if ($isWs1)   { Write-Host "  WARNING: Workspace ONE (AirWatch) enrollment present — must be removed (VMware docs) before/at Intune enrollment." -ForegroundColor Yellow }
if ($isWs1 -and $isIntune) { Write-Host "  WARNING: DUAL MANAGEMENT — both Workspace ONE and Intune detected. Remediate to single MDM." -ForegroundColor Red }
if ($isIntune -and -not $isWs1) { Write-Host "  OK: Intune-only enrollment detected." -ForegroundColor Green }
if (-not $isWs1 -and -not $isIntune -and $found.Count -eq 0) { Write-Host "  Device appears UNMANAGED — confirm Entra join + automatic enrollment." -ForegroundColor Yellow }

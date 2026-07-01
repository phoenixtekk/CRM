<#
.SYNOPSIS
    GPOPROG-Discovery.ps1 — transition readiness for a phased GPO-to-Intune program.
.DESCRIPTION
    PURPOSE
        Read-only readiness baseline for the transition program. On a domain-joined admin
        workstation it uses the GroupPolicy module to enumerate every GPO (scope, link state,
        enabled state) as the rationalization backlog input; it reports the local device's
        MDMWinsOverGP precedence state; and (with -UseGraph) it reports Intune coverage of the
        in-scope device population via Microsoft Graph. Nothing is changed.
    HOW TO RUN
        On a domain-joined admin workstation (RSAT Group Policy Management Tools installed):
            powershell -ExecutionPolicy Bypass -File .\GPOPROG-Discovery.ps1 -OutputPath .\GPOPROG-Out
        Add Intune coverage (Microsoft.Graph module + DeviceManagementManagedDevices.Read.All):
            powershell -ExecutionPolicy Bypass -File .\GPOPROG-Discovery.ps1 -UseGraph
    EXPECTED RESULTS
        A GPO inventory table + CSV (DisplayName, Id, GpoStatus, link/enabled state) for
        rationalization, the local MDMWinsOverGP precedence state, and — with -UseGraph — a count of
        Intune-managed Windows devices (coverage signal). Read-only.
.NOTES
    Workplace Marketplace — Migrations. Read-only. Requires the GroupPolicy module for the GPO side
    (Add-WindowsCapability -Online -Name Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0).
#>
[CmdletBinding()]
param(
    [string] $OutputPath = ".\GPOPROG-Out",
    [switch] $UseGraph
)

Write-Host "`n=== Transition readiness discovery ($($env:USERDNSDOMAIN)) ===" -ForegroundColor Cyan
if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

# 1) GPO inventory (rationalization backlog input)
if (Get-Module -ListAvailable -Name GroupPolicy) {
    Import-Module GroupPolicy -ErrorAction Stop
    $gpos = Get-GPO -All | Sort-Object DisplayName
    Write-Host ("Found {0} GPOs (rationalization backlog input)." -f $gpos.Count) -ForegroundColor Green
    $inv = foreach ($g in $gpos) {
        [pscustomobject]@{
            DisplayName  = $g.DisplayName
            Id           = $g.Id
            GpoStatus    = $g.GpoStatus
            CreationTime = $g.CreationTime
            ModifiedTime = $g.ModificationTime
        }
    }
    $inv | Format-Table DisplayName, GpoStatus, ModifiedTime -AutoSize
    $csv = Join-Path $OutputPath "GPOPROG-GPO-Inventory.csv"
    $inv | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
    Write-Host ("GPO inventory saved: {0}  (record a retire/keep/consolidate decision per GPO)" -f $csv) -ForegroundColor Green
} else {
    Write-Host "GroupPolicy module not found — skipping GPO inventory. Install RSAT Group Policy Management Tools to capture the rationalization backlog." -ForegroundColor Yellow
}

# 2) Local precedence state (MDM wins over GP)
$cpc = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\ControlPolicyConflict' -ErrorAction SilentlyContinue
$mdmWins = $cpc.MDMWinsOverGP
if ($mdmWins -eq 1) {
    Write-Host "MDMWinsOverGP (this device): ENABLED — Intune values win same-setting conflicts." -ForegroundColor Green
} else {
    Write-Host "MDMWinsOverGP (this device): not enabled — deploy 'Coexistence Policy - MDM Wins Over GP - All Migrated' before migrating settings." -ForegroundColor Yellow
}

# 3) Intune coverage of the in-scope population (optional, Graph)
if ($UseGraph) {
    Write-Host "`n=== Intune coverage (Graph) ===" -ForegroundColor Cyan
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -NoWelcome
    try {
        $win = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'Windows'&`$select=id,deviceName,operatingSystem,complianceState").value
        Write-Host ("Intune-managed Windows devices: {0}" -f @($win).Count) -ForegroundColor Green
        Write-Host "Compare this count to the GPO-scoped population to size the transition coverage gap." -ForegroundColor Gray
    } catch {
        Write-Host "Could not query managed devices: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    Disconnect-MgGraph | Out-Null
} else {
    Write-Host "`nRe-run with -UseGraph to report Intune coverage of the in-scope population." -ForegroundColor Gray
}

Write-Host "`nNext: rationalize the GPO backlog, then assign each kept setting area to exactly one phase (Core OS / Firewall / App Control)." -ForegroundColor Cyan

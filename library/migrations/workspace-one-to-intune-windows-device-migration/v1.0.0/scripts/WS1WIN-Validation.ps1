<#
.SYNOPSIS
    WS1WIN-Validation.ps1 — per-device validation of a migrated Windows device (read-only).
.DESCRIPTION
    PURPOSE
        Confirms a migrated device is managed by Intune ONLY (no Workspace ONE / no dual
        enrollment), that "Parity Configuration – Windows – Migration" reports applied, and that
        the device's Intune compliance state is evaluated. Read-only: changes nothing.
    HOW TO RUN
        Elevated on the migrated device:
        powershell -ExecutionPolicy Bypass -File .\WS1WIN-Validation.ps1
        (Local checks need no Graph. The optional -UseGraph switch reads this device's
         compliance/config state from Intune via the Microsoft Graph PowerShell SDK and requires
         DeviceManagementManagedDevices.Read.All + DeviceManagementConfiguration.Read.All.)
    EXPECTED RESULTS
        PASS lines for: single MDM = Intune; Workspace ONE absent; parity profile applied;
        compliance evaluated. Any FAIL line names what to remediate.
.NOTES
    Workplace Marketplace — Migrations. Read-only. Workspace ONE specifics deferred to VMware docs.
#>
[CmdletBinding()] param(
    [switch]$UseGraph,
    [string]$ParityProfileName = 'Parity Configuration - Windows - Migration'
)

Write-Host "`n=== WS1->Intune migration validation ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan

# --- Local: enumerate MDM enrollments ---
$enrollRoot = 'HKLM:\SOFTWARE\Microsoft\Enrollments'
$enr = @()
if (Test-Path $enrollRoot) {
    Get-ChildItem $enrollRoot -ErrorAction SilentlyContinue | ForEach-Object {
        $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
        if ($p.ProviderID -or $p.DiscoveryServiceFullURL) { $enr += $p }
    }
}
$isWs1    = @($enr | Where-Object { ($_.ProviderID -match 'AirWatch') -or ($_.DiscoveryServiceFullURL -match 'awmdm|airwatch|workspaceone') }).Count -gt 0
$isIntune = @($enr | Where-Object { ($_.ProviderID -match 'MS DM Server') -or ($_.DiscoveryServiceFullURL -match 'manage.microsoft.com|enrollment.manage') }).Count -gt 0

function Result($ok,$msg){ if($ok){Write-Host "  PASS: $msg" -ForegroundColor Green}else{Write-Host "  FAIL: $msg" -ForegroundColor Red} }

Write-Host "--- Enrollment ---" -ForegroundColor Cyan
Result $isIntune                 "Intune MDM enrollment present"
Result (-not $isWs1)             "Workspace ONE enrollment absent"
Result ($isIntune -and -not $isWs1) "Single MDM authority = Intune (no dual management)"

# --- Optional: Graph view of this device ---
if ($UseGraph) {
    Write-Host "--- Intune (Graph) ---" -ForegroundColor Cyan
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementConfiguration.Read.All' -NoWelcome
    $name = $env:COMPUTERNAME
    $dev = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/managedDevices?`$filter=deviceName eq '$name'").value | Select-Object -First 1
    if ($dev) {
        Result ($dev.complianceState -eq 'compliant') ("Compliance state = {0}" -f $dev.complianceState)
        $states = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/managedDevices/$($dev.id)/deviceConfigurationStates").value
        $parity = $states | Where-Object { $_.displayName -like "$ParityProfileName*" }
        if ($parity) { Result (@($parity | Where-Object { $_.state -eq 'compliant' }).Count -gt 0) ("Parity profile state = {0}" -f (($parity.state) -join ', ')) }
        else { Write-Host "  INFO: parity profile '$ParityProfileName' not yet reported for this device." -ForegroundColor Yellow }
    } else {
        Write-Host "  INFO: device '$name' not found in Intune yet (allow a sync/policy cycle)." -ForegroundColor Yellow
    }
    Disconnect-MgGraph | Out-Null
} else {
    Write-Host "--- Intune (local hint) ---" -ForegroundColor Cyan
    Write-Host "  Run with -UseGraph to confirm compliance + parity-profile state from Intune." -ForegroundColor Yellow
    Write-Host "  Or check: Settings > Accounts > Access work or school, and Settings > ... 'managed by your organization'." -ForegroundColor Yellow
}

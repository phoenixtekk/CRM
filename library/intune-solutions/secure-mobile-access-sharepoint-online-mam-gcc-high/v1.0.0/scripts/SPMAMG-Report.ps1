<#
.SYNOPSIS
    SPMAMG-Report.ps1 — summary report of MAM + CA posture and recent mobile sign-ins (GCC High).
.DESCRIPTION
    PURPOSE
        Produces a change-record summary: the App Protection Policies (iOS/Android) and their assignments,
        the Conditional Access policy state, and recent mobile (iOS/Android) sign-in results against
        Office 365 / SharePoint Online. Read-only. Optionally write the summary to a file with -OutFile.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SPMAMG-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\SPMAMG-Report.ps1 -OutFile .\spmamg-report.txt
        Connects to US Gov Graph: Connect-MgGraph -Environment USGov -Scopes 'Policy.Read.All','DeviceManagementApps.Read.All','AuditLog.Read.All'
    EXPECTED RESULTS
        A printed (and optionally saved) report of policies and recent mobile sign-in outcomes. Use it as
        evidence after each pilot/expansion wave.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding()]
param(
    [string]$OutFile
)

$lines = New-Object System.Collections.Generic.List[string]
function Emit($t) { $lines.Add($t); Write-Host $t }

Emit "=== Secure Mobile Access to SharePoint (GCC High) — report ==="
Emit ("Generated: {0}" -f (Get-Date -Format 'u'))

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment USGov -Scopes 'Policy.Read.All','DeviceManagementApps.Read.All','AuditLog.Read.All' -NoWelcome

$env = (Get-MgContext).Environment
Emit ("Graph environment: {0}" -f $env)
if ($env -ne 'USGov') { Emit "WRONG CLOUD — reconnect with -Environment USGov."; Disconnect-MgGraph | Out-Null; return }
Emit "Graph host: https://graph.microsoft.us (GCC High)"

# --- App Protection Policies ---
Emit "`n--- App Protection Policies ---"
$ios = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceAppManagement/iosManagedAppProtections').value
$and = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceAppManagement/androidManagedAppProtections').value
foreach ($p in @($ios) + @($and)) {
    Emit ("  {0}  (deployedAppCount={1})" -f $p.displayName, $p.deployedAppCount)
}

# --- Conditional Access policies ---
Emit "`n--- Conditional Access policies ---"
$pols = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
foreach ($c in $pols) { Emit ("  [{0}] {1}" -f $c.state, $c.displayName) }

# --- Recent mobile sign-ins (best-effort) ---
Emit "`n--- Recent mobile sign-ins (iOS/Android, last 50) ---"
try {
    $uri = "/v1.0/auditLogs/signIns?`$top=50&`$filter=(deviceDetail/operatingSystem eq 'iOS') or (deviceDetail/operatingSystem eq 'Android')"
    $signins = (Invoke-MgGraphRequest -Method GET -Uri $uri).value
    if (-not $signins -or $signins.Count -eq 0) { Emit "  (no matching sign-ins returned)" }
    foreach ($s in $signins) {
        $status = if ($s.status.errorCode -eq 0) { 'SUCCESS' } else { ("FAIL({0})" -f $s.status.errorCode) }
        Emit ("  {0}  {1}  {2}  app='{3}'  os='{4}'" -f $s.createdDateTime, $status, $s.userPrincipalName, $s.appDisplayName, $s.deviceDetail.operatingSystem)
    }
} catch {
    Emit "  Could not read sign-in logs (needs AuditLog.Read.All and Entra ID P1)."
}

if ($OutFile) { $lines | Out-File -FilePath $OutFile -Encoding UTF8; Write-Host ("`nSaved report to {0}" -f $OutFile) -ForegroundColor Green }
Disconnect-MgGraph | Out-Null

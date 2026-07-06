<#
.SYNOPSIS
    MACCA-Report.ps1 — per-Mac compliance state mapped to the access decision (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        The sign-off artifact for each rollout wave. For every enrolled Mac it reports the Intune
        compliance state and the resulting access decision under the compliant-device Conditional
        Access policy: Compliant + registered => ALLOW, otherwise => DENY. Also summarizes recent
        macOS sign-ins and their Conditional Access result so you can see the gate working live.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MACCA-Report.ps1 -CsvPath C:\Temp\macca-decisions.csv
        Requires Microsoft Graph SDK and scopes: DeviceManagementManagedDevices.Read.All,
        AuditLog.Read.All, Directory.Read.All.
    EXPECTED RESULTS
        A per-Mac table of compliance + ALLOW/DENY with counts, and a summary of recent macOS
        sign-in CA outcomes (success / blocked). Optional CSV of the per-Mac decisions.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param([string]$CsvPath)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','AuditLog.Read.All','Directory.Read.All' -NoWelcome

# --- Per-Mac decision ---
Write-Host "=== Per-Mac access decision (compliant-device gate) ===" -ForegroundColor Cyan
$macs = @()
$uri = "/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'macOS'&`$select=deviceName,osVersion,complianceState,azureADRegistered,userPrincipalName"
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $macs += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)

$decisions = $macs | ForEach-Object {
    $allow = ($_.complianceState -eq 'compliant') -and [bool]$_.azureADRegistered
    [pscustomobject]@{
        Device     = $_.deviceName
        OSVersion  = $_.osVersion
        Compliance = $_.complianceState
        EntraReg   = [bool]$_.azureADRegistered
        Decision   = $(if ($allow) { 'ALLOW' } else { 'DENY' })
        User       = $_.userPrincipalName
    }
}
if ($decisions) {
    $decisions | Sort-Object Decision, Device | Format-Table -AutoSize
    $allowN = ($decisions | Where-Object Decision -eq 'ALLOW').Count
    Write-Host ("Macs: {0} | ALLOW: {1} | DENY: {2}" -f $decisions.Count, $allowN, ($decisions.Count - $allowN)) -ForegroundColor Cyan
} else { Write-Host "  (no macOS devices found)" -ForegroundColor Yellow }

# --- Recent macOS sign-in CA outcomes ---
Write-Host "`n=== Recent macOS sign-ins — Conditional Access outcome ===" -ForegroundColor Cyan
try {
    $signins = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/auditLogs/signIns?`$top=200&`$filter=startsWith(deviceDetail/operatingSystem,'Mac') or startsWith(deviceDetail/operatingSystem,'macOS')").value
    if ($signins) {
        $succeeded = ($signins | Where-Object { $_.status.errorCode -eq 0 }).Count
        $blocked   = ($signins | Where-Object { $_.status.errorCode -ne 0 }).Count
        Write-Host ("  macOS sign-ins sampled: {0} | succeeded: {1} | blocked/challenged: {2}" -f $signins.Count, $succeeded, $blocked)
        $signins | Where-Object { $_.status.errorCode -ne 0 } | Select-Object -First 10 |
            ForEach-Object { Write-Host ("    BLOCKED  {0,-35} {1}" -f $_.userPrincipalName, $_.status.failureReason) -ForegroundColor Yellow }
    } else { Write-Host "  (no recent macOS sign-ins in the sample)" -ForegroundColor Yellow }
} catch { Write-Host "  (sign-in log query needs AuditLog.Read.All and Entra ID P1 — skipped)" -ForegroundColor Yellow }

if ($CsvPath -and $decisions) { $decisions | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "`nSaved $CsvPath" -ForegroundColor Green }
Disconnect-MgGraph | Out-Null

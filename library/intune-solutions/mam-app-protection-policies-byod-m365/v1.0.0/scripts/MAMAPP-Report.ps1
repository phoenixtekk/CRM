<#
.SYNOPSIS
    MAMAPP-Report.ps1 — coverage and enforcement report for MAM App Protection on BYOD.
.DESCRIPTION
    PURPOSE
        Produces a single read-only picture of MAM readiness: the iOS/Android App Protection Policies
        and their assigned groups, the App Configuration policies, and whether a Conditional Access
        grant that requires app protection is enabled — so you can confirm coverage and enforcement
        before and after rollout.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MAMAPP-Report.ps1 -CsvPath C:\Temp\mamapp.csv
        Requires the Microsoft Graph SDK and scopes:
        DeviceManagementApps.Read.All and Policy.Read.All.
    EXPECTED RESULTS
        A table of App Protection / App Configuration policies with assigned group counts, plus the
        state of the CA "Require app protection policy" grant. Optional CSV export.
.NOTES
    Intune Solutions — MAM App Protection Policies for BYOD. Read-only against Graph.
#>
[CmdletBinding()] param([string]$CsvPath)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All','Policy.Read.All' -NoWelcome

function AssignCount($base,$id){ try { ((Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceAppManagement/$base/$id/assignments").value).Count } catch { 0 } }
$rows = @()
foreach ($set in @(@{b='iosManagedAppProtections';t='iOS APP'}, @{b='androidManagedAppProtections';t='Android APP'}, @{b='targetedManagedAppConfigurations';t='App Config'})) {
    $items = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceAppManagement/$($set.b)").value
    foreach ($p in $items) { $rows += [pscustomobject]@{ Type=$set.t; Name=$p.displayName; AssignedGroups=(AssignCount $set.b $p.id) } }
}
Write-Host "=== App Protection / App Configuration coverage ===" -ForegroundColor Cyan
$rows | Format-Table -AutoSize

Write-Host "=== Conditional Access enforcement ===" -ForegroundColor Cyan
$ca = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
$appCa = $ca | Where-Object { $_.grantControls -and ($_.grantControls.builtInControls -contains 'compliantApplication' -or $_.grantControls.builtInControls -contains 'approvedApplication') }
if ($appCa) { foreach ($c in $appCa) { Write-Host ("  {0}  [state: {1}]" -f $c.displayName, $c.state) -ForegroundColor ($(if($c.state -eq 'enabled'){'Green'}else{'Yellow'})) } }
else { Write-Host "  WARNING: no CA policy requires app protection — data protection is NOT enforced." -ForegroundColor Yellow }

if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host ("Saved {0}" -f $CsvPath) }
Disconnect-MgGraph | Out-Null

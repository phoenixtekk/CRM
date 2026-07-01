<#
.SYNOPSIS
    AVD-Report.ps1 — Azure Virtual Desktop usage and assignment report.
.DESCRIPTION
    PURPOSE
        Inventories host pools, their session hosts, the published application groups, the security
        principals assigned to each application group, and any active/disconnected user sessions —
        so you can audit who has access and how the environment is being used.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AVD-Report.ps1 `
            -ResourceGroupName 'AVD - Resource Group - Core' -CsvPath C:\Temp\avd-usage.csv
        Requires Az.Accounts and Az.DesktopVirtualization; run Connect-AzAccount first. Read-only.
    EXPECTED RESULTS
        A per-host-pool summary of app groups, assigned principals, and live sessions, plus an
        optional per-session CSV.
.NOTES
    Azure Solutions — Azure Virtual Desktop. Read-only.
#>
[CmdletBinding()] param(
    [string]$ResourceGroupName = 'AVD - Resource Group - Core',
    [string]$CsvPath
)
foreach ($m in 'Az.Accounts','Az.DesktopVirtualization') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module $m -Scope CurrentUser -Force -AllowClobber }
    Import-Module $m -ErrorAction Stop
}
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }

$rows  = @()
$pools = @(Get-AzWvdHostPool -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue)
if (-not $pools) { Write-Host "No host pools found in '$ResourceGroupName'." -ForegroundColor Yellow; return }

foreach ($hp in $pools) {
    Write-Host ("`n=== Host pool: {0} ({1}) ===" -f $hp.Name, $hp.HostPoolType) -ForegroundColor Cyan
    $hosts = @(Get-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $hp.Name -ErrorAction SilentlyContinue)
    Write-Host ("  Session hosts : {0} ({1} Available)" -f $hosts.Count, @($hosts | Where-Object Status -eq 'Available').Count)

    $ags = @(Get-AzWvdApplicationGroup -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue | Where-Object { $_.HostPoolArmPath -eq $hp.Id })
    foreach ($ag in $ags) {
        $assign = @(Get-AzRoleAssignment -Scope $ag.Id -ErrorAction SilentlyContinue | Where-Object { $_.RoleDefinitionName -eq 'Desktop Virtualization User' })
        Write-Host ("  App group     : {0} [{1}]  assigned: {2}" -f $ag.Name, $ag.ApplicationGroupType, (($assign.DisplayName) -join ', '))
    }

    $sessions = @(Get-AzWvdUserSession -ResourceGroupName $ResourceGroupName -HostPoolName $hp.Name -ErrorAction SilentlyContinue)
    Write-Host ("  User sessions : {0}" -f $sessions.Count)
    foreach ($s in $sessions) {
        Write-Host ("    - {0}  state={1}  host={2}" -f $s.UserPrincipalName, $s.SessionState, $s.Name)
        $rows += [pscustomobject]@{ HostPool=$hp.Name; User=$s.UserPrincipalName; State=$s.SessionState; SessionHost=$s.Name }
    }
}
if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "`nSaved $CsvPath" -ForegroundColor Green }

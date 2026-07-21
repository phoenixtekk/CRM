<#
.SYNOPSIS
    RHELPG-Report.ps1 — export Remote Help deployment + RBAC role status to CSV (US Government tenant).
.DESCRIPTION
    PURPOSE
        Read-only reporting for the Government edition. Exports the Remote Help tenant configuration
        (state + key options, where present) and the Intune RBAC roles that carry Remote Help
        permissions, to CSV for audit/hand-off. On GCC High/DoD the Remote Help rows will show
        NOT-AVAILABLE (expected — the feature is not offered there at authoring time; verify against
        current Microsoft documentation). For a GCC tenant use -Environment Global (commercial instance).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\RHELPG-Report.ps1 -CsvPath C:\Temp\rhelpg-status.csv
        powershell -ExecutionPolicy Bypass -File .\RHELPG-Report.ps1 -Environment USGovDoD -CsvPath .\dod.csv
    GRAPH SCOPES
        DeviceManagementConfiguration.Read.All, DeviceManagementRBAC.Read.All
    EXPECTED RESULTS
        A console table and (if -CsvPath given) a CSV of Remote Help settings + role status. Read-only.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
    All sovereign specifics are "verify against current Microsoft documentation".
#>
[CmdletBinding()] param(
    [ValidateSet('USGov','USGovDoD','Global')][string]$Environment = 'USGov',
    [string]$CsvPath
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment $Environment -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementRBAC.Read.All' -NoWelcome

$rows = @()
$ctx = Get-MgContext
Write-Host "`n=== Remote Help status report — Government edition (env: $Environment) ===" -ForegroundColor Cyan

# Remote Help settings
try {
    $s = Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/remoteAssistanceSettings' -ErrorAction Stop
    $rows += [pscustomobject]@{ Environment=$ctx.Environment; Item='RemoteHelp.State';        Value=$s.remoteAssistanceState }
    $rows += [pscustomobject]@{ Environment=$ctx.Environment; Item='RemoteHelp.Unenrolled';   Value=$s.allowSessionsToUnenrolledDevices }
    $rows += [pscustomobject]@{ Environment=$ctx.Environment; Item='RemoteHelp.BlockChat';    Value=$s.blockChat }
} catch {
    $rows += [pscustomobject]@{ Environment=$ctx.Environment; Item='RemoteHelp.State'; Value='NOT-AVAILABLE (feature not present; expected on GCC High/DoD - verify)' }
}

# RBAC roles with Remote Help permissions
try {
    $roles = @((Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/roleDefinitions?$top=200').value)
    $rh = $roles | Where-Object { (@($_.rolePermissions.resourceActions.allowedResourceActions) -join ';') -match 'RemoteAssistance|RemoteHelp|RemoteTasks' }
    if ($rh) { foreach ($r in $rh) { $rows += [pscustomobject]@{ Environment=$ctx.Environment; Item=("RBACRole:"+$r.displayName); Value=("builtIn="+$r.isBuiltIn) } } }
    else     { $rows += [pscustomobject]@{ Environment=$ctx.Environment; Item='RBACRole'; Value='none with Remote Help permissions (expected if feature absent)' } }
} catch { $rows += [pscustomobject]@{ Environment=$ctx.Environment; Item='RBACRole'; Value=('read failed: '+$_.Exception.Message) } }

$rows | Format-Table -AutoSize
if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" -ForegroundColor Green }
Write-Host "Reminder: verify Remote Help availability/endpoints/licensing against current Microsoft documentation." -ForegroundColor DarkCyan
Disconnect-MgGraph | Out-Null

<#
.SYNOPSIS
    WHfB-TenantReport.ps1 — tenant-wide report of Windows Hello for Business registration via Microsoft Graph.

.DESCRIPTION
    PURPOSE
        Lists users and whether they have a Windows Hello for Business authentication method
        registered in Microsoft Entra ID. Use it to measure pilot/production rollout coverage.

    HOW TO RUN
        Requires the Microsoft Graph PowerShell SDK (installs automatically if missing) and an
        account with the directory permission to read authentication methods:
            powershell -ExecutionPolicy Bypass -File .\WHfB-TenantReport.ps1 -CsvPath C:\Temp\whfb-tenant.csv
        Optional: -GroupId <entra-group-object-id> to scope to your pilot group.

    EXPECTED RESULTS
        A table (and optional CSV) of UserPrincipalName + HasWHfB (True/False). Registered pilot
        users show HasWHfB = True.

.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only against Graph.
    Scopes requested: User.Read.All, UserAuthenticationMethod.Read.All.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [string]$GroupId
)

# Ensure Graph SDK
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Host "Installing Microsoft.Graph (current user)..." -ForegroundColor Yellow
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Import-Module Microsoft.Graph.Users -ErrorAction SilentlyContinue

Connect-MgGraph -Scopes 'User.Read.All','UserAuthenticationMethod.Read.All' -NoWelcome

# Resolve target users
if ($GroupId) {
    $members = Get-MgGroupMember -GroupId $GroupId -All
    $users = $members | Where-Object { $_.AdditionalProperties['@odata.type'] -eq '#microsoft.graph.user' }
} else {
    $users = Get-MgUser -All -Property Id,UserPrincipalName
}

$report = foreach ($u in $users) {
    $upn = $u.UserPrincipalName ?? $u.AdditionalProperties['userPrincipalName']
    $id  = $u.Id
    $hasWhfb = $false
    try {
        $methods = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$id/authentication/windowsHelloForBusinessMethods"
        $hasWhfb = ($methods.value.Count -gt 0)
    } catch { }
    [pscustomobject]@{ UserPrincipalName = $upn; HasWHfB = $hasWhfb }
}

$report | Sort-Object HasWHfB, UserPrincipalName | Format-Table -AutoSize
$total = ($report | Measure-Object).Count
$reg   = ($report | Where-Object HasWHfB).Count
Write-Host ("`nCoverage: {0}/{1} users have WHfB registered." -f $reg, $total) -ForegroundColor Cyan

if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }
Disconnect-MgGraph | Out-Null

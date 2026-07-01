<#
.SYNOPSIS
    AVD-Set-UserAssignmentTargeting.ps1 — build the AVD assignment groups and add members.
.DESCRIPTION
    PURPOSE
        Creates (idempotently) the two Entra ID security groups used for AVD assignment —
        'AVD - Users - Pilot' and 'AVD - Users - Production' — and optionally adds members from a
        CSV or a comma-separated UPN list. These groups are what you assign to the Desktop
        application group and the Conditional Access policy.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AVD-Set-UserAssignmentTargeting.ps1 `
            -Stage Pilot -UserUpns 'a@contoso.com,b@contoso.com'
        Or from a CSV with a 'UserPrincipalName' column:  -Stage Production -CsvPath C:\Temp\avd-users.csv
        Requires the Microsoft Graph SDK; grants Group.ReadWrite.All + User.Read.All. WRITES to Entra.
    EXPECTED RESULTS
        The named group exists; listed users are added. Re-running is safe (existing members skipped).
.NOTES
    Azure Solutions — Azure Virtual Desktop. Creates/updates Entra ID groups (not read-only).
#>
[CmdletBinding()] param(
    [ValidateSet('Pilot','Production')] [string]$Stage = 'Pilot',
    [string]$UserUpns,
    [string]$CsvPath
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Groups)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Groups -ErrorAction Stop
Import-Module Microsoft.Graph.Users  -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome

$groupName = "AVD - Users - $Stage"
$mailNick  = "avd-users-$($Stage.ToLower())"

$group = Get-MgGroup -Filter "displayName eq '$groupName'" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $group) {
    Write-Host "Creating group '$groupName'..." -ForegroundColor Cyan
    $group = New-MgGroup -DisplayName $groupName -MailEnabled:$false -MailNickname $mailNick -SecurityEnabled:$true -GroupTypes @()
    Write-Host ("  created (id {0})" -f $group.Id) -ForegroundColor Green
} else { Write-Host "Group '$groupName' already exists (id $($group.Id))." -ForegroundColor Green }

$upns = @()
if ($UserUpns) { $upns += ($UserUpns -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }
if ($CsvPath -and (Test-Path $CsvPath)) { $upns += (Import-Csv $CsvPath).UserPrincipalName }
$upns = $upns | Where-Object { $_ } | Select-Object -Unique

$existing = @(Get-MgGroupMember -GroupId $group.Id -All | Select-Object -ExpandProperty Id)
foreach ($upn in $upns) {
    $u = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $u) { Write-Host "  SKIP (not found): $upn" -ForegroundColor Yellow; continue }
    if ($existing -contains $u.Id) { Write-Host "  already a member: $upn" }
    else { New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $u.Id; Write-Host "  added: $upn" -ForegroundColor Green }
}
Write-Host "`nDone. Assign '$groupName' to 'AVD - App Group - Desktop' and 'AVD - Conditional Access - MFA'." -ForegroundColor Green
Disconnect-MgGraph | Out-Null

<#
.SYNOPSIS
    SAASLIC-Remediation.ps1 — flag dormant-seat reclaim candidates (safe; default -WhatIf).
.DESCRIPTION
    PURPOSE
        For a given app, lists the users who were assigned the app in Entra ID but have NOT signed in
        across the dormancy window — the reclaim candidates. By default it runs in -WhatIf mode: it
        only reports and writes a candidate file and changes nothing. The actual seat removal happens
        in the SaaS app's own admin console after the owner approves; this script does not delete
        vendor seats or Entra assignments unless you explicitly opt out of -WhatIf, in which case it
        only removes the Entra ID app *assignment* for confirmed candidates (still not the vendor seat).
    HOW TO RUN
        Flag only (default, safe):
            powershell -ExecutionPolicy Bypass -File .\SAASLIC-Remediation.ps1 -AppId <appId> -Days 30 -CsvPath C:\Temp\reclaim.csv
        Remove the Entra ID app assignment for candidates (requires AppRoleAssignment.ReadWrite.All):
            powershell -ExecutionPolicy Bypass -File .\SAASLIC-Remediation.ps1 -AppId <appId> -Days 30 -WhatIf:$false
    EXPECTED RESULTS
        A list of dormant assigned users (reclaim candidates) and a candidate CSV. With -WhatIf
        (default) nothing is changed — review the file with the app owner before acting in the app.
.NOTES
    Workplace Marketplace — Asset Mgt. Read-only by default; -WhatIf is ON unless disabled.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')] param(
    [Parameter(Mandatory)][string]$AppId,
    [int]$Days = 30,
    [string]$CsvPath
)
# Default to safe (WhatIf) unless the caller explicitly passed -WhatIf:$false
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = @('AuditLog.Read.All','Directory.Read.All','Application.Read.All')
if ($WhatIfPreference -eq $false) { $scopes += 'AppRoleAssignment.ReadWrite.All' }
Connect-MgGraph -Scopes $scopes -NoWelcome

# Resolve the service principal for the app
$sp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals?`$filter=appId eq '$AppId'&`$select=id,displayName").value | Select-Object -First 1
if (-not $sp) { throw "No service principal found for appId $AppId." }
Write-Host ("=== Reclaim candidates — {0} (dormant {1}+ days) ===" -f $sp.displayName, $Days) -ForegroundColor Cyan

# Assigned users (app role assignments to this SP)
$assigned = @(); $aUri = "/v1.0/servicePrincipals/$($sp.id)/appRoleAssignedTo?`$top=999"
do { $ar = Invoke-MgGraphRequest -Method GET -Uri $aUri; $assigned += $ar.value; $aUri = $ar.'@odata.nextLink' } while ($aUri)
$assignedUsers = $assigned | Where-Object { $_.principalType -eq 'User' }

# Users who signed in to this app over the window
$since = (Get-Date).ToUniversalTime().AddDays(-$Days).ToString('yyyy-MM-ddTHH:mm:ssZ')
$activeIds = New-Object System.Collections.Generic.HashSet[string]
$siUri = "/v1.0/auditLogs/signIns?`$filter=createdDateTime ge $since and appId eq '$AppId'&`$select=userId&`$top=1000"
do { $sr = Invoke-MgGraphRequest -Method GET -Uri $siUri; foreach ($e in $sr.value) { if ($e.userId) { [void]$activeIds.Add($e.userId) } }; $siUri = $sr.'@odata.nextLink' } while ($siUri)

$candidates = $assignedUsers | Where-Object { -not $activeIds.Contains($_.principalId) } |
    ForEach-Object { [pscustomobject]@{ App=$sp.displayName; User=$_.principalDisplayName; UserId=$_.principalId; AssignmentId=$_.id } }

if (-not $candidates) { Write-Host "No dormant assigned users — nothing to reclaim." -ForegroundColor Green; Disconnect-MgGraph | Out-Null; return }
$candidates | Select-Object App, User | Format-Table -AutoSize
Write-Host ("Reclaim candidates: {0} of {1} assigned users" -f $candidates.Count, $assignedUsers.Count) -ForegroundColor Yellow
if ($CsvPath) { $candidates | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved candidate list: $CsvPath" -ForegroundColor Green }

if ($WhatIfPreference -ne $false) {
    Write-Host "`n-WhatIf (default): no changes made. Review with the owner; reclaim the seat in the app's console." -ForegroundColor Cyan
} else {
    foreach ($c in $candidates) {
        if ($PSCmdlet.ShouldProcess("$($c.User) on $($c.App)", "Remove Entra ID app assignment")) {
            Invoke-MgGraphRequest -Method DELETE -Uri "/v1.0/servicePrincipals/$($sp.id)/appRoleAssignedTo/$($c.AssignmentId)"
            Write-Host ("  Removed Entra assignment: {0}" -f $c.User) -ForegroundColor Green
        }
    }
    Write-Host "`nNote: this removed the Entra ID app assignment only. Reclaim the paid vendor seat in the app's own admin console." -ForegroundColor Yellow
}
Disconnect-MgGraph | Out-Null

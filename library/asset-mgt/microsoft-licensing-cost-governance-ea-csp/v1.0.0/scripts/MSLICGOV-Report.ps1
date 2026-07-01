<#
.SYNOPSIS
    MSLICGOV-Report.ps1 — license-position and utilization report per product (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Produces the per-SKU license position (owned/prepaid vs assigned/consumed vs available) and,
        where a sign-in signal is available, flags assigned-but-inactive users as reharvest
        candidates. Feeds the License Position Register and the KPI set. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MSLICGOV-Report.ps1 -CsvPath C:\Temp\position.csv -InactiveDays 60
        Requires the Microsoft Graph PowerShell SDK and the Organization.Read.All and
        AuditLog.Read.All (for sign-in activity) and User.Read.All scopes.
    EXPECTED RESULTS
        A per-SKU position table, a total, and a count of reharvest candidates. Optional CSV.
        No tenant changes are made.
.NOTES
    Workplace Marketplace — Asset Mgt. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param([string]$CsvPath,[int]$InactiveDays = 60)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Organization.Read.All','User.Read.All','AuditLog.Read.All' -NoWelcome

Write-Host "`n=== License position by SKU ===" -ForegroundColor Cyan
$skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
$position = $skus | ForEach-Object {
    $owned = [int]$_.prepaidUnits.enabled; $consumed = [int]$_.consumedUnits
    [pscustomobject]@{
        SkuPartNumber = $_.skuPartNumber
        Owned         = $owned
        Assigned      = $consumed
        Position      = $owned - $consumed
    }
}
$position | Sort-Object SkuPartNumber | Format-Table SkuPartNumber, Owned, Assigned, Position -AutoSize
Write-Host ("Total assigned across all SKUs: {0}" -f (($position | Measure-Object Assigned -Sum).Sum)) -ForegroundColor Cyan

# Reharvest candidates: licensed users whose last sign-in is older than InactiveDays
Write-Host "`n=== Reharvest candidates (assigned but inactive > $InactiveDays days) ===" -ForegroundColor Cyan
$cutoff = (Get-Date).AddDays(-$InactiveDays)
$candidates = @()
try {
    $uri = "/v1.0/users?`$select=userPrincipalName,assignedLicenses,signInActivity&`$top=999"
    do {
        $r = Invoke-MgGraphRequest -Method GET -Uri $uri
        foreach ($u in $r.value) {
            if ($u.assignedLicenses -and $u.assignedLicenses.Count -gt 0) {
                $last = $u.signInActivity.lastSignInDateTime
                if ($last -and ([datetime]$last) -lt $cutoff) {
                    $candidates += [pscustomobject]@{ User = $u.userPrincipalName; LastSignIn = $last; Licenses = $u.assignedLicenses.Count }
                }
            }
        }
        $uri = $r.'@odata.nextLink'
    } while ($uri)
} catch {
    Write-Host "  Sign-in activity unavailable (needs Entra ID P1/P2 + AuditLog.Read.All): $($_.Exception.Message)" -ForegroundColor DarkYellow
}
if ($candidates.Count -gt 0) {
    $candidates | Sort-Object LastSignIn | Format-Table User, LastSignIn, Licenses -AutoSize
}
Write-Host ("Reharvest candidates: {0}" -f $candidates.Count) -ForegroundColor Yellow

if ($CsvPath) { $position | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" -ForegroundColor Green }
Disconnect-MgGraph | Out-Null

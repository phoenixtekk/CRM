<#
.SYNOPSIS
    ENTGSA-Discovery.ps1 — inventory Entra Global Secure Access configuration (read-only, Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Baselines the current GSA posture: whether traffic forwarding profiles (Microsoft / Internet /
        Private) are enabled, the Private Access connector groups, published private applications and
        their application segments, web-filtering policies, and any Conditional Access policies that
        target Global Secure Access. Run before you configure anything to see your starting point.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTGSA-Discovery.ps1 -CsvFolder C:\Temp\entgsa
        Requires the Microsoft Graph SDK and the read scopes below (consented on first run). GSA lives on
        Graph beta endpoints today, so the script uses /beta for networkAccess.
    EXPECTED RESULTS
        Console tables for profiles, connector groups, published apps + segments, filter policies, and
        CA-for-GSA, plus optional CSVs. PASS = the objects you built (ENTGSA - *) appear as expected.
.NOTES
    White-label — Entra ID Solutions. Read-only against Microsoft Graph. No credentials stored.
    GSA Graph endpoints are on /beta and may change while features are in preview — verify current schema.
.EXAMPLE
    .\ENTGSA-Discovery.ps1
#>
[CmdletBinding()] param([string]$CsvFolder)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'NetworkAccess.Read.All','Application.Read.All','Policy.Read.All' -NoWelcome

function Get-AllPages([string]$Uri) {
    $items = @()
    do { $r = Invoke-MgGraphRequest -Method GET -Uri $Uri; $items += $r.value; $Uri = $r.'@odata.nextLink' } while ($Uri)
    return $items
}
function Save-Csv($rows, $name) {
    if ($CsvFolder -and $rows) {
        if (-not (Test-Path $CsvFolder)) { New-Item -ItemType Directory -Path $CsvFolder | Out-Null }
        $p = Join-Path $CsvFolder "$name.csv"; $rows | Export-Csv -Path $p -NoTypeInformation
        Write-Host "  saved $p" -ForegroundColor Green
    }
}

# --- Traffic forwarding profiles ----------------------------------------------
Write-Host "`n=== GSA: Traffic forwarding profiles ===" -ForegroundColor Cyan
try {
    $profiles = Get-AllPages "/beta/networkAccess/forwardingProfiles"
    $profRows = $profiles | ForEach-Object {
        [pscustomobject]@{ Profile=$_.name; TrafficType=$_.trafficForwardingType; State=$_.state }
    }
    if ($profRows) { $profRows | Format-Table -AutoSize } else { Write-Host "  (none — GSA may not be activated)" -ForegroundColor Yellow }
    Save-Csv $profRows 'forwarding-profiles'
} catch { Write-Host "  Could not read forwardingProfiles: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Private Access connector groups ------------------------------------------
Write-Host "`n=== GSA: Connector groups (Private Access) ===" -ForegroundColor Cyan
try {
    $cgs = Get-AllPages "/beta/networkAccess/connectivity/branches"  # remote networks
    $conns = Get-AllPages "/beta/onPremisesPublishingProfiles/applicationProxy/connectorGroups"
    $cgRows = $conns | ForEach-Object {
        [pscustomobject]@{ ConnectorGroup=$_.name; Region=$_.region; ConnectorCount=$_.connectorCount }
    }
    if ($cgRows) { $cgRows | Format-Table -AutoSize } else { Write-Host "  (no connector groups)" -ForegroundColor Yellow }
    Save-Csv $cgRows 'connector-groups'
} catch { Write-Host "  Could not read connector groups: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Published private apps + segments ----------------------------------------
Write-Host "`n=== GSA: Published private applications + segments ===" -ForegroundColor Cyan
try {
    $apps = Get-AllPages "/beta/applications?`$filter=tags/any(t:t eq 'PrivateAccessNonWebApplication') or tags/any(t:t eq 'NetworkAccessManagedApplication')&`$select=id,displayName"
    $segRows = @()
    foreach ($a in $apps) {
        $segs = @()
        try { $segs = Get-AllPages "/beta/applications/$($a.id)/onPremisesPublishing/segmentsConfiguration/microsoftEntraPrivateAccess/applicationSegments" } catch {}
        if (-not $segs) { $segRows += [pscustomobject]@{ App=$a.displayName; Segment='(none)'; Ports='' }; continue }
        foreach ($s in $segs) {
            $segRows += [pscustomobject]@{ App=$a.displayName; Segment=$s.destinationHost; Ports=($s.ports -join ',') }
        }
    }
    if ($segRows) { $segRows | Format-Table -AutoSize } else { Write-Host "  (no published private apps)" -ForegroundColor Yellow }
    Save-Csv $segRows 'private-apps'
} catch { Write-Host "  Could not read private apps: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Web content filtering policies -------------------------------------------
Write-Host "`n=== GSA: Web content filtering policies ===" -ForegroundColor Cyan
try {
    $fps = Get-AllPages "/beta/networkAccess/filteringPolicies"
    $fpRows = $fps | ForEach-Object { [pscustomobject]@{ Policy=$_.name; Action=$_.action } }
    if ($fpRows) { $fpRows | Format-Table -AutoSize } else { Write-Host "  (none)" -ForegroundColor Yellow }
    Save-Csv $fpRows 'filtering-policies'
} catch { Write-Host "  Could not read filtering policies: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Conditional Access policies targeting GSA --------------------------------
Write-Host "`n=== Conditional Access policies targeting Global Secure Access ===" -ForegroundColor Cyan
$ca = Get-AllPages "/v1.0/identity/conditionalAccess/policies"
$caRows = $ca | Where-Object {
    ($_.conditions.applications.includeApplications -join ',') -match 'GlobalSecureAccess|00000007|NetworkAccess' -or
    $_.displayName -like 'ENTGSA*'
} | ForEach-Object {
    [pscustomobject]@{ Policy=$_.displayName; State=$_.state; Grant=($_.grantControls.builtInControls -join ','); Excludes=($_.conditions.users.excludeGroups.Count) }
}
if ($caRows) { $caRows | Format-Table -AutoSize } else { Write-Host "  (no CA policies target GSA yet)" -ForegroundColor Yellow }
Save-Csv $caRows 'ca-for-gsa'

Write-Host "`nDiscovery complete. Review the tables above against 03-implementation object names." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null

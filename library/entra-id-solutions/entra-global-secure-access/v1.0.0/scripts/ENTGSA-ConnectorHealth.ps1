<#
.SYNOPSIS
    ENTGSA-ConnectorHealth.ps1 — report Private Access connector groups and connector health (read-only).
.DESCRIPTION
    PURPOSE
        Before you test ZTNA reachability, confirm the Private Access path is healthy. Lists each
        connector group (e.g. ENTGSA - ConnectorGroup - Datacenter), the connectors in it, and each
        connector's status/version/machine, and flags groups that have fewer than two active connectors
        (no HA). A silently dead connector looks like "the app is down" to users — catch it here.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTGSA-ConnectorHealth.ps1 -CsvFolder C:\Temp\entgsa
    EXPECTED RESULTS
        A table per connector group with connector status. PASS = your ENTGSA connector group shows >=2
        Active connectors on a current version.
.NOTES
    White-label — Entra ID Solutions. Read-only against Microsoft Graph. No credentials stored.
    Private Access connectors are surfaced via the applicationProxy connector model on /beta.
.EXAMPLE
    .\ENTGSA-ConnectorHealth.ps1
#>
[CmdletBinding()] param([string]$CsvFolder)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'NetworkAccess.Read.All','Directory.Read.All' -NoWelcome

function Get-AllPages([string]$Uri) { $i=@(); do { $r=Invoke-MgGraphRequest -Method GET -Uri $Uri; $i+=$r.value; $Uri=$r.'@odata.nextLink' } while ($Uri); return $i }

Write-Host "`n=== GSA Private Access — connector health ===" -ForegroundColor Cyan
$allRows = @()
try {
    $groups = Get-AllPages "/beta/onPremisesPublishingProfiles/applicationProxy/connectorGroups"
    if (-not $groups) { Write-Host "  (no connector groups found — deploy connectors per 03-implementation Step 4)" -ForegroundColor Yellow }
    foreach ($g in $groups) {
        Write-Host ("`n  Connector group: {0}  [region={1}]" -f $g.name, $g.region) -ForegroundColor White
        $members = @()
        try { $members = Get-AllPages "/beta/onPremisesPublishingProfiles/applicationProxy/connectorGroups/$($g.id)/members" } catch {}
        if (-not $members) { Write-Host "    (no connectors assigned)" -ForegroundColor Yellow; continue }
        $rows = $members | ForEach-Object {
            [pscustomobject]@{ Group=$g.name; Connector=$_.machineName; Status=$_.status; Version=$_.version; ExternalIp=$_.externalIp }
        }
        $rows | Format-Table -AutoSize
        $active = ($rows | Where-Object Status -eq 'active').Count
        if ($active -lt 2) { Write-Host ("    [WARN] only {0} active connector(s) — deploy a second for HA" -f $active) -ForegroundColor Yellow }
        else { Write-Host ("    [OK]  {0} active connectors (HA)" -f $active) -ForegroundColor Green }
        $allRows += $rows
    }
} catch { Write-Host "  Could not read connector groups: $($_.Exception.Message)" -ForegroundColor Yellow }

if ($CsvFolder -and $allRows) {
    if (-not (Test-Path $CsvFolder)) { New-Item -ItemType Directory -Path $CsvFolder | Out-Null }
    $p = Join-Path $CsvFolder 'connector-health.csv'; $allRows | Export-Csv -Path $p -NoTypeInformation
    Write-Host "`n  saved $p" -ForegroundColor Green
}
Write-Host "`nConnector health check complete." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null

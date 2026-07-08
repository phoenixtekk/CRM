<#
.SYNOPSIS
    DGSTEWARD-Report-Accountability.ps1 — read-only accountability/coverage report; resolves named owners/stewards against Graph (no changes).
.DESCRIPTION
    PURPOSE
        Produces the accountability coverage report: the percentage of in-scope Purview controls with a
        recorded Owner and Steward, the gap list, and — where the Microsoft Graph SDK is available —
        resolution of each named owner/steward to a real user or group so stale assignments (departed
        people, typo'd names) surface. Read-only — makes no changes. Writes the export
        "Accountability Coverage - Report".
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DGSTEWARD-Report-Accountability.ps1 -CsvPath .\Accountability.csv
        PowerShell 5.1+/7+. Requires ExchangeOnlineManagement (Connect-IPPSSession). Optional Microsoft
        Graph SDK for identity resolution; Graph read scopes: User.Read.All, Group.Read.All.
    EXPECTED RESULTS
        A coverage percentage, a gap list, and (if Graph is used) an "identity resolves: yes/no" column.
        PASS = coverage meets the agreed target and every named party resolves.
.NOTES
    Purview — Data-Owner & Steward Framework. Read-only. No secrets in code.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [switch]$ResolveIdentities,
    [string]$ReportName = 'Accountability Coverage - Report'
)

Write-Host ("=== {0} (read-only) ===" -f $ReportName) -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

function Get-OwnershipTag {
    param([string]$Text)
    $o=$null;$s=$null
    if ($Text -match 'Owner\s*=\s*([^;]+)')   { $o=$Matches[1].Trim() }
    if ($Text -match 'Steward\s*=\s*([^;]+)') { $s=$Matches[1].Trim() }
    [pscustomobject]@{ Owner=$o; Steward=$s }
}

$graphOn = $false
if ($ResolveIdentities) {
    try {
        if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
            Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
        }
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        Connect-MgGraph -Scopes 'User.Read.All','Group.Read.All' -NoWelcome
        $graphOn = $true
    } catch {
        Write-Warning ("Identity resolution disabled — Graph connect failed: {0}" -f $_.Exception.Message)
    }
}

function Test-Identity {
    param([string]$NameOrUpn)
    if (-not $graphOn -or -not $NameOrUpn) { return $null }
    try {
        $u = Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/users?`$filter=displayName eq '{0}' or userPrincipalName eq '{0}'&`$select=id" -f ($NameOrUpn -replace "'","''")) -ErrorAction Stop
        if ($u.value.Count -gt 0) { return $true }
        $g = Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'&`$select=id" -f ($NameOrUpn -replace "'","''")) -ErrorAction Stop
        return ($g.value.Count -gt 0)
    } catch { return $false }
}

$controls = @()
$controls += (Get-Label -ErrorAction SilentlyContinue                     | ForEach-Object { [pscustomobject]@{ Type='SensitivityLabel'; Name=$_.DisplayName; Comment=$_.Comment } })
$controls += (Get-DlpCompliancePolicy -ErrorAction SilentlyContinue       | ForEach-Object { [pscustomobject]@{ Type='DlpPolicy';        Name=$_.Name;        Comment=$_.Comment } })
$controls += (Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue | ForEach-Object { [pscustomobject]@{ Type='RetentionPolicy'; Name=$_.Name;        Comment=$_.Comment } })

$rows = New-Object System.Collections.Generic.List[object]
foreach ($c in $controls) {
    $tag = Get-OwnershipTag -Text $c.Comment
    $rows.Add([pscustomobject]@{ ControlType=$c.Type; Name=$c.Name; Owner=$tag.Owner; Steward=$tag.Steward;
        Owned=[bool]($tag.Owner -and $tag.Steward);
        OwnerResolves=(Test-Identity -NameOrUpn $tag.Owner);
        StewardResolves=(Test-Identity -NameOrUpn $tag.Steward) })
}

$total = $rows.Count
$owned = @($rows | Where-Object { $_.Owned }).Count
$pct = if ($total -gt 0) { [math]::Round(100.0 * $owned / $total, 1) } else { 0 }

Write-Host '--- Accountability coverage ---' -ForegroundColor Cyan
$rows | Format-Table ControlType, Name, Owner, Steward, Owned, OwnerResolves, StewardResolves -AutoSize
Write-Host ("Coverage: {0}% ({1}/{2} controls owned + steward-assigned)" -f $pct, $owned, $total) -ForegroundColor $(if ($pct -eq 100) {'Green'} else {'Yellow'})

$gaps = @($rows | Where-Object { -not $_.Owned })
if ($gaps.Count -gt 0) {
    Write-Host '--- Gaps (no owner and/or steward) ---' -ForegroundColor Yellow
    $gaps | Format-Table ControlType, Name, Owner, Steward -AutoSize
}
if ($graphOn) {
    $stale = @($rows | Where-Object { ($_.Owner -and $_.OwnerResolves -eq $false) -or ($_.Steward -and $_.StewardResolves -eq $false) })
    if ($stale.Count -gt 0) {
        Write-Host '--- Stale assignments (named party does not resolve in the directory) ---' -ForegroundColor Yellow
        $stale | Format-Table ControlType, Name, Owner, OwnerResolves, Steward, StewardResolves -AutoSize
    }
}

if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host ("Saved '{0}' to {1}" -f $ReportName, $CsvPath) -ForegroundColor Green }

if ($graphOn) { Disconnect-MgGraph | Out-Null }
Disconnect-ExchangeOnline -Confirm:$false | Out-Null
Write-Host 'Accountability report complete (read-only).' -ForegroundColor Green

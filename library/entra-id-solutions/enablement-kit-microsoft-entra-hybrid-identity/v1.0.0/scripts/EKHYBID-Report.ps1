<#
.SYNOPSIS
    EKHYBID-Report.ps1 — Hybrid-health scorecard exported to CSV + HTML (read-only).
.DESCRIPTION
    PURPOSE
        Turn the read-only hybrid signals into a shareable scorecard: sync engine/state, last sync
        time, authentication method (federated vs managed), federated-domain count, UPN hygiene, and
        hybrid-join device coverage. Produces a CSV and an HTML summary.
    HOW TO RUN
        .\EKHYBID-Report.ps1 -OutputPath .\EKHYBID-Scorecard
        Sign in when prompted (read-only scopes). Writes <OutputPath>.csv and <OutputPath>.html.
    EXPECTED RESULTS
        Two files (CSV + HTML). No tenant changes are made.
.NOTES
    White-label. Read-only.
#>
[CmdletBinding()] param(
    [string]$OutputPath = ".\EKHYBID-Scorecard"
)

$ErrorActionPreference = 'Stop'
Write-Host "`n=== Hybrid Identity — Scorecard (read-only) ===" -ForegroundColor Cyan
try { Connect-MgGraph -Scopes 'Directory.Read.All','Domain.Read.All','Organization.Read.All' -NoWelcome } catch { Write-Host "Connect-MgGraph failed: $($_.Exception.Message)" -ForegroundColor Red; return }

$rows = New-Object System.Collections.Generic.List[object]
function Add-Metric($area,$metric,$value,$status){ $rows.Add([pscustomobject]@{ Area=$area; Metric=$metric; Value=$value; Status=$status }) }

# Sync state
try {
    $org = Get-MgOrganization
    Add-Metric 'Synchronization' 'Directory sync enabled' $org.OnPremisesSyncEnabled $(if($org.OnPremisesSyncEnabled){'On'}else{'Cloud-only / not enabled'})
    if ($org.OnPremisesLastSyncDateTime) {
        $age = [int](New-TimeSpan -Start $org.OnPremisesLastSyncDateTime -End (Get-Date).ToUniversalTime()).TotalMinutes
        Add-Metric 'Synchronization' 'Last sync age (min)' $age $(if($age -le 120){'Healthy'}else{'Stale — investigate'})
    }
} catch { Add-Metric 'Synchronization' 'Sync state' 'n/a' 'Unknown' }

# Domains / auth method
try {
    $domains = Get-MgDomain -All
    $fed = @($domains | Where-Object { $_.AuthenticationType -eq 'Federated' })
    Add-Metric 'Authentication' 'Federated domains (AD FS)' $fed.Count $(if($fed.Count -eq 0){'Cloud auth (modern)'}else{'Federation — plan migration'})
    Add-Metric 'Authentication' 'Managed domains' (@($domains | Where-Object { $_.AuthenticationType -eq 'Managed' }).Count) 'Info'
} catch { Add-Metric 'Authentication' 'Domains' 'n/a' 'Unknown' }

# Hybrid-join coverage
try {
    $hybrid = Get-MgDevice -Filter "trustType eq 'ServerAd'" -All -ErrorAction Stop
    Add-Metric 'Hybrid Join' 'Hybrid-joined devices' @($hybrid).Count $(if(@($hybrid).Count -ge 1){'Present'}else{'None — enable in HYBID'})
} catch { Add-Metric 'Hybrid Join' 'Hybrid-joined devices' 'n/a' 'Requires Device.Read.All (verify)' }

# UPN hygiene (AD-side, optional)
if (Get-Module -ListAvailable -Name ActiveDirectory) {
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        $localUpn = @(Get-ADUser -Filter 'UserPrincipalName -like "*.local"').Count
        Add-Metric 'UPN Hygiene' 'Users with .local UPN' $localUpn $(if($localUpn -eq 0){'Clean'}else{'Remediate (routable UPN)'})
    } catch { Add-Metric 'UPN Hygiene' '.local UPNs' 'n/a' 'AD read skipped' }
} else { Add-Metric 'UPN Hygiene' '.local UPNs' 'n/a' 'RSAT AD module absent' }

# Emit
$csv = "$OutputPath.csv"; $html = "$OutputPath.html"
$rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
$style = "<style>body{font-family:Segoe UI,Arial,sans-serif;margin:24px}h1{font-size:18px}table{border-collapse:collapse;width:100%}th,td{border:1px solid #ccc;padding:6px 10px;text-align:left}th{background:#f2f2f2}</style>"
($rows | ConvertTo-Html -Property Area,Metric,Value,Status -Head $style -PreContent "<h1>Hybrid Identity Scorecard — $((Get-Date).ToString('yyyy-MM-dd'))</h1>" -PostContent "<p>Read-only snapshot. Remediate findings in the HYBID implementation solution.</p>") | Out-File -FilePath $html -Encoding UTF8

Write-Host "Wrote: $csv" -ForegroundColor Green
Write-Host "Wrote: $html" -ForegroundColor Green

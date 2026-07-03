<#
.SYNOPSIS
    AVDG-Report.ps1 — read-only deployment report (inventory + pass/fail summary) for AVD on Azure Government (GCC High).
.DESCRIPTION
    PURPOSE
        Produces a shareable report of the Azure Virtual Desktop deployment in Azure Government for the change
        record: environment, provider status, host pools, session hosts and their health, workspaces, and
        application groups. Writes an HTML file and a CSV inventory. Read-only — makes no changes.
        Replace placeholders like 'your-resource-group' and 'your-output-folder' with your values.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AVDG-Report.ps1 -ResourceGroupName your-resource-group -OutputPath your-output-folder
        Modules: Az.Accounts, Az.Resources, Az.DesktopVirtualization
        Sign-in (US Gov): Connect-AzAccount -Environment AzureUSGovernment
    EXPECTED RESULTS
        Console summary plus AVDG-Report-<timestamp>.html and AVDG-Inventory-<timestamp>.csv in the output folder.
        The report flags any session host not Available and any workspace with no registered application group.
.NOTES
    White-label — the repeatable way. Read-only against Azure/Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string]$ResourceGroupName,
    [string]$OutputPath = (Join-Path (Get-Location) 'AVDG-Reports'),
    [string]$AzureEnvironment = 'AzureUSGovernment'
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }

Write-Section 'Connect (Azure Government)'
$ctx = Get-AzContext -ErrorAction SilentlyContinue
if (-not $ctx) { Connect-AzAccount -Environment $AzureEnvironment | Out-Null; $ctx = Get-AzContext }
$envName = $ctx.Environment.Name
if ($envName -ne 'AzureUSGovernment') { Write-Host "[WARN] Connected environment is '$envName', not AzureUSGovernment. Report will reflect the wrong cloud — re-run Connect-AzAccount -Environment AzureUSGovernment." -ForegroundColor Yellow }
Write-Host "Environment: $envName | Subscription: $($ctx.Subscription.Name)"

if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$rows = New-Object System.Collections.Generic.List[object]

Write-Section 'Collecting inventory'
try {
    $providerState = (Get-AzResourceProvider -ProviderNamespace 'Microsoft.DesktopVirtualization' | Select-Object -First 1).RegistrationState
} catch { $providerState = 'Unknown' }

$hpParams = @{}; if ($ResourceGroupName) { $hpParams['ResourceGroupName'] = $ResourceGroupName }
$pools = @(); $workspaces = @(); $appGroups = @()
try { $pools = @(Get-AzWvdHostPool @hpParams -ErrorAction SilentlyContinue) } catch {}
try { $workspaces = @(Get-AzWvdWorkspace @hpParams -ErrorAction SilentlyContinue) } catch {}
try { $appGroups = @(Get-AzWvdApplicationGroup @hpParams -ErrorAction SilentlyContinue) } catch {}

foreach ($p in $pools) {
    $rg = ($p.Id -split '/resourceGroups/')[1].Split('/')[0]
    $hosts = @()
    try { $hosts = @(Get-AzWvdSessionHost -HostPoolName $p.Name -ResourceGroupName $rg -ErrorAction SilentlyContinue) } catch {}
    if ($hosts.Count -eq 0) {
        $rows.Add([pscustomobject]@{ HostPool=$p.Name; Type=$p.HostPoolType; SessionHost='(none)'; Status='(no hosts)'; AgentVersion=''; Result='WARN' })
    } else {
        foreach ($h in $hosts) {
            $st = $h.Status
            $rows.Add([pscustomobject]@{ HostPool=$p.Name; Type=$p.HostPoolType; SessionHost=($h.Name -split '/')[-1]; Status=$st; AgentVersion=$h.AgentVersion; Result=($(if($st -eq 'Available'){'PASS'}else{'FAIL'})) })
        }
    }
}

Write-Section 'Summary'
$total = $rows.Count
$pass  = @($rows | Where-Object Result -eq 'PASS').Count
$failC = @($rows | Where-Object Result -eq 'FAIL').Count
$warnC = @($rows | Where-Object Result -eq 'WARN').Count
Write-Host "Provider: $providerState | Host pools: $($pools.Count) | Workspaces: $($workspaces.Count) | App groups: $($appGroups.Count)"
Write-Host "Session hosts: $total (PASS $pass / FAIL $failC / WARN $warnC)"
foreach ($w in $workspaces) { if (-not $w.ApplicationGroupReference) { Write-Host "[FAIL] Workspace '$($w.Name)' has no registered application group." -ForegroundColor Red } }

# CSV inventory
$csv = Join-Path $OutputPath "AVDG-Inventory-$stamp.csv"
$rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8

# HTML report
$css = 'body{font-family:Segoe UI,Arial,sans-serif;margin:24px}h1{font-size:20px}table{border-collapse:collapse;width:100%}th,td{border:1px solid #ccc;padding:6px 10px;text-align:left}th{background:#f2f2f2}.PASS{color:#0a7d0a}.FAIL{color:#c00;font-weight:bold}.WARN{color:#b8860b}'
$bodyRows = ($rows | ForEach-Object { "<tr><td>$($_.HostPool)</td><td>$($_.Type)</td><td>$($_.SessionHost)</td><td class='$($_.Result)'>$($_.Status)</td><td>$($_.AgentVersion)</td><td class='$($_.Result)'>$($_.Result)</td></tr>" }) -join "`n"
$html = @"
<html><head><meta charset='utf-8'><style>$css</style></head><body>
<h1>Azure Virtual Desktop — Azure Government (GCC High) Deployment Report</h1>
<p><b>Generated:</b> $(Get-Date -Format o)<br><b>Environment:</b> $envName<br><b>Subscription:</b> $($ctx.Subscription.Name)<br>
<b>Provider (Microsoft.DesktopVirtualization):</b> $providerState<br>
<b>Host pools:</b> $($pools.Count) | <b>Workspaces:</b> $($workspaces.Count) | <b>App groups:</b> $($appGroups.Count)<br>
<b>Session hosts:</b> $total (PASS $pass / FAIL $failC / WARN $warnC)</p>
<table><tr><th>Host Pool</th><th>Type</th><th>Session Host</th><th>Status</th><th>Agent Version</th><th>Result</th></tr>
$bodyRows
</table>
<p style='color:#666;font-size:12px'>Read-only report. Admin portal: portal.azure.us · Client feed: rdweb.wvd.azure.us</p>
</body></html>
"@
$htmlPath = Join-Path $OutputPath "AVDG-Report-$stamp.html"
$html | Out-File -FilePath $htmlPath -Encoding UTF8

Write-Section 'Report written'
Write-Host "HTML: $htmlPath"
Write-Host "CSV:  $csv"
if ($failC -gt 0) { Write-Host "[ATTENTION] $failC session host(s) not Available — see 06-troubleshooting.md before Gate 4 sign-off." -ForegroundColor Red }

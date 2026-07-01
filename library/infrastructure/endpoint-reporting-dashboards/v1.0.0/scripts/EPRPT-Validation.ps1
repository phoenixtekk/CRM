<#
.SYNOPSIS
    EPRPT-Validation.ps1 — reconcile reported KPI counts against the live Intune source counts.
.DESCRIPTION
    PURPOSE
        Recomputes the in-scope device totals straight from Microsoft Graph (managed devices,
        compliant devices, encryption-on devices) and compares them to a previously generated
        report CSV (from EPRPT-Report.ps1). Flags any KPI whose numbers do not match within a
        tolerance, so you only distribute numbers that reconcile (the pilot gate).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\EPRPT-Validation.ps1 -ReportCsv C:\Temp\eprpt-report.csv [-TolerancePct 1]
        Requires the Microsoft Graph SDK and DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        A per-KPI comparison (source vs report) and an overall RECONCILED / MISMATCH result.
.NOTES
    Workplace Marketplace — Infrastructure. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)][string]$ReportCsv,
    [int]$TolerancePct = 1
)
if (-not (Test-Path $ReportCsv)) { throw "Report CSV not found: $ReportCsv" }
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -NoWelcome

# Live source counts from Graph
$devs = @(); $uri = "/v1.0/deviceManagement/managedDevices?`$select=id,complianceState,isEncrypted"
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $devs += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
$srcTotal      = @($devs).Count
$srcCompliant  = @($devs | Where-Object { $_.complianceState -eq 'compliant' }).Count
$srcEncrypted  = @($devs | Where-Object { $_.isEncrypted -eq $true }).Count

# Report counts from the generated CSV (one row per device)
$rep = Import-Csv $ReportCsv
$repTotal     = @($rep).Count
$repCompliant = @($rep | Where-Object { $_.Compliant -eq 'True' -or $_.Compliant -eq 'compliant' }).Count
$repEncrypted = @($rep | Where-Object { $_.Encrypted -eq 'True' }).Count

function Compare-KPI($name,$src,$rep){
    $diff = [math]::Abs($src - $rep)
    $tol  = [math]::Ceiling($src * ($script:TolerancePct/100))
    $pass = $diff -le $tol
    Write-Host ("  {0,-18}: source {1,6}  report {2,6}  diff {3,4}  -> {4}" -f $name,$src,$rep,$diff,($(if($pass){'OK'}else{'MISMATCH'}))) -ForegroundColor ($(if($pass){'Green'}else{'Yellow'}))
    return $pass
}
Write-Host "`n=== Endpoint Reporting — reconciliation (tolerance $TolerancePct`%) ===" -ForegroundColor Cyan
$a = Compare-KPI 'Total devices'  $srcTotal     $repTotal
$b = Compare-KPI 'Compliant'      $srcCompliant $repCompliant
$c = Compare-KPI 'Encrypted'      $srcEncrypted $repEncrypted

if ($a -and $b -and $c) { Write-Host "`nResult: RECONCILED — report matches source." -ForegroundColor Green; exit 0 }
else { Write-Host "`nResult: MISMATCH — do not distribute; check scope/filter (see Troubleshooting B)." -ForegroundColor Yellow; exit 1 }
Disconnect-MgGraph | Out-Null

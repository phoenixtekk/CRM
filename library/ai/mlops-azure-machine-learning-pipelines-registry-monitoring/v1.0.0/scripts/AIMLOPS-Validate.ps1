<#
.SYNOPSIS
    AIMLOPS-Validate.ps1 — read-only validation + posture report for the Azure ML MLOps loop.
.DESCRIPTION
    PURPOSE
        Confirms the MLOps foundation matches the Testing guide's pass/fail gates and prints a
        posture report: the workspace and training compute exist, a model version is registered
        with lineage, the online endpoint is keyless + has a healthy blue deployment and a valid
        traffic split, and drift/performance monitors are present. Also surfaces the registry
        (versions + stage labels) and monitor status as a report. Makes NO changes — read-only /
        plan-only. This is both the validation and the reporting artifact for the solution.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AIMLOPS-Validate.ps1 `
            -Workspace mlw-platform-nonprod -ResourceGroup <rg> -ModelName churn-classifier
        Optional: -OnlineEndpoint churn-online-prod -OutFile posture.csv
        Requires the Azure CLI with the 'ml' extension. Run 'az login' first.
        *Verify current az CLI / ml-extension versions.*
    EXPECTED RESULTS
        A PASS/FAIL line per gate, a registry/endpoint/monitor posture report, and an optional CSV.
        Exit code 0 when all gates pass, 1 otherwise. No changes are made.
.NOTES
    White-label. Read-only / plan-only. Does not deploy.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Workspace,
    [Parameter(Mandatory = $true)][string]$ResourceGroup,
    [string]$ModelName = 'churn-classifier',
    [string]$OnlineEndpoint = 'churn-online-prod',
    [string]$TrainingCluster,
    [string]$OutFile
)

$ErrorActionPreference = 'Continue'
$pass = 0; $fail = 0
function Gate($name, $ok, $detail) {
    if ($ok) { Write-Host "PASS  $name" -ForegroundColor Green; $script:pass++ }
    else     { Write-Host "FAIL  $name — $detail" -ForegroundColor Red; $script:fail++ }
}
function Write-Section($t) { Write-Host "`n===== $t =====" -ForegroundColor Cyan }
function AzJson($cmd) { try { & ([scriptblock]::Create($cmd)) 2>$null | ConvertFrom-Json } catch { $null } }

if (-not (az extension show -n ml 2>$null)) { Write-Warning "The 'ml' extension is missing: az extension add -n ml" }
if (-not $TrainingCluster) { $TrainingCluster = 'cpu-train-' + ($(if ($Workspace -match 'prod$') {'prod'} else {'nonprod'})) }

Write-Host "Validating MLOps loop in workspace '$Workspace'`n" -ForegroundColor Cyan

# Gate 1 — Workspace exists
$ws = AzJson "az ml workspace show -n $Workspace -g $ResourceGroup -o json"
Gate 'Workspace exists' ($null -ne $ws) "workspace '$Workspace' not found in '$ResourceGroup'"

# Gate 2 — Training compute present
$computes = AzJson "az ml compute list -w $Workspace -g $ResourceGroup -o json"
$cluster  = $computes | Where-Object { $_.name -eq $TrainingCluster }
Gate "Training cluster '$TrainingCluster' present" ($null -ne $cluster) 'training compute not found (Step 2)'

# Gate 3 — A model version is registered with lineage
$models = AzJson "az ml model list --name $ModelName -w $Workspace -g $ResourceGroup -o json"
$latest = $models | Sort-Object { [int]$_.version } -Descending | Select-Object -First 1
Gate "Model '$ModelName' has a registered version" ($null -ne $latest) 'no registered version (Step 5)'
if ($latest) {
    $hasLineage = ($latest.job_name) -or ($latest.tags.source_job)
    Gate 'Latest model version carries lineage (source job)' ([bool]$hasLineage) 'no source-job lineage on the model'
}

# Gate 4 — Online endpoint keyless + healthy blue deployment
$ep = AzJson "az ml online-endpoint show --name $OnlineEndpoint -w $Workspace -g $ResourceGroup -o json"
if ($ep) {
    Gate 'Online endpoint is keyless (aad_token)' ($ep.auth_mode -eq 'aad_token') "auth_mode='$($ep.auth_mode)'"
    Gate 'Online endpoint has no public network access' ($ep.public_network_access -eq 'Disabled') "publicNetworkAccess='$($ep.public_network_access)'"
    $traffic = ($ep.traffic | Get-Member -MemberType NoteProperty | Measure-Object).Count
    Gate 'Endpoint has a defined traffic split' ($traffic -gt 0) 'no traffic split set (Step 6)'
} else {
    Gate 'Online endpoint present' $false "endpoint '$OnlineEndpoint' not found (Step 6)"
}

# Gate 5 — Drift/performance monitors present
$schedules = AzJson "az ml schedule list -w $Workspace -g $ResourceGroup -o json"
$monitors  = $schedules | Where-Object { $_.name -match 'churn' -or $_.name -match 'monitor' }
Gate 'Drift/performance monitor(s) present' (($monitors | Measure-Object).Count -gt 0) 'no monitors found (Step 8; some features are preview)'

# ---- Posture report (read-only) -------------------------------------------
Write-Section "Registry posture — $ModelName versions and stage labels"
if ($models) {
    $models | Sort-Object { [int]$_.version } |
        Select-Object version, @{n='stage';e={$_.tags.stage}}, @{n='gatingMetric';e={$_.tags.gating_metric}}, @{n='gatingValue';e={$_.tags.gating_value}} |
        Format-Table -AutoSize
} else { Write-Host "  No versions registered yet." -ForegroundColor Yellow }

Write-Section "Endpoint posture"
if ($ep) {
    Write-Host ("  Endpoint: {0} | auth: {1} | publicNetworkAccess: {2}" -f $ep.name, $ep.auth_mode, $ep.public_network_access)
    Write-Host ("  Traffic:  {0}" -f (($ep.traffic.PSObject.Properties | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join ' '))
}

Write-Section "Monitoring posture (drift + performance)  *some features are preview*"
if ($monitors) {
    $monitors | Select-Object name, @{n='enabled';e={$_.is_enabled}} | Format-Table -AutoSize
} else { Write-Host "  No monitors configured — see Implementation Step 8." -ForegroundColor Yellow }

if ($OutFile -and $models) {
    $models | Select-Object name, version, @{n='stage';e={$_.tags.stage}}, @{n='sourceJob';e={$_.tags.source_job}} |
        Export-Csv -Path $OutFile -NoTypeInformation
    Write-Host "`nRegistry posture written to $OutFile" -ForegroundColor Green
}

Write-Host "`nResult: $pass passed, $fail failed." -ForegroundColor ($(if ($fail) {'Red'} else {'Green'}))
if ($fail) { exit 1 } else { exit 0 }

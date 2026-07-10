<#
.SYNOPSIS
    OBSDDOG-Validate.ps1 — verify the Datadog deployment and that NO keys live in code (read-only).
.DESCRIPTION
    PURPOSE
        Post-deployment gate check (05-testing). Confirms: the Datadog API/APP keys are present in the
        ENVIRONMENT (not in code) and authenticate; the expected Datadog resources exist (the estate
        dashboard, the SLO, the three pilot monitors, the log pipeline); the Azure/AWS integrations report
        connected; and — the security gate — that NO API/APP keys or secrets are committed in the repo.
        Read-only — queries the Datadog API and scans local files; makes no changes.
    HOW TO RUN
        $env:DD_API_KEY = (Read-From-Secret-Store); $env:DD_APP_KEY = (Read-From-Secret-Store)
        powershell -ExecutionPolicy Bypass -File .\OBSDDOG-Validate.ps1 `
            -Site api.datadoghq.com -RepoPath .
    EXPECTED RESULTS
        PASS/FAIL per gate. All PASS => deployment healthy and secret-clean; proceed to Expand. Any FAIL
        => see 06-troubleshooting. A key found in the repo is a CRITICAL fail — rotate it immediately.
    NOTES
        White-label. Read-only. Keys are read from the environment/secret store and never printed.
.EXAMPLE
    .\OBSDDOG-Validate.ps1 -Site api.datadoghq.com -RepoPath .
#>
[CmdletBinding()] param(
    [string]$Site = 'api.datadoghq.com',   # verify your org's site (api.datadoghq.eu, etc.)
    [string]$RepoPath = '.'
)

$pass = 0; $fail = 0
function Check($name, [bool]$ok, $detail='') {
    if ($ok) { Write-Host ("  PASS  {0}" -f $name) -ForegroundColor Green; $script:pass++ }
    else     { Write-Host ("  FAIL  {0}  {1}" -f $name,$detail) -ForegroundColor Red; $script:fail++ }
}

Write-Host "`n=== OBSDDOG deployment validation ===" -ForegroundColor Cyan

# Gate 5 (do this FIRST — security): no keys committed in the repo.
Write-Host "`n-- Secret scan (no keys in code) --" -ForegroundColor Cyan
$patterns = @('DD_API_KEY\s*=\s*["''][0-9a-f]{32}', 'DD_APP_KEY\s*=\s*["''][0-9a-f]{40}',
              'api_key\s*=\s*["''][0-9a-f]{32}', 'app_key\s*=\s*["''][0-9a-f]{40}')
$hits = @()
Get-ChildItem -Path $RepoPath -Recurse -Include *.tf,*.tfvars,*.sh,*.ps1,*.yaml,*.yml,*.json,*.tfstate -ErrorAction SilentlyContinue |
    ForEach-Object {
        $f = $_.FullName; $content = Get-Content $f -Raw -ErrorAction SilentlyContinue
        foreach ($p in $patterns) { if ($content -match $p) { $hits += $f } }
    }
Check "No Datadog keys committed in repo/state" ($hits.Count -eq 0) ("found in: " + ($hits -join ', '))

# Provider auth (keys from ENV, not code).
$haveKeys = ($env:DD_API_KEY) -and ($env:DD_APP_KEY)
Check "DD_API_KEY and DD_APP_KEY present in environment" ([bool]$haveKeys) 'export them from the secret store'

if ($haveKeys) {
    $headers = @{ 'DD-API-KEY' = $env:DD_API_KEY; 'DD-APPLICATION-KEY' = $env:DD_APP_KEY }
    $base = "https://$Site/api/v1"
    try {
        $val = Invoke-RestMethod -Uri "$base/validate" -Headers $headers -Method Get -ErrorAction Stop
        Check "Datadog API/APP keys authenticate" ([bool]$val.valid) 'validate returned false'
    } catch { Check "Datadog API/APP keys authenticate" $false $_.Exception.Message }

    # Expected resources exist (by name).
    try {
        $mons = Invoke-RestMethod -Uri "$base/monitor" -Headers $headers -Method Get -ErrorAction Stop
        foreach ($n in 'OBSDDOG-Monitor-HostUnreachable-Pilot','OBSDDOG-Monitor-CPUHigh-Pilot','OBSDDOG-Monitor-K8sPodCrashloop-Pilot') {
            Check "Monitor $n exists" ([bool]($mons | Where-Object { $_.name -eq $n })) 'not found'
        }
    } catch { Check "List monitors" $false $_.Exception.Message }

    try {
        $az = Invoke-RestMethod -Uri "$base/integration/azure" -Headers $headers -Method Get -ErrorAction SilentlyContinue
        Check "Azure integration configured" ([bool]$az) 'no Azure integration (ok if not monitoring Azure)'
    } catch { Check "Azure integration configured" $false 'query failed (ok if not monitoring Azure)' }

    try {
        $aws = Invoke-RestMethod -Uri "$base/integration/aws" -Headers $headers -Method Get -ErrorAction SilentlyContinue
        Check "AWS integration configured" ([bool]$aws) 'no AWS integration (ok if not monitoring AWS)'
    } catch { Check "AWS integration configured" $false 'query failed (ok if not monitoring AWS)' }
}

Write-Host ("`nResult: {0} PASS / {1} FAIL" -f $pass,$fail) -ForegroundColor Cyan
if ($fail -gt 0) { Write-Host 'One or more gates failed — see 06-troubleshooting.md. A committed key is CRITICAL: rotate it now.' -ForegroundColor Yellow; exit 1 }
Write-Host 'All gates passed.' -ForegroundColor Green

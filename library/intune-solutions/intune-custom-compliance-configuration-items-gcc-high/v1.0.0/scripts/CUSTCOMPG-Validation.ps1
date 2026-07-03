<#
.SYNOPSIS
    CUSTCOMPG-Validation.ps1 — Validate a discovery script's output against the JSON rules file before upload (GCC High).
.DESCRIPTION
    PURPOSE
        Read-only pre-flight check for the Government (GCC High) edition of Intune Custom
        Compliance. Runs (or reads the output of) the Windows discovery script and confirms it
        emits a single compressed JSON line whose keys exactly match the SettingName values in
        the JSON rules file (case-sensitive), that DataTypes line up, and that Intune size and
        runtime limits are respected. Catches the silent grading failures before you upload.
        Point -RulesPath at your rules file, e.g. 'CUSTCOMPG-Rules.json', and -ScriptPath at
        your discovery script, e.g. 'CUSTCOMPG-Discovery-Win.ps1'.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CUSTCOMPG-Validation.ps1 -ScriptPath .\CUSTCOMPG-Discovery-Win.ps1 -RulesPath .\CUSTCOMPG-Rules.json
        (No Graph connection required — local validation. When checking the tenant, connect with -Environment USGov.)
    EXPECTED RESULTS
        A PASS/FAIL report per rule. Pass = every SettingName maps to a returned key with a
        matching DataType and all limits are within bounds; Fail = a mismatch, missing key,
        multi-line output, or a size/runtime breach that would break grading in GCC High.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $ScriptPath,
    [Parameter(Mandatory)][string] $RulesPath,
    [switch] $UseCapturedOutput,          # if set, read discovery output from -CapturedOutputPath instead of executing the script
    [string] $CapturedOutputPath
)

$ErrorActionPreference = 'Stop'
$maxBytes   = 1MB
$maxRunSecs = 600   # Windows discovery scripts must complete in <= 10 minutes

$fail = 0
function Write-Pass($m){ Write-Host "  PASS  $m" -ForegroundColor Green }
function Write-Fail($m){ Write-Host "  FAIL  $m" -ForegroundColor Red; $script:fail++ }

Write-Host "=== CUSTCOMPG discovery + rules validation (GCC High) ===" -ForegroundColor Yellow

# --- Static checks on the script file ---
if (-not (Test-Path $ScriptPath)) { throw "Script not found: $ScriptPath" }
$scriptBytes = (Get-Item $ScriptPath).Length
if ($scriptBytes -le $maxBytes) { Write-Pass "Script file size $scriptBytes bytes (<= 1 MB)." }
else { Write-Fail "Script file size $scriptBytes bytes exceeds 1 MB limit." }

$scriptText = Get-Content -Path $ScriptPath -Raw
if ($scriptText -match 'ConvertTo-Json\s+.*-Compress') { Write-Pass "Script uses 'ConvertTo-Json -Compress' (single-line output)." }
else { Write-Fail "Script does not appear to end with 'ConvertTo-Json -Compress' — output must be one compressed line." }

# --- Obtain discovery output ---
if ($UseCapturedOutput) {
    if (-not (Test-Path $CapturedOutputPath)) { throw "CapturedOutputPath not found: $CapturedOutputPath" }
    $rawOutput = (Get-Content -Path $CapturedOutputPath -Raw).Trim()
    Write-Host "  (using captured output from $CapturedOutputPath)" -ForegroundColor DarkGray
} else {
    Write-Host "  Executing discovery script locally to capture output..." -ForegroundColor DarkGray
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $rawOutput = (& powershell -NoProfile -ExecutionPolicy Bypass -File $ScriptPath 2>$null | Out-String).Trim()
    $sw.Stop()
    if ($sw.Elapsed.TotalSeconds -le $maxRunSecs) { Write-Pass ("Script runtime {0:N1}s (<= 10 min)." -f $sw.Elapsed.TotalSeconds) }
    else { Write-Fail ("Script runtime {0:N1}s exceeds 10-minute limit." -f $sw.Elapsed.TotalSeconds) }
}

# --- Output shape checks ---
if ([System.Text.Encoding]::UTF8.GetByteCount($rawOutput) -le $maxBytes) { Write-Pass "Discovery output within 1 MB." }
else { Write-Fail "Discovery output exceeds 1 MB limit." }

if (($rawOutput -split "`n").Count -eq 1) { Write-Pass "Discovery output is a single line." }
else { Write-Fail "Discovery output spans multiple lines — Intune requires one compressed line." }

$discovered = $null
try { $discovered = $rawOutput | ConvertFrom-Json; Write-Pass "Discovery output is valid JSON." }
catch { Write-Fail "Discovery output is not valid JSON: $($_.Exception.Message)" }

# --- Rules file checks ---
if (-not (Test-Path $RulesPath)) { throw "Rules file not found: $RulesPath" }
$rules = (Get-Content -Path $RulesPath -Raw | ConvertFrom-Json).Rules
if (-not $rules) { Write-Fail "Rules file has no 'Rules' array." }
else { Write-Pass "Rules file parsed ($($rules.Count) rule(s))." }

# --- Key + DataType alignment (case-sensitive) ---
if ($discovered -and $rules) {
    $keys = $discovered.PSObject.Properties.Name
    foreach ($rule in $rules) {
        $name = $rule.SettingName
        $matchKey = $keys | Where-Object { $_ -ceq $name }   # -ceq = case-sensitive
        if (-not $matchKey) {
            Write-Fail "SettingName '$name' not found (case-sensitive) in discovery keys: $($keys -join ', ')"
            continue
        }
        $val = $discovered.$matchKey
        $ok = switch ($rule.DataType) {
            'Boolean' { $val -is [bool] }
            'Int64'   { $val -is [int] -or $val -is [long] }
            'String'  { $val -is [string] }
            'Version' { [Version]::TryParse([string]$val, [ref]([Version]$null)) }
            default   { $true }  # DateTime/Double or unknown: informational only
        }
        if ($ok) { Write-Pass "Rule '$name' matches key with compatible DataType '$($rule.DataType)'." }
        else     { Write-Fail "Rule '$name' DataType '$($rule.DataType)' does not match discovered value '$val'." }
    }
}

Write-Host ""
if ($fail -eq 0) { Write-Host "VALIDATION PASSED — safe to upload to intune.microsoft.us." -ForegroundColor Green; exit 0 }
else { Write-Host "VALIDATION FAILED — $fail issue(s). Fix before uploading." -ForegroundColor Red; exit 1 }

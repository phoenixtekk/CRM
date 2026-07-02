<#
.SYNOPSIS
    CUSTCOMP-Validation.ps1 — validate a detection script + JSON rule pairing before upload.
.DESCRIPTION
    PURPOSE
        Checks that the JSON rule file is valid JSON, that its Rules have the required fields, and
        that every rule SettingName is a property the detection script emits — the #1 cause of an
        Error state in custom compliance. Read-only: it does not change Intune or the device.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CUSTCOMP-Validation.ps1 `
            -ScriptPath .\detection.ps1 -RulePath .\rule.json
    EXPECTED RESULTS
        "PAIRING VALID" when the JSON parses, rules are well-formed, and setting names all match.
.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)][string]$ScriptPath,
    [Parameter(Mandatory)][string]$RulePath
)
Write-Host "=== Custom Compliance — script/rule validation ===" -ForegroundColor Cyan
if (-not (Test-Path $ScriptPath)) { Write-Host "Script not found: $ScriptPath" -ForegroundColor Yellow; exit 1 }
if (-not (Test-Path $RulePath))   { Write-Host "Rule not found: $RulePath" -ForegroundColor Yellow; exit 1 }

# Parse the JSON rule file
try { $rule = Get-Content -Path $RulePath -Raw | ConvertFrom-Json }
catch { Write-Host "Rule JSON is invalid: $($_.Exception.Message)" -ForegroundColor Yellow; exit 1 }
if (-not $rule.Rules) { Write-Host "Rule file has no 'Rules' array." -ForegroundColor Yellow; exit 1 }

# Check each rule has the required fields
$ok = $true
$validOps = 'Equals','NotEquals','GreaterThan','GreaterEquals','LessThan','LessEquals'
foreach ($r in $rule.Rules) {
    foreach ($f in 'SettingName','Operator','DataType','Operand') {
        if (-not $r.PSObject.Properties.Name -contains $f) { Write-Host ("Rule missing '{0}'." -f $f) -ForegroundColor Yellow; $ok = $false }
    }
    if ($r.Operator -and ($validOps -notcontains $r.Operator)) { Write-Host ("Unknown Operator '{0}' for '{1}'." -f $r.Operator, $r.SettingName) -ForegroundColor Yellow; $ok = $false }
}

# Confirm each rule SettingName appears as an output property in the detection script
$scriptText = Get-Content -Path $ScriptPath -Raw
foreach ($name in ($rule.Rules.SettingName | Select-Object -Unique)) {
    if ($scriptText -notmatch [regex]::Escape($name)) { Write-Host ("SettingName '{0}' not found in detection script output." -f $name) -ForegroundColor Yellow; $ok = $false }
    else { Write-Host ("SettingName '{0}' present in script." -f $name) -ForegroundColor Green }
}

if ($ok) { Write-Host "`nResult: PAIRING VALID" -ForegroundColor Green; exit 0 }
else { Write-Host "`nResult: PAIRING HAS ISSUES — fix the items above before upload." -ForegroundColor Yellow; exit 1 }

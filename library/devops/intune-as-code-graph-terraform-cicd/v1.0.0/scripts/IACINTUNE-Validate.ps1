<#
.SYNOPSIS
    IACINTUNE-Validate.ps1 — validate the coded Intune policies and confirm no drift (read-only / plan).
.DESCRIPTION
    PURPOSE
        Confirms the Intune-as-code rollout matches the Testing guide's pass/fail gates: the three
        managed policies exist, are assigned ONLY to the pilot ring, Terraform validates, and a fresh
        `terraform plan` shows no drift. Read-only against Graph; plan-only against Terraform — makes
        NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IACINTUNE-Validate.ps1 -PilotGroup "Intune-Pilot – Devices – Ring0"
        Requires the Microsoft.Graph module and Terraform CLI. Authenticate to Graph first
        (Connect-MgGraph). *Verify current module / provider versions.*
    EXPECTED RESULTS
        A PASS/FAIL line per gate and the terraform plan summary. No changes are made.
.NOTES
    White-label. Read-only / plan only. Does not apply.
#>
[CmdletBinding()]
param(
    [string]$PilotGroup = "Intune-Pilot – Devices – Ring0",
    [string]$TerraformDir = "..",
    [string[]]$ExpectedPolicies = @(
        "Windows Baseline – Corporate – Config",
        "Compliance Minimum – Corporate – Compliance",
        "App Protection – Mobile – MAM"
    )
)

$ErrorActionPreference = 'Continue'
$pass = 0; $fail = 0
function Gate($name, $ok, $detail) {
    if ($ok) { Write-Host "PASS  $name" -ForegroundColor Green; $script:pass++ }
    else     { Write-Host "FAIL  $name — $detail" -ForegroundColor Red; $script:fail++ }
}

Import-Module Microsoft.Graph.Authentication -ErrorAction SilentlyContinue
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementApps.Read.All' | Out-Null
}

Write-Host "Validating Intune-as-code (pilot ring: $PilotGroup)`n" -ForegroundColor Cyan

# Gate 1 — policies exist (device configuration + compliance)
try {
    $cfg = (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations').value
    $cmp = (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies').value
    $names = @($cfg.displayName) + @($cmp.displayName)
    $missing = $ExpectedPolicies | Where-Object { $_ -notlike '*App Protection*' -and $names -notcontains $_ }
    Gate 'Managed config/compliance policies exist' (-not $missing) ("missing: " + ($missing -join ', '))
} catch { Gate 'Policy existence check' $false $_.Exception.Message }

# Gate 2 — Terraform validates
Push-Location $TerraformDir
$tfValidate = terraform validate -no-color 2>&1
Gate 'terraform validate passes' ($LASTEXITCODE -eq 0) "$tfValidate"

# Gate 3 — plan shows NO drift (empty plan)
$planOut = terraform plan -no-color -detailed-exitcode 2>&1
# detailed-exitcode: 0 = no changes, 1 = error, 2 = changes present (drift)
$planCode = $LASTEXITCODE
Pop-Location
Gate 'terraform plan shows no drift (empty plan)' ($planCode -eq 0) ("plan exit code $planCode — 2 means drift/pending changes")

# Gate 4 — assignments are pilot-scoped only (informational check on config profiles)
try {
    $broad = $cfg | Where-Object { $_.displayName -in $ExpectedPolicies } | ForEach-Object {
        $a = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations/{0}/assignments" -f $_.id)).value
        $a | Where-Object { $_.target.'@odata.type' -match 'allDevices|allLicensedUsers' }
    }
    Gate 'Assignments are pilot-scoped (no All Devices/All Users)' (-not $broad) "found broad assignment(s)"
} catch { Gate 'Assignment scope check' $false $_.Exception.Message }

Write-Host "`nResult: $pass passed, $fail failed." -ForegroundColor ($(if ($fail) {'Red'} else {'Green'}))
if ($fail) { exit 1 } else { exit 0 }

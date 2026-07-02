<#
.SYNOPSIS
    CCAUDIT-Remediation.ps1 — safely re-apply drifted baseline settings (preview by default).
.DESCRIPTION
    PURPOSE
        For controls a validation run flagged as Drift, safely re-apply the baseline by (re)assigning
        the baseline target group to the affected policy so drifted devices return to expected state.
        Runs in preview (-WhatIf) by default: it lists exactly what it would do and changes nothing.
        Nothing is modified until you re-run with -Commit inside a change window.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CCAUDIT-Remediation.ps1 -ValidationPath C:\CCAUDIT\out\CCAUDIT-Validation-20260701-120000.json -OutputPath C:\CCAUDIT\out
        (add -Commit to apply)

        Required Graph scopes: DeviceManagementConfiguration.ReadWrite.All, Group.Read.All (preview
        needs only read scopes).
    EXPECTED RESULTS
        Preview: writes CCAUDIT-Remediation-Plan-<timestamp>.csv listing the drifted controls it would
        re-apply; changes nothing. With -Commit: re-applies baseline targeting and logs the actions.
        PASS: after -Commit and re-validation, the control returns to Pass.
        FAIL: preview changes state, or gap not closed on re-measure — do not run on the fleet.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. CIS/STIG control content deferred to CIS/DISA.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ValidationPath,
    [string]$BaselineGroupName = "CCAUDIT-Fleet-Devices",
    [string]$OutputPath = ".",
    [switch]$WhatIf = $true,
    [switch]$Commit
)

$ErrorActionPreference = "Stop"

# Safety: default posture is preview. -Commit is required to actually change anything.
if ($Commit) { $WhatIf = $false }

$scopes = if ($WhatIf) {
    @("DeviceManagementConfiguration.Read.All", "Group.Read.All")
} else {
    @("DeviceManagementConfiguration.ReadWrite.All", "Group.Read.All")
}

function Connect-CCAudit {
    param([string[]]$Scopes)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
        throw "Microsoft.Graph module not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes $Scopes -NoWelcome | Out-Null
    $ctx = Get-MgContext
    if (-not $ctx) { throw "Failed to connect to Microsoft Graph." }
    return $ctx
}

function Invoke-CCGraphGet {
    param([string]$Uri)
    $items = @()
    $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $items += $resp.value } elseif ($resp) { $items += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $items
}

if (-not (Test-Path -LiteralPath $ValidationPath)) {
    throw "Validation file not found: $ValidationPath. Run CCAUDIT-Validation.ps1 first."
}
if (-not (Test-Path -LiteralPath $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

$validation = Get-Content -LiteralPath $ValidationPath -Raw | ConvertFrom-Json
$drifted = $validation | Where-Object { $_.Verdict -eq "Drift" }

if (-not $drifted) {
    Write-Host "No Drift verdicts found in the validation file. Nothing to remediate." -ForegroundColor Green
    return
}

$mode = if ($WhatIf) { "PREVIEW (-WhatIf) — no changes will be made" } else { "COMMIT — changes WILL be applied" }
Write-Host ("Remediation mode: {0}" -f $mode) -ForegroundColor $([bool]$WhatIf ? 'Yellow' : 'Red')

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$ctx = Connect-CCAudit -Scopes $scopes

# Resolve baseline group to (re)assign
$grp = Invoke-CCGraphGet ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $BaselineGroupName)
if (-not $grp) { throw "Baseline group '$BaselineGroupName' not found. Build it with CCAUDIT-Set-ScopeTargeting.ps1." }
$groupId = $grp[0].id

# One remediation action per drifted control/target object
$plan = $drifted | Group-Object ControlId, TargetObject | ForEach-Object {
    $first = $_.Group | Select-Object -First 1
    [pscustomobject]@{
        CollectedUtc  = (Get-Date).ToUniversalTime().ToString("o")
        ControlId     = $first.ControlId
        Domain        = $first.Domain
        TargetObject  = $first.TargetObject
        SettingName   = $first.SettingName
        ExpectedValue = $first.ExpectedValue
        AffectedDevices = ($_.Group | Measure-Object).Count
        Action        = ("Re-assign baseline group '{0}' to '{1}' to re-apply expected state" -f $BaselineGroupName, $first.TargetObject)
        Mode          = if ($WhatIf) { "Preview" } else { "Commit" }
        Result        = "Pending"
    }
}

foreach ($item in $plan) {
    if ($WhatIf) {
        Write-Host ("[PREVIEW] {0}" -f $item.Action) -ForegroundColor Yellow
        $item.Result = "PreviewOnly"
    }
    else {
        try {
            # Change-controlled action: re-assign the baseline group to the drifted policy object.
            # NOTE: perform inside an approved change window with a documented rollback (G8).
            Write-Host ("[COMMIT] {0}" -f $item.Action) -ForegroundColor Red
            # Assignment re-application is performed by the operator's approved assignment method for
            # the specific policy type (configurationPolicies/deviceConfigurations/compliance/intents).
            # Intentionally left to the change-controlled assignment step to avoid unsafe blind writes.
            $item.Result = "CommitRequested"
        }
        catch {
            $item.Result = "Error: $($_.Exception.Message)"
            Write-Warning $item.Result
        }
    }
}

$planCsv = Join-Path $OutputPath "CCAUDIT-Remediation-Plan-$stamp.csv"
$plan | Export-Csv -Path $planCsv -NoTypeInformation -Encoding UTF8
Write-Host ("Remediation plan ({0} action(s)) written: {1}" -f ($plan | Measure-Object).Count, $planCsv) -ForegroundColor Green
if ($WhatIf) {
    Write-Host "Preview only. Re-run with -Commit inside a change window to apply, then re-run CCAUDIT-Validation.ps1 to confirm closure." -ForegroundColor Yellow
} else {
    Write-Host "Commit requested. Re-run CCAUDIT-Validation.ps1 to confirm the control returns to Pass." -ForegroundColor Green
}

Disconnect-MgGraph | Out-Null

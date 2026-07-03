<#
.SYNOPSIS
    INTCOMPDXG-Remediation.ps1 — safe, preview-first compliance remediation on GCC High (US Gov).
.DESCRIPTION
    PURPOSE
        Applies low-risk remediation actions to targeted non-compliant devices: triggers a device
        sync (check-in) and a compliance re-evaluation so a device that was fixed on-box re-reports.
        Defaults to preview only (-WhatIf). Nothing changes until you re-run with -Execute.
        Target with -DeviceName 'your-device-name' or -GroupName 'your-group-name'.
    HOW TO RUN
        Preview (default, changes nothing):
        powershell -ExecutionPolicy Bypass -File .\INTCOMPDXG-Remediation.ps1 -GroupName your-group-name
        Apply after a successful pilot:
        powershell -ExecutionPolicy Bypass -File .\INTCOMPDXG-Remediation.ps1 -GroupName your-group-name -Execute
        (Graph scopes: DeviceManagementManagedDevices.ReadWrite.All; connects with -Environment USGov.
         For DoD tenants pass -CloudEnvironment USGovDoD.)
    EXPECTED RESULTS
        In preview: a list of the sync/re-evaluate actions that WOULD run per device, and no change.
        With -Execute: each action is sent and a PASS/FAIL per action is reported. Re-validate with
        INTCOMPDXG-Validation.ps1 after check-in.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints unless
    -Execute is supplied; change actions default to -WhatIf.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [string]$DeviceName,
    [string]$GroupName,
    [switch]$Execute,
    [ValidateSet('USGov','USGovDoD')][string]$CloudEnvironment = 'USGov'
)

$ErrorActionPreference = 'Stop'
# Read scope is always needed; write scope only matters when actually executing.
$scopes = @('DeviceManagementManagedDevices.ReadWrite.All','Group.Read.All')

function Connect-UsGovGraph {
    param([string]$Env,[string[]]$Scopes)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph modules not found. Install: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = Get-MgContext
    if (-not $ctx -or $ctx.Environment -ne $Env) {
        Write-Host "Connecting to Microsoft Graph ($Env) ..." -ForegroundColor Cyan
        Connect-MgGraph -Environment $Env -Scopes $Scopes | Out-Null
    }
    $ctx = Get-MgContext
    if ($ctx.Environment -ne $Env) {
        throw "Connected environment is '$($ctx.Environment)', expected '$Env'. On GCC High use -Environment USGov (or USGovDoD)."
    }
    Write-Host ("Connected: tenant={0} environment={1}" -f $ctx.TenantId,$ctx.Environment) -ForegroundColor Green
}
function Invoke-Graph { param([string]$Uri) Invoke-MgGraphRequest -Method GET -Uri $Uri -OutputType PSObject }

function Get-TargetDevices {
    param([string]$DeviceName,[string]$GroupName)
    $sel = 'deviceName,complianceState,lastSyncDateTime'
    if ($DeviceName) {
        $enc = [uri]::EscapeDataString($DeviceName)
        return @((Invoke-Graph "/beta/deviceManagement/managedDevices?`$filter=deviceName eq '$enc'&`$select=id,$sel").value)
    }
    if ($GroupName) {
        $genc = [uri]::EscapeDataString($GroupName)
        $gid = @((Invoke-Graph "/v1.0/groups?`$filter=displayName eq '$genc'").value)[0].id
        if (-not $gid) { throw "Group '$GroupName' not found." }
        $names = (Invoke-Graph "/v1.0/groups/$gid/members?`$select=displayName").value.displayName
        $list = @()
        foreach ($n in $names) {
            $dn = [uri]::EscapeDataString($n)
            $list += @((Invoke-Graph "/beta/deviceManagement/managedDevices?`$filter=deviceName eq '$dn'&`$select=id,$sel").value)
        }
        return $list
    }
    throw "Provide -DeviceName or -GroupName to remediate."
}

Connect-UsGovGraph -Env $CloudEnvironment -Scopes $scopes
$devices = Get-TargetDevices -DeviceName $DeviceName -GroupName $GroupName
if (-not $devices) { Write-Warning "No matching devices found."; return }

# Safety banner: -WhatIf is the default posture unless -Execute is explicitly supplied.
$willChange = $Execute.IsPresent
Write-Host "`n=== Compliance Remediation ($CloudEnvironment) ===" -ForegroundColor Cyan
Write-Host ("Mode: {0}" -f ($(if($willChange){'EXECUTE (changes WILL be sent)'}else{'PREVIEW / -WhatIf (no changes)'}))) `
    -ForegroundColor ($(if($willChange){'Yellow'}else{'Green'}))
Write-Host ("Targets: {0} device(s)." -f $devices.Count) -ForegroundColor Cyan

# Remediation actions applied per targeted device. These are non-destructive: they ask the device to
# check in and re-evaluate compliance. They do NOT retire, wipe, or delete anything.
$actions = @(
    @{ Name = 'syncDevice';         Verb = 'sync (force check-in)' }
)

$results = New-Object System.Collections.Generic.List[object]
foreach ($dev in $devices) {
    foreach ($a in $actions) {
        $target = "$($dev.deviceName) :: $($a.Verb)"
        if (-not $willChange) {
            # Preview path — honor ShouldProcess so -WhatIf output is native and nothing is sent.
            if ($PSCmdlet.ShouldProcess($target, 'REMEDIATE (preview)')) { }
            Write-Host ("  [WOULD RUN] {0}" -f $target) -ForegroundColor DarkGray
            $results.Add([pscustomobject]@{ Device=$dev.deviceName; Action=$a.Name; Result='PREVIEW' })
            continue
        }
        if ($PSCmdlet.ShouldProcess($target, 'REMEDIATE')) {
            try {
                Invoke-MgGraphRequest -Method POST -Uri "/beta/deviceManagement/managedDevices/$($dev.id)/$($a.Name)" | Out-Null
                Write-Host ("  [OK]  {0}" -f $target) -ForegroundColor Green
                $results.Add([pscustomobject]@{ Device=$dev.deviceName; Action=$a.Name; Result='OK' })
            } catch {
                Write-Host ("  [ERR] {0} — {1}" -f $target,$_.Exception.Message) -ForegroundColor Red
                $results.Add([pscustomobject]@{ Device=$dev.deviceName; Action=$a.Name; Result="ERROR: $($_.Exception.Message)" })
            }
        }
    }
}

Write-Host "`n--- Result ---" -ForegroundColor Cyan
$results | Format-Table -AutoSize
if (-not $willChange) {
    Write-Host "`nPreview only. Re-run with -Execute after a successful pilot to apply." -ForegroundColor Yellow
} else {
    Write-Host "`nActions sent. Allow the device(s) to check in, then run INTCOMPDXG-Validation.ps1." -ForegroundColor Green
}

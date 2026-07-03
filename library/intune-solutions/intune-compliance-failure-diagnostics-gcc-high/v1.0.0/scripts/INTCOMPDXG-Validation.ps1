<#
.SYNOPSIS
    INTCOMPDXG-Validation.ps1 — pass/fail a device against its assigned compliance policy on GCC High.
.DESCRIPTION
    PURPOSE
        Read-only. After you apply a fix, confirms a specific device (or the devices in a group) now
        meets each assigned compliance policy, and lists any setting still failing. Use this as the
        Validate step of the Playbook before expanding a fix.
        Pass -DeviceName 'your-device-name' (or -GroupName 'your-group-name').
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\INTCOMPDXG-Validation.ps1 -DeviceName your-device-name
        (Graph scopes: DeviceManagementManagedDevices.Read.All, DeviceManagementConfiguration.Read.All;
         connects with -Environment USGov. For DoD tenants pass -CloudEnvironment USGovDoD.)
    EXPECTED RESULTS
        Per device: an overall PASS (Compliant) / FAIL verdict and, on FAIL, the specific setting
        states still failing. A device that just became compliant may need a reboot + sync first
        (especially DHA-backed BitLocker/Secure Boot/Code Integrity rules).
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding()]
param(
    [string]$DeviceName,
    [string]$GroupName,
    [ValidateSet('USGov','USGovDoD')][string]$CloudEnvironment = 'USGov'
)

$ErrorActionPreference = 'Stop'
$scopes = @('DeviceManagementManagedDevices.Read.All','DeviceManagementConfiguration.Read.All','Group.Read.All')

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
    if ($DeviceName) {
        $enc = [uri]::EscapeDataString($DeviceName)
        return @((Invoke-Graph "/beta/deviceManagement/managedDevices?`$filter=deviceName eq '$enc'").value)
    }
    if ($GroupName) {
        $genc = [uri]::EscapeDataString($GroupName)
        $gid = @((Invoke-Graph "/v1.0/groups?`$filter=displayName eq '$genc'").value)[0].id
        if (-not $gid) { throw "Group '$GroupName' not found." }
        $members = Invoke-Graph "/v1.0/groups/$gid/members?`$select=displayName"
        $list = @()
        foreach ($m in $members.value) {
            $dn = [uri]::EscapeDataString($m.displayName)
            $list += @((Invoke-Graph "/beta/deviceManagement/managedDevices?`$filter=deviceName eq '$dn'").value)
        }
        return $list
    }
    throw "Provide -DeviceName or -GroupName to validate."
}

Connect-UsGovGraph -Env $CloudEnvironment -Scopes $scopes
$devices = Get-TargetDevices -DeviceName $DeviceName -GroupName $GroupName
if (-not $devices) { Write-Warning "No matching devices found."; return }

Write-Host "`n=== Compliance Validation ($CloudEnvironment) — $($devices.Count) device(s) ===" -ForegroundColor Cyan
$summary = New-Object System.Collections.Generic.List[object]

foreach ($dev in $devices) {
    $overall = $dev.complianceState
    $verdict = if ($overall -eq 'compliant') { 'PASS' } else { 'FAIL' }
    Write-Host ("`n[{0}] {1} — overall state: {2} (last check-in {3})" -f $verdict,$dev.deviceName,$overall,$dev.lastSyncDateTime) `
        -ForegroundColor ($(if($verdict -eq 'PASS'){'Green'}else{'Yellow'}))

    $failing = @()
    if ($verdict -eq 'FAIL') {
        try {
            $states = Invoke-Graph "/beta/deviceManagement/managedDevices/$($dev.id)/deviceCompliancePolicyStates"
            foreach ($s in $states.value | Where-Object { $_.state -ne 'compliant' }) {
                $failing += $s.displayName
                Write-Host ("    - failing: {0} = {1}" -f $s.displayName,$s.state) -ForegroundColor Yellow
            }
        } catch {
            Write-Host ("    - could not read setting states: {0}" -f $_.Exception.Message) -ForegroundColor DarkYellow
        }
    }

    $summary.Add([pscustomobject]@{
        Device      = $dev.deviceName
        Verdict     = $verdict
        State       = $overall
        LastCheckIn = $dev.lastSyncDateTime
        Failing     = ($failing -join '; ')
    })
}

Write-Host "`n--- Summary ---" -ForegroundColor Cyan
$summary | Format-Table -AutoSize
$pass = @($summary | Where-Object Verdict -eq 'PASS').Count
Write-Host ("Validation: {0}/{1} device(s) Compliant." -f $pass,$summary.Count) -ForegroundColor ($(if($pass -eq $summary.Count){'Green'}else{'Yellow'}))
Write-Host "For DHA-backed rules (BitLocker/Secure Boot/Code Integrity), a device must have rebooted + synced. Verify for GCC High if a rule uses an expanded DHA capability." -ForegroundColor DarkCyan

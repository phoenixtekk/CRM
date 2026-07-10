<#
.SYNOPSIS
    AVDDEP-Validate.ps1 — Validate the built AVD estate against the deployment gates (image provenance, host health, FSLogix, RBAC, scaling).
.DESCRIPTION
    PURPOSE
        Read-only pass/fail checks that map to the Testing guide (05-testing.md): every session host in
        the target host pool traces to the expected gallery image version; hosts are Available with a
        healthy agent; FSLogix registry points at the profile share; RBAC on the host pool uses the
        Desktop Virtualization roles; and a scaling plan is assigned. Prints PASS/FAIL per check.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AVDDEP-Validate.ps1 `
            -ResourceGroupName 'AVD - Resource Group - Core' `
            -HostPoolName 'AVD - Host Pool - Pilot' `
            -ExpectedImageVersion '1.0.0' `
            -ExpectedProfileUnc '\\avdprofilescore.file.core.windows.net\profiles'
        Requires Az.Accounts, Az.DesktopVirtualization, Az.Resources. FSLogix registry checks that
        include remote hosts require WinRM to the session hosts; otherwise run the FSLogix section
        locally on a host. Read-only.
    EXPECTED RESULTS
        A PASS/FAIL line per gate. Any FAIL points back to the matching step in 03-implementation.md.
.NOTES
    Azure Solutions — Azure Virtual Desktop (deployment/image/FSLogix/scaling). Read-only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$HostPoolName,
    [string]$ExpectedImageVersion = '1.0.0',
    [string]$ExpectedProfileUnc   = '',
    [string[]]$SessionHostComputerNames = @()
)

foreach ($m in 'Az.Accounts','Az.DesktopVirtualization','Az.Resources') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module $m -Scope CurrentUser -Force -AllowClobber }
    Import-Module $m -ErrorAction Stop
}
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }

function Write-Result([string]$name,[bool]$ok,[string]$detail) {
    $tag = if ($ok) { 'PASS' } else { 'FAIL' }
    $col = if ($ok) { 'Green' } else { 'Red' }
    Write-Host ("[{0}] {1} — {2}" -f $tag, $name, $detail) -ForegroundColor $col
}

Write-Host "`n=== AVD deployment validation: $HostPoolName ===" -ForegroundColor Cyan

# --- Gate: session hosts present and Available (Test 3) ---
$hosts = @(Get-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -ErrorAction SilentlyContinue)
if (-not $hosts) { Write-Result 'Session hosts present' $false 'no session hosts found in the host pool'; return }
$available = @($hosts | Where-Object { $_.Status -eq 'Available' })
Write-Result 'Session hosts Available (T3)' ($available.Count -eq $hosts.Count) ("{0}/{1} Available" -f $available.Count, $hosts.Count)

# --- Gate: image provenance (Test 2) ---
foreach ($h in $hosts) {
    $vmName = ($h.Name -split '/')[-1] -replace '\..*$',''
    $vm = Get-AzVM -Name $vmName -ErrorAction SilentlyContinue
    $imgId = $vm.StorageProfile.ImageReference.Id
    $exactVer = $vm.StorageProfile.ImageReference.ExactVersion
    $match = ($imgId -match 'galleries' ) -and ($exactVer -like "*$ExpectedImageVersion*" -or $imgId -like "*$ExpectedImageVersion*")
    Write-Result ("Image provenance (T2): {0}" -f $vmName) $match ("gallery image: {0}; exactVersion: {1}" -f ($imgId -ne $null), $exactVer)
}

# --- Gate: RBAC least-privilege on the host pool (Test 5) ---
$hp = Get-AzWvdHostPool -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -ErrorAction SilentlyContinue
if ($hp) {
    $ra = Get-AzRoleAssignment -Scope $hp.Id -ErrorAction SilentlyContinue
    $broad = @($ra | Where-Object { $_.RoleDefinitionName -in @('Owner','Contributor') -and $_.Scope -notlike "*$($hp.Id)*" })
    $dv    = @($ra | Where-Object { $_.RoleDefinitionName -like 'Desktop Virtualization*' })
    Write-Result 'RBAC uses Desktop Virtualization roles (T5)' ($dv.Count -gt 0) ("{0} Desktop Virtualization assignment(s); {1} broad Owner/Contributor at higher scope" -f $dv.Count, $broad.Count)
}

# --- Gate: scaling plan assigned (Test 6) ---
$plans = @(Get-AzWvdScalingPlan -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue |
           Where-Object { $_.HostPoolReference.HostPoolArmPath -like "*$HostPoolName*" -and $_.HostPoolReference.ScalingPlanEnabled })
Write-Result 'Scaling plan enabled & assigned (T6)' ($plans.Count -gt 0) ("{0} enabled plan(s) targeting this host pool" -f $plans.Count)

# --- Gate: FSLogix configuration on hosts (Test 4) ---
if ($SessionHostComputerNames.Count -gt 0) {
    foreach ($cn in $SessionHostComputerNames) {
        try {
            $reg = Invoke-Command -ComputerName $cn -ErrorAction Stop -ScriptBlock {
                $p = 'HKLM:\SOFTWARE\FSLogix\Profiles'
                if (Test-Path $p) { Get-ItemProperty $p | Select-Object Enabled, VHDLocations } else { $null }
            }
            $ok = $reg -and $reg.Enabled -eq 1 -and ($ExpectedProfileUnc -eq '' -or $reg.VHDLocations -contains $ExpectedProfileUnc -or $reg.VHDLocations -like "*$ExpectedProfileUnc*")
            Write-Result ("FSLogix config (T4): {0}" -f $cn) $ok ("Enabled={0}; VHDLocations={1}" -f $reg.Enabled, ($reg.VHDLocations -join ','))
        } catch {
            Write-Result ("FSLogix config (T4): {0}" -f $cn) $false "could not reach host via WinRM — run the FSLogix check locally on the host"
        }
    }
} else {
    Write-Host "[SKIP] FSLogix config (T4) — pass -SessionHostComputerNames to check the registry remotely, or run on a host." -ForegroundColor Yellow
}

Write-Host "`nValidation complete. Resolve any FAIL before expanding to production." -ForegroundColor Green

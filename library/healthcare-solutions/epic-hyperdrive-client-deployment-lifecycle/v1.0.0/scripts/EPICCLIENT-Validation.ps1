<#
.SYNOPSIS
    EPICCLIENT-Validation.ps1 — Confirms a device has the target Epic client version and launch prerequisites.

.DESCRIPTION
    PURPOSE
        Validates, on a pilot/broad device, that (1) the Epic client is installed, (2) the installed
        version matches the TARGET version you pinned in the Intune detection rule, (3) the device is
        Intune-managed/Entra-joined, and (4) launch prerequisites are present (the Edge WebView2
        runtime for Hyperdrive). Emits PASS/FAIL per check and an overall PROVISIONED / NOT
        PROVISIONED verdict. Run after Implementation Step 12 (pilot) and after each ring/lifecycle
        change. Read-only.

    HOW TO RUN
        On the device, in a normal PowerShell window. Supply your Epic build team's values:
            powershell -ExecutionPolicy Bypass -File .\EPICCLIENT-Validation.ps1 `
                -InstallDir "C:\Program Files\Epic" -Exe "Hyperdrive.exe" -TargetVersion "10.x.x" -Client Hyperdrive
        For the legacy client use -Client Hyperspace (WebView2 check is skipped).

    EXPECTED RESULTS
        A PASS/FAIL list and an overall verdict. A PROVISIONED device shows the target version
        installed, MDM enrollment present, and (Hyperdrive) WebView2 present. If NOT PROVISIONED, run
        EPICCLIENT-Remediation.ps1, confirm the app shows Installed in Intune, then re-test.

.NOTES
    Healthcare Solutions — read-only. Makes no changes. Reports device/app state only; never captures
    patient data.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InstallDir,
    [Parameter(Mandatory)][string]$Exe,
    [Parameter(Mandatory)][string]$TargetVersion,
    [ValidateSet('Hyperdrive','Hyperspace')][string]$Client = 'Hyperdrive'
)

function Test-Result($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}

$results = New-Object System.Collections.Generic.List[object]
$exePath = Join-Path $InstallDir $Exe

# 1) Client installed
$installed = Test-Path $exePath
$results.Add( (Test-Result 'Epic client installed' $installed $exePath) )

# 2) Version matches target
$ver = $null
if ($installed) { try { $ver = (Get-Item $exePath).VersionInfo.ProductVersion } catch {} }
$verOk = $false
if ($ver) {
    # Compare leniently: accept exact match or installed >= target where both parse as [version].
    try { $verOk = ([version]($ver -replace '[^\d\.]','')) -ge ([version]($TargetVersion -replace '[^\d\.]','')) }
    catch { $verOk = ($ver -eq $TargetVersion) }
}
$results.Add( (Test-Result "Version matches target ($TargetVersion)" $verOk ($(if ($ver) { "installed: $ver" } else { 'no version read' }))) )

# 3) Intune MDM enrollment + Entra join
$dsreg     = (dsregcmd /status) 2>$null
$aadJoined = ($dsreg | Select-String 'AzureAdJoined\s*:\s*YES') -ne $null
$mdm       = ($dsreg | Select-String 'MdmUrl\s*:\s*http') -ne $null
$results.Add( (Test-Result 'Microsoft Entra joined' $aadJoined ($(if ($aadJoined) { 'YES' } else { 'NO' }))) )
$results.Add( (Test-Result 'Intune MDM enrolled'   $mdm       ($(if ($mdm)       { 'YES' } else { 'NO' }))) )

# 4) WebView2 runtime (Hyperdrive only)
if ($Client -eq 'Hyperdrive') {
    $wv2Roots = @(
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}',
        'HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
    )
    $wv2 = $null
    foreach ($k in $wv2Roots) { $p = Get-ItemProperty $k -ErrorAction SilentlyContinue; if ($p.pv) { $wv2 = $p.pv; break } }
    $results.Add( (Test-Result 'WebView2 runtime present' ([bool]$wv2) ($(if ($wv2) { "v$wv2" } else { 'not detected' }))) )
}

Write-Host "`n=== Epic Client Validation ($Client / $($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize

$fail    = $results | Where-Object { $_.Result -eq 'FAIL' }
$overall = $(if ($fail) { 'NOT PROVISIONED' } else { 'PROVISIONED' })
Write-Host "Overall: $overall" -ForegroundColor ($(if ($overall -eq 'PROVISIONED') { 'Green' } else { 'Yellow' }))
if ($fail) { Write-Host "Next: run EPICCLIENT-Remediation.ps1, confirm the Win32 app shows 'Installed' in Intune (correct version-pinned detection), then re-test." -ForegroundColor Yellow }

<#
.SYNOPSIS
    Report a device's Windows Protected Print mode (WPP) eligibility and current state — OS build
    (24H2+) and the WindowsProtectedPrintGroupPolicyState registry value.

.DESCRIPTION
    Reads the OS build to confirm Windows 11 24H2+ eligibility and the WPP policy registry value under
    HKLM\Software\Policies\Microsoft\Windows NT\Printers\WPP, reporting enabled / disabled / not
    configured. Use before deployment (eligibility) and after (confirm enabled).

.HOW TO RUN
    Run on a target device (locally elevated, or via Intune platform script / Proactive Remediation):
        .\WPPRINT-Get-WPPState.ps1

.EXPECTED RESULT
    OS build + edition, an eligibility verdict, and the current WPP state.

.NOTES
    Windows Ready Print / WPP deployment — read-only. Windows PowerShell 5.1+.
#>
[CmdletBinding()]
param()

$computer = $env:COMPUTERNAME
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$build = [int]($os.BuildNumber)
$caption = $os.Caption
# Windows 11 24H2 = build 26100+
$eligibleBuild = ($build -ge 26100)
$supportedEditions = @('Pro','Enterprise','Education','IoT Enterprise')
$editionOk = $false
foreach ($e in $supportedEditions) { if ($caption -match $e) { $editionOk = $true } }

Write-Host "Device : $computer" -ForegroundColor Cyan
Write-Host ("OS     : {0} (build {1})" -f $caption, $build)
Write-Host ("24H2+ eligible : {0}" -f $eligibleBuild) -ForegroundColor $(if($eligibleBuild){'Green'}else{'Yellow'})
if (-not $editionOk) { Write-Host "  NOTE: edition may be unsupported for WPP (needs Pro/Enterprise/Education/IoT Enterprise)." -ForegroundColor Yellow }

$key = 'HKLM:\Software\Policies\Microsoft\Windows NT\Printers\WPP'
$valueName = 'WindowsProtectedPrintGroupPolicyState'
$state = 'Not configured'
try {
    $item = Get-ItemProperty -Path $key -Name $valueName -ErrorAction Stop
    $raw = $item.$valueName
    switch ($raw) {
        1 { $state = 'Enabled (1)' }
        0 { $state = 'Disabled (0)' }
        default { $state = "Set (value=$raw)" }
    }
} catch {
    $state = 'Not configured (registry value absent)'
}

Write-Host ("WPP state : {0}" -f $state) -ForegroundColor $(if($state -like 'Enabled*'){'Green'}elseif($state -like 'Disabled*'){'Yellow'}else{'Gray'})

if (-not $eligibleBuild) {
    Write-Host "`nThis device is NOT 24H2+ — the ConfigureWindowsProtectedPrint policy will not apply. Exclude it via an OS-version filter." -ForegroundColor Yellow
} elseif ($state -like 'Enabled*') {
    Write-Host "`nWPP is enabled — validate printing via the IPP class driver with WPPRINT-Validate-Deployment.ps1." -ForegroundColor Green
} else {
    Write-Host "`nEligible; WPP not yet enabled. Deploy the Custom OMA-URI profile (ConfigureWindowsProtectedPrint = <enabled/>)." -ForegroundColor Cyan
}

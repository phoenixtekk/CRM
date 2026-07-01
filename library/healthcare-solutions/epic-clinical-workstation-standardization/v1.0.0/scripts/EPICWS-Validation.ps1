<#
.SYNOPSIS
    EPICWS-Validation.ps1 — Confirms a clinical workstation matches the standard: printers, default printer, peripherals, power.

.DESCRIPTION
    PURPOSE
        Validates, on a pilot/broad device, that the Epic clinical-workstation standard landed:
        (1) the device is Intune-managed / Entra-joined, (2) the unit's wristband/script/document
        printers are present, (3) the DEFAULT printer equals the expected unit default, (4) power/
        display is set to never-sleep with the agreed display timeout, and (5) the clinical peripherals
        (signature pad / scanner / badge reader) are recognized. Emits PASS/FAIL per check and an
        overall PROVISIONED / NOT PROVISIONED verdict. Run after Implementation Step 12 (pilot) and
        after each unit/change. Read-only.

    HOW TO RUN
        On the device, in a normal PowerShell window. Supply your unit's expected values:
            powershell -ExecutionPolicy Bypass -File .\EPICWS-Validation.ps1 `
                -Unit "ED" -ExpectedDefault "<UNIT_DEFAULT_PRINTER>" `
                -ExpectedPrinters "Wristband-ED","Script-ED","Doc-ED" `
                -MaxDisplayTimeoutMinutes 20

    EXPECTED RESULTS
        A PASS/FAIL list and an overall verdict. A PROVISIONED device shows MDM enrollment, the
        expected printers present, the correct default printer, never-sleep power, and recognized
        peripherals. If NOT PROVISIONED, run EPICWS-Remediation.ps1 (and re-check the Intune profile/
        printer assignments), then re-test.

.NOTES
    Healthcare Solutions — read-only. Makes no changes. Reports device/printer/app state only; never
    captures patient data.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Unit,
    [Parameter(Mandatory)][string]$ExpectedDefault,
    [string[]]$ExpectedPrinters = @(),
    [int]$MaxDisplayTimeoutMinutes = 30,
    [string]$SignaturePadLike = 'Topaz|SigLite|SigPad|Wacom|ePad',
    [string]$ScannerLike      = 'Scanner|Fujitsu|Canon DR|Kodak|TWAIN|WIA',
    [string]$BadgeReaderLike  = 'RFIDeas|pcProx|HID Global|Imprivata|OMNIKEY|proximity'
)

function Test-Result($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}

$results = New-Object System.Collections.Generic.List[object]

# 1) Intune MDM + Entra join
$dsreg     = (dsregcmd /status) 2>$null
$aadJoined = ($dsreg | Select-String 'AzureAdJoined\s*:\s*YES') -ne $null
$mdm       = ($dsreg | Select-String 'MdmUrl\s*:\s*http') -ne $null
$results.Add( (Test-Result 'Microsoft Entra joined' $aadJoined ($(if ($aadJoined) { 'YES' } else { 'NO' }))) )
$results.Add( (Test-Result 'Intune MDM enrolled'   $mdm       ($(if ($mdm)       { 'YES' } else { 'NO' }))) )

# 2) Expected printers present
$installed = @()
try { $installed = (Get-Printer -ErrorAction Stop).Name } catch {}
if ($ExpectedPrinters.Count -gt 0) {
    foreach ($p in $ExpectedPrinters) {
        $present = $installed -contains $p
        $results.Add( (Test-Result "Printer present: $p" $present ($(if ($present) { 'installed' } else { 'MISSING' }))) )
    }
} else {
    $results.Add( (Test-Result "Printers present (count)" ($installed.Count -gt 0) "$($installed.Count) printer(s); pass -ExpectedPrinters to check the unit set") )
}

# 3) Default printer = expected unit default
$default = (Get-CimInstance Win32_Printer -ErrorAction SilentlyContinue | Where-Object { $_.Default }).Name
$defOk   = ($default -eq $ExpectedDefault)
$results.Add( (Test-Result "Default printer = unit default ($ExpectedDefault)" $defOk ($(if ($default) { "is: $default" } else { '(none set)' }))) )

# 4) Power: never sleep + display timeout within max
function Get-PowerIndexMinutes($sub, $setting) {
    $q = (powercfg /q SCHEME_CURRENT $sub $setting) 2>$null | Select-String 'Current AC Power Setting Index'
    if ($q -match '0x([0-9a-fA-F]+)') { return [convert]::ToInt32($matches[1],16) / 60 }
    return $null
}
$sleepMin   = Get-PowerIndexMinutes 'SUB_SLEEP' 'STANDBYIDLE'   # 0 = never
$displayMin = Get-PowerIndexMinutes 'SUB_VIDEO' 'VIDEOIDLE'
$sleepOk    = ($sleepMin -eq 0 -or $null -eq $sleepMin -and $false) -or ($sleepMin -eq 0)
$results.Add( (Test-Result 'Power: never sleep (AC)' ($sleepMin -eq 0) ($(if ($null -ne $sleepMin) { "$sleepMin min" } else { 'unread' }))) )
$dispOk = ($null -ne $displayMin) -and ($displayMin -le $MaxDisplayTimeoutMinutes)
$results.Add( (Test-Result "Power: display timeout <= $MaxDisplayTimeoutMinutes min" $dispOk ($(if ($null -ne $displayMin) { "$displayMin min" } else { 'unread' }))) )

# 5) Peripherals recognized
function Test-Peripheral([string]$Pattern) {
    $drv = Get-CimInstance Win32_PnPSignedDriver -ErrorAction SilentlyContinue |
           Where-Object { $_.DeviceName -match $Pattern -or $_.Description -match $Pattern } | Select-Object -First 1
    $svc = Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match $Pattern -or $_.Name -match $Pattern } | Select-Object -First 1
    [bool]($drv -or $svc)
}
$results.Add( (Test-Result 'Signature pad recognized'   (Test-Peripheral $SignaturePadLike) '') )
$results.Add( (Test-Result 'Document scanner recognized' (Test-Peripheral $ScannerLike)     '') )
$results.Add( (Test-Result 'Badge/prox reader recognized' (Test-Peripheral $BadgeReaderLike) '') )

Write-Host "`n=== EPIC Clinical Workstation Validation (Unit: $Unit / $($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize

$fail    = $results | Where-Object { $_.Result -eq 'FAIL' }
$overall = $(if ($fail) { 'NOT PROVISIONED' } else { 'PROVISIONED' })
Write-Host "Overall: $overall" -ForegroundColor ($(if ($overall -eq 'PROVISIONED') { 'Green' } else { 'Yellow' }))
if ($fail) {
    Write-Host "Next: run EPICWS-Remediation.ps1, confirm the baseline profile + the unit printer policy show 'Succeeded' in Intune, then re-test. Confirm Epic queue->printer mapping with your Epic team for the clinical print tests (05-testing)." -ForegroundColor Yellow
}

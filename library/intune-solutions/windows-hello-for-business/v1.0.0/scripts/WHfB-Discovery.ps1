<#
.SYNOPSIS
    WHfB-Discovery.ps1 — Windows Hello for Business device readiness check.

.DESCRIPTION
    PURPOSE
        Reports whether the local device meets the requirements for Windows Hello for
        Business: OS version, TPM presence/readiness, Microsoft Entra join state, and
        biometric hardware. Use it before deployment to find devices that need remediation.

    HOW TO RUN
        Run on the device in a normal (non-elevated) PowerShell window:
            powershell -ExecutionPolicy Bypass -File .\WHfB-Discovery.ps1
        Optional: export a CSV row for fleet collation:
            .\WHfB-Discovery.ps1 -CsvPath C:\Temp\whfb-readiness.csv

    EXPECTED RESULTS
        A readiness summary with PASS/FAIL per check and an overall verdict. A READY device
        shows TPM 2.0 ready, supported OS, and AzureAdJoined = YES.

.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only; makes no changes.
#>
[CmdletBinding()]
param(
    [string]$CsvPath
)

function Test-Result($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = if ($Pass) { 'PASS' } else { 'FAIL' }; Detail = $Detail }
}

$results = New-Object System.Collections.Generic.List[object]

# OS version
$os  = Get-CimInstance Win32_OperatingSystem
$ver = [version]$os.Version
$osOk = $ver -ge [version]'10.0.19044'   # Win10 21H2 / Win11
$results.Add( (Test-Result 'OS supported (Win10 21H2+/Win11)' $osOk "$($os.Caption) $($os.Version)") )

# TPM
try {
    $tpm = Get-Tpm -ErrorAction Stop
    $tpmOk = $tpm.TpmPresent -and $tpm.TpmReady
    $spec = (Get-CimInstance -Namespace 'root\cimv2\security\microsofttpm' -ClassName Win32_Tpm -ErrorAction SilentlyContinue).SpecVersion
    $results.Add( (Test-Result 'TPM present and ready' $tpmOk "Present=$($tpm.TpmPresent) Ready=$($tpm.TpmReady) Spec=$spec") )
} catch {
    $results.Add( (Test-Result 'TPM present and ready' $false "Get-Tpm failed: $($_.Exception.Message)") )
}

# Entra join state
$dsreg = (dsregcmd /status) 2>$null
$aadJoined = ($dsreg | Select-String 'AzureAdJoined\s*:\s*YES') -ne $null
$domainJoined = ($dsreg | Select-String 'DomainJoined\s*:\s*YES') -ne $null
$joinDetail = if ($aadJoined -and $domainJoined) { 'Hybrid joined' } elseif ($aadJoined) { 'Entra joined (cloud)' } else { 'Not Entra joined' }
$results.Add( (Test-Result 'Microsoft Entra joined' $aadJoined $joinDetail) )

# Biometric hardware (informational — PIN works without it)
$bio = Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue | Where-Object { $_.PNPClass -eq 'Biometric' }
$results.Add( (Test-Result 'Biometric hardware (optional)' ([bool]$bio) (($bio.Name -join '; '))) )

# Output
Write-Host "`n=== Windows Hello for Business — Readiness ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize

$blocking = $results | Where-Object { $_.Check -notmatch 'optional' -and $_.Result -eq 'FAIL' }
$overall = if ($blocking) { 'NOT READY' } else { 'READY' }
Write-Host "Overall: $overall" -ForegroundColor ($(if ($overall -eq 'READY') { 'Green' } else { 'Yellow' }))

if ($CsvPath) {
    $row = [pscustomobject]@{
        ComputerName = $env:COMPUTERNAME
        Overall      = $overall
        OS           = "$($os.Caption) $($os.Version)"
        JoinState    = $joinDetail
        Timestamp    = (Get-Date).ToString('s')
    }
    $row | Export-Csv -Path $CsvPath -NoTypeInformation -Append
    Write-Host "Appended readiness row to $CsvPath"
}

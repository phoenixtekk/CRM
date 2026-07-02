<#
.SYNOPSIS
    EPM-Validation.ps1 — Confirms Endpoint Privilege Management is deployed and healthy.

.DESCRIPTION
    PURPOSE
        Validates, on a pilot/production device, that the EPM client is installed and running,
        that the device is Intune-managed and Entra joined, and that the EPM elevation context
        menu ("Run with elevated access") is available — i.e. the base policy has applied and the
        device can actually broker elevations. Run after Implementation Step 8 and after each wave.

    HOW TO RUN
        Run on the device as the signed-in user in a normal PowerShell window:
            powershell -ExecutionPolicy Bypass -File .\EPM-Validation.ps1

    EXPECTED RESULTS
        A PASS/FAIL list and an overall PROVISIONED / NOT PROVISIONED verdict. A PROVISIONED
        device shows the EPM client running, MDM enrollment present, and the elevation shell
        extension registered. If NOT PROVISIONED, run EPM-Remediation.ps1 and re-test.

.NOTES
    White-label — Intune Solutions. Read-only; makes no changes.
#>
[CmdletBinding()]
param()

function Test-Result($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = if ($Pass) { 'PASS' } else { 'FAIL' }; Detail = $Detail }
}

$results = New-Object System.Collections.Generic.List[object]

# EPM client install
$agentPath = Join-Path $env:ProgramFiles 'Microsoft EPM Agent'
$agentInstalled = Test-Path $agentPath
$results.Add( (Test-Result 'EPM client installed' $agentInstalled $agentPath) )

# EPM client service
$svc = Get-Service -Name 'EPMAgent','EpmService' -ErrorAction SilentlyContinue | Select-Object -First 1
$svcOk = $svc -and $svc.Status -eq 'Running'
$results.Add( (Test-Result 'EPM client service running' $svcOk ($(if ($svc) { "$($svc.Name) = $($svc.Status)" } else { 'service not found' }))) )

# Intune MDM enrollment
$dsreg = (dsregcmd /status) 2>$null
$aadJoined = ($dsreg | Select-String 'AzureAdJoined\s*:\s*YES') -ne $null
$mdm = ($dsreg | Select-String 'MdmUrl\s*:\s*http') -ne $null
$results.Add( (Test-Result 'Microsoft Entra joined' $aadJoined ($(if ($aadJoined) { 'YES' } else { 'NO' }))) )
$results.Add( (Test-Result 'Intune MDM enrolled' $mdm ($(if ($mdm) { 'YES' } else { 'NO' }))) )

# Elevation shell extension registered ("Run with elevated access")
# EPM registers a shell verb/context-menu handler; check for the EPM elevation client binary + a registered handler key.
$elevClient = Get-ChildItem -Path $agentPath -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match 'elev|EPM.*Client|PrivilegeManagement' } | Select-Object -First 1
$verbRegistered = $false
foreach ($root in @('HKLM:\SOFTWARE\Classes\*\shell','HKLM:\SOFTWARE\Classes\exefile\shell')) {
    if (Get-ChildItem $root -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match 'EPM|ElevatedAccess|elevation' }) { $verbRegistered = $true }
}
$extOk = [bool]$elevClient -or $verbRegistered
$results.Add( (Test-Result 'Elevation extension present' $extOk ($(if ($elevClient) { $elevClient.Name } elseif ($verbRegistered) { 'shell verb registered' } else { 'not detected' }))) )

# Output
Write-Host "`n=== EPM Validation ($($env:COMPUTERNAME) / $($env:USERNAME)) ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize

$fail = $results | Where-Object { $_.Result -eq 'FAIL' }
$overall = if ($fail) { 'NOT PROVISIONED' } else { 'PROVISIONED' }
Write-Host "Overall: $overall" -ForegroundColor ($(if ($overall -eq 'PROVISIONED') { 'Green' } else { 'Yellow' }))
if ($fail) { Write-Host "Next: run EPM-Remediation.ps1, confirm the EPM license is assigned and the base policy shows 'Succeeded' in Intune, then re-test." -ForegroundColor Yellow }

<#
.SYNOPSIS
    EPM-Discovery.ps1 — Endpoint Privilege Management device readiness check.

.DESCRIPTION
    PURPOSE
        Reports whether the local device is ready for Microsoft Intune Endpoint Privilege
        Management: OS version, Microsoft Entra join / Intune enrollment state, the EPM client
        (elevation extension) install and service health, and which accounts currently hold
        local administrator rights. Run it before and during deployment to find devices that
        need remediation and to confirm the client landed.

    HOW TO RUN
        Run on the device in a normal (non-elevated) PowerShell window:
            powershell -ExecutionPolicy Bypass -File .\EPM-Discovery.ps1
        Optional: export a CSV row for fleet collation:
            .\EPM-Discovery.ps1 -CsvPath C:\Temp\epm-readiness.csv

    EXPECTED RESULTS
        A readiness summary with PASS/FAIL per check and an overall verdict. A READY device
        shows a supported OS, AzureAdJoined = YES, and the EPM Agent service present and running
        once the base policy has applied. The local-administrators list is informational — the
        goal state is that everyday users are NOT in it.

.NOTES
    White-label — Intune Solutions. Read-only; makes no changes.
#>
[CmdletBinding()]
param(
    [string]$CsvPath
)

function Test-Result($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = if ($Pass) { 'PASS' } else { 'FAIL' }; Detail = $Detail }
}

$results = New-Object System.Collections.Generic.List[object]

# OS version (Win10 supported builds / Win11)
$os  = Get-CimInstance Win32_OperatingSystem
$ver = [version]$os.Version
$osOk = $ver -ge [version]'10.0.19044'   # Win10 21H2 / Win11
$results.Add( (Test-Result 'OS supported (Win10 21H2+/Win11)' $osOk "$($os.Caption) $($os.Version)") )

# Microsoft Entra join / device state
$dsreg = (dsregcmd /status) 2>$null
$aadJoined = ($dsreg | Select-String 'AzureAdJoined\s*:\s*YES') -ne $null
$domainJoined = ($dsreg | Select-String 'DomainJoined\s*:\s*YES') -ne $null
$joinDetail = if ($aadJoined -and $domainJoined) { 'Hybrid joined' } elseif ($aadJoined) { 'Entra joined (cloud)' } else { 'Not Entra joined' }
$results.Add( (Test-Result 'Microsoft Entra joined' $aadJoined $joinDetail) )

# Intune MDM enrollment (presence of the enrollment account certificate / MDM URL)
$mdm = ($dsreg | Select-String 'MdmUrl\s*:\s*http') -ne $null
$results.Add( (Test-Result 'Intune MDM enrolled' $mdm (if ($mdm) { 'MDM enrollment detected' } else { 'No MDM enrollment detected' })) )

# EPM client (elevation extension) install
$agentPath = Join-Path $env:ProgramFiles 'Microsoft EPM Agent'
$agentInstalled = Test-Path $agentPath
$results.Add( (Test-Result 'EPM client installed' $agentInstalled $agentPath) )

# EPM client service health (service name has varied: EPMAgent / EpmService)
$svc = Get-Service -Name 'EPMAgent','EpmService' -ErrorAction SilentlyContinue | Select-Object -First 1
$svcOk = $svc -and $svc.Status -eq 'Running'
$svcDetail = if ($svc) { "$($svc.Name) = $($svc.Status)" } else { 'EPM service not found (base policy may not have applied yet)' }
$results.Add( (Test-Result 'EPM client service running' $svcOk $svcDetail) )

# Local administrators (informational — goal is everyday users are NOT here)
try {
    $admins = (Get-LocalGroupMember -Group 'Administrators' -ErrorAction Stop | ForEach-Object { $_.Name }) -join '; '
} catch {
    $admins = (net localgroup administrators) 2>$null | Where-Object { $_ -and $_ -notmatch 'command completed|^Members|^-|^Alias|^Comment' } | Out-String
    $admins = ($admins -split "`r?`n" | Where-Object { $_.Trim() }) -join '; '
}
$results.Add( (Test-Result 'Local administrators (informational)' $true $admins) )

# Output
Write-Host "`n=== Endpoint Privilege Management — Readiness ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize

# Blocking = non-informational FAILs (the EPM service can be expected-missing pre-policy, so warn not fail)
$blocking = $results | Where-Object { $_.Check -notmatch 'informational' -and $_.Check -ne 'EPM client service running' -and $_.Check -ne 'EPM client installed' -and $_.Result -eq 'FAIL' }
$clientPending = -not $agentInstalled -or -not $svcOk
$overall = if ($blocking) { 'NOT READY' } elseif ($clientPending) { 'READY (EPM client pending policy)' } else { 'READY' }
Write-Host "Overall: $overall" -ForegroundColor ($(if ($overall -eq 'READY') { 'Green' } else { 'Yellow' }))

if ($CsvPath) {
    $row = [pscustomobject]@{
        ComputerName   = $env:COMPUTERNAME
        Overall        = $overall
        OS             = "$($os.Caption) $($os.Version)"
        JoinState      = $joinDetail
        EpmInstalled   = $agentInstalled
        EpmService     = $svcDetail
        Timestamp      = (Get-Date).ToString('s')
    }
    $row | Export-Csv -Path $CsvPath -NoTypeInformation -Append
    Write-Host "Appended readiness row to $CsvPath"
}

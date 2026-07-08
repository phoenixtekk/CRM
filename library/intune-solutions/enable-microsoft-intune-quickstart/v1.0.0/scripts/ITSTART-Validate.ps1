<#
.SYNOPSIS
    ITSTART-Validate.ps1 — scores the Intune enablement against the Quick-Start success criteria.
.DESCRIPTION
    PURPOSE
        Read-only PASS/FAIL scorecard: MDM authority = Intune, Apple push certificate valid, Windows
        auto-enrollment scoped, baseline compliance policies assigned, and at least one Windows and one
        iOS device enrolled and compliant.
    HOW TO RUN
        Connect-MgGraph -Scopes "DeviceManagementServiceConfig.Read.All","DeviceManagementConfiguration.Read.All","DeviceManagementManagedDevices.Read.All","Directory.Read.All"
        .\ITSTART-Validate.ps1
    EXPECTED RESULTS
        All checks PASS when the Quick-Start is complete. Any FAIL names the step to revisit.
.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()] param()

function V($n,$ok,$d){ [pscustomobject]@{ Criterion=$n; Result=$(if($ok){'PASS'}else{'FAIL'}); Detail=$d } }
$r = New-Object System.Collections.Generic.List[object]
if (-not (Get-MgContext)) { Write-Host 'Not connected. Run Connect-MgGraph first (see .SYNOPSIS).' -ForegroundColor Yellow; return }

try { $auth = (Invoke-MgGraphRequest -Method GET -Uri 'v1.0/organization?$select=mobileDeviceManagementAuthority').value[0].mobileDeviceManagementAuthority }
catch { $auth = 'unknown' }
$r.Add( (V 'MDM authority = Intune' ($auth -eq 'intune') "authority=$auth (implementation Step 3)") )

try { $apns = Invoke-MgGraphRequest -Method GET -Uri 'v1.0/deviceManagement/applePushNotificationCertificate'; $valid = ([datetime]$apns.expirationDateTime -gt (Get-Date)) }
catch { $valid = $false }
$r.Add( (V 'Apple MDM push certificate valid' $valid $(if($valid){"expires $(([datetime]$apns.expirationDateTime).ToString('yyyy-MM-dd'))"}else{'missing/expired (implementation Step 4)'})) )

try { $mob = (Invoke-MgGraphRequest -Method GET -Uri "v1.0/policies/mobileDeviceManagementPolicies?`$select=displayName,appliesTo").value | Where-Object displayName -match 'Intune' | Select-Object -First 1; $winauto = $mob.appliesTo -in @('all','selected') }
catch { $winauto = $false }
$r.Add( (V 'Windows automatic enrollment enabled' $winauto "appliesTo=$($mob.appliesTo) (implementation Step 7)") )

# baseline compliance policies + assignment
$assignedOk = $false
try {
    $cp = (Invoke-MgGraphRequest -Method GET -Uri "v1.0/deviceManagement/deviceCompliancePolicies?`$expand=assignments").value
    $base = $cp | Where-Object { $_.displayName -match 'Baseline' }
    $assignedOk = ($base.Count -ge 2) -and (($base | Where-Object { $_.assignments.Count -ge 1 }).Count -ge 2)
} catch {}
$r.Add( (V 'Baseline compliance policies assigned' $assignedOk "$($base.Count) baseline policies found (implementation Step 8)") )

# enrolled devices by platform + compliance
try {
    $dev = (Invoke-MgGraphRequest -Method GET -Uri "v1.0/deviceManagement/managedDevices?`$select=deviceName,operatingSystem,complianceState").value
    $win = $dev | Where-Object operatingSystem -match 'Windows'
    $ios = $dev | Where-Object operatingSystem -match 'iOS|iPadOS'
    $r.Add( (V 'Windows device enrolled & compliant' (($win | Where-Object complianceState -eq 'compliant').Count -ge 1) "$($win.Count) Windows enrolled") )
    $r.Add( (V 'iOS device enrolled & compliant'     (($ios | Where-Object complianceState -eq 'compliant').Count -ge 1) "$($ios.Count) iOS enrolled") )
} catch {
    $r.Add( (V 'Windows device enrolled & compliant' $false 'unable to read managed devices') )
    $r.Add( (V 'iOS device enrolled & compliant' $false 'unable to read managed devices') )
}

Write-Host "`n=== Intune Quick-Start Validation ===" -ForegroundColor Cyan
$r | Format-Table -AutoSize
$fail = ($r | Where-Object Result -eq 'FAIL').Count
Write-Host ("Overall: {0}" -f $(if($fail){"$fail criteria to complete"}else{'ALL PASS — functioning Intune'})) -ForegroundColor $(if($fail){'Yellow'}else{'Green'})

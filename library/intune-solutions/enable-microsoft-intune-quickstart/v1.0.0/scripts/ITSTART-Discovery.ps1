<#
.SYNOPSIS
    ITSTART-Discovery.ps1 — reports Intune enablement readiness for the tenant.
.DESCRIPTION
    PURPOSE
        Read-only snapshot of the tenant's Intune enablement state: MDM authority, Apple MDM push
        (APNs) certificate and expiry, Windows automatic-enrollment scope, the pilot group, and the
        baseline compliance/configuration policies this Quick-Start creates.
    HOW TO RUN
        Connect-MgGraph -Scopes "DeviceManagementServiceConfig.Read.All","DeviceManagementConfiguration.Read.All","Directory.Read.All"
        .\ITSTART-Discovery.ps1
    EXPECTED RESULTS
        A table of readiness facts with OK / CHECK flags. Nothing is changed.
.NOTES
    White-label — Intune Solutions. Read-only. Requires the Microsoft.Graph modules.
#>
[CmdletBinding()] param(
    [string]$PilotGroup = 'INTUNE - QuickStart - Pilot'
)

function Row($n,$ok,$d){ [pscustomobject]@{ Check=$n; Status=$(if($ok){'OK'}else{'CHECK'}); Detail=$d } }
$out = New-Object System.Collections.Generic.List[object]

if (-not (Get-MgContext)) { Write-Host 'Not connected. Run Connect-MgGraph first (see .SYNOPSIS).' -ForegroundColor Yellow; return }

# MDM authority
try {
    $org = Invoke-MgGraphRequest -Method GET -Uri 'v1.0/organization?$select=mobileDeviceManagementAuthority'
    $auth = $org.value[0].mobileDeviceManagementAuthority
    $out.Add( (Row 'MDM authority' ($auth -eq 'intune') "authority = $auth") )
} catch { $out.Add( (Row 'MDM authority' $false "unable to read: $($_.Exception.Message)") ) }

# Apple MDM push certificate
try {
    $apns = Invoke-MgGraphRequest -Method GET -Uri 'v1.0/deviceManagement/applePushNotificationCertificate'
    $exp  = [datetime]$apns.expirationDateTime
    $days = [int]([math]::Round(($exp - (Get-Date)).TotalDays))
    $out.Add( (Row 'Apple MDM push certificate' ($days -gt 0) "AppleID=$($apns.appleIdentifier); expires $($exp.ToString('yyyy-MM-dd')) ($days days)") )
    if ($days -le 30 -and $days -gt 0) { Write-Host "  ! APNs certificate expires in $days days — renew with the SAME Apple ID." -ForegroundColor Yellow }
} catch { $out.Add( (Row 'Apple MDM push certificate' $false 'not configured — Apple enrollment will fail until added') ) }

# Windows automatic-enrollment configuration presence (mobility/MDM)
try {
    $mob = Invoke-MgGraphRequest -Method GET -Uri "v1.0/policies/mobileDeviceManagementPolicies?`$select=displayName,appliesTo"
    $intunePol = $mob.value | Where-Object { $_.displayName -match 'Intune' } | Select-Object -First 1
    $applies = if ($intunePol){ $intunePol.appliesTo } else { 'none' }
    $out.Add( (Row 'Windows auto-enrollment (MDM user scope)' ($applies -in @('all','selected')) "appliesTo = $applies") )
} catch { $out.Add( (Row 'Windows auto-enrollment (MDM user scope)' $false 'unable to read mobility policy (verify permissions/endpoint)') ) }

# Pilot group
try {
    $grp = Invoke-MgGraphRequest -Method GET -Uri ("v1.0/groups?`$filter=displayName eq '{0}'" -f ($PilotGroup -replace "'","''"))
    $found = $grp.value.Count -ge 1
    $out.Add( (Row "Pilot group '$PilotGroup'" $found $(if($found){"id=$($grp.value[0].id)"}else{'not found — create per implementation Step 6'})) )
} catch { $out.Add( (Row "Pilot group '$PilotGroup'" $false 'lookup failed') ) }

# Baseline compliance policies
try {
    $cp = Invoke-MgGraphRequest -Method GET -Uri "v1.0/deviceManagement/deviceCompliancePolicies?`$select=displayName"
    $names = @($cp.value.displayName)
    $win = $names -match 'Windows.*Baseline'; $ios = $names -match 'iOS.*Baseline'
    $out.Add( (Row 'Baseline compliance policies' ($win -and $ios) "found: $([string]::Join(', ', ($names | Where-Object {$_ -match 'Baseline'})))") )
} catch { $out.Add( (Row 'Baseline compliance policies' $false 'unable to read compliance policies') ) }

Write-Host "`n=== Intune Enablement Discovery ($((Get-MgContext).TenantId)) ===" -ForegroundColor Cyan
$out | Format-Table -AutoSize
$checks = ($out | Where-Object Status -eq 'CHECK').Count
Write-Host ("Summary: {0} OK, {1} to review." -f (($out|Where-Object Status -eq 'OK').Count), $checks) -ForegroundColor $(if($checks){'Yellow'}else{'Green'})

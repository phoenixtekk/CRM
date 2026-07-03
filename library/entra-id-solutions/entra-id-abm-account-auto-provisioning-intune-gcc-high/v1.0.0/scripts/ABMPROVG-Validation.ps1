<#
.SYNOPSIS
    ABMPROVG-Validation.ps1 — read-only pass/fail validation of the ABM + Intune Government config.
.DESCRIPTION
    PURPOSE
        Validates the supported GCC High configuration against clear pass/fail criteria: US Gov
        connection, Apple MDM push certificate validity, ABM/ADE enrollment token validity and sync,
        an Automated Device Enrollment profile, and the pilot scope group assignment. It changes
        nothing. Replace sample names with your-group-name / your-profile-name values if renamed
        (defaults: ABM-Apple-Pilot-Devices, ABM-ADE-Profile-Gov).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ABMPROVG-Validation.ps1
        (Graph scopes: DeviceManagementServiceConfig.Read.All, DeviceManagementConfiguration.Read.All,
         Group.Read.All; -Environment USGov)
    EXPECTED RESULTS
        A checklist of PASS/FAIL lines and a final summary count. All PASS means the configuration is
        ready to pilot/expand. Any FAIL identifies the exact item to fix before proceeding.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string]$PilotDeviceGroup = 'ABM-Apple-Pilot-Devices',
    [string]$AdeProfileName   = 'ABM-ADE-Profile-Gov',
    [int]$ExpiryWarningDays   = 30
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]

function Add-Check {
    param([string]$Name, [bool]$Passed, [string]$Detail)
    $status = if ($Passed) { 'PASS' } else { 'FAIL' }
    $color  = if ($Passed) { 'Green' } else { 'Red' }
    Write-Host ("[{0}] {1} — {2}" -f $status, $Name, $Detail) -ForegroundColor $color
    $results.Add([pscustomobject]@{ Check = $Name; Passed = $Passed; Detail = $Detail })
}

Write-Host "=== ABMPROVG Validation (GCC High / US Gov) ===" -ForegroundColor White

# --- Connect ---
try {
    $scopes = @(
        'DeviceManagementServiceConfig.Read.All',
        'DeviceManagementConfiguration.Read.All',
        'Group.Read.All'
    )
    Connect-MgGraph -Environment USGov -Scopes $scopes -NoWelcome
    $ctx = Get-MgContext
    Add-Check 'US Gov Graph connection' ($ctx.Environment -eq 'USGov') "Environment=$($ctx.Environment), Tenant=$($ctx.TenantId)"
    if ($ctx.Environment -ne 'USGov') { Write-Host "Reconnect with -Environment USGov." -ForegroundColor Yellow; return }
}
catch {
    Add-Check 'US Gov Graph connection' $false $_.Exception.Message
    return
}

# --- APNs certificate ---
try {
    $apns = Get-MgDeviceManagementApplePushNotificationCertificate -ErrorAction Stop
    if ($apns -and $apns.AppleIdentifier) {
        $daysLeft = if ($apns.ExpirationDateTime) { [int]([datetime]$apns.ExpirationDateTime - (Get-Date)).TotalDays } else { 9999 }
        Add-Check 'Apple MDM push certificate' ($daysLeft -gt $ExpiryWarningDays) "Apple ID $($apns.AppleIdentifier); expires in $daysLeft day(s)"
    }
    else {
        Add-Check 'Apple MDM push certificate' $false 'Not configured — create in endpoint.microsoft.us'
    }
}
catch { Add-Check 'Apple MDM push certificate' $false $_.Exception.Message }

# --- ABM / ADE token ---
try {
    $tokens = Get-MgDeviceManagementDepOnboardingSetting -All -ErrorAction Stop
    if ($tokens) {
        foreach ($t in $tokens) {
            $daysLeft = if ($t.TokenExpirationDateTime) { [int]([datetime]$t.TokenExpirationDateTime - (Get-Date)).TotalDays } else { 9999 }
            $synced   = $null -ne $t.LastSuccessfulSyncDateTime
            $name = if ($t.TokenName) { $t.TokenName } else { $t.AppleIdentifier }
            Add-Check "ABM token '$name' valid" ($daysLeft -gt $ExpiryWarningDays) "expires in $daysLeft day(s)"
            Add-Check "ABM token '$name' syncing" $synced "last sync $($t.LastSuccessfulSyncDateTime)"
        }
    }
    else {
        Add-Check 'ABM / ADE enrollment token' $false 'No token — link ABM to Intune Government'
    }
}
catch { Add-Check 'ABM / ADE enrollment token' $false $_.Exception.Message }

# --- ADE profile presence ---
try {
    $tokens = Get-MgDeviceManagementDepOnboardingSetting -All -ErrorAction SilentlyContinue
    $foundProfile = $false
    foreach ($t in $tokens) {
        $uri = "https://graph.microsoft.us/beta/deviceManagement/depOnboardingSettings/$($t.Id)/enrollmentProfiles"
        try {
            $profiles = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
            if ($profiles.value | Where-Object { $_.displayName -eq $AdeProfileName }) { $foundProfile = $true }
        } catch { }
    }
    Add-Check "ADE profile '$AdeProfileName'" $foundProfile $(if ($foundProfile) { 'present' } else { "not found — create under the ABM token in endpoint.microsoft.us" })
}
catch { Add-Check "ADE profile '$AdeProfileName'" $false $_.Exception.Message }

# --- Pilot group ---
try {
    $g = Get-MgGroup -Filter "displayName eq '$PilotDeviceGroup'" -ErrorAction Stop
    if ($g) {
        $count = (Get-MgGroupMember -GroupId $g.Id -All -ErrorAction SilentlyContinue).Count
        Add-Check "Pilot group '$PilotDeviceGroup'" ($count -ge 1) "members: $count"
    }
    else {
        Add-Check "Pilot group '$PilotDeviceGroup'" $false 'not found — run ABMPROVG-Set-ScopeTargeting.ps1'
    }
}
catch { Add-Check "Pilot group '$PilotDeviceGroup'" $false $_.Exception.Message }

# --- Summary ---
$passed = ($results | Where-Object Passed).Count
$total  = $results.Count
Write-Host ("`nValidation summary: {0}/{1} checks passed." -f $passed, $total) -ForegroundColor White
if ($passed -eq $total) { Write-Host "All checks green — ready to pilot/expand." -ForegroundColor Green }
else { Write-Host "Resolve the FAIL item(s) above, then re-run." -ForegroundColor Yellow }

Write-Host "`nParity note: Entra<->ABM federation/SCIM auto-provisioning is not supported in national clouds; this validates the supported ABM<->Intune Government path only." -ForegroundColor Cyan

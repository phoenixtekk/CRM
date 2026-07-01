<#
.SYNOPSIS
    ADEMAC-Remediation.ps1 — safe remediation helpers for macOS ADE + Platform SSO.

.DESCRIPTION
    PURPOSE
        Performs the common fixes that unblock ADE/SSO: re-sync the ADE token with Apple,
        surface tokens/certificates nearing expiry, and (optionally) re-assign the macOS
        enrollment profile and Platform SSO configuration profile to a target group.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        # Read-only audit (default — makes NO changes):
        .\ADEMAC-Remediation.ps1
        # Trigger an ADE token sync and re-assignments (explicit opt-in):
        .\ADEMAC-Remediation.ps1 -Apply -GroupId <entra-group-object-id> -SsoPolicyId <id> -EnrollmentProfileId <id>

    EXPECTED RESULTS
        Without -Apply: an audit of token/cert expiry and what WOULD be done.
        With -Apply: a token sync is requested and the named profiles are assigned to the group.

.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Defaults to read-only; changes require -Apply.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Apply,
    [string]$GroupId,
    [string]$SsoPolicyId,
    [string]$EnrollmentProfileId
)

$ErrorActionPreference = 'Stop'
$scopes = if ($Apply) { 'DeviceManagementServiceConfig.ReadWrite.All','DeviceManagementConfiguration.ReadWrite.All' }
          else        { 'DeviceManagementServiceConfig.Read.All','DeviceManagementConfiguration.Read.All' }
Connect-MgGraph -Scopes $scopes | Out-Null

function DaysLeft($iso) { if (-not $iso) { return $null }; [int]([datetime]$iso - (Get-Date)).TotalDays }

# --- Expiry audit (always) ---
Write-Host '== Expiry audit ==' -ForegroundColor Cyan
try {
    $apns = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/applePushNotificationCertificate'
    $d = DaysLeft $apns.expirationDateTime
    $flag = if ($d -lt 30) { '  <-- RENEW SOON' } else { '' }
    Write-Host ("APNs certificate ({0}): {1} day(s) left{2}" -f $apns.appleIdentifier, $d, $flag)
} catch { Write-Host 'APNs certificate: not configured.' -ForegroundColor Yellow }

$tokens = @()
try {
    $dep = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/deviceManagement/depOnboardingSettings'
    $tokens = @($dep.value)
    foreach ($t in $tokens) {
        $d = DaysLeft $t.tokenExpirationDateTime
        $flag = if ($d -lt 30) { '  <-- RENEW SOON' } else { '' }
        Write-Host ("ADE token '{0}': {1} day(s) left{2}" -f $t.tokenName, $d, $flag)
    }
} catch { Write-Host 'ADE token: none / unreadable.' -ForegroundColor Yellow }

if (-not $Apply) {
    Write-Host ''
    Write-Host 'Read-only mode. Re-run with -Apply (and -GroupId / -SsoPolicyId / -EnrollmentProfileId) to make changes.' -ForegroundColor Yellow
    return
}

# --- Re-sync ADE token(s) ---
foreach ($t in $tokens) {
    if ($PSCmdlet.ShouldProcess($t.tokenName, 'Sync ADE token with Apple')) {
        try {
            Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/depOnboardingSettings/$($t.id)/syncWithAppleDeviceEnrollmentProgram" | Out-Null
            Write-Host "Synced ADE token '$($t.tokenName)'." -ForegroundColor Green
        } catch { Write-Warning "Sync failed for '$($t.tokenName)': $($_.Exception.Message)" }
    }
}

# --- Re-assign the Platform SSO settings-catalog policy to the group ---
if ($SsoPolicyId -and $GroupId -and $PSCmdlet.ShouldProcess($SsoPolicyId, "Assign SSO policy to group $GroupId")) {
    $body = @{ assignments = @(@{ target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $GroupId } }) }
    Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$SsoPolicyId/assign" -Body ($body | ConvertTo-Json -Depth 6) -ContentType 'application/json' | Out-Null
    Write-Host 'Platform SSO policy re-assigned.' -ForegroundColor Green
}

# --- Re-assign the macOS enrollment profile (set as default for the token's devices) ---
if ($EnrollmentProfileId -and $tokens.Count -gt 0 -and $PSCmdlet.ShouldProcess($EnrollmentProfileId, 'Set as default enrollment profile')) {
    foreach ($t in $tokens) {
        try {
            $body = @{ enrollmentProfileId = $EnrollmentProfileId } | ConvertTo-Json
            Invoke-MgGraphRequest -Method PUT -Uri "https://graph.microsoft.com/beta/deviceManagement/depOnboardingSettings/$($t.id)/defaultMacOsEnrollmentProfile" -Body $body -ContentType 'application/json' | Out-Null
            Write-Host "Default macOS enrollment profile set on token '$($t.tokenName)'." -ForegroundColor Green
        } catch { Write-Warning "Could not set default profile on '$($t.tokenName)': $($_.Exception.Message)" }
    }
}

Write-Host ''
Write-Host 'Remediation complete. Re-run ADEMAC-Discovery.ps1 to confirm.' -ForegroundColor Green

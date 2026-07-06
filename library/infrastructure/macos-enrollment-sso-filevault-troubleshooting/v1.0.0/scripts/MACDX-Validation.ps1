<#
.SYNOPSIS
    MACDX-Validation.ps1 — read-only per-device, per-layer state check for a macOS + Intune failure.
.DESCRIPTION
    PURPOSE
        Validates the state of one macOS device at the layer a Diagnostic Playbook branch cares
        about, so a technician can confirm what a check expects. -Check selects the layer:
        Enrollment (ADE token/profile context), Profiles (SSO app-extension and other profile
        states), FileVault (disk-encryption profile state + personal recovery-key escrow), or
        Compliance (named non-compliant settings). Read-only: it never changes the tenant.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MACDX-Validation.ps1 -DeviceName device-name-or-serial -Check Profiles
        powershell -ExecutionPolicy Bypass -File .\MACDX-Validation.ps1 -DeviceName device-name-or-serial -Check FileVault

        Required Graph scopes (read-only):
            DeviceManagementManagedDevices.Read.All
            DeviceManagementConfiguration.Read.All
            DeviceManagementServiceConfig.Read.All
    EXPECTED RESULTS
        A per-device summary for the selected layer that matches the Intune portal for a pilot
        device. PASS when the reported state agrees with the portal; FAIL if scopes are missing or
        the device is not found. Pair it with the on-Mac command for that layer (see the Playbook).
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding()]
param(
    # Device name or serial to validate (substring match). Required.
    [Parameter(Mandatory = $true)]
    [string]$DeviceName,

    # Which layer to validate. Defaults to a full pass across all layers.
    [ValidateSet('All', 'Enrollment', 'Profiles', 'FileVault', 'Compliance')]
    [string]$Check = 'All',

    # Optional tenant id, e.g. your-tenant-id. Leave blank for interactive/default tenant.
    [string]$TenantId
)

$ErrorActionPreference = 'Stop'

$RequiredScopes = @(
    'DeviceManagementManagedDevices.Read.All',
    'DeviceManagementConfiguration.Read.All',
    'DeviceManagementServiceConfig.Read.All'
)

function Connect-Graph {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph.Authentication is not installed. Run: Install-Module Microsoft.Graph.Authentication -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if (-not (Get-MgContext -ErrorAction SilentlyContinue)) {
        Write-Host "Connecting to Microsoft Graph (read-only scopes)..." -ForegroundColor Cyan
        if ($TenantId) { Connect-MgGraph -Scopes $RequiredScopes -TenantId $TenantId | Out-Null }
        else { Connect-MgGraph -Scopes $RequiredScopes | Out-Null }
    }
    Write-Host ("Connected as {0}." -f (Get-MgContext).Account) -ForegroundColor Green
}

function Invoke-GraphGet {
    param([string]$Uri)
    $items = @()
    $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $items += $resp.value } else { $items += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $items
}

try {
    Connect-Graph

    Write-Host ("Locating macOS device matching '{0}'..." -f $DeviceName) -ForegroundColor Cyan
    $all = Invoke-GraphGet -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'macOS'"
    $device = $all | Where-Object { $_.deviceName -like "*$DeviceName*" -or $_.serialNumber -like "*$DeviceName*" } | Select-Object -First 1

    if (-not $device) {
        Write-Warning "No macOS device matched '$DeviceName'. Confirm it is enrolled (Intune -> Devices -> macOS) and try the serial."
        exit 1
    }

    $id = $device.id
    Write-Host ""
    Write-Host "=== Device ===" -ForegroundColor Yellow
    [pscustomobject]@{
        DeviceName  = $device.deviceName
        Serial      = $device.serialNumber
        PrimaryUser = $device.userPrincipalName
        Ownership   = $device.managedDeviceOwnerType
        Enrolled    = [bool]$device.enrolledDateTime
        Compliance  = $device.complianceState
        OSVersion   = $device.osVersion
        LastCheckIn = $device.lastSyncDateTime
    } | Format-List

    # --- Enrollment / ADE token context (Branch A) ---
    if ($Check -in 'All', 'Enrollment') {
        Write-Host "=== Enrollment / ADE context (Branch A) ===" -ForegroundColor Yellow
        Write-Host ("Enrollment type: {0}   Enrolled: {1}" -f $device.deviceEnrollmentType, [bool]$device.enrolledDateTime)
        try {
            $tokens = Invoke-GraphGet -Uri "https://graph.microsoft.com/v1.0/deviceManagement/depOnboardingSettings"
            if ($tokens) {
                $tokens | ForEach-Object {
                    $exp = if ($_.tokenExpirationDateTime) { [datetime]$_.tokenExpirationDateTime } else { $null }
                    $daysLeft = if ($exp) { [math]::Round(($exp - (Get-Date)).TotalDays, 0) } else { $null }
                    [pscustomobject]@{
                        AppleId         = $_.appleIdentifier
                        TokenExpiry     = $exp
                        DaysToExpiry    = $daysLeft
                        DefaultProfile  = $_.defaultMacOsEnrollmentProfileId
                    }
                } | Format-Table -AutoSize
                if (($tokens | Where-Object { $_.tokenExpirationDateTime -and ([datetime]$_.tokenExpirationDateTime) -lt (Get-Date) })) {
                    Write-Host "WARNING: an enrollment program token is EXPIRED — all new ADE enrollments will fail until renewed." -ForegroundColor Red
                }
            }
            else { Write-Host "No enrollment program tokens found (Apple ADE may not be configured)." }
        }
        catch { Write-Host "Could not read enrollment program tokens: $($_.Exception.Message)" -ForegroundColor Yellow }
    }

    # --- Configuration profile states, incl. SSO extension (Branch B) ---
    if ($Check -in 'All', 'Profiles') {
        Write-Host "=== Configuration profile states (Branch B — SSO extension et al.) ===" -ForegroundColor Yellow
        $cfg = Invoke-GraphGet -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$id/deviceConfigurationStates"
        if ($cfg) {
            $cfg | ForEach-Object { [pscustomobject]@{ Profile = $_.displayName; State = $_.state } } | Sort-Object State | Format-Table -AutoSize
            $sso = $cfg | Where-Object { $_.displayName -match 'SSO|Single Sign|Extensible|Platform' }
            if ($sso) {
                foreach ($s in $sso) {
                    $col = if ($s.state -eq 'compliant' -or $s.state -eq 'succeeded') { 'Green' } else { 'Red' }
                    Write-Host ("SSO extension profile '{0}': {1}" -f $s.displayName, $s.state) -ForegroundColor $col
                }
            }
            else { Write-Host "No profile whose name matches SSO/Platform/Extensible — confirm the SSO app-extension profile is assigned." -ForegroundColor Yellow }
            $bad = $cfg | Where-Object { $_.state -notin 'compliant', 'succeeded', 'notApplicable' }
            if ($bad) { Write-Host ("Profiles NOT succeeded: {0}" -f (($bad.displayName) -join ', ')) -ForegroundColor Red }
        }
        else { Write-Host "No configuration profile states returned for this device." }
    }

    # --- FileVault profile state + recovery-key escrow (Branch C) ---
    if ($Check -in 'All', 'FileVault') {
        Write-Host "=== FileVault / SecureToken (Branch C) ===" -ForegroundColor Yellow
        $cfg2 = Invoke-GraphGet -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$id/deviceConfigurationStates"
        $fv = $cfg2 | Where-Object { $_.displayName -match 'FileVault|Disk [Ee]ncryption|Encryption' }
        if ($fv) {
            $fv | ForEach-Object { [pscustomobject]@{ Profile = $_.displayName; State = $_.state } } | Format-Table -AutoSize
        }
        else { Write-Host "No FileVault/Disk-encryption profile matched by name — confirm the policy is assigned to this device." -ForegroundColor Yellow }

        # Personal recovery key escrow (metadata only; the key value itself is not printed)
        try {
            $key = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$id/getFileVaultKey" -ErrorAction Stop
            if ($key) { Write-Host "Personal recovery key IS escrowed to Intune (retrievable under Recovery keys)." -ForegroundColor Green }
            else { Write-Host "No personal recovery key returned — escrow may be missing." -ForegroundColor Red }
        }
        catch {
            Write-Host "Recovery key not retrievable (not escrowed, FileVault off, or scope missing): $($_.Exception.Message)" -ForegroundColor Yellow
        }
        Write-Host "On the Mac, confirm the token: sysadminctl -secureTokenStatus theusername ; fdesetup status ; profiles status -type bootstraptoken" -ForegroundColor Cyan
    }

    # --- Compliance detail, named non-compliant settings (Branch D) ---
    if ($Check -in 'All', 'Compliance') {
        Write-Host "=== Compliance detail (Branch D) ===" -ForegroundColor Yellow
        $states = Invoke-GraphGet -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$id/deviceCompliancePolicyStates"
        if ($states) {
            $states | ForEach-Object { [pscustomobject]@{ Policy = $_.displayName; State = $_.state } } | Format-Table -AutoSize
            $bad = $states | Where-Object { $_.state -ne 'compliant' }
            if ($bad) { Write-Host ("NON-COMPLIANT: {0}" -f (($bad.displayName) -join ', ')) -ForegroundColor Red }
            else { Write-Host "All evaluated compliance policies are compliant. If access is still denied, read Entra Sign-in logs -> Conditional Access (Branch D)." -ForegroundColor Green }
        }
        else { Write-Host "No compliance policy states returned." }
    }

    Write-Host ""
    Write-Host "Validation complete. Compare the above to the Intune portal (and Entra Sign-in logs for Branch D)." -ForegroundColor Green
}
catch {
    Write-Error ("Validation failed: {0}" -f $_.Exception.Message)
    exit 1
}

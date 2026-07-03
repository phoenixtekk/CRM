<#
.SYNOPSIS
    ABMPROVG-Discovery.ps1 — read-only readiness discovery for ABM + Intune Government (GCC High).
.DESCRIPTION
    PURPOSE
        Inventories a GCC High tenant's readiness to enrol Apple devices via Apple Business Manager
        linked to Intune Government. Reports sign-in context, Apple enrollment configuration presence
        (APNs push certificate, ABM/ADE enrollment tokens), and the pilot scope groups. It never
        changes anything. Replace the sample group names with your-group-name values if you renamed
        them (defaults: ABM-Apple-Pilot-Devices, ABM-Apple-Enroll-Users).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ABMPROVG-Discovery.ps1
        (Graph scopes: DeviceManagementServiceConfig.Read.All, DeviceManagementConfiguration.Read.All,
         Group.Read.All, Organization.Read.All; -Environment USGov)
    EXPECTED RESULTS
        A section-by-section readout with PASS/WARN/INFO lines. PASS means the item is present and
        healthy; WARN flags a gap to resolve before configuring. Confirms the connection is US Gov.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string]$PilotDeviceGroup = 'ABM-Apple-Pilot-Devices',
    [string]$EnrollUserGroup   = 'ABM-Apple-Enroll-Users'
)

$ErrorActionPreference = 'Stop'

function Write-Line {
    param([string]$Status, [string]$Message)
    $color = switch ($Status) { 'PASS' {'Green'} 'WARN' {'Yellow'} 'FAIL' {'Red'} default {'Cyan'} }
    Write-Host ("[{0}] {1}" -f $Status, $Message) -ForegroundColor $color
}

Write-Host "=== ABMPROVG Discovery (GCC High / US Gov) ===" -ForegroundColor White

# --- Connect to US Gov Graph ---
try {
    $scopes = @(
        'DeviceManagementServiceConfig.Read.All',
        'DeviceManagementConfiguration.Read.All',
        'Group.Read.All',
        'Organization.Read.All'
    )
    Connect-MgGraph -Environment USGov -Scopes $scopes -NoWelcome
    $ctx = Get-MgContext
    if ($ctx.Environment -ne 'USGov') {
        Write-Line 'FAIL' "Connected environment is '$($ctx.Environment)', expected 'USGov'. Reconnect with -Environment USGov."
        return
    }
    Write-Line 'PASS' "Connected to US Gov Graph (graph.microsoft.us). Tenant: $($ctx.TenantId)"
}
catch {
    Write-Line 'FAIL' "Could not connect to Microsoft Graph US Gov: $($_.Exception.Message)"
    Write-Host "Ensure the Microsoft.Graph SDK is installed and you used -Environment USGov." -ForegroundColor Yellow
    return
}

# --- Organization / licensing signal ---
Write-Host "`n-- Organization & licensing --" -ForegroundColor White
try {
    $org = Get-MgOrganization -ErrorAction Stop | Select-Object -First 1
    Write-Line 'INFO' "Organization: $($org.DisplayName)"
    $skus = Get-MgSubscribedSku -All -ErrorAction Stop
    $govSignal = $skus | Where-Object { $_.SkuPartNumber -match 'GOV|G3|G5|INTUNE' }
    if ($govSignal) {
        foreach ($s in $govSignal) { Write-Line 'PASS' "License signal: $($s.SkuPartNumber) (consumed $($s.ConsumedUnits))" }
    }
    else {
        Write-Line 'WARN' "No obvious Government/Intune SKU found. Confirm Government licensing in portal.office365.us."
    }
}
catch {
    Write-Line 'WARN' "Could not read organization/licensing: $($_.Exception.Message)"
}

# --- Apple MDM push certificate (APNs) ---
Write-Host "`n-- Apple MDM push certificate (APNs) --" -ForegroundColor White
try {
    $apns = Get-MgDeviceManagementApplePushNotificationCertificate -ErrorAction Stop
    if ($apns -and $apns.AppleIdentifier) {
        $daysLeft = if ($apns.ExpirationDateTime) { [int]([datetime]$apns.ExpirationDateTime - (Get-Date)).TotalDays } else { $null }
        Write-Line 'PASS' "APNs present. Apple ID: $($apns.AppleIdentifier). Expires in $daysLeft day(s)."
        if ($daysLeft -ne $null -and $daysLeft -lt 30) { Write-Line 'WARN' "APNs expires in under 30 days — schedule renewal (same Apple ID)." }
    }
    else {
        Write-Line 'WARN' "No Apple MDM push certificate found. Create it in endpoint.microsoft.us before Apple enrollment."
    }
}
catch {
    Write-Line 'WARN' "Could not read APNs certificate: $($_.Exception.Message)"
}

# --- ABM / ADE enrollment tokens ---
Write-Host "`n-- ABM / Automated Device Enrollment tokens --" -ForegroundColor White
try {
    $tokens = Get-MgDeviceManagementDepOnboardingSetting -All -ErrorAction Stop
    if ($tokens) {
        foreach ($t in $tokens) {
            $daysLeft = if ($t.TokenExpirationDateTime) { [int]([datetime]$t.TokenExpirationDateTime - (Get-Date)).TotalDays } else { $null }
            $name = if ($t.TokenName) { $t.TokenName } else { $t.AppleIdentifier }
            Write-Line 'PASS' "ABM token: '$name'. Expires in $daysLeft day(s). Last sync: $($t.LastSuccessfulSyncDateTime)"
            if ($daysLeft -ne $null -and $daysLeft -lt 30) { Write-Line 'WARN' "ABM token '$name' expires in under 30 days — renew from Apple Business Manager." }
        }
    }
    else {
        Write-Line 'WARN' "No ABM/ADE enrollment token found. Link Apple Business Manager to Intune Government (endpoint.microsoft.us)."
    }
}
catch {
    Write-Line 'WARN' "Could not read ABM/ADE tokens: $($_.Exception.Message)"
}

# --- Pilot scope groups ---
Write-Host "`n-- Pilot scope groups --" -ForegroundColor White
foreach ($gName in @($PilotDeviceGroup, $EnrollUserGroup)) {
    try {
        $g = Get-MgGroup -Filter "displayName eq '$gName'" -ErrorAction Stop
        if ($g) {
            $count = (Get-MgGroupMember -GroupId $g.Id -All -ErrorAction SilentlyContinue).Count
            Write-Line 'PASS' "Group '$gName' exists (Id $($g.Id)); members: $count"
        }
        else {
            Write-Line 'WARN' "Group '$gName' not found. Create it (or run ABMPROVG-Set-ScopeTargeting.ps1)."
        }
    }
    catch {
        Write-Line 'WARN' "Could not query group '$gName': $($_.Exception.Message)"
    }
}

# --- Parity reminder ---
Write-Host "`n-- Parity note (GCC High) --" -ForegroundColor White
Write-Line 'INFO' "Entra <-> ABM federation and SCIM auto-provisioning are NOT supported for national clouds (Apple)."
Write-Line 'INFO' "This solution uses the supported path: ABM <-> Intune Government enrollment with ABM-native Managed Apple IDs."

Write-Host "`nDiscovery complete. Resolve WARN/FAIL items before configuring." -ForegroundColor White

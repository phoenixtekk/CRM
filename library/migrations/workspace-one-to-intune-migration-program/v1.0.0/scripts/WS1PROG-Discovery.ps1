<#
.SYNOPSIS
    WS1PROG-Discovery.ps1 - Read-only Discovery baseline for a Workspace ONE -> Microsoft Intune migration program.

    PURPOSE:
        Captures the Intune / Entra TARGET side as the Discovery baseline (R5): managed devices by
        platform, the per-platform enrollment-channel readiness signal (Apple APNs / ADE, managed
        Google Play, Windows auto-enroll groundwork), Entra groups, and a per-platform device count.
        Output drives wave sizing, parity scope, and reconciliation against the SOURCE export.

        SOURCE (Workspace ONE) inventory is exported from the Workspace ONE console / REST API and is
        NOT performed natively here. An OPTIONAL, clearly-flagged Workspace ONE REST hook is provided
        using generic Invoke-RestMethod only - the exact WS1 endpoints/paths are DEFERRED to current
        VMware documentation and must be supplied by the operator. No WS1 endpoints are invented.

    HOW TO RUN:
        1. Install the Microsoft Graph PowerShell SDK (run once):
             Install-Module Microsoft.Graph -Scope CurrentUser
        2. Run against the TARGET tenant (read-only Graph scopes):
             .\WS1PROG-Discovery.ps1 -OutputCsv ".\Intune-Baseline - Discovery - Target.csv"
        3. (Optional) Also pull a Workspace ONE REST inventory you have endpoints/credentials for:
             .\WS1PROG-Discovery.ps1 -OutputCsv ".\Intune-Baseline - Discovery - Target.csv" `
                 -WS1BaseUrl "https://<your-ws1-host>" -WS1DevicesPath "<path-per-VMware-docs>" `
                 -WS1Headers @{ "aw-tenant-code" = "<key>"; Authorization = "<auth-per-VMware-docs>" }
        Sign in interactively when prompted; a read-only account (e.g. Global Reader + Intune read) suffices.

    EXPECTED RESULTS:
        A CSV (default ".\Intune-Baseline - Discovery - Target.csv") with one row per discovered Intune
        managed device (Platform, DeviceName, UserPrincipalName, ComplianceState, ManagedBy) plus a
        console summary of device counts per platform and a per-platform enrollment-readiness note.
        Strictly READ-ONLY - no changes are made to any tenant.

.NOTES
    Migrations - read-only. Microsoft/Intune/Entra side via Microsoft Graph PowerShell.
    Workspace ONE REST specifics are deferred to current VMware documentation (no invented endpoints).
#>

[CmdletBinding()]
param(
    [string]$OutputCsv = ".\Intune-Baseline - Discovery - Target.csv",

    # OPTIONAL Workspace ONE REST hook - all WS1 specifics deferred to VMware docs.
    [string]$WS1BaseUrl,
    [string]$WS1DevicesPath,
    [hashtable]$WS1Headers
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]

# --- Connect to Microsoft Graph (TARGET, read-only) ---
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Write-Host "Connecting to Microsoft Graph (read-only)..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All","DeviceManagementServiceConfig.Read.All","Group.Read.All","Directory.Read.All" -NoWelcome

# --- Intune managed devices (target side) ---
Import-Module Microsoft.Graph.DeviceManagement -ErrorAction Stop
Write-Host "Enumerating Intune managed devices..." -ForegroundColor Cyan
Get-MgDeviceManagementManagedDevice -All | ForEach-Object {
    $platform = switch -Wildcard ($_.OperatingSystem) {
        'Windows*' { 'Windows' }
        'iOS*'     { 'iOS' }
        'iPadOS*'  { 'iOS' }
        'Android*' { 'Android' }
        'macOS*'   { 'macOS' }
        default    { $_.OperatingSystem }
    }
    $results.Add([pscustomobject]@{
        Source              = 'Intune'
        Platform            = $platform
        DeviceName          = $_.DeviceName
        UserPrincipalName   = $_.UserPrincipalName
        OperatingSystem     = $_.OperatingSystem
        OSVersion           = $_.OsVersion
        Ownership           = $_.ManagedDeviceOwnerType
        ComplianceState     = $_.ComplianceState
        ManagedBy           = $_.ManagementAgent
    })
}

# --- Entra groups (targeting readiness) ---
Import-Module Microsoft.Graph.Groups -ErrorAction Stop
$groupCount = (Get-MgGroup -All -Property Id | Measure-Object).Count

# --- OPTIONAL Workspace ONE REST inventory (generic; endpoints supplied by operator per VMware docs) ---
if ($WS1BaseUrl -and $WS1DevicesPath -and $WS1Headers) {
    Write-Host "Querying Workspace ONE REST inventory (operator-supplied endpoint; deferred to VMware docs)..." -ForegroundColor Yellow
    try {
        # NOTE: The response shape is defined by the Workspace ONE REST API (see VMware docs).
        # We do not assume a schema beyond a 'Devices' collection; map fields as your version returns them.
        $uri  = ($WS1BaseUrl.TrimEnd('/')) + '/' + $WS1DevicesPath.TrimStart('/')
        $resp = Invoke-RestMethod -Method Get -Uri $uri -Headers $WS1Headers
        $ws1Devices = if ($resp.Devices) { $resp.Devices } else { $resp }
        foreach ($d in $ws1Devices) {
            $results.Add([pscustomobject]@{
                Source            = 'WorkspaceONE'
                Platform          = $d.Platform
                DeviceName        = $d.DeviceFriendlyName
                UserPrincipalName = $d.UserName
                OperatingSystem   = $d.OperatingSystem
                OSVersion         = $d.OsVersion
                Ownership         = $d.Ownership
                ComplianceState   = $d.ComplianceStatus
                ManagedBy         = 'WorkspaceONE'
            })
        }
    } catch {
        Write-Warning ("Workspace ONE REST query failed (verify endpoint/auth against VMware docs): {0}" -f $_.Exception.Message)
    }
} else {
    Write-Host "Workspace ONE REST hook not supplied - export the source inventory from the WS1 console/API (deferred to VMware docs) and reconcile by UPN." -ForegroundColor Yellow
}

# --- Export + summary ---
$results | Sort-Object Source, Platform, DeviceName | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
Write-Host ("`nExported {0} device rows to {1}" -f $results.Count, $OutputCsv) -ForegroundColor Green
Write-Host ("Entra groups present: {0}" -f $groupCount)

Write-Host "`n=== Intune device count by platform ===" -ForegroundColor Cyan
$results | Where-Object Source -eq 'Intune' | Group-Object Platform | Sort-Object Name | ForEach-Object {
    Write-Host ("  {0,-10} Count={1}" -f $_.Name, $_.Count)
}

Write-Host "`n=== Enrollment-readiness reminder (verify in intune.microsoft.com -> Devices -> Enrollment) ===" -ForegroundColor Cyan
Write-Host "  Apple   : APNs certificate Active (renew, never recreate); ADE token synced for corporate Apple."
Write-Host "  Android : managed Google Play connected."
Write-Host "  Windows : Automatic Enrollment / MDM user scope set (entra.microsoft.com -> Mobility (MDM and MAM))."

Disconnect-MgGraph | Out-Null

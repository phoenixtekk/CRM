<#
.SYNOPSIS
    EPICCLIENT-Report.ps1 — Fleet rollout / version report for the Epic client (per-ring counts, version spread) to CSV.

.DESCRIPTION
    PURPOSE
        Builds a tenant-wide rollout report for the Epic client Win32 app: per deployment ring how
        many devices have Installed / Failed / Pending, and the version spread across the fleet, using
        Microsoft Graph (Intune) data. Use it to confirm a ring is converged before expanding, and to
        catch version drift over time. Read-only.

    HOW TO RUN
        Requires the Microsoft.Graph PowerShell SDK and an operator with Intune read rights.
            Install-Module Microsoft.Graph -Scope CurrentUser   # one time
            powershell -ExecutionPolicy Bypass -File .\EPICCLIENT-Report.ps1 `
                -AppName "Epic Hyperdrive - <EPIC_VERSION>" `
                -PilotGroup "Epic Hyperdrive - Pilot Ring" -BroadGroup "Epic Hyperdrive - Broad Ring" `
                -OutCsv .\EpicClient-Rollout.csv

    EXPECTED RESULTS
        A CSV (and an on-screen summary) of per-ring install status and version counts. Use it as
        evidence for the Testing acceptance gate (Test 8) and for change records.

.NOTES
    Healthcare Solutions — read-only. Queries Intune via Graph; makes no changes. Reports device/app
    state only; never captures patient data.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$AppName,
    [string]$PilotGroup = 'Epic Hyperdrive - Pilot Ring',
    [string]$BroadGroup = 'Epic Hyperdrive - Broad Ring',
    [string]$OutCsv = ".\EpicClient-Rollout-$(Get-Date -Format yyyyMMdd-HHmm).csv"
)

# --- Connect to Graph (read-only scopes) ---
try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Import-Module Microsoft.Graph.Devices.CorporateManagement -ErrorAction SilentlyContinue
    if (-not (Get-MgContext)) {
        Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All','DeviceManagementManagedDevices.Read.All','Group.Read.All' -NoWelcome
    }
} catch {
    Write-Error "Microsoft Graph SDK required. Run: Install-Module Microsoft.Graph -Scope CurrentUser. Details: $($_.Exception.Message)"
    return
}

# --- Find the Win32 app by exact display name ---
$app = Get-MgDeviceAppManagementMobileApp -Filter "displayName eq '$AppName'" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $app) { Write-Error "Win32 app named '$AppName' not found in Intune. Check the exact name."; return }
Write-Host "App: $($app.DisplayName)  (id $($app.Id))" -ForegroundColor Cyan

# --- Pull per-device install status for the app ---
$statusUri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($app.Id)/deviceStatuses"
$rows = New-Object System.Collections.Generic.List[object]
$next = $statusUri
while ($next) {
    $page = Invoke-MgGraphRequest -Method GET -Uri $next -ErrorAction Stop
    foreach ($d in $page.value) {
        $rows.Add([pscustomobject]@{
            DeviceName      = $d.deviceName
            UserName        = $d.userName
            InstallState    = $d.installState
            InstallStateDetail = $d.installStateDetail
            AppVersion      = $d.displayVersion
            LastSync        = $d.lastSyncDateTime
        })
    }
    $next = $page.'@odata.nextLink'
}

if ($rows.Count -eq 0) { Write-Warning "No device status returned yet — the app may not have reached devices."; }

# --- Summaries ---
Write-Host "`n--- Install state summary ---" -ForegroundColor Cyan
$rows | Group-Object InstallState | Sort-Object Count -Descending |
    Select-Object @{n='InstallState';e={$_.Name}}, Count | Format-Table -AutoSize

Write-Host "--- Version spread ---" -ForegroundColor Cyan
$rows | Where-Object AppVersion | Group-Object AppVersion | Sort-Object Count -Descending |
    Select-Object @{n='Version';e={$_.Name}}, Count | Format-Table -AutoSize

# --- Export ---
$rows | Sort-Object InstallState, DeviceName | Export-Csv -NoTypeInformation -Path $OutCsv -Encoding UTF8
Write-Host "Wrote $($rows.Count) rows to $OutCsv" -ForegroundColor Green
Write-Host "Rings referenced: '$PilotGroup' (pilot), '$BroadGroup' (broad). Confirm pilot is fully Installed before expanding to broad." -ForegroundColor Yellow

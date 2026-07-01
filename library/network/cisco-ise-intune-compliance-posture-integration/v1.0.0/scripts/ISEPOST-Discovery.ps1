<#
.SYNOPSIS
    ISEPOST-Discovery.ps1 — connector readiness: the Entra app registration ISE uses, its Graph permissions/secret, and the Intune compliance policies.
.DESCRIPTION
    PURPOSE
        Read-only readiness check for the ISE-to-Intune posture connector. Confirms the
        Entra app registration named 'ISE-Intune-Compliance-Connector' exists, reports its
        Microsoft Graph application permissions and client-secret expiry, and lists the
        Intune device compliance policies ISE's decision depends on. Nothing is changed.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ISEPOST-Discovery.ps1

        Required Graph scopes: Application.Read.All, DeviceManagementConfiguration.Read.All
    EXPECTED RESULTS
        Prints the app registration, its consented Graph permissions, secret expiry (PASS/
        WARN/FAIL), and the compliance policies with assignment counts. PASS when the app,
        a valid secret, and the read permissions are present and policies exist.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. Cisco ISE internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string]$AppName = 'ISE-Intune-Compliance-Connector'
)

$ErrorActionPreference = 'Stop'

# Graph permissions the ISE connector should hold to read device compliance/enrollment.
$RequiredGraphPermissions = @(
    'DeviceManagementManagedDevices.Read.All',
    'DeviceManagementConfiguration.Read.All'
)

function Connect-GraphSafe {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = $null
    try { $ctx = Get-MgContext } catch { $ctx = $null }
    if (-not $ctx) {
        Connect-MgGraph -Scopes 'Application.Read.All','DeviceManagementConfiguration.Read.All' -NoWelcome | Out-Null
    }
}

Write-Host "=== ISEPOST Discovery — connector readiness ===" -ForegroundColor Cyan
Connect-GraphSafe

# --- 1. The Entra app registration ISE uses ---------------------------------
Write-Host "`n[1] Entra app registration: $AppName" -ForegroundColor Cyan
$app = Get-MgApplication -Filter "displayName eq '$AppName'" -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $app) {
    Write-Host "  FAIL  App registration '$AppName' not found. Create it (Implementation Step 1)." -ForegroundColor Red
} else {
    Write-Host "  PASS  Found. AppId (client id) = $($app.AppId)" -ForegroundColor Green

    # --- Client secret expiry ---
    Write-Host "`n[2] Client secret state" -ForegroundColor Cyan
    if (-not $app.PasswordCredentials -or $app.PasswordCredentials.Count -eq 0) {
        Write-Host "  FAIL  No client secret on the app. ISE cannot authenticate." -ForegroundColor Red
    } else {
        foreach ($sec in $app.PasswordCredentials) {
            $days = [math]::Round(($sec.EndDateTime - (Get-Date)).TotalDays)
            if ($days -lt 0)      { Write-Host "  FAIL  Secret '$($sec.DisplayName)' EXPIRED $([math]::Abs($days))d ago." -ForegroundColor Red }
            elseif ($days -lt 30) { Write-Host "  WARN  Secret '$($sec.DisplayName)' expires in $days d — renew soon." -ForegroundColor Yellow }
            else                  { Write-Host "  PASS  Secret '$($sec.DisplayName)' valid for $days d." -ForegroundColor Green }
        }
    }

    # --- Graph application permissions ---
    Write-Host "`n[3] Microsoft Graph application permissions" -ForegroundColor Cyan
    $graphSpId = '00000003-0000-0000-c000-000000000000'  # Microsoft Graph resource appId
    $graphSp = Get-MgServicePrincipal -Filter "appId eq '$graphSpId'" -ErrorAction SilentlyContinue | Select-Object -First 1
    $grantedRoleIds = @()
    if ($app.RequiredResourceAccess) {
        $graphAccess = $app.RequiredResourceAccess | Where-Object { $_.ResourceAppId -eq $graphSpId }
        if ($graphAccess) { $grantedRoleIds = $graphAccess.ResourceAccess | Where-Object { $_.Type -eq 'Role' } | ForEach-Object { $_.Id } }
    }
    foreach ($perm in $RequiredGraphPermissions) {
        $role = $graphSp.AppRoles | Where-Object { $_.Value -eq $perm } | Select-Object -First 1
        if ($role -and ($grantedRoleIds -contains $role.Id)) {
            Write-Host "  PASS  $perm requested on the app." -ForegroundColor Green
        } else {
            Write-Host "  FAIL  $perm NOT on the app. Add + admin-consent (Implementation Step 2)." -ForegroundColor Red
        }
    }

    # --- Admin consent (granted app-role assignments on the service principal) ---
    Write-Host "`n[4] Admin consent (granted permissions)" -ForegroundColor Cyan
    $appSp = Get-MgServicePrincipal -Filter "appId eq '$($app.AppId)'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $appSp) {
        Write-Host "  WARN  No service principal for the app yet — consent likely not granted." -ForegroundColor Yellow
    } else {
        $assignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $appSp.Id -ErrorAction SilentlyContinue
        foreach ($perm in $RequiredGraphPermissions) {
            $role = $graphSp.AppRoles | Where-Object { $_.Value -eq $perm } | Select-Object -First 1
            if ($role -and $assignments -and ($assignments.AppRoleId -contains $role.Id)) {
                Write-Host "  PASS  $perm admin-consented." -ForegroundColor Green
            } else {
                Write-Host "  FAIL  $perm not consented. Grant admin consent in Entra." -ForegroundColor Red
            }
        }
    }
}

# --- 5. Intune compliance policies ------------------------------------------
Write-Host "`n[5] Intune device compliance policies" -ForegroundColor Cyan
$policies = Get-MgDeviceManagementDeviceCompliancePolicy -All -ErrorAction SilentlyContinue
if (-not $policies -or $policies.Count -eq 0) {
    Write-Host "  FAIL  No compliance policies found. ISE's decision would be meaningless." -ForegroundColor Red
} else {
    Write-Host "  Found $($policies.Count) compliance policy(ies):" -ForegroundColor Green
    foreach ($p in $policies) {
        $assignCount = 0
        try {
            $assigns = Get-MgDeviceManagementDeviceCompliancePolicyAssignment -DeviceCompliancePolicyId $p.Id -ErrorAction SilentlyContinue
            if ($assigns) { $assignCount = @($assigns).Count }
        } catch {}
        Write-Host ("    - {0}  (assignments: {1})" -f $p.DisplayName, $assignCount)
    }
    $expected = @('Compliance – Windows – Baseline','Compliance – iOS – Baseline','Compliance – Android – Baseline','Compliance – macOS – Baseline')
    foreach ($e in $expected) {
        if ($policies.DisplayName -contains $e) { Write-Host "  PASS  Baseline present: $e" -ForegroundColor Green }
        else { Write-Host "  INFO  Baseline not found (create if this platform is in scope): $e" -ForegroundColor Yellow }
    }
}

Write-Host "`n=== Discovery complete ===" -ForegroundColor Cyan
Write-Host "Review any FAIL/WARN lines above. Cisco ISE External MDM setup is deferred to Cisco documentation."

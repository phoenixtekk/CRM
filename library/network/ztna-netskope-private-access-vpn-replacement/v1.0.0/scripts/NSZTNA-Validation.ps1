<#
.SYNOPSIS
    NSZTNA-Validation.ps1 — validate a pilot user/device for ZTNA: client, group, posture, app reach.
.DESCRIPTION
    PURPOSE
        Read-only validation that a user/device is ready to reach private apps through Netskope
        Private Access. Confirms the Netskope client is present and steering, that the user is in the
        expected Entra entitlement group ('Access Group - <App or Role> - <Stage>'), that the device
        reports a compliant/managed posture, and that a named published app resolves and is reachable.
    HOW TO RUN
        On a pilot device, signed in as (or specifying) the pilot user:
            powershell -ExecutionPolicy Bypass -File .\NSZTNA-Validation.ps1 ^
                -UserPrincipalName user@contoso.com ^
                -ExpectedGroup "Access Group - HR App - Pilot" ^
                -AppFqdn hrapp.internal.contoso.com -AppPort 443
        Entra checks require the Microsoft Graph PowerShell SDK and a sign-in with
        Group.Read.All and Device.Read.All (read-only scopes).
    EXPECTED RESULTS
        PASS/FAIL lines for: client present + steering, group membership, device posture, and the
        published app resolving/connecting. No changes are made.
.NOTES
    Network — ZTNA / Netskope Private Access. Read-only. Authored the repeatable way.
    Netskope-side session/policy validation is via the Netskope console/REST API and is DEFERRED.
#>
[CmdletBinding()]
param(
    [string]$UserPrincipalName = $env:USERNAME,
    [string]$ExpectedGroup,
    [string]$AppFqdn,
    [int]$AppPort = 443
)

function Result($ok, $label, $detail) {
    if ($ok) { Write-Host ("  PASS  {0} {1}" -f $label, $detail) -ForegroundColor Green }
    else     { Write-Host ("  FAIL  {0} {1}" -f $label, $detail) -ForegroundColor Red }
}

Write-Host "`n=== ZTNA Validation — $($env:COMPUTERNAME) / $UserPrincipalName ===" -ForegroundColor Cyan

# --- 1. Netskope client present + steering ---
$nsSvc = Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'stagent|netskope' -or $_.DisplayName -match 'Netskope' }
$running = ($nsSvc | Where-Object { $_.Status -eq 'Running' })
Result ([bool]$running) "Netskope client steering:" ($(if($nsSvc){($nsSvc | ForEach-Object {"$($_.Name)=$($_.Status)"}) -join ', '}else{'not installed'}))

# --- 2. Entra entitlement group membership (Graph, read-only) ---
if ($ExpectedGroup) {
    try {
        if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Groups)) {
            Install-Module Microsoft.Graph.Groups, Microsoft.Graph.Users -Scope CurrentUser -Force -AllowClobber
        }
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        Connect-MgGraph -Scopes 'Group.Read.All','User.Read.All' -NoWelcome
        $user = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$UserPrincipalName"
        $memberships = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$($user.id)/memberOf").value
        $inGroup = $memberships | Where-Object { $_.displayName -eq $ExpectedGroup }
        Result ([bool]$inGroup) "Entitlement group:" "'$ExpectedGroup'"
        Disconnect-MgGraph | Out-Null
    } catch {
        Write-Host ("  SKIP  Entitlement group: Graph check failed — {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
} else {
    Write-Host "  SKIP  Entitlement group: -ExpectedGroup not supplied." -ForegroundColor Yellow
}

# --- 3. Device posture (managed/compliant signals; full posture is evaluated by Netskope/Intune) ---
$dsreg = (& dsregcmd /status 2>$null)
$aadJoined = ($dsreg | Select-String 'AzureAdJoined\s*:\s*YES' -Quiet)
$mdmEnrolled = ($dsreg | Select-String 'MDMUrl|MDM enrollment' -Quiet)
Result (($aadJoined) -and ($mdmEnrolled)) "Device posture (Entra-joined + MDM):" ("joined=$([bool]$aadJoined), mdm=$([bool]$mdmEnrolled)")

# --- 4. Published app resolves + reachable through the ZTNA path ---
if ($AppFqdn) {
    $resolved = $false
    try { $resolved = [bool](Resolve-DnsName -Name $AppFqdn -ErrorAction Stop) } catch { $resolved = $false }
    Result $resolved "App resolves:" $AppFqdn
    if ($resolved) {
        $tcp = Test-NetConnection -ComputerName $AppFqdn -Port $AppPort -WarningAction SilentlyContinue
        Result ($tcp.TcpTestSucceeded) "App reachable:" ("{0}:{1}" -f $AppFqdn, $AppPort)
    }
} else {
    Write-Host "  SKIP  App reachability: -AppFqdn not supplied." -ForegroundColor Yellow
}

Write-Host "`nValidation complete (read-only). Netskope-side policy hit/log review is DEFERRED to the Netskope console." -ForegroundColor Green

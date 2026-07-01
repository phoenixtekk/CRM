<#
.SYNOPSIS
    ISE8021X-Set-ScopeTargeting.ps1 — Create and populate the pilot Entra security group(s) used as 802.1X profile assignment targets (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Creates the pilot Entra security group (default 'PILOT - 802.1X Devices') if it does not
        exist, and optionally adds named devices to it, so the 802.1X trusted-root, SCEP cert,
        Wi-Fi and wired profiles have a clean assignment target. Runs in -WhatIf mode by default —
        pass -Apply to make changes. Does not touch Cisco ISE/switch/WLC.
    HOW TO RUN
        Preview:  powershell -ExecutionPolicy Bypass -File .\ISE8021X-Set-ScopeTargeting.ps1 -DeviceNames 'LT-0001','LT-0002'
        Apply:    powershell -ExecutionPolicy Bypass -File .\ISE8021X-Set-ScopeTargeting.ps1 -DeviceNames 'LT-0001','LT-0002' -Apply

        Required Graph scopes: Group.ReadWrite.All, Device.Read.All, Directory.Read.All
    EXPECTED RESULTS
        Confirmation that the pilot group exists (created if needed) and, when -Apply is set, that
        the requested devices were added as members. In preview mode it only reports what it would do.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. Cisco ISE + network-infra internals deferred to vendor docs.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$GroupName = 'PILOT - 802.1X Devices',
    [string[]]$DeviceNames = @(),
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
if (-not $Apply) { $WhatIfPreference = $true }

function Connect-Graph {
    $scopes = @('Group.ReadWrite.All','Device.Read.All','Directory.Read.All')
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph PowerShell SDK is not installed. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = $null; try { $ctx = Get-MgContext } catch { $ctx = $null }
    if (-not $ctx -or ($ctx.Scopes -notcontains 'Group.ReadWrite.All')) {
        Connect-MgGraph -Scopes $scopes | Out-Null
    }
    Write-Host "Connected to Graph tenant: $((Get-MgContext).TenantId)" -ForegroundColor Cyan
}

function Invoke-GraphGet {
    param([Parameter(Mandatory)][string]$Uri)
    $out = @(); $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $out += $resp.value } elseif ($resp) { $out += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $out
}

Connect-Graph
$base = 'https://graph.microsoft.com/v1.0'

if (-not $Apply) {
    Write-Host "`n*** PREVIEW MODE (-WhatIf) — no changes will be made. Re-run with -Apply to commit. ***`n" -ForegroundColor Yellow
}

# 1) Ensure the group exists
$escaped = $GroupName.Replace("'","''")
$existing = Invoke-GraphGet -Uri "$base/groups?`$filter=displayName eq '$escaped'&`$select=id,displayName"
if ($existing) {
    $groupId = $existing[0].id
    Write-Host "Group '$GroupName' already exists ($groupId)." -ForegroundColor Green
} else {
    Write-Host "Group '$GroupName' does not exist." -ForegroundColor DarkYellow
    $groupId = $null
    if ($PSCmdlet.ShouldProcess($GroupName, "Create Entra security group")) {
        $mailNick = ($GroupName -replace '[^a-zA-Z0-9]', '')
        if ([string]::IsNullOrWhiteSpace($mailNick)) { $mailNick = 'pilot8021xdevices' }
        $body = @{
            displayName     = $GroupName
            description     = 'Pilot assignment target for Cisco ISE 802.1X EAP-TLS profiles.'
            mailEnabled     = $false
            mailNickname    = $mailNick
            securityEnabled = $true
        } | ConvertTo-Json
        $new = Invoke-MgGraphRequest -Method POST -Uri "$base/groups" -Body $body
        $groupId = $new.id
        Write-Host "  -> created group ($groupId)." -ForegroundColor Green
    } else {
        Write-Host "  (would create the group here)" -ForegroundColor Yellow
    }
}

# 2) Add devices, if requested
if ($DeviceNames.Count -gt 0) {
    Write-Host "`nResolving devices to add..." -ForegroundColor Cyan
    foreach ($dn in $DeviceNames) {
        $esc = $dn.Replace("'","''")
        $dev = Invoke-GraphGet -Uri "$base/devices?`$filter=displayName eq '$esc'&`$select=id,displayName"
        if (-not $dev) {
            Write-Host "  [NOT FOUND] device '$dn' — skipping." -ForegroundColor Red
            continue
        }
        $devObjId = $dev[0].id
        if ($PSCmdlet.ShouldProcess($dn, "Add device to group '$GroupName'")) {
            if (-not $groupId) { Write-Host "  (group not yet created in preview — would add '$dn')" -ForegroundColor Yellow; continue }
            $refBody = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$devObjId" } | ConvertTo-Json
            try {
                Invoke-MgGraphRequest -Method POST -Uri "$base/groups/$groupId/members/`$ref" -Body $refBody | Out-Null
                Write-Host "  [ADDED] $dn" -ForegroundColor Green
            } catch {
                if ($_.Exception.Message -match 'already exist') { Write-Host "  [OK] $dn already a member." -ForegroundColor Green }
                else { Write-Warning "  Could not add '$dn': $($_.Exception.Message)" }
            }
        }
    }
}

Write-Host "`nDone. Assign the 802.1X profiles to '$GroupName' (see Implementation) or run ISE8021X-Remediation.ps1." -ForegroundColor Cyan

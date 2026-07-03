<#
.SYNOPSIS
    EGRESSG-Set-ScopeTargeting.ps1 — create/populate the pilot Entra group for staged egress rollout on GCC High (safe by default: -WhatIf).
.DESCRIPTION
    PURPOSE
        Creates or confirms the EGRESSG-Pilot Microsoft Entra security group and adds specified
        members, so the new egress allow-list can be piloted before fleet rollout. Connects to the
        US Government Graph environment (-Environment USGov) — the Commercial default fails on a GCC
        High tenant. By default it only previews (-WhatIf) and changes nothing; -Execute applies.
        Provide members as your-user-or-device-object-ids.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\EGRESSG-Set-ScopeTargeting.ps1 -GroupName "EGRESSG-Pilot"            (preview)
        powershell -ExecutionPolicy Bypass -File .\EGRESSG-Set-ScopeTargeting.ps1 -GroupName "EGRESSG-Pilot" -Execute   (apply)
        (note the GCC High Graph environment: -Environment USGov; endpoints web-service instance USGOVGCCHigh)
    EXPECTED RESULTS
        In preview mode: the planned group create/membership changes are printed, nothing is
        applied. With -Execute: the group exists and members are added. PASS when connected to the
        USGov Graph environment; FAIL otherwise.
.NOTES
    White-label — the repeatable way. Read-only by default (-WhatIf); connects to US Gov Graph (-Environment USGov).
#>

#Requires -Version 5.1
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$GroupName = 'EGRESSG-Pilot',
    [string]$GroupDescription = 'EGRESSG staged egress-filtering pilot (GCC High)',
    # Object IDs of users or devices to add to the pilot group.
    [string[]]$MemberObjectIds = @(),
    # Actually apply changes. Without this the script only previews (-WhatIf behavior).
    [switch]$Execute
)

$ErrorActionPreference = 'Stop'

# --- Ensure the Microsoft Graph module ------------------------------------------------------------
if (-not (Get-Module Microsoft.Graph.Groups -ListAvailable)) {
    Write-Warning "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    Write-Warning "Continuing in preview mode only."
}

# --- Connect to the US Gov Graph environment (critical for GCC High) -------------------------------
try {
    Import-Module Microsoft.Graph.Groups -ErrorAction Stop
    Connect-MgGraph -Environment USGov -Scopes 'Group.ReadWrite.All','GroupMember.ReadWrite.All' -NoWelcome
    $ctx = Get-MgContext
    if ($ctx.Environment -ne 'USGov') {
        Write-Error "FAIL: connected Graph environment is '$($ctx.Environment)', expected 'USGov'. Reconnect with -Environment USGov."
        exit 1
    }
    Write-Host "Connected to Microsoft Graph (environment: $($ctx.Environment), tenant: $($ctx.TenantId))."
} catch {
    Write-Warning "Could not connect to USGov Graph ($($_.Exception.Message)). Running preview only."
    $ctx = $null
}

# --- Find or plan the group -----------------------------------------------------------------------
$existing = $null
if ($ctx) {
    $existing = Get-MgGroup -Filter "displayName eq '$GroupName'" -ConsistencyLevel eventual -CountVariable c -ErrorAction SilentlyContinue
}

if ($existing) {
    Write-Host "Group '$GroupName' already exists (Id: $($existing.Id))."
} else {
    Write-Host "Group '$GroupName' does not exist — it will be created."
}

Write-Host ""
Write-Host "Planned scope-targeting actions (GCC High):"
Write-Host "  Group        : $GroupName"
Write-Host "  Description  : $GroupDescription"
Write-Host ("  Members add  : {0}" -f @($MemberObjectIds).Count)
$MemberObjectIds | ForEach-Object { Write-Host "    + $_" }

# --- Preview gate ---------------------------------------------------------------------------------
if (-not $Execute) {
    Write-Host ""
    Write-Host "PREVIEW ONLY (-WhatIf default). Re-run with -Execute to apply. No changes were made."
    if ($ctx) { Disconnect-MgGraph | Out-Null }
    exit 0
}

if (-not $ctx) {
    Write-Error "FAIL: cannot -Execute without a USGov Graph connection."
    exit 1
}

# --- Apply ----------------------------------------------------------------------------------------
if (-not $existing) {
    if ($PSCmdlet.ShouldProcess($GroupName, 'Create Entra security group (USGov)')) {
        $mailNickname = ($GroupName -replace '[^a-zA-Z0-9]', '')
        $existing = New-MgGroup -DisplayName $GroupName -Description $GroupDescription `
            -MailEnabled:$false -MailNickname $mailNickname -SecurityEnabled:$true
        Write-Host "Created group '$GroupName' (Id: $($existing.Id))."
    }
}

foreach ($id in $MemberObjectIds) {
    if ($PSCmdlet.ShouldProcess($id, "Add to $GroupName")) {
        try {
            New-MgGroupMember -GroupId $existing.Id -DirectoryObjectId $id
            Write-Host "  Added member: $id"
        } catch {
            Write-Warning "  Could not add $id : $($_.Exception.Message)"
        }
    }
}

Write-Host ""
Write-Host "PASS: pilot scope-targeting applied on the USGov Graph environment."
Disconnect-MgGraph | Out-Null

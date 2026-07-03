<#
.SYNOPSIS
    ABMPROVG-Set-ScopeTargeting.ps1 — build/populate the pilot scope group for staged Apple rollout.
.DESCRIPTION
    PURPOSE
        Creates the named pilot scope group if missing and adds the members you supply (device or user
        object IDs, or the members of a seed group) so you can pilot then expand in controlled waves.
        Defaults to preview mode (-WhatIf) and makes no change until re-run without -WhatIf. Replace
        sample values with your-group-name and your-object-ids (default group:
        ABM-Apple-Pilot-Devices). Provide members via -MemberObjectId or -SeedGroupName.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ABMPROVG-Set-ScopeTargeting.ps1 -MemberObjectId '00000000-0000-0000-0000-000000000001'
        powershell -ExecutionPolicy Bypass -File .\ABMPROVG-Set-ScopeTargeting.ps1 -SeedGroupName 'ABM-Apple-Enroll-Users' -WhatIf:$false
        (Graph scopes: Group.ReadWrite.All; -Environment USGov)
    EXPECTED RESULTS
        In preview each planned add prints as "WHATIF: add the object id". With -WhatIf:$false members are added
        and the resulting count is shown. Widen the group in waves, validating between each.
.NOTES
    White-label — the repeatable way. Change actions are gated behind -WhatIf (on by default) against
    Microsoft Graph US Gov endpoints.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$PilotDeviceGroup = 'ABM-Apple-Pilot-Devices',
    [string[]]$MemberObjectId = @(),
    [string]$SeedGroupName,
    [switch]$WhatIf = $true
)

if ($WhatIf) { $WhatIfPreference = $true }
$ErrorActionPreference = 'Stop'

function Write-Plan { param([string]$m) Write-Host ("WHATIF: {0}" -f $m) -ForegroundColor Yellow }
function Write-Did  { param([string]$m) Write-Host ("APPLIED: {0}" -f $m) -ForegroundColor Green }

Write-Host "=== ABMPROVG Set-ScopeTargeting (GCC High / US Gov) ===" -ForegroundColor White
if ($WhatIfPreference) { Write-Host "Preview mode (-WhatIf). No changes will be made." -ForegroundColor Yellow }
else { Write-Host "APPLY mode. Changes WILL be made." -ForegroundColor Red }

# --- Connect ---
try {
    Connect-MgGraph -Environment USGov -Scopes @('Group.ReadWrite.All') -NoWelcome
    $ctx = Get-MgContext
    if ($ctx.Environment -ne 'USGov') {
        Write-Host "[FAIL] Connected environment is '$($ctx.Environment)', expected 'USGov'. Reconnect with -Environment USGov." -ForegroundColor Red
        return
    }
    Write-Host "Connected to US Gov Graph. Tenant: $($ctx.TenantId)" -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Could not connect: $($_.Exception.Message)" -ForegroundColor Red
    return
}

# --- Ensure the pilot group exists ---
$group = Get-MgGroup -Filter "displayName eq '$PilotDeviceGroup'" -ErrorAction SilentlyContinue
if (-not $group) {
    if ($PSCmdlet.ShouldProcess($PilotDeviceGroup, "Create security group")) {
        $mailNick = ($PilotDeviceGroup -replace '[^a-zA-Z0-9]', '')
        $group = New-MgGroup -DisplayName $PilotDeviceGroup -MailEnabled:$false `
                    -MailNickname $mailNick -SecurityEnabled:$true `
                    -Description "Pilot scope for ABM + Intune Government Apple enrollment (ABMPROVG)."
        Write-Did "Created security group '$PilotDeviceGroup' (Id $($group.Id))."
    }
    else {
        Write-Plan "Create security group '$PilotDeviceGroup'."
    }
}
else {
    Write-Host "Group '$PilotDeviceGroup' exists (Id $($group.Id))." -ForegroundColor Cyan
}

# --- Resolve the desired members ---
$desired = New-Object System.Collections.Generic.List[string]
foreach ($id in $MemberObjectId) { if ($id) { $desired.Add($id) } }

if ($SeedGroupName) {
    $seed = Get-MgGroup -Filter "displayName eq '$SeedGroupName'" -ErrorAction SilentlyContinue
    if ($seed) {
        $seedMembers = Get-MgGroupMember -GroupId $seed.Id -All -ErrorAction SilentlyContinue
        foreach ($m in $seedMembers) { $desired.Add($m.Id) }
        Write-Host "Seed group '$SeedGroupName' contributes $($seedMembers.Count) member(s)." -ForegroundColor Cyan
    }
    else {
        Write-Host "Seed group '$SeedGroupName' not found — skipping seed." -ForegroundColor Yellow
    }
}

if ($desired.Count -eq 0) {
    Write-Host "`nNo members supplied. Provide -MemberObjectId and/or -SeedGroupName. Nothing to add." -ForegroundColor Yellow
    return
}

# --- Add members not already present ---
$existing = @()
if ($group -and $group.Id) {
    $existing = (Get-MgGroupMember -GroupId $group.Id -All -ErrorAction SilentlyContinue).Id
}

$toAdd = $desired | Select-Object -Unique | Where-Object { $_ -notin $existing }
if (-not $toAdd) {
    Write-Host "All desired members already present — no changes." -ForegroundColor Cyan
}
foreach ($id in $toAdd) {
    if ($PSCmdlet.ShouldProcess("$id", "Add to '$PilotDeviceGroup'")) {
        try {
            if ($group -and $group.Id) {
                New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $id -ErrorAction Stop
                Write-Did "Added $id to '$PilotDeviceGroup'."
            }
            else { Write-Plan "Add $id (group not yet created in preview)." }
        }
        catch { Write-Host "Could not add $id : $($_.Exception.Message)" -ForegroundColor Red }
    }
    else {
        Write-Plan "add $id to '$PilotDeviceGroup'."
    }
}

# --- Final count ---
if ($group -and $group.Id -and -not $WhatIfPreference) {
    $count = (Get-MgGroupMember -GroupId $group.Id -All -ErrorAction SilentlyContinue).Count
    Write-Host "`n'$PilotDeviceGroup' now has $count member(s)." -ForegroundColor Green
}

Write-Host "`nAssign the ADE profile (ABM-ADE-Profile-Gov) to '$PilotDeviceGroup' in endpoint.microsoft.us, then run ABMPROVG-Validation.ps1." -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "Preview complete. Re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow }

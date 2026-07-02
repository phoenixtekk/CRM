<#
.SYNOPSIS
    EGRESS-Set-ScopeTargeting.ps1 — build/populate the pilot Entra security group for staged allow-list rollout.
.DESCRIPTION
    PURPOSE
        Creates the Entra security group SG-EGRESS-Pilot (if missing) and adds the pilot device or
        user object IDs you supply, so the allow-list can be validated on a limited scope before
        fleet rollout. Runs in preview by default and shows exactly what it would create/add; it
        makes no changes to Entra until you re-run with -Commit.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\EGRESS-Set-ScopeTargeting.ps1 -PilotGroupName SG-EGRESS-Pilot -MemberObjectId id-one,id-two
        Needs Microsoft Graph PowerShell and admin rights (scopes Group.ReadWrite.All,
        GroupMember.ReadWrite.All, Device.Read.All). Preview by default; add -Commit to apply.
    EXPECTED RESULTS
        Preview prints the group and members it would create/add. With -Commit it creates/populates
        the group and prints the group id. PASS = SG-EGRESS-Pilot exists and contains the pilot members.
.NOTES
    White-label — the repeatable way. Preview/-WhatIf by default for any change-generating action.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [string]$PilotGroupName = 'SG-EGRESS-Pilot',

    [string[]]$MemberObjectId = @(),

    [switch]$Commit
)

$ErrorActionPreference = 'Stop'

# Preview unless -Commit. -WhatIf (SupportsShouldProcess) also forces preview.
$doCommit = $Commit.IsPresent -and -not $WhatIfPreference
$mode = if ($doCommit) { 'COMMIT' } else { 'PREVIEW (-WhatIf default; re-run with -Commit to apply)' }

Write-Host ''
Write-Host "EGRESS Set-ScopeTargeting — $mode" -ForegroundColor Cyan
Write-Host ('-' * 60)
Write-Host "Pilot group : $PilotGroupName"
Write-Host "Members     : $([string]::Join(', ', $MemberObjectId))"
Write-Host ''

# --- Ensure Microsoft Graph is available ------------------------------------
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Groups)) {
    Write-Warning "Microsoft.Graph PowerShell SDK not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    if ($doCommit) { throw "Cannot commit without the Microsoft Graph module." }
}

try {
    Import-Module Microsoft.Graph.Groups -ErrorAction Stop
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
}
catch {
    Write-Warning "Could not import Microsoft.Graph modules: $($_.Exception.Message)"
    if ($doCommit) { throw }
}

# --- Connect (only needed to read/write; preview also connects to look up) ---
$connected = $false
try {
    $ctx = Get-MgContext -ErrorAction SilentlyContinue
    if (-not $ctx) {
        Connect-MgGraph -Scopes 'Group.ReadWrite.All', 'GroupMember.ReadWrite.All', 'Device.Read.All' -NoWelcome -ErrorAction Stop
    }
    $connected = $true
}
catch {
    Write-Warning "Not connected to Microsoft Graph: $($_.Exception.Message)"
    Write-Warning "Preview will describe intended actions without live lookups."
}

# --- Look up / plan the group ----------------------------------------------
$existingGroup = $null
if ($connected) {
    $existingGroup = Get-MgGroup -Filter "displayName eq '$PilotGroupName'" -ErrorAction SilentlyContinue | Select-Object -First 1
}

if ($existingGroup) {
    Write-Host "Group '$PilotGroupName' already exists (id $($existingGroup.Id))." -ForegroundColor Green
    $groupId = $existingGroup.Id
}
else {
    Write-Host "Group '$PilotGroupName' does not exist and WOULD BE CREATED." -ForegroundColor Yellow
    $groupId = $null

    if ($PSCmdlet.ShouldProcess($PilotGroupName, "Create security group") -and $doCommit) {
        $mailNick = ($PilotGroupName -replace '[^a-zA-Z0-9]', '')
        $newGroup = New-MgGroup -DisplayName $PilotGroupName `
            -Description 'Pilot scope for M365/Intune egress allow-list validation.' `
            -MailEnabled:$false -MailNickname $mailNick -SecurityEnabled:$true
        $groupId = $newGroup.Id
        Write-Host "Created group '$PilotGroupName' (id $groupId)." -ForegroundColor Green
    }
}

# --- Add members ------------------------------------------------------------
foreach ($m in $MemberObjectId) {
    if ($PSCmdlet.ShouldProcess("$m -> $PilotGroupName", "Add group member")) {
        if ($doCommit -and $groupId) {
            try {
                New-MgGroupMember -GroupId $groupId -DirectoryObjectId $m -ErrorAction Stop
                Write-Host "  Added member: $m" -ForegroundColor Green
            }
            catch {
                Write-Warning "  Could not add member $m : $($_.Exception.Message)"
            }
        }
        else {
            Write-Host "  WOULD ADD member: $m" -ForegroundColor Yellow
        }
    }
}

Write-Host ''
if ($doCommit) {
    Write-Host "GATE R4: pilot group prepared. Point AllowList-M365-Endpoints at this scope, then validate." -ForegroundColor Green
}
else {
    Write-Host "Preview only — no changes made. Re-run with -Commit to create/populate the group." -ForegroundColor Gray
}

<#
.SYNOPSIS
    TUNMAMG-Set-ScopeTargeting.ps1 — Create/populate the pilot and production groups for Microsoft Tunnel for MAM on a GCC High / DoD tenant.
.DESCRIPTION
    PURPOSE
        Builds the scope-targeting groups this solution uses (GRP-TUNMAMG-Pilot and
        GRP-TUNMAMG-Prod) on a US sovereign-cloud (GCC High / DoD) tenant, and can add members from
        a supplied list of user principal names. Use it to stand up the pilot group before Phase 3
        and the production group before Phase 5. Defaults to -WhatIf: nothing changes until you pass
        -Commit. Replace placeholders like your-tenant-id and the member UPNs with real values.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TUNMAMG-Set-ScopeTargeting.ps1 -Scope Pilot                       # preview
        powershell -ExecutionPolicy Bypass -File .\TUNMAMG-Set-ScopeTargeting.ps1 -Scope Pilot -Members user1@your-domain.us,user2@your-domain.us -Commit
        (Graph scopes: Group.ReadWrite.All, User.Read.All.
         Uses -Environment USGov for GCC High; pass -Environment USGovDoD for DoD.)
    EXPECTED RESULTS
        Reports whether the group exists (creates it if -Commit) and which members would be/were
        added. PASS = group present and members reconciled. FAIL = Graph error or non-Gov context.
.NOTES
    White-label — the repeatable way. Read-only unless -Commit is supplied; targets Microsoft Graph US Gov endpoints.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [ValidateSet('USGov', 'USGovDoD')]
    [string]$Environment = 'USGov',

    [ValidateSet('Pilot', 'Prod')]
    [string]$Scope = 'Pilot',

    # User principal names to add as members, e.g. -Members user1@your-domain.us,user2@your-domain.us
    [string[]]$Members = @(),

    # Apply changes. Omit for a safe WhatIf preview.
    [switch]$Commit
)

$ErrorActionPreference = 'Stop'
if (-not $Commit) { $WhatIfPreference = $true }

$groupName = "GRP-TUNMAMG-$Scope"
$mailNick  = "grp-tunmamg-$($Scope.ToLower())"

function Connect-GovGraph {
    param([string]$Env)
    $scopes = @('Group.ReadWrite.All', 'User.Read.All')
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph PowerShell SDK not found. Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Write-Host "Connecting to Microsoft Graph (US Gov environment: $Env)..." -ForegroundColor Cyan
    Connect-MgGraph -Environment $Env -Scopes $scopes | Out-Null
    return Get-MgContext
}

function Invoke-GraphGet {
    param([string]$Uri)
    try { return Invoke-MgGraphRequest -Method GET -Uri $Uri -ErrorAction Stop }
    catch { Write-Warning "GET $Uri failed: $($_.Exception.Message)"; return $null }
}

try {
    $ctx   = Connect-GovGraph -Env $Environment
    $gbase = if ($Environment -eq 'USGovDoD') { 'https://dod-graph.microsoft.us/v1.0' } else { 'https://graph.microsoft.us/v1.0' }

    if ($ctx.Environment -notmatch 'USGov') { throw "Not a US Gov Graph context (Environment=$($ctx.Environment)). Reconnect with -Environment USGov/USGovDoD." }

    Write-Host ("Mode: {0}   Group: {1}" -f $(if ($Commit) { 'COMMIT' } else { 'WHATIF (preview)' }), $groupName) -ForegroundColor $(if ($Commit) { 'Yellow' } else { 'Green' })

    # 1) Ensure the group exists
    $existing = Invoke-GraphGet "$gbase/groups?`$filter=displayName eq '$groupName'"
    $groupId  = ($existing.value | Select-Object -First 1).id

    if ($groupId) {
        Write-Host "[OK] Group '$groupName' already exists (id=$groupId)." -ForegroundColor Green
    }
    else {
        if ($PSCmdlet.ShouldProcess($groupName, "Create security group")) {
            $body = @{
                displayName     = $groupName
                mailEnabled     = $false
                mailNickname    = $mailNick
                securityEnabled = $true
                description     = "Scope-targeting group for Microsoft Tunnel for MAM (TUNMAMG) - $Scope"
            } | ConvertTo-Json
            try {
                $new = Invoke-MgGraphRequest -Method POST -Uri "$gbase/groups" -Body $body -ContentType 'application/json' -ErrorAction Stop
                $groupId = $new.id
                Write-Host "[APPLIED] Created group '$groupName' (id=$groupId)." -ForegroundColor Green
            }
            catch { throw "Failed to create group '$groupName': $($_.Exception.Message)" }
        }
        else {
            Write-Host "[WHATIF] Would create security group '$groupName'." -ForegroundColor Yellow
        }
    }

    # 2) Reconcile members
    if ($Members.Count -gt 0) {
        Write-Host "`nReconciling $($Members.Count) member(s)..." -ForegroundColor Cyan
        foreach ($upn in $Members) {
            $user = Invoke-GraphGet "$gbase/users/$([uri]::EscapeDataString($upn))"
            if (-not $user) { Write-Warning "User '$upn' not found — skipping."; continue }
            if ($PSCmdlet.ShouldProcess($upn, "Add to group '$groupName'")) {
                if (-not $groupId) { Write-Warning "Group id unknown (WhatIf create). Would add '$upn' after group creation."; continue }
                $ref = @{ '@odata.id' = "$gbase/directoryObjects/$($user.id)" } | ConvertTo-Json
                try {
                    Invoke-MgGraphRequest -Method POST -Uri "$gbase/groups/$groupId/members/`$ref" -Body $ref -ContentType 'application/json' -ErrorAction Stop | Out-Null
                    Write-Host "[APPLIED] Added '$upn'." -ForegroundColor Green
                }
                catch {
                    if ($_.Exception.Message -match 'already exist') { Write-Host "[OK] '$upn' already a member." -ForegroundColor DarkGray }
                    else { Write-Warning "Failed to add '$upn': $($_.Exception.Message)" }
                }
            }
        }
    }
    else {
        Write-Host "`nNo -Members supplied; group ensured but membership unchanged." -ForegroundColor DarkGray
    }

    Write-Host "`nScope targeting complete ($(if ($Commit) { 'COMMIT' } else { 'WHATIF' }))." -ForegroundColor Green
    if (-not $Commit) { Write-Host "No changes were made. Re-run with -Commit to apply." -ForegroundColor Yellow }
    Write-Host "Next: add '$groupName' to the Assignments of all TUNMAMG policies (keep the group set identical across them)."
}
catch {
    Write-Error "Set-ScopeTargeting failed: $($_.Exception.Message)"
    exit 1
}
finally {
    if (Get-MgContext -ErrorAction SilentlyContinue) { Disconnect-MgGraph | Out-Null }
}

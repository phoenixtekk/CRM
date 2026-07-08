<#
.SYNOPSIS
    PURVARCH-Set-Scope.ps1 - scaffold the pilot ring group (SG-PA-Pilot) and an example adaptive scope (AS-PA-Pilot); -WhatIf by default.
.DESCRIPTION
    PURPOSE
        Stands up the foundation "pilot ring" the architecture designs: a security group (default
        SG-PA-Pilot) that every capability validates on first, and - where adaptive scopes are in the
        design - an example query-based adaptive scope (default AS-PA-Pilot). SAFE BY DEFAULT: it runs in
        -WhatIf mode and only DESCRIBES what it would create/populate; nothing is written until -Commit is
        supplied. It creates NO capability policy (DLP, label, retention, insider risk) - only the ring and
        scope those policies will later target, in simulation/test first.
    HOW TO RUN
        # Dry-run (default) - report current state and what WOULD be created:
        powershell -ExecutionPolicy Bypass -File .\PURVARCH-Set-Scope.ps1
        # Create/populate after reviewing the dry-run:
        powershell -ExecutionPolicy Bypass -File .\PURVARCH-Set-Scope.ps1 -PilotMemberCsv .\pilot-members.csv -Commit

        PilotMemberCsv: a single column "Member" of UPNs to add to the pilot group. Prereqs:
        Microsoft.Graph (Connect-MgGraph, Group.ReadWrite.All to create/populate the group) and
        ExchangeOnlineManagement (Connect-IPPSSession) for the adaptive scope. Adaptive-scope availability
        is licensing-gated and the cmdlet surface evolves - VERIFY New-AdaptiveScope in your tenant.
    EXPECTED RESULTS
        Without -Commit: a plan showing whether SG-PA-Pilot / AS-PA-Pilot already exist and exactly what
        WOULD be created/added. With -Commit: the pilot group created if absent and members added, plus the
        adaptive scope scaffolded where supported - each with a PASS/FAIL line. PASS = pilot ring exists and
        holds the intended members; no capability policy was touched.
.NOTES
    White-label. -WhatIf by default; writes only with -Commit. Microsoft Graph + Security & Compliance
    PowerShell. No credentials in code. Removal of the ring/scope is safe until a capability policy targets it.
#>

[CmdletBinding()]
param(
    [string] $PilotGroupName    = 'SG-PA-Pilot',
    [string] $AdaptiveScopeName = 'AS-PA-Pilot',
    [string] $PilotMemberCsv,
    [switch] $SkipAdaptiveScope,
    [switch] $Commit
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

$mode = if ($Commit) { 'COMMIT (changes WILL be applied)' } else { '-WhatIf (dry-run - no changes)' }
Write-Section ("Mode: {0}" -f $mode)

# ------------------------------------------------------------------ pilot ring (Graph security group)
Write-Section ("Pilot ring group: {0}" -f $PilotGroupName)
$members = @()
if ($PilotMemberCsv) {
    if (-not (Test-Path $PilotMemberCsv)) { Write-Host ("  [WARN] member CSV not found: {0}" -f $PilotMemberCsv) -ForegroundColor Yellow }
    else { $members = @(Import-Csv -Path $PilotMemberCsv | ForEach-Object { $_.Member } | Where-Object { $_ }) }
}

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Host '  [SKIP] Microsoft.Graph not installed - cannot manage the pilot group. Install-Module Microsoft.Graph -Scope CurrentUser' -ForegroundColor Yellow
} else {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    try {
        $scopes = if ($Commit) { 'Group.ReadWrite.All' } else { 'Group.Read.All' }
        Connect-MgGraph -Scopes $scopes -NoWelcome
        $existing = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'" -f $PilotGroupName)).value
        if ($existing -and $existing.Count -gt 0) {
            $groupId = $existing[0].id
            Write-Host ("  [FOUND] {0} already exists (id={1})" -f $PilotGroupName, $groupId) -ForegroundColor Green
        } else {
            if ($Commit) {
                $body = @{
                    displayName     = $PilotGroupName
                    mailEnabled     = $false
                    mailNickname    = ($PilotGroupName -replace '[^0-9A-Za-z]', '')
                    securityEnabled  = $true
                }
                $new = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
                $groupId = $new.id
                Write-Host ("  [PASS] created security group {0} (id={1})" -f $PilotGroupName, $groupId) -ForegroundColor Green
            } else {
                $groupId = $null
                Write-Host ("  [WHATIF] would create security group {0}" -f $PilotGroupName)
            }
        }

        foreach ($m in $members) {
            if (-not $Commit) { Write-Host ("  [WHATIF] would add member {0}" -f $m); continue }
            if (-not $groupId) { continue }
            try {
                $u = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/users/{0}" -f $m)).id
                $ref = @{ '@odata.id' = ("https://graph.microsoft.com/v1.0/directoryObjects/{0}" -f $u) }
                Invoke-MgGraphRequest -Method POST -Uri ("/v1.0/groups/{0}/members/`$ref" -f $groupId) -Body ($ref | ConvertTo-Json) | Out-Null
                Write-Host ("  [PASS] added {0}" -f $m) -ForegroundColor Green
            } catch { Write-Host ("  [FAIL] add {0}: {1}" -f $m, $_.Exception.Message) -ForegroundColor Red }
        }
    } catch { Write-Host ("  [WARN] Graph group step failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}

# ------------------------------------------------------------------ adaptive scope (S&C PowerShell, licensing-gated)
if ($SkipAdaptiveScope) {
    Write-Section 'Adaptive scope: skipped (-SkipAdaptiveScope)'
} else {
    Write-Section ("Adaptive scope: {0}" -f $AdaptiveScopeName)
    try {
        if (-not (Get-Command Get-AdaptiveScope -ErrorAction SilentlyContinue)) {
            Connect-IPPSSession -ErrorAction Stop | Out-Null
        }
        if (-not (Get-Command New-AdaptiveScope -ErrorAction SilentlyContinue)) {
            Write-Host '  [CHECK] New-AdaptiveScope not available - adaptive scopes are licensing-/tenant-dependent. Verify your plan; use a static scope otherwise.' -ForegroundColor Yellow
        } else {
            $exists = @(Get-AdaptiveScope -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $AdaptiveScopeName })
            if ($exists.Count -gt 0) {
                Write-Host ("  [FOUND] adaptive scope {0} already exists" -f $AdaptiveScopeName) -ForegroundColor Green
            } elseif ($Commit) {
                # Example: scope users whose Department attribute marks them as the pilot ring.
                # Adjust the query to your design before committing in production.
                New-AdaptiveScope -Name $AdaptiveScopeName -LocationType User `
                    -FilterConditions @{ Conditions = @(@{ Key = 'Department'; Operator = 'Equals'; Value = @('PurviewPilot') }) } `
                    -ErrorAction Stop | Out-Null
                Write-Host ("  [PASS] created adaptive scope {0} (User / Department = PurviewPilot - adjust to your design)" -f $AdaptiveScopeName) -ForegroundColor Green
            } else {
                Write-Host ("  [WHATIF] would create adaptive scope {0} (User / Department = PurviewPilot - adjust to your design)" -f $AdaptiveScopeName)
            }
        }
    } catch { Write-Host ("  [WARN] adaptive-scope step failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}

Write-Section 'Summary'
if ($Commit) {
    Write-Host 'Pilot ring / adaptive scope scaffolded. Re-run PURVARCH-Discovery.ps1 to confirm.'
    Write-Host ("ROLLBACK: remove the group {0} and adaptive scope {1} in the portal - no capability policy references them yet, so removal is safe." -f $PilotGroupName, $AdaptiveScopeName)
} else {
    Write-Host 'Dry-run only. Review the plan above, then re-run with -Commit to create/populate.'
}
Write-Host 'This tool scaffolds ONLY the pilot ring/scope. Capability policies are built later, in simulation first.'

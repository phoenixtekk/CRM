<#
.SYNOPSIS
    GWCONSOL-Remediation.ps1 — Safe remediation of consolidation readiness gaps (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Fixes the identity-side readiness gaps that GWCONSOL-Validation.ps1 / GWCONSOL-Report.ps1
        surface, using Microsoft Graph:
          - CreateScopeGroups : create any missing per-wave scope groups
                                ("Consolidation Wave Scope - <Scope> - Pilot/Broad").
          - AddPilotMembers   : add users (from an input CSV) to a wave's Pilot group.
        Every mode is SAFE BY DEFAULT: it runs -WhatIf and only reports what it WOULD do. Pass -Apply to
        make changes (you will still be asked to confirm). Legacy-system decommissions themselves are
        NOT performed here — they are gated program actions executed under change control per the
        roadmap. This script only remediates the Microsoft Graph identity/targeting readiness side.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWCONSOL-Remediation.ps1 -Mode CreateScopeGroups
        Required Graph scopes: Group.ReadWrite.All, User.Read.All. Install once:
        Install-Module Microsoft.Graph -Scope CurrentUser
          Preview missing scope groups (default):  .\GWCONSOL-Remediation.ps1 -Mode CreateScopeGroups
          Apply:                                   .\GWCONSOL-Remediation.ps1 -Mode CreateScopeGroups -Apply
          Preview adding pilot members (CSV column UserPrincipalName):
                 .\GWCONSOL-Remediation.ps1 -Mode AddPilotMembers -Scope Collab -InputCsv .\collab-pilot.csv
          Apply: add -Apply to the above.
    EXPECTED RESULTS
        Without -Apply: a per-item "WOULD ..." report and no changes. With -Apply: each change is made
        (with confirmation) and reported. A summary of changed/skipped/failed items prints at the end.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][ValidateSet('CreateScopeGroups','AddPilotMembers')]
    [string]$Mode,
    [ValidateSet('Baseline','Collab','AI','Identity','Decommission')]
    [string]$Scope,
    [string]$InputCsv,
    [string]$GroupNamePrefix = "Consolidation Wave Scope",
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$changed = 0; $skipped = 0; $failed = 0

# Force preview unless -Apply (ShouldProcess honors WhatIfPreference automatically).
if (-not $Apply) { $WhatIfPreference = $true }

function Do-Action {
    param([string]$Target, [string]$Op, [scriptblock]$Action)
    try {
        if ($PSCmdlet.ShouldProcess($Target, $Op)) {
            & $Action
            Write-Host ("CHANGED: {0} - {1}" -f $Op, $Target) -ForegroundColor Green
            $script:changed++
        } else {
            Write-Host ("WOULD {0}: {1}" -f $Op, $Target) -ForegroundColor Yellow
            $script:skipped++
        }
    } catch {
        Write-Host ("FAILED: {0} - {1} :: {2}" -f $Op, $Target, $_.Exception.Message) -ForegroundColor Red
        $script:failed++
    }
}

function Get-GroupByName {
    param([string]$Name)
    Get-MgGroup -Filter "displayName eq '$Name'" -All -ErrorAction Stop | Select-Object -First 1
}

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
# Group.ReadWrite.All is required only to apply; reading uses the same scope set.
Connect-MgGraph -Scopes @("Group.ReadWrite.All","User.Read.All") -NoWelcome

switch ($Mode) {

    'CreateScopeGroups' {
        $scopes = if ($Scope) { @($Scope) } else { @('Baseline','Collab','AI','Identity','Decommission') }
        foreach ($sc in $scopes) {
            foreach ($stage in @('Pilot','Broad')) {
                $name = "$GroupNamePrefix - $sc - $stage"
                $existing = Get-GroupByName -Name $name
                if ($existing) {
                    Write-Host ("EXISTS: {0}" -f $name) -ForegroundColor DarkGray
                    $skipped++
                    continue
                }
                Do-Action -Target $name -Op "Create security group" -Action {
                    $mailNick = ($name -replace '[^a-zA-Z0-9]', '')
                    New-MgGroup -DisplayName $name -SecurityEnabled:$true -MailEnabled:$false `
                        -MailNickname $mailNick -GroupTypes @() -ErrorAction Stop | Out-Null
                }
            }
        }
    }

    'AddPilotMembers' {
        if (-not $Scope)    { throw "AddPilotMembers requires -Scope." }
        if (-not $InputCsv) { throw "AddPilotMembers requires -InputCsv (column: UserPrincipalName)." }
        if (-not (Test-Path $InputCsv)) { throw "Input CSV not found: $InputCsv" }

        $pilotName = "$GroupNamePrefix - $Scope - Pilot"
        $pilot = Get-GroupByName -Name $pilotName
        if (-not $pilot) { throw "Pilot group '$pilotName' not found - run CreateScopeGroups first." }

        $rows = Import-Csv $InputCsv
        foreach ($r in $rows) {
            $upn = $r.UserPrincipalName
            if (-not $upn) { continue }
            Do-Action -Target $upn -Op "Add to $pilotName" -Action {
                $user = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction Stop | Select-Object -First 1
                if (-not $user) { throw "User not found: $upn" }
                New-MgGroupMember -GroupId $pilot.Id -DirectoryObjectId $user.Id -ErrorAction Stop
            }
        }
    }
}

Disconnect-MgGraph | Out-Null

Write-Host ("`nSummary [{0}] - Changed: {1}  WouldChange/Skipped: {2}  Failed: {3}" -f $Mode, $changed, $skipped, $failed) -ForegroundColor Cyan
if (-not $Apply) { Write-Host "Preview only. Re-run with -Apply to make changes." -ForegroundColor Yellow }
Write-Host "Reminder: legacy-system decommissions are gated program actions under change control per the roadmap - not performed by this script." -ForegroundColor Yellow

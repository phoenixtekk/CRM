<#
.SYNOPSIS
    COPILOT-Set-ScopeTargeting.ps1 — create the Copilot pilot scope group (idempotent).
.DESCRIPTION
    PURPOSE
        Creates (idempotently) the Entra security group used to scope the controlled Microsoft 365
        Copilot rollout, following the solution naming convention so Copilot licensing, DLP-for-Copilot,
        and label policies can be assigned consistently:
            Copilot Adoption - Pilot Users - Pilot
        An existing group (matched by displayName) is reused, not duplicated. Members are NOT added —
        add a few representative pilot users by hand per your standard. Assign Copilot licenses to this
        group (group-based licensing) so scope stays tied to the group and is easy to roll back.
    HOW TO RUN
        Report only (default):  powershell -ExecutionPolicy Bypass -File .\COPILOT-Set-ScopeTargeting.ps1
        Apply:                  ... .\COPILOT-Set-ScopeTargeting.ps1 -Apply
        Requires the Microsoft Graph SDK and Group.ReadWrite.All.
    EXPECTED RESULTS
        The pilot scope group exists (created if missing, reused if present), with its object ID printed
        for use in Copilot licensing and Purview policy assignments.
.NOTES
    White-label — the repeatable way. Safe by default (-WhatIf); pass -Apply to create the group. The
    display name uses ASCII hyphens; keep it verbatim across scripts, licensing, and policy assignments.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [switch]$Apply
)

if (-not $Apply -and -not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All' -NoWelcome

$groups = @(
    'Copilot Adoption - Pilot Users - Pilot'
)

function Get-GroupByName([string]$name) {
    $escaped = $name.Replace("'","''")
    try { (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$escaped'").value } catch { @() }
}

function New-MailNickname([string]$name) {
    ($name -replace '[^a-zA-Z0-9]','').ToLower()
}

Write-Host "`n=== Copilot pilot scope group ===" -ForegroundColor Cyan
foreach ($g in $groups) {
    $existing = Get-GroupByName $g
    if ($existing) {
        Write-Host ("  EXISTS: {0}  (id {1})" -f $g, $existing[0].id) -ForegroundColor Green
        continue
    }
    if ($PSCmdlet.ShouldProcess($g, "Create Entra security group")) {
        $body = @{
            displayName     = $g
            description     = "Scope group for the Microsoft 365 Copilot secure-adoption pilot ($g)."
            mailEnabled     = $false
            mailNickname    = (New-MailNickname $g)
            securityEnabled = $true
        }
        try {
            $created = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
            Write-Host ("  CREATED: {0}  (id {1})" -f $g, $created.id) -ForegroundColor Green
        } catch {
            Write-Host ("  Failed to create {0}: {1}" -f $g, $_.Exception.Message) -ForegroundColor Red
        }
    }
}

Write-Host "`nAdd a few representative pilot users, then assign Copilot licenses to this group (Implementation Steps 5-7)." -ForegroundColor Yellow
Disconnect-MgGraph | Out-Null

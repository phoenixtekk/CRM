<#
.SYNOPSIS
    M365SEC-Set-ScopeTargeting.ps1 — create the baseline scope Entra groups (pilot / broad).
.DESCRIPTION
    PURPOSE
        Creates (idempotently) the Entra security groups used to scope the Microsoft 365 baseline
        pilot and expansion, following the solution naming convention so scoped policies
        (Conditional Access, DLP, preset security policies) can be assigned consistently:
            M365 Baseline Scope - Pilot - Users
            M365 Baseline Scope - Broad - Users
        Existing groups (matched by displayName) are reused, not duplicated. Members are NOT added —
        add pilot users by hand or via dynamic rules per your standard.
    HOW TO RUN
        Report only (default, safe):  powershell -ExecutionPolicy Bypass -File .\M365SEC-Set-ScopeTargeting.ps1
        Apply:                        ... .\M365SEC-Set-ScopeTargeting.ps1 -Apply
        Requires the Microsoft Graph SDK and Group.ReadWrite.All.
    EXPECTED RESULTS
        The two scope groups exist (created if missing, reused if present), with their object IDs
        printed for use in the scoped-policy assignments in the Implementation Guide.
.NOTES
    White-label — the repeatable way. Safe by default (-WhatIf); pass -Apply to create groups.
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
    'M365 Baseline Scope - Pilot - Users',
    'M365 Baseline Scope - Broad - Users'
)

function Get-GroupByName([string]$name) {
    $escaped = $name.Replace("'","''")
    try { (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$escaped'").value } catch { @() }
}

function New-MailNickname([string]$name) {
    ($name -replace '[^a-zA-Z0-9]','').ToLower()
}

Write-Host "`n=== M365 baseline scope groups ===" -ForegroundColor Cyan
foreach ($g in $groups) {
    $existing = Get-GroupByName $g
    if ($existing) {
        Write-Host ("  EXISTS: {0}  (id {1})" -f $g, $existing[0].id) -ForegroundColor Green
        continue
    }
    if ($PSCmdlet.ShouldProcess($g, "Create Entra security group")) {
        $body = @{
            displayName     = $g
            description     = "Scope group for the Microsoft 365 security baseline ($g)."
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

Write-Host "`nAssign these groups to the scoped Conditional Access / DLP / preset security policies (Implementation Steps 3-6)." -ForegroundColor Yellow
Disconnect-MgGraph | Out-Null

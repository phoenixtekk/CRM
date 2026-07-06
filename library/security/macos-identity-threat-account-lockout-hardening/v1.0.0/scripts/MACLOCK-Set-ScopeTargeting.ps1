<#
.SYNOPSIS
    MACLOCK-Set-ScopeTargeting.ps1 — create the Mac scope Entra groups (pilot / broad).
.DESCRIPTION
    PURPOSE
        Creates (idempotently) the Entra security groups used to scope the macOS identity-hardening
        pilot and expansion, following the solution naming convention so the MFA Conditional Access
        policy and the Intune-delivered Mac remediation can be assigned consistently:
            MACLOCK Scope - Pilot - Macs
            MACLOCK Scope - Broad - Macs
        Existing groups (matched by displayName) are reused, not duplicated. Members are NOT added —
        add the pilot users (or their Macs) by hand or via dynamic rules per your standard. Use
        'your-tenant-id' style values, not bracketed placeholders.
    HOW TO RUN
        Report only (default, safe):  powershell -ExecutionPolicy Bypass -File .\MACLOCK-Set-ScopeTargeting.ps1
        Apply:                        ... .\MACLOCK-Set-ScopeTargeting.ps1 -Apply
        Requires the Microsoft Graph SDK and Group.ReadWrite.All.
    EXPECTED RESULTS
        The two scope groups exist (created if missing, reused if present), with their object IDs
        printed for use in the MFA Conditional Access assignment (Implementation Step 4) and the
        Intune remediation assignment (Implementation Step 5).
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
    'MACLOCK Scope - Pilot - Macs',
    'MACLOCK Scope - Broad - Macs'
)

function Get-GroupByName([string]$name) {
    $escaped = $name.Replace("'","''")
    try { (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$escaped'").value } catch { @() }
}

function New-MailNickname([string]$name) {
    ($name -replace '[^a-zA-Z0-9]','').ToLower()
}

Write-Host "`n=== MACLOCK scope groups ===" -ForegroundColor Cyan
foreach ($g in $groups) {
    $existing = Get-GroupByName $g
    if ($existing) {
        Write-Host ("  EXISTS: {0}  (id {1})" -f $g, $existing[0].id) -ForegroundColor Green
        continue
    }
    if ($PSCmdlet.ShouldProcess($g, "Create Entra security group")) {
        $body = @{
            displayName     = $g
            description     = "Scope group for the macOS identity-threat & account-lockout hardening solution ($g)."
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

Write-Host "`nAssign 'MACLOCK Scope - Pilot - Macs' to the MFA Conditional Access policy (Step 4) and the Intune Mac remediation (Step 5)." -ForegroundColor Yellow
Disconnect-MgGraph | Out-Null

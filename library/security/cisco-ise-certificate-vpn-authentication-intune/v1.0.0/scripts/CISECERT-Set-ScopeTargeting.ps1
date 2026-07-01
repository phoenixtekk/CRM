<#
.SYNOPSIS
    CISECERT-Set-ScopeTargeting.ps1 — create the Cisco VPN certificate scope Entra groups (pilot/broad).
.DESCRIPTION
    PURPOSE
        Creates (idempotently) the Entra security groups used to scope Cisco EAP-TLS VPN certificate
        issuance, following the solution naming convention so the Intune Trusted Root and SCEP/PKCS
        profiles can be assigned consistently:
            PILOT - Cisco Cert VPN Users
            BROAD - Cisco Cert VPN Users
        Existing groups (matched by displayName) are reused, not duplicated. Members are NOT added —
        add pilot users/devices by hand or via dynamic rules per your standard.
    HOW TO RUN
        Report only (default):  powershell -ExecutionPolicy Bypass -File .\CISECERT-Set-ScopeTargeting.ps1
        Apply:                  powershell -ExecutionPolicy Bypass -File .\CISECERT-Set-ScopeTargeting.ps1 -Apply
        Requires the Microsoft Graph PowerShell SDK and consent to: Group.ReadWrite.All.
    EXPECTED RESULTS
        The two scope groups exist (created if missing, reused if present), with their object IDs
        printed for use in the Intune profile assignments (Implementation Steps 2-3).
.NOTES
    White-label — the repeatable way. Read-only unless -Apply (safe by default -WhatIf). Cisco ISE internals deferred to vendor docs.
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
    'PILOT - Cisco Cert VPN Users',
    'BROAD - Cisco Cert VPN Users'
)

function Get-GroupByName([string]$name) {
    $escaped = $name.Replace("'","''")
    try { (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$escaped'").value } catch { @() }
}

function New-MailNickname([string]$name) {
    ($name -replace '[^a-zA-Z0-9]','').ToLower()
}

Write-Host "`n=== Cisco VPN certificate scope groups ===" -ForegroundColor Cyan
foreach ($g in $groups) {
    $existing = Get-GroupByName $g
    if ($existing) {
        Write-Host ("  EXISTS: {0}  (id {1})" -f $g, $existing[0].id) -ForegroundColor Green
        continue
    }
    if ($PSCmdlet.ShouldProcess($g, "Create Entra security group")) {
        $body = @{
            displayName     = $g
            description     = "Scope group for Cisco EAP-TLS VPN certificate issuance ($g)."
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

Write-Host "`nNext: add pilot members to 'PILOT - Cisco Cert VPN Users', then assign both groups to" -ForegroundColor Yellow
Write-Host "'Cisco VPN - Trusted Root' and the SCEP/PKCS profile (Implementation Steps 2-3, expand at Step 7)." -ForegroundColor Yellow
Disconnect-MgGraph | Out-Null

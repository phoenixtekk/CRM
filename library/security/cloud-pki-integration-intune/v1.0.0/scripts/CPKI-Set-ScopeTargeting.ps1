<#
.SYNOPSIS
    CPKI-Set-ScopeTargeting.ps1 — create the certificate-scope Entra groups (devices/users, pilot/broad).
.DESCRIPTION
    PURPOSE
        Creates (idempotently) the four Entra security groups used to scope cloud PKI certificate
        issuance, following the solution naming convention so the Intune trust / SCEP / PKCS / Wi-Fi /
        VPN profiles can be assigned consistently:
            Cloud PKI Cert - Devices - Pilot
            Cloud PKI Cert - Devices - Broad
            Cloud PKI Cert - Users  - Pilot
            Cloud PKI Cert - Users  - Broad
        Existing groups (matched by displayName) are reused, not duplicated. Members are NOT added —
        add pilot devices/users by hand or via dynamic rules per your standard.
    HOW TO RUN
        Report only (default):  powershell -ExecutionPolicy Bypass -File .\CPKI-Set-ScopeTargeting.ps1
        Apply:                  ... .\CPKI-Set-ScopeTargeting.ps1 -Apply
        Requires the Microsoft Graph SDK and Group.ReadWrite.All.
    EXPECTED RESULTS
        The four scope groups exist (created if missing, reused if present), with their object IDs
        printed for use in the Intune profile assignments.
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
    'Cloud PKI Cert - Devices - Pilot',
    'Cloud PKI Cert - Devices - Broad',
    'Cloud PKI Cert - Users - Pilot',
    'Cloud PKI Cert - Users - Broad'
)

function Get-GroupByName([string]$name) {
    $escaped = $name.Replace("'","''")
    try { (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$escaped'").value } catch { @() }
}

function New-MailNickname([string]$name) {
    ($name -replace '[^a-zA-Z0-9]','').ToLower()
}

Write-Host "`n=== Cloud PKI certificate scope groups ===" -ForegroundColor Cyan
foreach ($g in $groups) {
    $existing = Get-GroupByName $g
    if ($existing) {
        Write-Host ("  EXISTS: {0}  (id {1})" -f $g, $existing[0].id) -ForegroundColor Green
        continue
    }
    if ($PSCmdlet.ShouldProcess($g, "Create Entra security group")) {
        $body = @{
            displayName     = $g
            description     = "Scope group for cloud PKI certificate issuance ($g)."
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

Write-Host "`nAssign these groups to the Trusted certificate, SCEP/PKCS, and Wi-Fi/VPN profiles (Implementation Steps 3-6)." -ForegroundColor Yellow
Disconnect-MgGraph | Out-Null
